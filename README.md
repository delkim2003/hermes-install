# Hermes Agent

> **Autonomous AI agent deployment toolkit** by [Nous Research](https://github.com/nousresearch/hermes-agent)  
> Pre-configured with Docker, MySQL backup, and Open WebUI

[![Docker](https://img.shields.io/badge/docker-ready-2496ED?logo=docker&logoColor=white)](https://www.docker.com)
[![MySQL](https://img.shields.io/badge/mysql-8.0-4479A1?logo=mysql&logoColor=white)](https://www.mysql.com)
[![WSL](https://img.shields.io/badge/wsl-2-0E7A0D?logo=linux&logoColor=white)](https://learn.microsoft.com/en-us/windows/wsl/)
[![License](https://img.shields.io/badge/license-Apache%202.0-blue)](LICENSE)

---

## Overview

This repository provides a complete, production-ready deployment of **Hermes Agent** – the autonomous AI agent by Nous Research – on a local Windows machine. Everything runs in Docker, fully offline and private.

```
  ┌──────────────────────────────────────────────────┐
  │                                                   │
  │   ┌──────────┐   ┌───────────┐   ┌───────────┐  │
  │   │ Hermes   │   │ Dashboard │   │Open WebUI │  │
  │   │ API      │   │ :9119     │   │ :3000     │  │
  │   │ :8642    │   │           │   │           │  │
  │   └────┬─────┘   └─────┬─────┘   └─────┬─────┘  │
  │        └───────────────┼───────────────┘         │
  │                       │                         │
  │              ┌────────▼────────┐                 │
  │              │ Docker Network  │                 │
  │              │  hermes-net     │                 │
  │              └────────┬────────┘                 │
  │                       │                         │
  │              ┌────────▼────────┐                 │
  │              │  MySQL 8.0      │                 │
  │              │  (backup via    │                 │
  │              │   mysqldump)    │                 │
  │              └────────┬────────┘                 │
  │                       │                         │
  │              ┌────────▼────────┐                 │
  │              │  hermes_dump.sql│                 │
  │              │  (in backups/)  │                 │
  │              └─────────────────┘                 │
  └──────────────────────────────────────────────────┘
```

## Features

| Feature | Description |
|---------|-------------|
| **Zero configuration** | Edit 5 variables in the batch file, double-click, and go |
| **MySQL backup** | Every start creates a full dump of all sessions, messages, and memory |
| **Open WebUI** | Beautiful chat interface at `http://localhost:3000` |
| **Hermes Dashboard** | Monitor agent status at `http://localhost:9119` |
| **Local first** | No cloud dependency. Your data stays on your machine |
| **Any provider** | Works with OpenRouter, Anthropic, OpenAI, DeepSeek, or custom endpoints |
| **Drive mounting** | Optionally mount project folders into the containers |

## Quick Start

```powershell
# 1. Install prerequisites (see INSTALLATION.md for details)
# 2. Clone this repository
git clone https://github.com/delkim2003/hermes-install.git

# 3. Edit configuration
notepad hermes_start.bat
#   → Set API_KEY, MPASS, PROVIDER, MODEL

# 4. Build the Docker image
docker build -t hermes-agent:latest .

# 5. Start everything
hermes_start.bat
```

Open your browser to `http://localhost:3000` and start chatting.

## What's Included

| File | Purpose |
|------|---------|
| `hermes_start.bat` | One-click launcher for all services |
| `INSTALLATION.md` | Step-by-step setup guide (30-45 minutes) |
| `RECOVERY.md` | Disaster recovery from MySQL dump |
| `Dockerfile` | Builds the Hermes Agent container image |
| `mysql_sync.py` | Synchronizes state.db ↔ MySQL |
| `.gitignore` | Prevents secrets and databases from being committed |

## Backup Strategy

```
state.db (SQLite)  ──sync──▶  MySQL  ──dump──▶  hermes_dump.sql
                                                    │
              ▲◀─── reverse-sync ◀─── restore ──────┘
```

| What | When | Where |
|------|------|-------|
| **MySQL dump** | Every container start (automatic) | `%DUMP_DIR%\hermes_dump.sql` |
| **Hermes config** | Manually on changes | `%USERPROFILE%\.hermes\` |
| **Docker volumes** | Manually (every few months) | `docker volume inspect` |

## Requirements

| Requirement | Minimum | Recommended |
|-------------|---------|-------------|
| OS | Windows 10 Pro 22H2 | Windows 11 Pro |
| RAM | 16 GB | 32 GB |
| CPU | 4 cores | 8+ cores |
| Disk | 50 GB free | 100+ GB SSD |
| CPU virtualization | Enabled in BIOS | – |

## Security

- **Your API keys** – only stored in the config file and Windows env variables
- **Your chat data** – never leaves your machine
- **Your AI queries** – go directly to your chosen provider (OpenRouter, etc.)
- **No cloud tunnel** – no remote access points (by design)
- **Automatic MySQL dump** – backup the entire Hermes brain to `backups\hermes_dump.sql`

## License

Apache 2.0 – see [LICENSE](https://github.com/nousresearch/hermes-agent/blob/main/LICENSE).

Built with [Hermes Agent](https://github.com/nousresearch/hermes-agent) by Nous Research.
