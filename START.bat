@echo off
REM ===========================================================================
REM  AC7 Ride — double-click launcher
REM
REM  Runs scripts\start-dev.ps1 with the execution policy bypassed for this
REM  process only, so no permanent PowerShell setting is changed.
REM
REM  Nothing to type. Just double-click this file.
REM ===========================================================================

title AC7 Ride - starting

cd /d "%~dp0"

echo.
echo   ================================================
echo    AC7 Ride
echo    Starting the development stack
echo   ================================================
echo.
echo   Folder: %CD%
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\start-dev.ps1"

echo.
echo   ------------------------------------------------
echo    The stack has stopped.
echo   ------------------------------------------------
echo.
pause
