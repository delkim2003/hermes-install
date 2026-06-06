# Hermes Agent – Complete Installation Guide

This guide walks you through setting up **Hermes Agent** on a blank Windows system.  
Follow the steps in order – each builds on the previous one.

**Estimated total time:** 30–45 minutes (mostly waiting for downloads).

> **Path conventions:** All paths in this guide are relative to your repository folder.
> If you cloned to `C:\hermes`, then `<REPO_DIR>` = `C:\hermes`.
> If you cloned to `D:\hermes`, then `<REPO_DIR>` = `D:\hermes`.
> The batch file automatically detects its own location — no manual path editing needed.

---

## Table of Contents

- [Phase 1: Prerequisites](#phase-1-prerequisites)
- [Phase 2: Repository & Image](#phase-2-repository--image)
- [Phase 3: Configuration](#phase-3-configuration)
- [Phase 4: First Start](#phase-4-first-start)
- [Phase 5: Verification](#phase-5-verification)
- [Phase 6: Daily Operation](#phase-6-daily-operation)
- [Phase 7: Troubleshooting](#phase-7-troubleshooting)

---

## Phase 1: Prerequisites

### Step 1: Enable WSL 2

**Duration: ~5 minutes**

Open **PowerShell as Administrator** and run:

```powershell
wsl --install -d Ubuntu
```

What happens:
- Windows may restart once
- After restart, an Ubuntu terminal opens automatically
- **You must create a Linux username and password** – write these down!
- This is your WSL user, not your Windows user

**Verify:**

```powershell
wsl -l -v
```

Expected output:
```
  NAME      STATE           VERSION
* Ubuntu    Running         2
```

**If `wsl` is not found**, enable the Windows feature first:

```powershell
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
```

Then **restart Windows** and run `wsl --install -d Ubuntu` again.

---

### Step 2: Install Docker Desktop

**Duration: ~10 minutes**

1. Download Docker Desktop from: https://www.docker.com/products/docker-desktop/
2. Run the installer (default settings are fine)
3. During setup, check **"Use WSL 2 instead of Hyper-V"**
4. After installation, Docker Desktop starts automatically
5. Wait for the green "Engine running" indicator in the bottom-left corner

**Verify:**

```powershell
docker --version
docker compose version
```

Both should show version numbers, not errors.

**Important:** Docker Desktop must be started manually after each Windows reboot. You can enable auto-start in Docker Desktop → Settings → General → "Start Docker Desktop when you log in".

---

### Step 3: Enable WSL Integration in Docker

**Duration: ~2 minutes**

1. Open Docker Desktop
2. Go to **Settings** (gear icon) → **Resources** → **WSL Integration**
3. Toggle **ON** for **Ubuntu**
4. Click **Apply & Restart**

**Verify:**

```powershell
wsl docker ps
```

Should show an empty container list (no error).

---

## Phase 2: Repository & Image

### Step 4: Clone the Repository

**Duration: ~2 minutes**

```powershell
cd <REPO_DIR>
git clone https://github.com/delkim2003/hermes-install.git .
cd <REPO_DIR>
```

**Result:** Folder `<REPO_DIR>\` with all installation files:

| File | Description |
|------|-------------|
| `hermes_start.bat` | One-click launcher for daily use |
| `INSTALLATION.md` | This guide |
| `RECOVERY.md` | Disaster recovery instructions |
| `Dockerfile` | Build file for the Hermes container |
| `mysql_sync.py` | Database synchronization script |
| `.gitignore` | Protects sensitive files from Git |

---

### Step 5: Build the Hermes Docker Image

**Duration: 10–20 minutes (depends on internet speed)**

```powershell
cd <REPO_DIR>
docker build -t hermes-agent:latest .
```

Docker downloads the Python base image (~120 MB) and installs Hermes Agent from PyPI.  
You only need to do this once. After that, the image is cached locally.

**Verify:**

```powershell
docker images hermes-agent
```

Expected output (versions may differ):
```
REPOSITORY      TAG       IMAGE ID       CREATED          SIZE
hermes-agent    latest    a1b2c3d4e5f6   2 minutes ago    350 MB
```

**Tip:** When a new version of Hermes Agent is released, just re-run `docker build -t hermes-agent:latest .` to update.

---

## Phase 3: Configuration

### Step 6: Edit the Batch File

**Duration: ~5 minutes**

Open `<REPO_DIR>\hermes_start.bat` in Notepad and edit these 5 variables:

```batch
set "API_KEY=change-me-to-a-secure-password"    -> Your own password (any text)
set "MPASS=change-me-mysql-password"            -> MySQL root password (any text)
set "PROVIDER=openrouter"                       -> Your AI provider
set "MODEL=anthropic/claude-sonnet-4"           -> Your AI model
set "WEBUI_NAME=My Company - Hermes"            -> Your company/project name
```

**Variable reference:**

| Variable | Required | Description |
|----------|----------|-------------|
| `API_KEY` | ✅ Yes | Any password. Used for API authentication between Hermes and Open WebUI. |
| `MPASS` | ✅ Yes | MySQL root password. Used for the database container and backups. |
| `PROVIDER` | ✅ Yes | AI provider: `openrouter`, `anthropic`, `openai`, `deepseek`, or `custom` |
| `MODEL` | ✅ Yes | Model name: `anthropic/claude-sonnet-4`, `gpt-4o`, `deepseek-v4-flash`, etc. |
| `WEBUI_NAME` | ❌ No | Display name shown in Open WebUI (top-left corner). |
| `DUMP_DIR` | ❌ No | Path for MySQL backup. Default: `<REPO_DIR>\\backups\\` |

**On first run, you also need to set your provider's API key:**

Your AI provider (OpenRouter, Anthropic, etc.) needs an API key for billing. Set it as a Windows environment variable:

```powershell
:: For OpenRouter
setx OPENROUTER_API_KEY "sk-or-...your-key-here"

:: For Anthropic
setx ANTHROPIC_API_KEY "sk-ant-...your-key-here"

:: For OpenAI
setx OPENAI_API_KEY "sk-...your-key-here"
```

After running `setx`, close and reopen PowerShell, or restart your computer for the variable to take effect.

---

## Phase 4: First Start

### Step 7: Run the Batch File

**Duration: ~5 minutes (first run: +2 minutes for MySQL image pull)**

1. **Start Docker Desktop** (if not already running)
2. **Double-click** `<REPO_DIR>\hermes_start.bat`
3. The batch will ask about additional drive mounts (press Enter to skip)
4. Watch the progress – the batch runs through 8 steps:

```
[1/8] Docker Network         → Creates hermes-net
[2/8] Optional mounts        → Your folders inside containers
[3/8] Create config          → Writes %USERPROFILE%\.hermes\config.yaml
[4/8] Dashboard              → Starts Hermes Dashboard on port 9119
[5/8] API Server             → Starts Hermes API on port 8642
[6/8] Open WebUI             → Starts chat UI on port 3000
[7/8] MySQL + Sync + Dump    → Starts MySQL, syncs database, creates dump
[8/8] Summary                → Shows all running services
```

**First-run notes:**
- The MySQL container (~450 MB) is downloaded on first start – this takes ~2 minutes
- The batch waits automatically for MySQL to be ready before proceeding
- If a service fails to start, the batch continues with the remaining services

---

## Phase 5: Verification

### Step 8: Test Everything

**Duration: ~5 minutes**

After the batch finishes successfully:

| Service | URL | Expected Result |
|---------|-----|-----------------|
| **Hermes API** | http://localhost:8642/v1/models | JSON with model list |
| **Hermes Dashboard** | http://localhost:9119 | Hermes status page |
| **Open WebUI** | http://localhost:3000 | Login/register page |

**API Test:**
```powershell
curl http://localhost:8642/v1/models
```

Should return a JSON array with your configured model.

**Open WebUI Login:**
- First visit: Create an account (username + password – free choice)
- You should see your configured `WEBUI_NAME` in the top-left corner
- Select your model from the dropdown at the top of the chat

**Dashboard Check:**
- Open http://localhost:9119
- Should show the Hermes dashboard with service status

**Send a test message:**
1. Go to Open WebUI (http://localhost:3000)
2. Start a new chat
3. Type "Hello" – Hermes should respond

---

### Step 9: Verify MySQL Backup

**Duration: ~2 minutes**

Check that the database sync worked:

```powershell
:: Count sessions in MySQL
docker exec hermes-agent-mysql mysql -uroot -pYOUR_MPASS hermes -e "SELECT COUNT(*) AS sessions FROM sessions"

:: Count messages in MySQL
docker exec hermes-agent-mysql mysql -uroot -pYOUR_MPASS hermes -e "SELECT COUNT(*) AS messages FROM messages"

:: Check the dump file exists
dir %DUMP_DIR%
```

Expected:
- Sessions ≥ 0 (increases with use)
- Messages ≥ 0 (increases with use)
- `hermes_dump.sql` exists and is not empty

---

## Phase 6: Daily Operation

### Daily Start

```powershell
# 1. Start Docker Desktop (or it auto-starts)
# 2. Run the batch
<REPO_DIR>\hermes_start.bat
```

After ~2 minutes, all services are running.

**Desktop shortcut (optional):**
1. Right-click your desktop → New → Shortcut
2. Location: `<REPO_DIR>\hermes_start.bat`
3. Name: "Hermes Agent"
4. Optional: Right-click shortcut → Properties → Advanced → "Run as administrator"

### Managing Containers

```powershell
# View running services
docker ps --filter network=hermes-net

# View logs for a specific service
docker logs hermes-agent

# Stop all services (without running the batch)
docker stop hermes-agent open-webui hermes-dashboard hermes-agent-mysql
```

### Backup Strategy

| What | When | Where |
|------|------|-------|
| **MySQL dump** | Every start (automatic) | `%DUMP_DIR%\hermes_dump.sql` |
| **Hermes config** | Manually on changes | `%USERPROFILE%\.hermes\` |
| **Docker volumes** | Manually (every few months) | `docker volume inspect hermes_mysql_data` |

**External backup:** Copy `%DUMP_DIR%\hermes_dump.sql` to a USB drive or NAS regularly.  
This single file contains all your sessions, messages, and memory.

---

## Phase 7: Troubleshooting

### "Docker" is not recognized

→ Docker Desktop is not installed or not running.  
Open Docker Desktop and wait for "Engine running."

### "WSL" is not recognized

→ Run as Administrator:
```powershell
wsl --install -d Ubuntu
```

### MySQL fails to start

```powershell
docker logs hermes-agent-mysql
```

Common causes:
- Port 3306 is already in use (another MySQL running)
- Not enough disk space for the volume

### MySQL sync fails

Run the sync manually:
```powershell
docker exec -e MYSQL_HOST=hermes-agent-mysql -e MYSQL_PASS=YOUR_MPASS hermes-agent python3 /opt/data/home/scripts/mysql_sync.py
```

Check the verbose output for errors.

### API returns empty model list

- Check that `%USERPROFILE%\.hermes\config.yaml` exists and has `provider` and `model` set
- Check that your provider's API key is set as a Windows environment variable
- Restart the API server: `docker restart hermes-agent`

### Open WebUI shows "No model selected"

- Open WebUI → click the model dropdown at the top → select your model
- If it's not there, restart the API server: `docker restart hermes-agent`
- If the name doesn't match, check the `MODEL` variable in your batch file

### "hermes: command not found" in Docker build

This happens if pip couldn't install `hermes-agent`. Try:
```powershell
docker build --no-cache -t hermes-agent:latest .
```

---

## Post-Installation Checklist

- [ ] Open WebUI login works
- [ ] You can send a message and get a response
- [ ] MySQL dump exists in `%DUMP_DIR%`
- [ ] Desktop shortcut created
- [ ] External backup of dump configured
- [ ] `RECOVERY.md` printed and filed with system documentation

---

## Next Steps

- Customize Open WebUI with your company logo and colors
- Enable Hermes skills for your use case (web search, file operations, etc.)
- Set up automated external backups of `%DUMP_DIR%`
- Print `RECOVERY.md` and keep it with your system documentation

---

## Support & Contact

<p align="center">
  <strong>Built by <a href="https://einfach-online.dev">einfach-online.dev</a></strong><br/>
  Philipp Schlemmer | info@einfach-online.dev | +43 664 2550 779<br/>
  <em>Local First. Performance Driven. Privacy Centric.</em>
</p>

Need help with installation or a custom deployment?
[Send me an email](mailto:info@einfach-online.dev) — I reply within 24 hours.
