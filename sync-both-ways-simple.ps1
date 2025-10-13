# Two-way sync between GitHub and MediaWiki (PowerShell version)
# This script helps you sync pages in both directions

Write-Host "Two-Way Wiki Sync Script" -ForegroundColor Cyan
Write-Host "========================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This script will help you sync between GitHub and MediaWiki" -ForegroundColor Yellow
Write-Host ""

# Menu
Write-Host "Select sync direction:" -ForegroundColor Cyan
Write-Host "1. Pull from MediaWiki to GitHub (download all wiki pages)" -ForegroundColor White
Write-Host "2. Push from GitHub to MediaWiki (upload local changes)" -ForegroundColor White
Write-Host "3. Full sync (pull then push - recommended)" -ForegroundColor Green
Write-Host "4. Exit" -ForegroundColor White
Write-Host ""

$choice = Read-Host "Enter your choice (1-4)"

if ($choice -eq "4") {
    Write-Host "Exiting..." -ForegroundColor Yellow
    exit 0
}

# Get credentials
Write-Host ""
$WIKI_API = Read-Host "Enter your MediaWiki API URL (e.g., https://wiki.example.com/api.php)"
$WIKI_USER = Read-Host "Enter your MediaWiki username"
$WIKI_PASS = Read-Host "Enter your MediaWiki password (or bot password)" -AsSecureString
$WIKI_PASS_TEXT = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($WIKI_PASS))

Write-Host ""

# Extract base URL
$WIKI_API = $WIKI_API -replace '\?.*$','' -replace '#.*$',''
$WIKI_API = $WIKI_API -replace '/api\.php$','' -replace '/index\.php$',''
$WIKI_API = $WIKI_API.TrimEnd('/')

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

# Check git repository
if (-not (Test-Path .git)) {
    Write-Host "Error: Not in a git repository. Please run 'git init' first." -ForegroundColor Red
    exit 1
}

# Setup MediaWiki remote
$remotes = git remote
if ($remotes -contains "wiki") {
    git remote set-url wiki "$MEDIAWIKI_REMOTE" 2>&1 | Out-Null
} else {
    git remote add wiki "$MEDIAWIKI_REMOTE" 2>&1 | Out-Null
}

# Get current branch
$CURRENT_BRANCH = git rev-parse --abbrev-ref HEAD 2>$null
if ([string]::IsNullOrEmpty($CURRENT_BRANCH) -or $CURRENT_BRANCH -eq "HEAD") {
    Write-Host "Creating 'main' branch..." -ForegroundColor Yellow
    git checkout -b main
    $CURRENT_BRANCH = "main"
}

# Function to pull from MediaWiki
function Pull-FromMediaWiki {
    Write-Host ""
    Write-Host "=== PULLING FROM MEDIAWIKI ===" -ForegroundColor Cyan
    Write-Host "Fetching all pages from MediaWiki..." -ForegroundColor Yellow
    Write-Host ""
    
    git fetch wiki 2>&1 | Write-Host
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "[SUCCESS] Fetched from MediaWiki!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Merging MediaWiki pages into $CURRENT_BRANCH..." -ForegroundColor Yellow
        
        git merge wiki/master --allow-unrelated-histories -m "Sync from MediaWiki" 2>&1 | Write-Host
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "[SUCCESS] Merged MediaWiki pages!" -ForegroundColor Green
            return $true
        } else {
            Write-Host ""
            Write-Host "[WARNING] Merge conflict. Please resolve conflicts manually." -ForegroundColor Yellow
            return $false
        }
    } else {
        Write-Host ""
        Write-Host "[ERROR] Failed to fetch from MediaWiki" -ForegroundColor Red
        return $false
    }
}

# Function to push to MediaWiki
function Push-ToMediaWiki {
    Write-Host ""
    Write-Host "=== PUSHING TO MEDIAWIKI ===" -ForegroundColor Cyan
    Write-Host "Pushing changes to MediaWiki..." -ForegroundColor Yellow
    Write-Host ""
    
    $refspec = "${CURRENT_BRANCH}:refs/heads/master"
    git push wiki $refspec 2>&1 | Write-Host
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "[SUCCESS] Pushed to MediaWiki!" -ForegroundColor Green
        return $true
    } else {
        Write-Host ""
        Write-Host "[ERROR] Failed to push to MediaWiki" -ForegroundColor Red
        return $false
    }
}

# Execute based on choice
switch ($choice) {
    "1" {
        # Pull only
        if (Pull-FromMediaWiki) {
            Write-Host ""
            Write-Host "Next step: Push to GitHub with 'git push origin $CURRENT_BRANCH'" -ForegroundColor Cyan
        }
    }
    "2" {
        # Push only
        if (Push-ToMediaWiki) {
            Write-Host ""
            Write-Host "[SUCCESS] Changes are now live on MediaWiki!" -ForegroundColor Green
        }
    }
    "3" {
        # Full sync
        Write-Host "Starting full two-way sync..." -ForegroundColor Cyan
        
        # First pull from MediaWiki
        if (Pull-FromMediaWiki) {
            # Then push to MediaWiki (in case we had local changes)
            if (Push-ToMediaWiki) {
                Write-Host ""
                Write-Host "=== SYNCING TO GITHUB ===" -ForegroundColor Cyan
                Write-Host "Pushing to GitHub..." -ForegroundColor Yellow
                
                # Check if origin remote exists
                $remotes = git remote
                if ($remotes -contains "origin") {
                    git push origin $CURRENT_BRANCH 2>&1 | Write-Host
                    
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host ""
                        Write-Host "[SUCCESS] Pushed to GitHub!" -ForegroundColor Green
                        Write-Host ""
                        Write-Host "Full sync complete! All repositories are now in sync." -ForegroundColor Green
                    } else {
                        Write-Host ""
                        Write-Host "[WARNING] Failed to push to GitHub. You may need to set up the remote first:" -ForegroundColor Yellow
                        Write-Host "  git remote add origin YOUR-GITHUB-REPO-URL" -ForegroundColor White
                    }
                } else {
                    Write-Host ""
                    Write-Host "[WARNING] No GitHub remote found. Add it with:" -ForegroundColor Yellow
                    Write-Host "  git remote add origin YOUR-GITHUB-REPO-URL" -ForegroundColor White
                    Write-Host "  git push -u origin $CURRENT_BRANCH" -ForegroundColor White
                }
            }
        }
    }
    default {
        Write-Host "Invalid choice. Exiting..." -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "========================" -ForegroundColor Cyan
Write-Host "Sync operation complete!" -ForegroundColor Cyan
Write-Host ""

