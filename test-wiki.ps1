# Simple MediaWiki Connection Test

Write-Host "`nMediaWiki Connection Test`n" -ForegroundColor Cyan

$WIKI_API = Read-Host "Enter your MediaWiki API URL"
$WIKI_USER = Read-Host "Enter your MediaWiki username"
$WIKI_PASS = Read-Host "Enter your MediaWiki password" -AsSecureString
$WIKI_PASS_TEXT = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($WIKI_PASS))

Write-Host "`n[Test 1] Checking API accessibility..." -ForegroundColor Yellow
try {
    Invoke-WebRequest -Uri "$WIKI_API?action=query&meta=siteinfo&format=json" -UseBasicParsing | Out-Null
    Write-Host "SUCCESS: API is accessible`n" -ForegroundColor Green
} catch {
    Write-Host "FAILED: $($_.Exception.Message)`n" -ForegroundColor Red
    exit 1
}

Write-Host "[Test 2] Testing authentication..." -ForegroundColor Yellow
try {
    $body = @{action="login"; lgname=$WIKI_USER; lgpassword=$WIKI_PASS_TEXT; format="json"}
    $result = Invoke-RestMethod -Uri $WIKI_API -Method Post -Body $body
    Write-Host "Response: $($result | ConvertTo-Json -Compress)" -ForegroundColor Gray
    Write-Host "Result: $($result.login.result)`n" -ForegroundColor Cyan
} catch {
    Write-Host "FAILED: $($_.Exception.Message)`n" -ForegroundColor Red
}

Write-Host "[Test 3] URL format check..." -ForegroundColor Yellow
$WIKI_API -match "^(https?://)?(.+?)(/api\.php)?(\?.*)?$" | Out-Null
$baseUrl = $matches[2] -replace "/$", ""
Write-Host "Git URL would be: mediawiki::https://${WIKI_USER}:PASSWORD@${baseUrl}`n" -ForegroundColor Cyan

Write-Host "Done! Check results above.`n" -ForegroundColor Green

