@echo off
REM ===========================================================================
REM  AC7 Ride — backend only
REM
REM  Use this when the frontend is ALREADY running (Vite on :3000) and you
REM  just need the API behind it.
REM
REM  Starts: Kong, auth, rides, geo, payments, Redis, NATS — pointed at
REM  Supabase. Seven containers, not seventeen: the free tier allows 60
REM  pooled connections and the full set exhausts them.
REM ===========================================================================

title AC7 Ride - backend

cd /d "%~dp0"

echo.
echo   ================================================
echo    AC7 Ride - starting the backend
echo   ================================================
echo.

REM --- Is Docker up? -------------------------------------------------------
docker info >nul 2>&1
if errorlevel 1 (
    echo   [X] Docker is not responding.
    echo.
    echo       Open Docker Desktop, wait for the whale icon to stop
    echo       animating, then run this file again.
    echo.
    pause
    exit /b 1
)
echo   [OK] Docker is running
echo.

REM --- Is the password set? ------------------------------------------------
findstr /R /C:"^DB_PASSWORD=..*" "backend\.env" >nul 2>&1
if errorlevel 1 (
    echo   [X] DB_PASSWORD is empty in backend\.env
    echo.
    echo       Supabase dashboard - Settings - Database - Database password
    echo.
    pause
    exit /b 1
)
echo   [OK] Database password is set
echo.

echo   Starting containers. First run pulls images - this can take
echo   several minutes.
echo.

REM --env-file is required: compose reads .env from the project directory,
REM not from backend\. Without it the ${DB_USER:?} interpolation fails.
docker compose --env-file backend/.env -f deploy/docker-compose.yml -f deploy/docker-compose.supabase.yml up -d redis nats kong auth-service rides-service geo-service payments-service

if errorlevel 1 (
    echo.
    echo   [X] docker compose failed. Read the error above.
    echo.
    pause
    exit /b 1
)

echo.
echo   [OK] Containers started. Waiting for the gateway...
echo.

REM --- Poll until Kong answers --------------------------------------------
set ATTEMPT=0
:WAIT
set /a ATTEMPT+=1
if %ATTEMPT% GTR 40 goto TIMEOUT

powershell -NoProfile -Command "try { $r = Invoke-WebRequest -Uri 'http://localhost:8000/api/v1/auth/healthz' -TimeoutSec 3 -UseBasicParsing; if ($r.StatusCode -eq 200) { exit 0 } else { exit 1 } } catch { exit 1 }" >nul 2>&1

if errorlevel 1 (
    timeout /t 3 /nobreak >nul
    echo      still starting... [%ATTEMPT%/40]
    goto WAIT
)

echo.
echo   ================================================
echo    READY
echo.
echo    API:  http://localhost:8000
echo    App:  http://localhost:3000
echo.
echo    Sign in with:
echo      ghaalabh10@gmail.com
echo   ================================================
echo.
echo   You can close this window - the containers keep running.
echo   To stop them:  docker compose -f deploy/docker-compose.yml down
echo.
pause
exit /b 0

:TIMEOUT
echo.
echo   [!] The gateway did not respond within two minutes.
echo.
echo       Check what went wrong:
echo         docker compose -f deploy/docker-compose.yml logs auth-service
echo.
echo       Most likely causes:
echo         - Wrong database password in backend\.env
echo         - Supabase project paused again
echo         - Port 8000 already in use
echo.
pause
exit /b 1
