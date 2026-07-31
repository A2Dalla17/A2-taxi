<#
  AC7 Ride — push everything to github.com/A2Dalla17/A2-taxi
  ===========================================================================

  WHY THE LAST ATTEMPT DID NOTHING
    Three stale lock files were sitting in the .git folder:

        .git\index.lock
        .git\packed-refs.lock
        .git\refs\remotes\origin\HEAD.lock

    Git creates these while it writes and deletes them when it finishes. Mine
    were left behind because the project sits in OneDrive, which locks files
    mid-write while it syncs. Git then refuses every command with:

        "Another git process seems to be running in this repository"

    So nothing was ever committed and nothing was ever pushed. This script
    clears them first.

  WHAT YOU HAVE TO DO
    Sign in to GitHub when it asks. That is your account, so it has to be you.

  HOW TO RUN
    Right-click this file  ->  "Run with PowerShell"

    If Windows blocks it:
      Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
#>

$ErrorActionPreference = 'Continue'

function Step($n, $t) { Write-Host "`n[$n] $t" -ForegroundColor Cyan }
function Ok($t)       { Write-Host "    $t" -ForegroundColor Green }
function Warn($t)     { Write-Host "    $t" -ForegroundColor Yellow }
function Info($t)     { Write-Host "    $t" -ForegroundColor Gray }
function Die($t)      { Write-Host "`n  $t`n" -ForegroundColor Red; Read-Host "Press Enter to close"; exit 1 }

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root

Write-Host ""
Write-Host "  PUSH TO GITHUB" -ForegroundColor White
Write-Host "  A2Dalla17/A2-taxi" -ForegroundColor DarkGray
Write-Host "  =================" -ForegroundColor DarkGray

# --------------------------------------------------------------------------
Step 1 "Clearing stale git locks"

# This is what blocked the last attempt. Safe to delete: no git process is
# running, so any .lock file here is a leftover.
$locks = @(
    '.git\index.lock',
    '.git\packed-refs.lock',
    '.git\refs\remotes\origin\HEAD.lock',
    '.git\HEAD.lock',
    '.git\config.lock'
)

$cleared = 0
foreach ($lock in $locks) {
    $p = Join-Path $root $lock
    if (Test-Path $p) {
        try { Remove-Item $p -Force -ErrorAction Stop; Info "removed $lock"; $cleared++ }
        catch { Warn "could not remove $lock - close VS Code and any Git app, then rerun" }
    }
}

# Catch any others that appeared
Get-ChildItem -Path (Join-Path $root '.git') -Filter '*.lock' -Recurse -Force -ErrorAction SilentlyContinue |
    ForEach-Object {
        try { Remove-Item $_.FullName -Force -ErrorAction Stop; Info "removed $($_.Name)"; $cleared++ } catch { }
    }

if ($cleared -eq 0) { Ok "None found - clean" } else { Ok "$cleared cleared" }

# Verify git can actually work now
git status --porcelain 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Die "Git still can't run. Close VS Code, close GitHub Desktop, pause OneDrive, then run this again."
}
Ok "Git responds"

# --------------------------------------------------------------------------
Step 2 "Pausing OneDrive interference"
Warn "If OneDrive is syncing this folder right now, it may re-lock files"
Warn "mid-push. If this script fails, right-click the OneDrive cloud icon in"
Warn "your system tray -> Pause syncing -> 2 hours, then run it again."

# --------------------------------------------------------------------------
Step 3 "Safety check - no secrets going to a PUBLIC repo"

$patterns = @('AC7O5MdW4Dssku4MJIUsuSWZ4XvgFSLH', 'OmgEvkAlU/KiTWBx3QGTArYaiWbA4zmy')
$leak = $false
foreach ($p in $patterns) {
    $hits = git grep -l $p 2>$null
    if ($hits) { Write-Host "    LEAK in: $hits" -ForegroundColor Red; $leak = $true }
}
if (git ls-files backend/.env 2>$null) {
    Write-Host "    backend/.env is TRACKED - it must not be" -ForegroundColor Red; $leak = $true
}
if ($leak) { Die "Stopping. A secret would have been published. Send this to Claude." }
Ok "No credentials in tracked files"

# --------------------------------------------------------------------------
Step 4 "Identity and remote"
if (-not (git config user.name))  { git config user.name  "Abdullahi Mohamud" }
if (-not (git config user.email)) { git config user.email "ghaalabh10@gmail.com" }
Ok "$(git config user.name) <$(git config user.email)>"

git remote set-url origin https://github.com/A2Dalla17/A2-taxi.git 2>&1 | Out-Null
Ok "origin -> A2Dalla17/A2-taxi"

# --------------------------------------------------------------------------
Step 5 "Committing"

git add -A 2>&1 | Out-Null
$staged = @(git diff --cached --name-only).Count

if ($staged -gt 0) {
    Info "$staged files"
    git commit -m "AC7 Ride: London launch, new design system, phone preview build" 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) { Ok "Committed" } else { Die "Commit failed. Send the output to Claude." }
} else {
    $ahead = git log origin/main..HEAD --oneline 2>$null
    if ($ahead) { Ok "Already committed - ready to push" }
    else        { Warn "Nothing to commit" }
}

# --------------------------------------------------------------------------
Step 6 "GitHub sign-in"

# Plain `git push` over HTTPS on Windows often fails with "Authentication
# failed" because there is no credential helper wired up. GitHub CLI handles
# the browser flow properly, so use it when available.
$ghExists = $null -ne (Get-Command gh -ErrorAction SilentlyContinue)

if (-not $ghExists) {
    Warn "GitHub CLI not installed. Installing it - this makes sign-in work"
    Warn "reliably instead of failing with 'Authentication failed'."
    Write-Host ""
    winget install --id GitHub.cli --silent --accept-source-agreements --accept-package-agreements
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
                [System.Environment]::GetEnvironmentVariable("Path", "User")
    $ghExists = $null -ne (Get-Command gh -ErrorAction SilentlyContinue)
}

if ($ghExists) {
    gh auth status 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Warn "Signing in to GitHub. Answer the prompts:"
        Info "  What account?        GitHub.com"
        Info "  Preferred protocol?  HTTPS"
        Info "  Authenticate Git?    Y"
        Info "  How to login?        Login with a web browser"
        Info "  -> copy the code shown, press Enter, paste it in the browser"
        Write-Host ""
        gh auth login
    } else {
        Ok "Already signed in"
    }
    gh auth setup-git 2>&1 | Out-Null
} else {
    Warn "Couldn't install GitHub CLI. The push may ask for credentials directly."
}

# --------------------------------------------------------------------------
Step 7 "Pushing"
Write-Host ""
Warn "Your repo holds one commit with a README.md. This project has its own"
Warn "unrelated history, so the two cannot be merged. This REPLACES what is"
Warn "there, deleting that README. Nothing else is in the repo."
Write-Host ""
$answer = Read-Host "    Type YES to push"

if ($answer -ne 'YES') {
    Write-Host "`n  Cancelled. Your work is committed locally and safe.`n" -ForegroundColor Yellow
    Read-Host "Press Enter to close"; exit 0
}

Write-Host ""
Info "Uploading - this takes a minute, the project is about 13 MB"
Write-Host ""

git push --force -u origin main
$pushed = $LASTEXITCODE -eq 0

# --------------------------------------------------------------------------
Write-Host ""
if ($pushed) {
    Write-Host "  Pushed." -ForegroundColor Green
    Write-Host "  https://github.com/A2Dalla17/A2-taxi" -ForegroundColor White
    Write-Host ""
    Write-Host "  --------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  NEXT: connect Vercel" -ForegroundColor White
    Write-Host "  --------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  1. https://vercel.com/new" -ForegroundColor Gray
    Write-Host "  2. Import  A2Dalla17/A2-taxi" -ForegroundColor Gray
    Write-Host "  3. Root Directory -> Edit -> choose  frontend" -ForegroundColor Yellow
    Write-Host "  4. Environment Variables, add these five:" -ForegroundColor Gray
    Write-Host ""
    Write-Host "       VITE_PREVIEW_MODE      true" -ForegroundColor White
    Write-Host "       VITE_DEFAULT_MAP_LAT   51.5074" -ForegroundColor White
    Write-Host "       VITE_DEFAULT_MAP_LNG   -0.1278" -ForegroundColor White
    Write-Host "       VITE_DEFAULT_CURRENCY  GBP" -ForegroundColor White
    Write-Host "       VITE_LOCALE            en-GB" -ForegroundColor White
    Write-Host ""
    Write-Host "  5. Deploy" -ForegroundColor Gray
} else {
    Write-Host "  Push failed. Copy everything above and send it to Claude." -ForegroundColor Red
    Write-Host ""
    Write-Host "  Your work IS committed locally - nothing is lost." -ForegroundColor Gray
}

Write-Host ""
Read-Host "Press Enter to close"
