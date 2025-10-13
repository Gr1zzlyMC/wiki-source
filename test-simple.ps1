# Simple MediaWiki Test

$WIKI_API = "https://wiki.2bz.org/api.php"

Write-Host "`nTesting connection to: $WIKI_API`n" -ForegroundColor Cyan

Write-Host "[Test 1] Can we reach the API?" -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "$WIKI_API`?action=query&meta=siteinfo&format=json" -UseBasicParsing -ErrorAction Stop
    Write-Host "SUCCESS: API is reachable!`n" -ForegroundColor Green
} catch {
    Write-Host "FAILED: Cannot reach API" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)`n" -ForegroundColor Red
    exit 1
}

Write-Host "[Test 2] Now testing with your credentials..." -ForegroundColor Yellow
$WIKI_USER = Read-Host "Enter your bot username (e.g., Username@BotName)"
$securePass = Read-Host "Enter your bot password" -AsSecureString
$WIKI_PASS = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePass))

try {
    $body = @{
        action = "login"
        lgname = $WIKI_USER
        lgpassword = $WIKI_PASS
        format = "json"
    }
    $result = Invoke-RestMethod -Uri $WIKI_API -Method Post -Body $body -ErrorAction Stop
    Write-Host "Login result: $($result.login.result)" -ForegroundColor Cyan
    
    if ($result.login.result -eq "Success") {
        Write-Host "SUCCESS: Authentication works!`n" -ForegroundColor Green
    } else {
        Write-Host "Authentication response: $($result | ConvertTo-Json)`n" -ForegroundColor Yellow
    }
} catch {
    Write-Host "FAILED: $($_.Exception.Message)`n" -ForegroundColor Red
}

Write-Host "If Test 1 passed, your wiki is accessible." -ForegroundColor Green
Write-Host "If Test 2 shows 'NeedToken', that's normal - credentials are likely correct.`n" -ForegroundColor Green

