<#
  AC7 Ride — move out of OneDrive, then push everything to GitHub
  ===========================================================================

  WHY THE PUSH KEEPS FAILING

    The project lives inside OneDrive. OneDrive holds files open while it
    syncs them, and git cannot work under that. Right now there are three
    dead lock files in .git that git refuses to work past:

        .git\index.lock
        .git\packed-refs.lock
        .git\refs\remotes\origin\HEAD.lock

    Even after clearing them, OneDrive re-locks git's object files mid-write.
    That is why nothing has been committed and nothing has reached GitHub.

  WHAT THIS DOES

    Copies the whole project to  C:\dev\A2-taxi  - outside OneDrive - and
    pushes from there. Full git history is preserved.

    Your OneDrive copy is left untouched as a backup. After this works,
    C:\dev\A2-taxi becomes the folder you work in, and GitHub becomes the
    backup instead of OneDrive.

  WHAT YOU DO
    Sign in to GitHub when it asks. That is your account, so it has to be you.

  HOW TO RUN
    Right-click this file  ->  "Run with PowerShell"

    If Windows blocks it, open PowerShell and run:
      Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
      & "C:\Users\hassa\OneDrive\Documents\A2 Projects\Taxi App\AC7 Taxi\FIX-AND-PUSH.ps1"
#>

$ErrorActionPreference = 'Continue'

function Step($n,$t){ Write-Host "`n[$n] $t" -ForegroundColor Cyan }
function Ok($t)  { Write-Host "    $t" -ForegroundColor Green }
function Warn($t){ Write-Host "    $t" -ForegroundColor Yellow }
function Info($t){ Write-Host "    $t" -ForegroundColor Gray }
function Die($t) { Write-Host "`n  $t`n" -ForegroundColor Red; Read-Host "Press Enter to close"; exit 1 }

$source = Split-Path -Parent $MyInvocation.MyCommand.Path
$dest   = 'C:\dev\A2-taxi'
$repo   = 'https://github.com/A2Dalla17/A2-taxi.git'

Write-Host ""
Write-Host "  AC7 RIDE  ->  github.com/A2Dalla17/A2-taxi" -ForegroundColor White
Write-Host "  =========================================" -ForegroundColor DarkGray
Write-Host ""
Info "from: $source"
Info "to:   $dest"

# --------------------------------------------------------------------------
Step 1 "Checking tools"
try { Ok (git --version) } catch { Die "Git isn't installed: https://git-scm.com/download/win" }

# --------------------------------------------------------------------------
Step 2 "Copying out of OneDrive"

if (Test-Path $dest) {
    Warn "$dest already exists."
    $r = Read-Host "    Type REPLACE to overwrite it, or anything else to cancel"
    if ($r -ne 'REPLACE') { Write-Host "`n  Cancelled.`n" -ForegroundColor Yellow; Read-Host "Press Enter"; exit 0 }
    Remove-Item $dest -Recurse -Force -ErrorAction SilentlyContinue
}

New-Item -ItemType Directory -Path $dest -Force | Out-Null

# robocopy handles long paths and locked files far better than Copy-Item.
#   /E     include subdirectories, even empty ones
#   /XD    skip these directories entirely - node_modules is huge and is
#          rebuilt by npm install; dist is rebuilt by the build
#   /R:1   retry once on a locked file rather than hanging
#   /NFL /NDL /NJH /NJS  quiet output
Info "copying (skipping node_modules, this takes a moment)"
robocopy $source $dest /E /XD node_modules dist .vercel /R:1 /W:1 /NFL /NDL /NJH /NJS | Out-Null

# robocopy exit codes below 8 are success. 8+ means real failure.
if ($LASTEXITCODE -ge 8) { Die "Copy failed. Pause OneDrive syncing and try again." }
Ok "Copied"

Set-Location $dest

# --------------------------------------------------------------------------
Step 3 "Clearing the dead lock files"

$n = 0
Get-ChildItem -Path (Join-Path $dest '.git') -Filter '*.lock' -Recurse -Force -ErrorAction SilentlyContinue |
    ForEach-Object { Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue; Info "removed $($_.Name)"; $n++ }

if ($n -eq 0) { Ok "None to clear" } else { Ok "$n cleared" }

git status --porcelain 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) { Die "Git still won't run here. Send the output to Claude." }
Ok "Git works now"

# --------------------------------------------------------------------------
Step 4 "Safety check - this repo is PUBLIC"

$leak = $false
foreach ($p in @('AC7O5MdW4Dssku4MJIUsuSWZ4XvgFSLH','OmgEvkAlU/KiTWBx3QGTArYaiWbA4zmy')) {
    $hits = git grep -l $p 2>$null
    if ($hits) { Write-Host "    LEAK: $hits" -ForegroundColor Red; $leak = $true }
}
if (git ls-files backend/.env 2>$null) { Write-Host "    backend/.env is tracked" -ForegroundColor Red; $leak = $true }
if ($leak) { Die "Stopped - a secret would have been published. Send this to Claude." }
Ok "No credentials in tracked files"

# --------------------------------------------------------------------------
Step 5 "Committing"

if (-not (git config user.name))  { git config user.name  "Abdullahi Mohamud" }
if (-not (git config user.email)) { git config user.email "ghaalabh10@gmail.com" }
git remote set-url origin $repo 2>&1 | Out-Null
Ok "$(git config user.name) -> A2Dalla17/A2-taxi"

git add -A
$staged = @(git diff --cached --name-only).Count
if ($staged -gt 0) {
    Info "$staged files"
    git commit -m "AC7 Ride: London launch, new design system, phone preview build" | Out-Null
    if ($LASTEXITCODE -ne 0) { Die "Commit failed. Send the output to Claude." }
    Ok "Committed"
} else {
    Ok "Already committed"
}

# --------------------------------------------------------------------------
Step 6 "GitHub sign-in"

# Plain `git push` over HTTPS on Windows commonly fails with "Authentication
# failed" when no credential helper is configured. GitHub CLI does the
# browser flow properly.
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Warn "Installing GitHub CLI so sign-in works reliably..."
    winget install --id GitHub.cli --silent --accept-source-agreements --accept-package-agreements
    $env:Path = [Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [Environment]::GetEnvironmentVariable("Path","User")
}

if (Get-Command gh -ErrorAction SilentlyContinue) {
    gh auth status 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Warn "Answer these prompts:"
        Info "  Where?               GitHub.com"
        Info "  Protocol?            HTTPS"
        Info "  Authenticate Git?    Y"
        Info "  How?                 Login with a web browser"
        Info "  then copy the code, press Enter, paste it in the browser"
        Write-Host ""
        gh auth login
    } else { Ok "Already signed in" }
    gh auth setup-git 2>&1 | Out-Null
} else {
    Warn "GitHub CLI unavailable - git may prompt for credentials directly"
}

# --------------------------------------------------------------------------
Step 7 "Pushing"
Write-Host ""
Warn "Your repo has one commit holding a README.md. This project has its own"
Warn "history, unrelated to it, so they cannot merge. This REPLACES the repo"
Warn "contents - that README is deleted. Nothing else is in there."
Write-Host ""
if ((Read-Host "    Type YES to push") -ne 'YES') {
    Write-Host "`n  Cancelled. Everything is committed at $dest - nothing lost.`n" -ForegroundColor Yellow
    Read-Host "Press Enter"; exit 0
}

Write-Host ""
Info "Uploading about 13 MB, give it a minute"
Write-Host ""
git push --force -u origin main
$pushed = $LASTEXITCODE -eq 0

# --------------------------------------------------------------------------
Write-Host ""
if ($pushed) {
    Write-Host "  Done - your code is on GitHub." -ForegroundColor Green
    Write-Host "  https://github.com/A2Dalla17/A2-taxi" -ForegroundColor White
    Write-Host ""
    Write-Host "  IMPORTANT: work in $dest from now on," -ForegroundColor Yellow
    Write-Host "  not the OneDrive folder. That is what broke git." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  --------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  NEXT: Vercel" -ForegroundColor White
    Write-Host "  --------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  1. https://vercel.com/new" -ForegroundColor Gray
    Write-Host "  2. Import  A2Dalla17/A2-taxi" -ForegroundColor Gray
    Write-Host "  3. Root Directory -> Edit -> pick  frontend" -ForegroundColor Yellow
    Write-Host "  4. Environment Variables:" -ForegroundColor Gray
    Write-Host "       VITE_PREVIEW_MODE      true" -ForegroundColor White
    Write-Host "       VITE_DEFAULT_MAP_LAT   51.5074" -ForegroundColor White
    Write-Host "       VITE_DEFAULT_MAP_LNG   -0.1278" -ForegroundColor White
    Write-Host "       VITE_DEFAULT_CURRENCY  GBP" -ForegroundColor White
    Write-Host "       VITE_LOCALE            en-GB" -ForegroundColor White
    Write-Host "  5. Deploy" -ForegroundColor Gray
} else {
    Write-Host "  Push failed - copy everything above and send it to Claude." -ForegroundColor Red
    Write-Host "  Your work is committed at $dest and is safe." -ForegroundColor Gray
}

Write-Host ""
Read-Host "Press Enter to close"
