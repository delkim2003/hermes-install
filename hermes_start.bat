@echo off
title Hermes Agent - Vollstart
chcp 65001 >nul
setlocal enabledelayedexpansion

:: ============================================
:: KUNDENSPEZIFISCHE KONFIGURATION
:: ============================================
:: Vor dem ersten Start anpassen!
:: ============================================

set "API_KEY=dein-api-key-hier"       :: Beliebiges Passwort (frei waehlbar)
set "MPASS=dein-mysql-passwort"       :: MySQL Root-Passwort (frei waehlbar)
set "PROVIDER=openrouter"             :: KI-Anbieter: openrouter, anthropic, openai, deepseek
set "MODEL=anthropic/claude-sonnet-4" :: KI-Modell
set "WEBUI_NAME=Meine Firma - Hermes" :: Anzeigename in Open WebUI
set "DUMP_DIR=D:\hermes-db-backup"   :: Pfad fuer MySQL-Dump (Backup-Ordner)

:: ============================================
:: ENDE KONFIGURATION
:: ============================================

:: REPO_ROOT = Pfad in dem diese Batch liegt
set "REPO_ROOT=%~dp0"

set "NAME=hermes-agent"
set "OWUI=open-webui"

echo ======================================
echo    Hermes Agent - Vollstart
echo ======================================
echo.

:: === 1/8  Docker-Netzwerk ===
echo [1/8] Docker-Netzwerk prüfen...
docker network inspect hermes-net >nul 2>&1 && (
    echo    Netzwerk existiert bereits.
) || (
    docker network create hermes-net >nul && echo    Netzwerk angelegt.
)
echo.

:: === 2/8  Laufwerke konfigurieren ===
echo [2/8] Zusaetzliche Laufwerke in Container mounten?
set "MOUNT_VARS="
set /p ADD_MOUNT="Pfad eingeben (Enter = keins, z.B. D:\Projekte): "
if not "!ADD_MOUNT!"=="" (
    echo    Hinweis: Alle Laufwerke werden unter /mnt/ im Container verfuegbar sein.
    set "MOUNT_VARS=-v "!ADD_MOUNT!:/mnt/data""
    echo    Mount: !ADD_MOUNT! -> /mnt/data
) else (
    echo    Keine zusaetzlichen Laufwerke.
)
echo.

:: === 3/8  Hermes-Config erstellen ===
echo [3/8] Hermes-Config vorbereiten...
if not exist "%USERPROFILE%\.hermes" mkdir "%USERPROFILE%\.hermes"
(
echo # Hermes Agent Config
echo # Automatisch erstellt am %DATE% %TIME%
echo.
echo provider: %PROVIDER%
echo model: %MODEL%
echo api_key: %API_KEY%
echo tools:
echo   - terminal
echo   - web_search
echo   - file
echo   - browser
echo   - vision
) > "%USERPROFILE%\.hermes\config.yaml"
echo    Config geschrieben: %USERPROFILE%\.hermes\config.yaml
echo.

:: === 4/8  Dashboard ===
echo [4/8] Dashboard starten...
docker rm -f hermes-dashboard >nul 2>&1
docker run -d --restart=unless-stopped --network=hermes-net ^
    --name=hermes-dashboard -h hermes-dashboard ^
    -v "%USERPROFILE%\.hermes:/root/.hermes" ^
    -p 9119:9119 ^
    --label "com.centurylinklabs.watchtower.enable=false" ^
    hermes-agent:latest ^
    hermes dashboard --host 0.0.0.0 --port 9119
echo.

:: === 5/8  API Server ===
echo [5/8] API Server starten...
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

:: === 6/8  Open WebUI ===
echo [6/8] Open WebUI starten...
docker rm -f %OWUI% >nul 2>&1
docker run -d --restart=unless-stopped --network=hermes-net ^
    --name=%OWUI% -h %OWUI% ^
    -e OPENAI_API_BASE_URL="http://%NAME%:8642/v1" ^
    -e OPENAI_API_KEY="%API_KEY%" ^
    -e WEBUI_NAME="%WEBUI_NAME%" ^
    -p 3000:8080 ^
    --label "com.centurylinklabs.watchtower.enable=false" ^
    ghcr.io/open-webui/open-webui:main
echo.

:: === 7/8  MySQL + Sync + Dump ===
echo [7/8] MySQL Container starten...

:: MySQL Container
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

:: Sync-Script in Container kopieren
echo    Kopiere Sync-Script in den Container...

:: Warten bis Container fuer docker cp bereit ist
set tries=0
:wait_cp
docker exec %NAME% mkdir -p /opt/data/home/scripts >nul 2>&1
if not !errorlevel! equ 0 (
    set /a tries+=1
    if !tries! lss 15 (
        timeout /t 2 /nobreak >nul
        goto wait_cp
    )
    echo    Warnung: Container nicht rechtzeitig erreichbar fuer docker cp.
    goto skip_sync
)
docker cp "%REPO_ROOT%mysql_sync.py" %NAME%:/opt/data/home/scripts/mysql_sync.py

:: pymysql installieren und syncen
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
mkdir "%DUMP_DIR%" 2>nul
docker exec %NAME%-mysql ^
    mysqldump -uroot -p%MPASS% --databases hermes ^
    --routines --triggers --single-transaction > "%DUMP_DIR%\hermes_dump.sql"
echo    Dump gespeichert: %DUMP_DIR%\hermes_dump.sql
echo.
goto end_sync

:skip_sync
echo    Sync uebersprungen (Container nicht bereit).
:end_sync

:: === 8/8  Zusammenfassung ===
echo ======================================
echo    ALLE DIENSTE GESTARTET
echo ======================================
echo.
echo    Hermes API      : http://localhost:8642
echo    Hermes Dashboard: http://localhost:9119
echo    Open WebUI      : http://localhost:3000
echo    MySQL           : %NAME%-mysql:3306
echo    MySQL-Dump      : %DUMP_DIR%\hermes_dump.sql
echo.
echo    Container:
docker ps --filter network=hermes-net --format "table {{.Names}}	{{.Status}}	{{.Ports}}"
echo.
echo    Zum Anschauen der Logs: docker logs <name>
echo    Zum Stoppen: docker stop %NAME% %OWUI% hermes-dashboard
echo.
echo    Provider : %PROVIDER%
echo    Modell   : %MODEL%
if not "!ADD_MOUNT!"=="" echo    Mounts   : %ADD_MOUNT% -> /mnt/data

endlocal
