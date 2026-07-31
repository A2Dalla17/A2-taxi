@echo off
REM ===========================================================================
REM  AC7 Ride — frontend only
REM
REM  Starts just the interface. No Docker, no database, no backend.
REM
REM  Every screen renders and you can navigate the whole app, but anything
REM  that needs data — login, trips, wallet, earnings — will not work.
REM  Use this to review the design.
REM ===========================================================================

title AC7 Ride - frontend only

cd /d "%~dp0"

echo.
echo   ================================================
echo    AC7 Ride - FRONTEND ONLY
echo    No backend. Login will not work.
echo   ================================================
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\start-dev.ps1" -FrontendOnly

echo.
pause
