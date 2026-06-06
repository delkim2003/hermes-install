@echo off
:: ============================================
:: Hermes Agent Deployment Kit
:: Copyright (c) 2026 Philipp Schlemmer, einfach-online.dev
:: Licensed under the Apache License, Version 2.0
:: ============================================
title Hermes Agent - Start All Services
chcp 65001 >nul
setlocal enabledelayedexpansion

:: ============================================
:: CUSTOMER CONFIGURATION
:: Edit these values before first run
:: ============================================
set "API_KEY=change-me-to-a-secure-password"  :: Free choice - used for API auth
set "MPASS=change-me-mysql-password"          :: MySQL root password - free choice
set "PROVIDER=openrouter"                     :: AI provider: openrouter, anthropic, openai, deepseek, custom
                                             ::   EU/GDPR: use openrouter + set CUSTOM_API_BASE=https://api.cortecs.ai/v1
                                             ::   Private: deepseek ($1.28/month), Free: local-model + ollama
set "MODEL=anthropic/claude-sonnet-4"         :: AI model name

set "DUMP_DIR=%REPO_ROOT%backups"              :: Directory for MySQL backups (relative to REPO_ROOT)
:: ============================================

:: Internal variables - do not edit
set "REPO_ROOT=%~dp0"
set "NAME=hermes-agent"

set "HERMES_API_KEY=%API_KEY%"

echo ======================================
echo    Hermes Agent - Starting all services
echo ======================================
echo.

:: === 1/7  Docker Network ===
echo [1/7] Setting up Docker network...
docker network inspect hermes-net >nul 2>&1 && (
    echo    Network 'hermes-net' already exists.
) || (
    docker network create hermes-net >nul && echo    Network 'hermes-net' created.
)
echo.

:: === 2/7  Optional drive mounts ===
echo [2/7] Mount additional folders into containers?
set "MOUNT_VARS="
set /p ADD_MOUNT="Folder path (Enter = skip, e.g. C:\Projects): "
if not "!ADD_MOUNT!"=="" (
    echo    Mounted folders are available at /mnt/data inside the container.
    set "MOUNT_VARS=-v "!ADD_MOUNT!:/mnt/data""
    echo    Mount: !ADD_MOUNT! -^> /mnt/data
) else (
    echo    No additional mounts configured.
)
echo.

:: === 3/7  Create Hermes config ===
echo [3/7] Creating Hermes configuration...
if not exist "%USERPROFILE%\.hermes" mkdir "%USERPROFILE%\.hermes"
(
echo # Hermes Agent Configuration
echo # Auto-generated on %DATE% %TIME%
echo.
echo provider: %PROVIDER%
echo model: %MODEL%
echo api_key: %API_KEY%
echo terminal:
echo   backend: local
echo api_server:
echo   enabled: true
echo   port: 8642
echo   api_key: %API_KEY%
echo tools:
echo   - terminal
echo   - web_search
echo   - file
echo   - browser
echo   - vision
) > "%USERPROFILE%\.hermes\config.yaml"
echo    Config written: %USERPROFILE%\.hermes\config.yaml
echo.

:: === 4/7  Dashboard ===
echo [4/7] Starting Hermes Dashboard...
docker rm -f hermes-dashboard >nul 2>&1
docker run -d --restart=unless-stopped --network=hermes-net ^
    --name=hermes-dashboard -h hermes-dashboard ^
    -v "%USERPROFILE%\.hermes:/root/.hermes" ^
    -p 9119:9119 ^
    --label "com.centurylinklabs.watchtower.enable=false" ^
    hermes-agent:latest ^
    hermes dashboard --host 0.0.0.0 --port 9119
echo.

:: === 5/7  API Server ===
echo [5/7] Starting Hermes API Server...
docker rm -f %NAME% >nul 2>&1
docker run -d --restart=unless-stopped --network=hermes-net ^
    --name=%NAME% -h %NAME% ^
    -v "%USERPROFILE%\.hermes:/root/.hermes" ^
    -e HERMES_PROVIDER_OVERRIDE="%PROVIDER%" ^
    -e HERMES_MODEL_OVERRIDE="%MODEL%" ^
    -e HERMES_API_KEY="%API_KEY%" ^
    %MOUNT_VARS% ^
    -p 8642:8642 ^
    -p 8641:8641 ^
    --label "com.centurylinklabs.watchtower.enable=false" ^
    hermes-agent:latest ^
    hermes api-server --host 0.0.0.0 --port 8642
echo.



:: === 6/7  MySQL + Sync + Dump ===
echo [6/7] Starting MySQL and syncing database...

:: MySQL Container
docker rm -f %NAME%-mysql >nul 2>&1
docker run -d --restart=unless-stopped --network=hermes-net ^
    --name=%NAME%-mysql -h %NAME%-mysql ^
    -e MYSQL_ROOT_PASSWORD="%MPASS%" ^
    -v hermes_mysql_data:/var/lib/mysql ^
    --label "com.centurylinklabs.watchtower.enable=false" ^
    mysql:8.0 ^
    --default-authentication-plugin=mysql_native_password

:: Wait for MySQL to be ready
echo    Waiting for MySQL to start...
set tries=0
:wait_mysql
timeout /t 3 /nobreak >nul
docker exec %NAME%-mysql mysqladmin ping -uroot -p%MPASS% --silent >nul 2>&1
if not !errorlevel! equ 0 (
    set /a tries+=1
    if !tries! lss 15 goto wait_mysql
)
if !tries! lss 15 (
    echo    MySQL is ready.
) else (
    echo    Warning: MySQL not reachable within timeout.
)

:: Copy sync script into container
echo    Copying sync script into container...

:: Wait for container to be ready for docker cp
set tries=0
:wait_cp
docker exec %NAME% mkdir -p /opt/data/home/scripts >nul 2>&1
if not !errorlevel! equ 0 (
    set /a tries+=1
    if !tries! lss 15 (
        timeout /t 2 /nobreak >nul
        goto wait_cp
    )
    echo    Warning: Container not ready for sync copy.
    goto skip_sync
)
docker cp "%REPO_ROOT%mysql_sync.py" %NAME%:/opt/data/home/scripts/mysql_sync.py

:: Install pymysql and sync
echo    Installing pymysql...
docker exec %NAME% pip install pymysql -q 2>nul
echo    Syncing state.db to MySQL...
docker exec ^
    -e MYSQL_HOST=%NAME%-mysql ^
    -e MYSQL_PASS=%MPASS% ^
    -e MYSQL_DB=hermes ^
    -e SQLITE_PATH=/root/.hermes/state.db ^
    %NAME% python3 /opt/data/home/scripts/mysql_sync.py

:: Create SQL dump
echo    Creating MySQL dump...
mkdir "%DUMP_DIR%" 2>nul
docker exec %NAME%-mysql ^
    mysqldump -uroot -p%MPASS% --databases hermes ^
    --routines --triggers --single-transaction > "%DUMP_DIR%\hermes_dump.sql"
echo    Dump saved: %DUMP_DIR%\hermes_dump.sql
echo.
goto end_sync

:skip_sync
echo    Sync skipped (container not ready).
:end_sync

:: === 7/7  Summary ===
echo ======================================
echo    ALL SERVICES STARTED
echo ======================================
echo.
echo    Hermes API      : http://localhost:8642
echo    Hermes Dashboard: http://localhost:9119
echo    (Open WebUI entfernt)
echo    MySQL           : %NAME%-mysql:3306
echo    MySQL Dump      : %DUMP_DIR%\hermes_dump.sql
echo.
echo    Running containers:
docker ps --filter network=hermes-net --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo.
echo    View logs: docker logs <container-name>
echo    Stop all : docker stop %NAME% hermes-dashboard hermes-agent-mysql
echo.
echo    Provider : %PROVIDER%
echo    Model    : %MODEL%
if not "!ADD_MOUNT!"=="" echo    Mounts   : %ADD_MOUNT% -^> /mnt/data

endlocal
