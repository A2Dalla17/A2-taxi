<#
.SYNOPSIS
    AC7 Ride — start the development stack.

.DESCRIPTION
    Starts the backend (Kong + auth + Redis + NATS) against Supabase, then the
    frontend, then opens the browser.

    Checks prerequisites first and explains clearly what is missing rather than
    failing halfway with a cryptic error.

.EXAMPLE
    .\scripts\start-dev.ps1
    .\scripts\start-dev.ps1 -FrontendOnly
    .\scripts\start-dev.ps1 -LocalDatabase
#>

[CmdletBinding()]
param(
    # Skip the backend. The UI renders; anything needing data will be empty.
    [switch]$FrontendOnly,

    # Use the local Postgres container instead of Supabase.
    [switch]$LocalDatabase,

    # Bring up all 17 services. Off by default — the Supabase free tier allows
    # 60 pooled connections and 17 services will exhaust them.
    [switch]$AllServices
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

function Write-Step { param($n, $m) Write-Host "`n[$n] $m" -ForegroundColor Cyan }
function Write-Ok   { param($m) Write-Host "    OK  $m" -ForegroundColor Green }
function Write-Warn { param($m) Write-Host "    !   $m" -ForegroundColor Yellow }
function Write-Err  { param($m) Write-Host "    X   $m" -ForegroundColor Red }

Write-Host "`n  AC7 Ride — development stack" -ForegroundColor White
Write-Host "  $root`n" -ForegroundColor DarkGray

# ---------------------------------------------------------------------------
# 1. Prerequisites
# ---------------------------------------------------------------------------
Write-Step 1 'Checking prerequisites'

if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Err 'Node.js not found. Install from https://nodejs.org (v20 or later).'
    exit 1
}
Write-Ok "Node $(node --version)"

if (-not $FrontendOnly) {
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        Write-Err 'Docker not found. Install Docker Desktop, or re-run with -FrontendOnly.'
        exit 1
    }

    try {
        docker info 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) { throw }
        Write-Ok 'Docker is running'
    } catch {
        Write-Err 'Docker Desktop is installed but not running. Start it and try again.'
        exit 1
    }
}

# ---------------------------------------------------------------------------
# 2. Backend configuration
# ---------------------------------------------------------------------------
if (-not $FrontendOnly -and -not $LocalDatabase) {
    Write-Step 2 'Checking Supabase configuration'

    $envPath = Join-Path $root 'backend\.env'

    if (-not (Test-Path $envPath)) {
        Write-Err 'backend\.env is missing.'
        Write-Host ''
        Write-Host '    Create it:' -ForegroundColor Yellow
        Write-Host '      cd backend' -ForegroundColor White
        Write-Host '      copy .env.supabase.example .env' -ForegroundColor White
        Write-Host ''
        Write-Host '    Then fill in DB_PASSWORD and JWT_SECRET.' -ForegroundColor Yellow
        Write-Host '    Password: Supabase dashboard -> Settings -> Database' -ForegroundColor DarkGray
        Write-Host ''
        Write-Host '    Or run with -LocalDatabase to use the Postgres container instead.' -ForegroundColor DarkGray
        exit 1
    }

    $envText = Get-Content $envPath -Raw

    if ($envText -notmatch '(?m)^DB_PASSWORD=.+$') {
        Write-Err 'DB_PASSWORD is empty in backend\.env'
        Write-Host '    Get it from: Supabase dashboard -> Settings -> Database' -ForegroundColor DarkGray
        exit 1
    }
    Write-Ok 'DB_PASSWORD is set'

    if ($envText -notmatch '(?m)^JWT_SECRET=.+$') {
        Write-Warn 'JWT_SECRET is empty — tokens cannot be signed.'
        Write-Host '    Generate one:  openssl rand -base64 48' -ForegroundColor DarkGray
        exit 1
    }
    Write-Ok 'JWT_SECRET is set'
}

# ---------------------------------------------------------------------------
# 3. Backend
# ---------------------------------------------------------------------------
if (-not $FrontendOnly) {
    Write-Step 3 'Starting backend'

    # --env-file is required: compose reads .env from the project directory,
    # not from backend/. Without it the ${DB_USER:?} interpolation fails.
    $composeArgs = @('compose')
    if (Test-Path (Join-Path $root 'backend\.env')) {
        $composeArgs += @('--env-file', 'backend/.env')
    }
    $composeArgs += @('-f', 'deploy/docker-compose.yml')

    if (-not $LocalDatabase) {
        $composeArgs += @('-f', 'deploy/docker-compose.supabase.yml')
        Write-Host '    Database: Supabase' -ForegroundColor DarkGray
    } else {
        Write-Host '    Database: local Postgres container' -ForegroundColor DarkGray
    }

    $composeArgs += 'up'
    $composeArgs += '-d'

    if (-not $AllServices) {
        # Enough for authentication, booking and tracking. Adding the other
        # ten services multiplies connection use for no benefit in dev.
        $composeArgs += @('redis', 'nats', 'kong', 'auth-service', 'rides-service', 'geo-service', 'payments-service')
        if ($LocalDatabase) { $composeArgs += 'postgres' }
    }

    Push-Location $root
    try {
        & docker @composeArgs
        if ($LASTEXITCODE -ne 0) { throw 'docker compose failed' }
        Write-Ok 'Containers started'
    } catch {
        Write-Err "Backend failed to start: $_"
        Pop-Location
        exit 1
    }
    Pop-Location

    # Wait for Kong to answer rather than guessing with a fixed sleep.
    Write-Host '    Waiting for the gateway…' -ForegroundColor DarkGray
    $ready = $false
    foreach ($i in 1..30) {
        Start-Sleep -Seconds 2
        try {
            $r = Invoke-WebRequest -Uri 'http://localhost:8000/api/v1/auth/healthz' `
                                   -TimeoutSec 3 -UseBasicParsing -ErrorAction Stop
            if ($r.StatusCode -eq 200) { $ready = $true; break }
        } catch { }
    }

    if ($ready) {
        Write-Ok 'Gateway is responding on http://localhost:8000'
    } else {
        Write-Warn 'Gateway did not respond within 60s.'
        Write-Host '    Check the logs:  docker compose -f deploy/docker-compose.yml logs auth-service' -ForegroundColor DarkGray
        Write-Host '    Continuing — the frontend will still start.' -ForegroundColor DarkGray
    }
}

# ---------------------------------------------------------------------------
# 4. Frontend
# ---------------------------------------------------------------------------
Write-Step 4 'Starting frontend'

$frontend = Join-Path $root 'frontend'

if (-not (Test-Path (Join-Path $frontend 'node_modules'))) {
    Write-Host '    Installing dependencies (first run only)…' -ForegroundColor DarkGray
    Push-Location $frontend
    npm install
    if ($LASTEXITCODE -ne 0) { Write-Err 'npm install failed'; Pop-Location; exit 1 }
    Pop-Location
    Write-Ok 'Dependencies installed'
} else {
    Write-Ok 'Dependencies already present'
}

Write-Host ''
Write-Host '  ────────────────────────────────────────────────' -ForegroundColor DarkGray
Write-Host '   App:      http://localhost:3000' -ForegroundColor White
if (-not $FrontendOnly) {
    Write-Host '   API:      http://localhost:8000' -ForegroundColor White
}
Write-Host ''
Write-Host '   Use the LOCAL url above.' -ForegroundColor Yellow
Write-Host '   Ignore the "Network:" address Vite prints — if you are in WSL' -ForegroundColor DarkGray
Write-Host '   that is the WSL gateway and Windows cannot reach it.' -ForegroundColor DarkGray
Write-Host '  ────────────────────────────────────────────────' -ForegroundColor DarkGray
Write-Host ''

Start-Process 'http://localhost:3000'

Push-Location $frontend
npm run dev
Pop-Location
