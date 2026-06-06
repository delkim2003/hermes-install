# Hermes Agent – Disaster Recovery

> **Restore everything from a MySQL dump.**  
> Use this when the system is completely gone – new PC, drive failure, or full reinstall.

This guide assumes:
- You have a MySQL dump file (`hermes_dump.sql`) from a previous backup
- You have cloned this repository (or can access it on GitHub)
- You are starting from a **blank Windows system**

**Recovery time:** ~30 minutes (mostly downloads).

---

## Table of Contents

- [Before You Start](#before-you-start)
- [Step 1: Prerequisites](#step-1-prerequisites)
- [Step 2: Locate Your Dump](#step-2-locate-your-dump)
- [Step 3: Clone & Build](#step-3-clone--build)
- [Step 4: Restore MySQL](#step-4-restore-mysql)
- [Step 5: Start Hermes](#step-5-start-hermes)
- [Step 6: Reverse Sync](#step-6-reverse-sync)
- [Step 7: Verify](#step-7-verify)
- [Quick Reference](#quick-reference)
- [Troubleshooting](#troubleshooting)

---

## Before You Start

You need these to recover:

- [ ] Docker Desktop installed and running
- [ ] WSL 2 enabled with Ubuntu
- [ ] This repository cloned (`git clone https://github.com/delkim2003/hermes-install.git D:\hermes`)
- [ ] Hermes Docker image built (`docker build -t hermes-agent:latest D:\hermes`)
- [ ] Your dump file: `hermes_dump.sql`
- [ ] Your batch configuration (API_KEY, MPASS, PROVIDER, MODEL)

> **If you don't have the prerequisites yet**, follow [INSTALLATION.md](INSTALLATION.md) Phase 1 (Steps 1–3) and Phase 2 (Steps 4–5) to set them up.

---

## Step 1: Prerequisites

If you're on a new machine, start here.

### 1A: Enable WSL 2

```powershell
# PowerShell as Administrator
wsl --install -d Ubuntu
```

After restart, create your Linux user.

### 1B: Install Docker Desktop

Download from: https://www.docker.com/products/docker-desktop/

During installation, select **"Use WSL 2 instead of Hyper-V"**.

### 1C: WSL Integration

Docker Desktop → Settings → Resources → WSL Integration → Toggle **Ubuntu** ON → Apply & Restart

---

## Step 2: Locate Your Dump

The backup was created at `%DUMP_DIR%\hermes_dump.sql`.  
Common locations:

| Source | Typical path |
|--------|-------------|
| Default backup | `D:\hermes-db-backup\hermes_dump.sql` |
| Your copy | wherever you saved it |

**Copy the dump into your repo folder** for easy access:

```powershell
copy D:\hermes-db-backup\hermes_dump.sql D:\hermes\
:: or from USB / network drive
copy E:\backups\hermes_dump.sql D:\hermes\
```

---

## Step 3: Clone & Build

```powershell
cd D:\
git clone https://github.com/delkim2003/hermes-install.git hermes
cd D:\hermes
docker build -t hermes-agent:latest .
```

> If you already did this during initial setup, skip ahead to Step 4.

---

## Step 4: Restore MySQL

### 4A: Start MySQL Container

```powershell
docker network create hermes-net 2>nul
docker run -d --restart=unless-stopped --network=hermes-net ^
    --name=hermes-agent-mysql -h hermes-agent-mysql ^
    -e MYSQL_ROOT_PASSWORD=YOUR_MPASS ^
    -v hermes_mysql_data:/var/lib/mysql ^
    mysql:8.0 ^
    --default-authentication-plugin=mysql_native_password
```

Wait ~30 seconds for MySQL to initialize:

```powershell
:wait_loop
docker exec hermes-agent-mysql mysqladmin ping -uroot -pYOUR_MPASS --silent >nul 2>&1
if %errorlevel% neq 0 (timeout /t 3 /nobreak >nul & goto wait_loop)
echo MySQL is ready
```

### 4B: Import the Dump

```powershell
type D:\hermes\hermes_dump.sql | docker exec -i hermes-agent-mysql mysql -uroot -pYOUR_MPASS
```

**Verify:**

```powershell
docker exec hermes-agent-mysql mysql -uroot -pYOUR_MPASS hermes -e "SELECT COUNT(*) AS sessions FROM sessions"
docker exec hermes-agent-mysql mysql -uroot -pYOUR_MPASS hermes -e "SELECT COUNT(*) AS messages FROM messages"
```

These should match your pre-disaster counts. If they show 0, the import failed – check the dump file.

---

## Step 5: Start Hermes

### 5A: Copy Config & Sync Script

```powershell
:: Create config directory
if not exist "%USERPROFILE%\.hermes" mkdir "%USERPROFILE%\.hermes"

:: Write config.yaml
(
echo provider: YOUR_PROVIDER
echo model: YOUR_MODEL
echo api_key: YOUR_API_KEY
echo terminal:
echo   backend: local
echo api_server:
echo   enabled: true
echo   port: 8642
echo   api_key: YOUR_API_KEY
echo tools:
echo   - terminal
echo   - web_search
echo   - file
echo   - browser
echo   - vision
) > "%USERPROFILE%\.hermes\config.yaml"
```

### 5B: Start Hermes API & Dashboard

```powershell
:: Dashboard
docker run -d --restart=unless-stopped --network=hermes-net ^
    --name=hermes-dashboard -h hermes-dashboard ^
    -v "%USERPROFILE%\.hermes:/root/.hermes" ^
    -p 9119:9119 ^
    hermes-agent:latest ^
    hermes dashboard --host 0.0.0.0 --port 9119

:: API Server
docker run -d --restart=unless-stopped --network=hermes-net ^
    --name=hermes-agent -h hermes-agent ^
    -v "%USERPROFILE%\.hermes:/root/.hermes" ^
    -e HERMES_PROVIDER_OVERRIDE="YOUR_PROVIDER" ^
    -e HERMES_MODEL_OVERRIDE="YOUR_MODEL" ^
    -e HERMES_API_KEY="YOUR_API_KEY" ^
    -p 8642:8642 ^
    -p 8641:8641 ^
    hermes-agent:latest ^
    hermes api-server --host 0.0.0.0 --port 8642

:: Open WebUI
docker run -d --restart=unless-stopped --network=hermes-net ^
    --name=open-webui -h open-webui ^
    -e OPENAI_API_BASE_URL="http://hermes-agent:8642/v1" ^
    -e OPENAI_API_KEY="YOUR_API_KEY" ^
    -e WEBUI_NAME="My Company - Hermes" ^
    -e WEBUI_SECRET_KEY="YOUR_API_KEY" ^
    -p 3000:8080 ^
    ghcr.io/open-webui/open-webui:main
```

Wait for the API server:

```powershell
timeout /t 5 /nobreak >nul
```

### 5C: Copy Sync Script into Container

```powershell
docker exec hermes-agent mkdir -p /opt/data/home/scripts
docker cp D:\hermes\mysql_sync.py hermes-agent:/opt/data/home/scripts/mysql_sync.py
docker exec hermes-agent pip install pymysql -q
```

---

## Step 6: Reverse Sync

This is the critical step – it restores `state.db` (Hermes' internal database) from MySQL.

```powershell
docker exec ^
    -e MYSQL_HOST=hermes-agent-mysql ^
    -e MYSQL_PASS=YOUR_MPASS ^
    -e MYSQL_DB=hermes ^
    -e SYNC_DIRECTION=reverse ^
    hermes-agent python3 /opt/data/home/scripts/mysql_sync.py
```

Expected output:
```
[HH:MM:SS] Hermes -> MySQL Synchronisation gestartet
[HH:MM:SS]   SQLite: /opt/data/state.db
[HH:MM:SS]   MySQL:  root@hermes-agent-mysql:3306/hermes
[HH:MM:SS] Modus: REVERSE - MySQL -> SQLite
[HH:MM:SS]   XX Sessions wiederhergestellt
[HH:MM:SS]   YY Messages wiederhergestellt
[HH:MM:SS]   SQLite-Commit erfolgreich
[HH:MM:SS]   Fertig: state.db wiederhergestellt aus MySQL
[HH:MM:SS] === Synchronisation abgeschlossen ===
```

If this succeeds, **Hermes now has all your old sessions and messages back**.

---

## Step 7: Verify

### 7A: API Test

```powershell
curl http://localhost:8642/v1/models
```

Should return your model list.

### 7B: Open WebUI

Open http://localhost:3000 in your browser.

- Your old chat sessions should appear in the sidebar
- You can continue conversations where you left off
- All memory entries are restored

### 7C: Container Status

```powershell
docker ps --filter network=hermes-net
```

All 4 containers should be running: `hermes-agent`, `hermes-dashboard`, `open-webui`, `hermes-agent-mysql`.

### 7D: Create a Fresh Dump

Run `D:\hermes\hermes_start.bat` once to create a fresh backup.

---

## Quick Reference

**One-liner recovery** (run from `D:\hermes\` after prerequisites are done):

```powershell
:: 1. Start MySQL and import
docker run -d --restart=unless-stopped --network=hermes-net --name=hermes-agent-mysql -h hermes-agent-mysql -e MYSQL_ROOT_PASSWORD=YOUR_MPASS -v hermes_mysql_data:/var/lib/mysql mysql:8.0 --default-authentication-plugin=mysql_native_password
timeout /t 30 /nobreak >nul
type hermes_dump.sql | docker exec -i hermes-agent-mysql mysql -uroot -pYOUR_MPASS

:: 2. Start Hermes
docker run -d --restart=unless-stopped --network=hermes-net --name=hermes-dashboard -h hermes-dashboard -v "%USERPROFILE%\.hermes:/root/.hermes" -p 9119:9119 hermes-agent:latest hermes dashboard --host 0.0.0.0 --port 9119
docker run -d --restart=unless-stopped --network=hermes-net --name=hermes-agent -h hermes-agent -v "%USERPROFILE%\.hermes:/root/.hermes" -e HERMES_PROVIDER_OVERRIDE="YOUR_PROVIDER" -e HERMES_MODEL_OVERRIDE="YOUR_MODEL" -e HERMES_API_KEY="YOUR_API_KEY" -p 8642:8642 -p 8641:8641 hermes-agent:latest hermes api-server --host 0.0.0.0 --port 8642
docker run -d --restart=unless-stopped --network=hermes-net --name=open-webui -h open-webui -e OPENAI_API_BASE_URL="http://hermes-agent:8642/v1" -e OPENAI_API_KEY="YOUR_API_KEY" -e WEBUI_NAME="My Company - Hermes" -e WEBUI_SECRET_KEY="YOUR_API_KEY" -p 3000:8080 ghcr.io/open-webui/open-webui:main
timeout /t 10 /nobreak >nul

:: 3. Reverse sync
docker exec hermes-agent mkdir -p /opt/data/home/scripts
docker cp mysql_sync.py hermes-agent:/opt/data/home/scripts/mysql_sync.py
docker exec hermes-agent pip install pymysql -q
docker exec -e MYSQL_HOST=hermes-agent-mysql -e MYSQL_PASS=YOUR_MPASS -e MYSQL_DB=hermes -e SYNC_DIRECTION=reverse hermes-agent python3 /opt/data/home/scripts/mysql_sync.py

:: 4. Done
echo Hermes restored from dump. Open http://localhost:3000
```

---

## Troubleshooting

### "Access denied for user" when restoring dump

→ Your MPASS in the command doesn't match the MPASS used during backup.

### MySQL container exits immediately

```powershell
docker logs hermes-agent-mysql
```

Common causes:
- Port conflict on 3306
- Corrupted volume: `docker volume rm hermes_mysql_data` then restart

### Reverse sync says "SQLite: /opt/data/state.db not found"

The Hermes API server creates `state.db` automatically on first start.  
Restart the API server: `docker restart hermes-agent`, wait 10 seconds, then retry.

### Reverse sync says "MySQL not reachable"

→ MySQL container isn't running or the password is wrong.

```powershell
docker ps                              # Is MySQL running?
docker exec hermes-agent-mysql mysqladmin ping -uroot -pYOUR_MPASS --silent  # Can we reach it?
```

### Dump file is empty or corrupted

→ Restore from an older backup copy. Check `%DUMP_DIR%` for previous versions.

### Open WebUI shows no old chats

→ The reverse sync may have failed. Check the sync output for errors.  
→ Try running the reverse sync command again.

---

## Prevention: Keep These Safe

To avoid a future disaster, back up **these 3 things** regularly:

| What | Where to find it | Backup frequency |
|------|-----------------|-----------------|
| **MySQL dump** | `%DUMP_DIR%\hermes_dump.sql` | Every system start (automatic) |
| **Hermes config** | `%USERPROFILE%\.hermes\config.yaml` | On changes |
| **This repo** | GitHub | Always available |

The MySQL dump is the most important – it contains everything Hermes knows.
