<#
.SYNOPSIS
    AC7 Ride — deploy everything, one command.

.DESCRIPTION
    Installs the CLIs, deploys the Go auth service to Fly.io and the React app
    to Vercel, then wires CORS between them.

    Two browser sign-ins are unavoidable (Fly and Vercel) — those cannot be
    scripted. Everything else runs unattended.

.EXAMPLE
    .\DEPLOY.ps1
#>

[CmdletBinding()]
param(
    [string]$AppName  = 'ac7-ride-auth',
    [string]$Region   = 'lhr',
    [switch]$SkipInstall
)

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot

function Step { param($n,$m) Write-Host "`n[$n] $m" -ForegroundColor Cyan }
function Ok   { param($m) Write-Host "    OK  $m" -ForegroundColor Green }
function Warn { param($m) Write-Host "    !   $m" -ForegroundColor Yellow }
function Fail { param($m) Write-Host "    X   $m" -ForegroundColor Red }

Write-Host @"

  ===========================================
   AC7 Ride - deploy
  ===========================================

   Backend  -> Fly.io    (free tier)
   Frontend -> Vercel    (free)
   Database -> Supabase  (already live)

   You will be asked to sign in twice, in a
   browser. Everything else is automatic.

"@ -ForegroundColor White

# ---------------------------------------------------------------------------
# 1. Tooling
# ---------------------------------------------------------------------------
Step 1 'Checking tools'

if (-not $SkipInstall) {
    if (-not (Get-Command fly -ErrorAction SilentlyContinue)) {
        Write-Host '    Installing the Fly CLI...' -ForegroundColor DarkGray
        iwr https://fly.io/install.ps1 -useb | iex

        # The installer adds this to the user PATH, but the current process
        # will not see it until we add it by hand.
        $flyBin = "$env:USERPROFILE\.fly\bin"
        if (Test-Path $flyBin) { $env:PATH = "$flyBin;$env:PATH" }
    }

    if (-not (Get-Command vercel -ErrorAction SilentlyContinue)) {
        Write-Host '    Installing the Vercel CLI...' -ForegroundColor DarkGray
        npm i -g vercel --silent
    }
}

foreach ($tool in 'fly','vercel','npm') {
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
        Fail "$tool is still not on PATH."
        Write-Host '    Close PowerShell, reopen it, and run this script again.' -ForegroundColor Yellow
        exit 1
    }
}
Ok 'fly, vercel and npm are available'

# ---------------------------------------------------------------------------
# 2. Sign in
# ---------------------------------------------------------------------------
Step 2 'Signing in (browser windows will open)'

$flyOk = $false
try { fly auth whoami 2>&1 | Out-Null; if ($LASTEXITCODE -eq 0) { $flyOk = $true } } catch {}

if (-not $flyOk) {
    Write-Host '    Fly.io - complete the sign-in in your browser, then return here.' -ForegroundColor Yellow
    fly auth login
    if ($LASTEXITCODE -ne 0) { Fail 'Fly sign-in failed.'; exit 1 }
}
Ok "Fly.io: $(fly auth whoami 2>$null)"

$vercelOk = $false
try { vercel whoami 2>&1 | Out-Null; if ($LASTEXITCODE -eq 0) { $vercelOk = $true } } catch {}

if (-not $vercelOk) {
    Write-Host '    Vercel - complete the sign-in in your browser, then return here.' -ForegroundColor Yellow
    vercel login
    if ($LASTEXITCODE -ne 0) { Fail 'Vercel sign-in failed.'; exit 1 }
}
Ok 'Vercel signed in'

# ---------------------------------------------------------------------------
# 3. Backend
# ---------------------------------------------------------------------------
Step 3 'Deploying the backend to Fly.io'

Push-Location (Join-Path $root 'backend')
try {
    $exists = $false
    try { fly status --app $AppName 2>&1 | Out-Null; if ($LASTEXITCODE -eq 0) { $exists = $true } } catch {}

    if (-not $exists) {
        Write-Host "    Creating $AppName in $Region..." -ForegroundColor DarkGray
        # --copy-config reuses the fly.toml already in this folder rather than
        # generating a new one and overwriting the Supabase settings.
        fly launch --name $AppName --region $Region --no-deploy --copy-config --yes
        if ($LASTEXITCODE -ne 0) { throw 'fly launch failed' }
    } else {
        Ok "$AppName already exists"
    }

    # Read the secrets out of backend/.env rather than hard-coding them here.
    $envFile = Join-Path $root 'backend\.env'
    if (-not (Test-Path $envFile)) { throw 'backend\.env is missing' }

    $dbPass = (Select-String -Path $envFile -Pattern '^DB_PASSWORD=(.+)$').Matches.Groups[1].Value
    $jwt    = (Select-String -Path $envFile -Pattern '^JWT_SECRET=(.+)$').Matches.Groups[1].Value

    if (-not $dbPass) { throw 'DB_PASSWORD is empty in backend\.env' }
    if (-not $jwt)    { throw 'JWT_SECRET is empty in backend\.env' }

    Write-Host '    Setting secrets...' -ForegroundColor DarkGray
    fly secrets set "DB_PASSWORD=$dbPass" "JWT_SECRET=$jwt" --app $AppName --stage | Out-Null

    Write-Host '    Building and deploying (3-5 minutes on the first run)...' -ForegroundColor DarkGray
    fly deploy --app $AppName --yes
    if ($LASTEXITCODE -ne 0) { throw 'fly deploy failed' }

    Ok "Backend live at https://$AppName.fly.dev"
} catch {
    Fail $_
    Write-Host '    Diagnose with:  fly logs --app ' -NoNewline -ForegroundColor Yellow
    Write-Host $AppName -ForegroundColor Yellow
    Pop-Location
    exit 1
}
Pop-Location

# Confirm it actually answers before moving on.
Write-Host '    Waiting for the health check...' -ForegroundColor DarkGray
$healthy = $false
foreach ($i in 1..20) {
    Start-Sleep -Seconds 3
    try {
        $r = Invoke-RestMethod "https://$AppName.fly.dev/healthz" -TimeoutSec 5
        if ($r.status -eq 'healthy') { $healthy = $true; break }
    } catch {}
}

if ($healthy) { Ok 'Backend is healthy' }
else { Warn "No health response yet. Check: fly logs --app $AppName" }

# ---------------------------------------------------------------------------
# 4. Frontend
# ---------------------------------------------------------------------------
Step 4 'Deploying the frontend to Vercel'

Push-Location (Join-Path $root 'frontend')
try {
    @"
VITE_API_BASE_URL=https://$AppName.fly.dev
VITE_WS_BASE_URL=wss://$AppName.fly.dev
VITE_DEFAULT_MAP_LAT=2.0469
VITE_DEFAULT_MAP_LNG=45.3182
VITE_DEFAULT_CURRENCY=USD
VITE_GOOGLE_MAPS_BROWSER_KEY=
"@ | Out-File -Encoding utf8 -NoNewline '.env.production'

    Ok 'Wrote .env.production pointing at the deployed API'

    if (-not (Test-Path 'node_modules')) {
        Write-Host '    Installing dependencies...' -ForegroundColor DarkGray
        npm install --silent
    }

    Write-Host '    Deploying...' -ForegroundColor DarkGray
    $output = vercel --prod --yes 2>&1 | Tee-Object -Variable vercelLog
    if ($LASTEXITCODE -ne 0) { throw 'vercel deploy failed' }

    $url = ($vercelLog | Select-String -Pattern 'https://[a-z0-9-]+\.vercel\.app' |
            Select-Object -Last 1).Matches.Value

    if (-not $url) { $url = "https://$AppName.vercel.app" }

    Ok "Frontend live at $url"
    $script:FrontendUrl = $url
} catch {
    Fail $_
    Pop-Location
    exit 1
}
Pop-Location

# ---------------------------------------------------------------------------
# 5. CORS
# ---------------------------------------------------------------------------
Step 5 'Allowing the frontend to call the backend'

# Without this the browser blocks every request from the Vercel origin.
fly secrets set "CORS_ORIGINS=$($script:FrontendUrl)" --app $AppName | Out-Null
Ok "CORS set to $($script:FrontendUrl)"

Write-Host '    Restarting the backend...' -ForegroundColor DarkGray
Start-Sleep -Seconds 25

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
Write-Host @"

  ===========================================
   DONE
  ===========================================

   App:      $($script:FrontendUrl)
   API:      https://$AppName.fly.dev

   Sign in:  ghaalabh10@gmail.com

   Now turn this computer off and open the
   app on your phone. It keeps running.

  -------------------------------------------
   Redeploy after a change:
     cd backend  ; fly deploy
     cd frontend ; vercel --prod

   Logs:
     fly logs --app $AppName
  ===========================================

"@ -ForegroundColor Green

Start-Process $script:FrontendUrl
