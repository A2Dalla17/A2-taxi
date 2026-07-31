@echo off
REM ===========================================================================
REM  AC7 Ride — run the auth service, and record everything
REM
REM  Opens ONE window running the Go auth service, and writes the same output
REM  to logs\auth.log so it can be read afterwards without screenshots.
REM
REM  -u abdalla17 is essential. Without it wsl.exe opens as root, whose PATH
REM  has no Go — which is what produced "Command 'go' not found" before.
REM ===========================================================================

title AC7 Ride - auth service

set "PROJ=/mnt/c/Users/hassa/OneDrive/Documents/A2 Projects/Taxi App/AC7 Taxi"

echo.
echo   ================================================
echo    AC7 Ride - auth service
echo   ================================================
echo.
echo   Running as WSL user: abdalla17
echo   Output also saved to: logs\auth.log
echo.
echo   First run compiles the whole module - up to 2 minutes.
echo   Leave this window OPEN once it starts.
echo.

wsl.exe -u abdalla17 bash -lic "cd '%PROJ%' && mkdir -p logs && cd backend && echo '=== AC7 auth service ===' && echo \"go: $(command -v go || echo MISSING)\" && echo '' && stdbuf -oL -eL go run ./cmd/auth 2>&1 | tee '%PROJ%/logs/auth.log'; echo ''; echo '*** process ended - error is above ***'; exec bash"

echo.
echo   Window closed.
pause
