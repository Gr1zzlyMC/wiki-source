# Pull all pages from MediaWiki to local Git repository (PowerShell version)
# This script fetches all pages from your MediaWiki and converts them to files

Write-Host "MediaWiki to GitHub Sync Script" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# Prompt for credentials
$WIKI_API = Read-Host "Enter your MediaWiki API URL (e.g., https://wiki.example.com/api.php)"
$WIKI_USER = Read-Host "Enter your MediaWiki username"
$WIKI_PASS = Read-Host "Enter your MediaWiki password (or bot password)" -AsSecureString
$WIKI_PASS_TEXT = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($WIKI_PASS))

Write-Host ""

# Extract base URL from API URL
$WIKI_API = $WIKI_API -replace '\?.*$','' -replace '#.*$',''
$WIKI_API = $WIKI_API -replace '/api\.php$','' -replace '/index\.php$',''
$WIKI_API = $WIKI_API.TrimEnd('/')

# Extract scheme and rest
if ($WIKI_API -match '^(https?)://(.+)$') {
    $SCHEME = $matches[1]
    $REST = $matches[2]
} else {
    Write-Host "Error: Invalid API URL format" -ForegroundColor Red
    exit 1
}

$BASE_URL = "${SCHEME}://${REST}"
$MEDIAWIKI_REMOTE = "mediawiki::${SCHEME}://${WIKI_USER}:${WIKI_PASS_TEXT}@${REST}"

Write-Host "Base URL: $BASE_URL" -ForegroundColor Yellow
Write-Host ""

# Check if we're in a git repository
if (-not (Test-Path .git)) {
    Write-Host "Error: Not in a git repository. Please run 'git init' first." -ForegroundColor Red
    exit 1
}

# Check if mediawiki remote already exists
$remotes = git remote
if ($remotes -contains "wiki") {
    Write-Host "MediaWiki remote 'wiki' already exists. Updating..." -ForegroundColor Yellow
    git remote set-url wiki "$MEDIAWIKI_REMOTE"
} else {
    Write-Host "Adding MediaWiki remote as 'wiki'..." -ForegroundColor Green
    git remote add wiki "$MEDIAWIKI_REMOTE"
}

Write-Host ""
Write-Host "Fetching all pages from MediaWiki..." -ForegroundColor Cyan
Write-Host "This may take a while depending on the number of pages..." -ForegroundColor Yellow
Write-Host ""

# Fetch from MediaWiki
try {
    git fetch wiki 2>&1 | Write-Host
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "✓ Successfully fetched from MediaWiki!" -ForegroundColor Green
        Write-Host ""
        
        # Show what branches are available
        Write-Host "Available MediaWiki branches:" -ForegroundColor Cyan
        git branch -r | Where-Object { $_ -like "*wiki/*" } | Write-Host
        Write-Host ""
        
        # Check current branch
        $CURRENT_BRANCH = git rev-parse --abbrev-ref HEAD 2>$null
        
        if ([string]::IsNullOrEmpty($CURRENT_BRANCH) -or $CURRENT_BRANCH -eq "HEAD") {
            Write-Host "No local branch detected. Creating 'main' branch..." -ForegroundColor Yellow
            git checkout -b main
            $CURRENT_BRANCH = "main"
        }
        
        # Merge the master branch from MediaWiki
        Write-Host "Merging MediaWiki pages into current branch ($CURRENT_BRANCH)..." -ForegroundColor Cyan
        Write-Host ""
        
        git merge wiki/master --allow-unrelated-histories 2>&1 | Write-Host
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "✓ Successfully merged MediaWiki pages!" -ForegroundColor Green
            Write-Host ""
            Write-Host "Pages have been downloaded to your local repository." -ForegroundColor Green
            Write-Host ""
            Write-Host "Next steps:" -ForegroundColor Cyan
            Write-Host "1. Review the downloaded files: dir" -ForegroundColor Yellow
            Write-Host "2. Push to GitHub: git push origin $CURRENT_BRANCH" -ForegroundColor Yellow
            Write-Host ""
        } else {
            Write-Host ""
            Write-Host "⚠ Merge conflict occurred. You may need to resolve conflicts manually." -ForegroundColor Yellow
            Write-Host "After resolving conflicts, run:" -ForegroundColor Yellow
            Write-Host "  git add ." -ForegroundColor White
            Write-Host "  git commit -m 'Merged pages from MediaWiki'" -ForegroundColor White
            Write-Host "  git push origin $CURRENT_BRANCH" -ForegroundColor White
            Write-Host ""
        }
    } else {
        throw "Fetch failed"
    }
} catch {
    Write-Host ""
    Write-Host "✗ Failed to fetch from MediaWiki" -ForegroundColor Red
    Write-Host ""
    Write-Host "Possible issues:" -ForegroundColor Yellow
    Write-Host "1. git-remote-mediawiki is not installed" -ForegroundColor White
    Write-Host "2. Incorrect credentials" -ForegroundColor White
    Write-Host "3. MediaWiki API is not accessible" -ForegroundColor White
    Write-Host ""
    Write-Host "To install git-remote-mediawiki on Windows:" -ForegroundColor Cyan
    Write-Host "  - Install Strawberry Perl or ActivePerl" -ForegroundColor White
    Write-Host "  - Run: cpan MediaWiki::API" -ForegroundColor White
    Write-Host "  - Add git-remote-mediawiki to your PATH" -ForegroundColor White
    exit 1
}

