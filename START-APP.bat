@echo off
REM ===========================================================================
REM  AC7 Ride — start everything, one double-click
REM
REM  Opens two WSL windows:
REM    1. auth service  (Go, port 8080)  -> talks to Supabase
REM    2. frontend      (Vite, port 3000)
REM
REM  No Docker. The auth service needs only PostgreSQL, which is Supabase.
REM
REM  Leave BOTH windows open. Closing one stops that server.
REM ===========================================================================

title AC7 Ride - launcher

set "PROJ=/mnt/c/Users/hassa/OneDrive/Documents/A2 Projects/Taxi App/AC7 Taxi"

echo.
echo   ================================================
echo    AC7 Ride
echo   ================================================
echo.
echo   Opening two windows:
echo     1. Backend  - auth service on :8080
echo     2. Frontend - Vite on :3000
echo.
echo   Keep BOTH open.
echo.

REM --- 1. Backend ----------------------------------------------------------
REM -u abdalla17 matters: without it wsl.exe opens as root, whose PATH does
REM not include the Go and Node installs that belong to the normal user.
REM PORT is forced here on purpose. godotenv.Load() does NOT overwrite a
REM variable already present in the shell, so a stray PORT in the environment
REM silently wins over backend/.env — which is how the service ended up on
REM :8081 while the frontend proxy pointed at :8080.
start "AC7 Backend (auth)" wsl.exe -u abdalla17 bash -lic "cd '%PROJ%/backend' && echo '=== AC7 auth service ===' && PORT=8080 go run ./cmd/auth; echo; echo '*** stopped - read the error above ***'; exec bash"

echo   [1/2] Backend window opened.
echo         Waiting 25s for Go to compile...
timeout /t 25 /nobreak >nul

REM --- 2. Frontend ---------------------------------------------------------
start "AC7 Frontend (vite)" wsl.exe -u abdalla17 bash -lic "cd '%PROJ%/frontend' && echo '=== AC7 frontend ===' && npm run dev; echo; echo '*** stopped ***'; exec bash"

echo   [2/2] Frontend window opened.
echo         Waiting 15s for Vite...
timeout /t 15 /nobreak >nul

REM --- 3. Browser ----------------------------------------------------------
echo.
echo   Opening the browser...
start "" "http://localhost:3000"

echo.
echo   ================================================
echo    Open:  http://localhost:3000
echo.
echo    Sign in:  Ghaalabh10@gmail.com
echo.
echo    Use LOCALHOST, not the 172.x or 10.x addresses
echo    Vite prints - Windows cannot reach those.
echo   ================================================
echo.
echo   If the page does not load, look at the two windows
echo   that opened - the error will be in one of them.
echo.
pause
