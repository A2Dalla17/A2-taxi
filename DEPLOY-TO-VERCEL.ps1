<#
  AC7 Ride — deploy the phone preview to Vercel
  ===========================================================================

  Run this and you get a live URL you can open on your phone.

  It uploads the frontend folder straight to Vercel. No GitHub needed for
  this — that can come later, and doesn't block seeing the app.

  WHAT YOU HAVE TO DO
    One thing: when the browser opens, approve the Vercel login. That is
    your account and your password, so it has to be you. Everything else
    below is automatic.

  HOW TO RUN
    Right-click this file  ->  "Run with PowerShell"

    Or from a PowerShell window:
      cd "C:\Users\hassa\OneDrive\Documents\A2 Projects\Taxi App\AC7 Taxi"
      .\DEPLOY-TO-VERCEL.ps1

  If Windows blocks it, run this once first:
      Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
#>

$ErrorActionPreference = 'Stop'

function Step($n, $text) { Write-Host "`n[$n] $text" -ForegroundColor Cyan }
function Ok($text)       { Write-Host "    $text" -ForegroundColor Green }
function Warn($text)     { Write-Host "    $text" -ForegroundColor Yellow }
function Die($text)      { Write-Host "`n  $text`n" -ForegroundColor Red; Read-Host "Press Enter to close"; exit 1 }

$root     = Split-Path -Parent $MyInvocation.MyCommand.Path
$frontend = Join-Path $root 'frontend'

Write-Host ""
Write-Host "  AC7 RIDE - phone preview deploy" -ForegroundColor White
Write-Host "  ===============================" -ForegroundColor DarkGray

# --------------------------------------------------------------------------
Step 1 "Checking Node.js"

try {
    $nodeVersion = (node --version) 2>$null
    Ok "Node $nodeVersion"
} catch {
    Die "Node.js isn't installed. Get it from https://nodejs.org (pick LTS), then run this again."
}

if (-not (Test-Path $frontend)) {
    Die "Can't find the frontend folder. This script must sit in the AC7 Taxi folder."
}

# --------------------------------------------------------------------------
Step 2 "Installing dependencies"
Write-Host "    (first run takes a minute or two)" -ForegroundColor DarkGray

Push-Location $frontend
try {
    npm install --no-audit --no-fund 2>&1 | Out-Null
    Ok "Dependencies ready"
} catch {
    Pop-Location
    Die "npm install failed. Check your internet connection and try again."
}

# --------------------------------------------------------------------------
Step 3 "Test build (catches errors before uploading)"

# Vercel rebuilds on its own servers, so these local variables only serve as
# a pre-flight check. The ones that actually matter are passed to Vercel with
# --build-env in step 5 - setting them here alone would produce a deployed
# app WITHOUT preview mode, showing a login screen that cannot work.
$env:VITE_PREVIEW_MODE     = 'true'
$env:VITE_DEFAULT_MAP_LAT  = '51.5074'
$env:VITE_DEFAULT_MAP_LNG  = '-0.1278'
$env:VITE_DEFAULT_MAP_ZOOM = '13'
$env:VITE_DEFAULT_CURRENCY = 'GBP'
$env:VITE_LOCALE           = 'en-GB'

try {
    npx --yes vite build 2>&1 | Out-Null
    if (-not (Test-Path (Join-Path $frontend 'dist\index.html'))) { throw "no output" }
    Ok "Built"
} catch {
    Pop-Location
    Die "The build failed. Copy the error above and send it to Claude."
}

# --------------------------------------------------------------------------
Step 4 "Signing in to Vercel"
Write-Host ""
Warn "A browser window will open. Approve the login there."
Warn "If you don't have a Vercel account, choose 'Continue with GitHub' -"
Warn "it's free and takes about 20 seconds."
Write-Host ""

try {
    npx --yes vercel@latest whoami 2>&1 | Out-Null
    Ok "Already signed in"
} catch {
    npx --yes vercel@latest login
    if ($LASTEXITCODE -ne 0) { Pop-Location; Die "Vercel login didn't complete. Run the script again." }
    Ok "Signed in"
}

# --------------------------------------------------------------------------
Step 5 "Deploying"
Write-Host "    Answer the prompts like this:" -ForegroundColor DarkGray
Write-Host "      Set up and deploy?      Y" -ForegroundColor DarkGray
Write-Host "      Which scope?            your own name" -ForegroundColor DarkGray
Write-Host "      Link to existing?       N" -ForegroundColor DarkGray
Write-Host "      Project name?           ac7-taxi" -ForegroundColor DarkGray
Write-Host "      Code directory?         ./           (just press Enter)" -ForegroundColor DarkGray
Write-Host "      Modify settings?        N" -ForegroundColor DarkGray
Write-Host ""

# --build-env passes these to Vercel's build, which is where they are needed.
#   VITE_PREVIEW_MODE=true  is the one that matters. Without it the deployed
#   app tries to reach a backend that isn't running and you get a dead login
#   screen instead of the app.
#
# --prod publishes to the main URL rather than a throwaway preview one, so
# the link stays the same every time you redeploy.
npx --yes vercel@latest deploy --prod `
    --build-env VITE_PREVIEW_MODE=true `
    --build-env VITE_DEFAULT_MAP_LAT=51.5074 `
    --build-env VITE_DEFAULT_MAP_LNG=-0.1278 `
    --build-env VITE_DEFAULT_MAP_ZOOM=13 `
    --build-env VITE_DEFAULT_CURRENCY=GBP `
    --build-env VITE_LOCALE=en-GB

$deployed = $LASTEXITCODE -eq 0
Pop-Location

Write-Host ""
if ($deployed) {
    Write-Host "  Done." -ForegroundColor Green
    Write-Host ""
    Write-Host "  The URL above is live. Open it on your phone." -ForegroundColor White
    Write-Host ""
    Write-Host "  To make it look like a real app:" -ForegroundColor White
    Write-Host "    iPhone   Share button  ->  Add to Home Screen" -ForegroundColor Gray
    Write-Host "    Android  three dots    ->  Add to Home screen" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  The yellow PREVIEW pill at the bottom switches between" -ForegroundColor White
    Write-Host "  Rider, Driver and Admin." -ForegroundColor White
} else {
    Write-Host "  The deploy didn't finish. Copy the error above and send it to Claude." -ForegroundColor Red
}

Write-Host ""
Read-Host "Press Enter to close"
