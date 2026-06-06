@echo off
title Hermes Agent - Vollstart
chcp 65001 >nul
setlocal enabledelayedexpansion

:: ============================================
:: KUNDENSPEZIFISCHE KONFIGURATION
:: ============================================
:: Passe diese Werte vor dem ersten Start an!
:: ============================================

set "API_KEY=dein-api-key-hier"      :: Beliebiges Passwort für den API-Zugriff
set "CPASS=dein-cryptomator-passwort"  :: Cryptomator Vault Passwort (optional)
set "MPASS=dein-mysql-passwort"        :: MySQL Root-Passwort (frei wählbar)
set "PROVIDER=openrouter"             :: KI-Anbieter (openrouter, anthropic, openai)
set "MODEL=anthropic/claude-sonnet-4" :: KI-Modell
set "WEBUI_NAME=Meine Firma - Hermes" :: Anzeigename in Open WebUI

:: ============================================
:: ENDE KONFIGURATION
:: ============================================

set "NAME=hermes-agent"
set "OWUI=open-webui"

echo ======================================
echo    Hermes Agent - Vollstart
echo ======================================
echo.

:: === 1/9  Docker-Netzwerk ===
echo [1/9] Docker-Netzwerk prufen...
docker network inspect hermes-net >nul 2>&1 && (
    echo    Netzwerk existiert bereits.
) || (
    docker network create hermes-net >nul && echo    Netzwerk angelegt.
)

:: === 2/9  Cryptomator Vault (optional) ===
echo [2/9] Cryptomator Vault entsperren...
if exist /agency_core/Scripts/cryptomator-entry.sh (
    docker run --rm -it ^
        -v /opt/data:/opt/data ^
        -v /agency_core/Scripts/cryptomator-entry.sh:/entry.sh ^
        --entrypoint /bin/sh ^
        alpine:latest ^
        /entry.sh "%CPASS%"
) else (
    echo    Kein Cryptomator-Script gefunden, ueberspringe.
)

:: === 3/9  Dashboard ===
echo [3/9] Dashboard starten...
docker rm -f hermes-dashboard >nul 2>&1
docker run -d --restart=unless-stopped --network=hermes-net ^
    --name=hermes-dashboard -h hermes-dashboard ^
    -v "%USERPROFILE%\.hermes:/root/.hermes" ^
    -p 9119:9119 ^
    --label "com.centurylinklabs.watchtower.enable=false" ^
    hermes-agent:latest ^
    hermes dashboard --host 0.0.0.0 --port 9119

:: === 4/9  API Server ===
echo [4/9] API Server starten...
docker rm -f %NAME% >nul 2>&1
docker run -d --restart=unless-stopped --network=hermes-net ^
    --name=%NAME% -h %NAME% ^
    -v "%USERPROFILE%\.hermes:/root/.hermes" ^
    -v /opt/data:/opt/data ^
    -e HERMES_PROVIDER_OVERRIDE="%PROVIDER%" ^
    -e HERMES_MODEL_OVERRIDE="%MODEL%" ^
    -e HERMES_API_KEY="%API_KEY%" ^
    -p 8642:8642 ^
    -p 8641:8641 ^
    --label "com.centurylinklabs.watchtower.enable=false" ^
    hermes-agent:latest ^
    hermes api-server --host 0.0.0.0 --port 8642

:: === 5/9  Open WebUI ===
echo [5/9] Open WebUI starten...
docker rm -f %OWUI% >nul 2>&1
docker run -d --restart=unless-stopped --network=hermes-net ^
    --name=%OWUI% -h %OWUI% ^
    -e OPENAI_API_BASE_URL="http://%NAME%:8642/v1" ^
    -e OPENAI_API_KEY="%API_KEY%" ^
    -e WEBUI_NAME="%WEBUI_NAME%" ^
    -p 3000:8080 ^
    --label "com.centurylinklabs.watchtower.enable=false" ^
    ghcr.io/open-webui/open-webui:main

:: === 6/9  API-Server-Patch ===
echo [6/9] Warte auf API-Server...
set tries=0
:wait_api
timeout /t 2 /nobreak >nul
docker exec %NAME% wget -qO- http://localhost:8642/v1/models >nul 2>&1
if not !errorlevel! equ 0 (
    set /a tries+=1
    if !tries! lss 15 goto wait_api
)
echo    API-Server bereit.

:: === 7/9  MySQL Container ===
echo [7/9] MySQL Container starten...
docker rm -f %NAME%-mysql >nul 2>&1
docker run -d --restart=unless-stopped --network=hermes-net ^
    --name=%NAME%-mysql -h %NAME%-mysql ^
    -e MYSQL_ROOT_PASSWORD="%MPASS%" ^
    -v hermes_mysql_data:/var/lib/mysql ^
    --label "com.centurylinklabs.watchtower.enable=false" ^
    mysql:8.0 ^
    --default-authentication-plugin=mysql_native_password

:: Warten bis MySQL bereit
echo    Warte auf MySQL...
set tries=0
:wait_mysql
timeout /t 3 /nobreak >nul
docker exec %NAME%-mysql mysqladmin ping -uroot -p%MPASS% --silent >nul 2>&1
if not !errorlevel! equ 0 (
    set /a tries+=1
    if !tries! lss 15 goto wait_mysql
)
if !tries! lss 15 (
    echo    MySQL ist bereit.
) else (
    echo    Warnung: MySQL nicht rechtzeitig erreichbar.
)

:: === 8/9  DB Sync + Dump ===
echo [8/9] Hermes-DB nach MySQL syncen...

:: Script kopieren falls nicht vorhanden
docker exec %NAME% sh -c "test -f /opt/data/home/scripts/mysql_sync.py" >nul 2>&1
if !errorlevel! neq 0 (
    echo    Kopiere Sync-Script in den Container...
    docker exec %NAME% mkdir -p /opt/data/home/scripts
    docker cp mysql_sync.py %NAME%:/opt/data/home/scripts/mysql_sync.py
)

echo    Installiere pymysql...
docker exec %NAME% pip install pymysql -q 2>nul
echo    Synchronisiere state.db nach MySQL...
docker exec ^
    -e MYSQL_HOST=%NAME%-mysql ^
    -e MYSQL_PASS=%MPASS% ^
    -e MYSQL_DB=hermes ^
    %NAME% python3 /opt/data/home/scripts/mysql_sync.py

:: Dump erstellen
echo    Erstelle MySQL-Dump...
mkdir "D:\hermes-db-backup" 2>nul
docker exec %NAME%-mysql ^
    mysqldump -uroot -p%MPASS% --databases hermes ^
    --routines --triggers --single-transaction > "D:\hermes-db-backup\hermes_dump.sql"
echo    Dump gespeichert: D:\hermes-db-backup\hermes_dump.sql

:: === 9/9  Zusammenfassung ===
echo ======================================
echo    ALLE DIENSTE GESTARTET
echo ======================================
echo.
echo    Hermes API      : http://localhost:8642
echo    Hermes Dashboard: http://localhost:9119
echo    Open WebUI      : http://localhost:3000
echo    MySQL           : %NAME%-mysql:3306
echo    MySQL-Dump      : D:\hermes-db-backup\hermes_dump.sql
echo.
echo    Container:
docker ps --filter network=hermes-net --format "table {{.Names}}	{{.Status}}	{{.Ports}}"
echo.
echo    Zum Anschauen der Logs: docker logs ^<name^>
echo    Zum Stoppen: docker stop %NAME% %OWUI% hermes-dashboard

endlocal
