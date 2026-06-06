# 🤖 Hermes Agent Deployment Kit

<p align="center">
  <img src="https://einfach-online.dev/logo.png" alt="Einfach Online Logo" width="200"/>
  <br/>
  <strong>Built by <a href="https://einfach-online.dev">einfach-online.dev</a></strong>
  <br/>
  <em>Local First. Performance Driven. Privacy Centric.</em>
</p>

<p align="center">
  [![Docker](https://img.shields.io/badge/docker-ready-2496ED?logo=docker&logoColor=white)](https://www.docker.com)
  [![MySQL](https://img.shields.io/badge/mysql-8.0-4479A1?logo=mysql&logoColor=white)](https://www.mysql.com)
  [![WSL](https://img.shields.io/badge/wsl-2-0E7A0D?logo=linux&logoColor=white)](https://learn.microsoft.com/en-us/windows/wsl/)
  [![Hermes Agent](https://img.shields.io/badge/hermes-agent-8B5CF6?logo=python&logoColor=white)](https://hermes-agent.nousresearch.com)
  [![License](https://img.shields.io/badge/license-Apache%202.0-blue)](LICENSE)
  [![GitHub](https://img.shields.io/badge/GitHub-delkim2003/hermes--install-181717?logo=github&logoColor=white)](https://github.com/delkim2003/hermes-install)
</p>

---

## 🚀 Overview

**Hermes Agent Deployment Kit** is a production-ready, **zero-configuration deployment system** for [Hermes Agent](https://hermes-agent.nousresearch.com) by Nous Research — the autonomous AI agent for developers.

Everything runs **locally in Docker**. No cloud dependency. No data leaves your machine.

> **Built by [Philipp Schlemmer](https://einfach-online.dev) at einfach-online.dev — an Austrian web agency specializing in DSGVO-compliant, local-first infrastructure.**

---

## 🏗 Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                                                                     │
│   ┌──────────────┐    ┌──────────────┐    ┌──────────────────────┐  │
│   │   Hermes     │    │  Hermes      │    │    Open WebUI        │  │
│   │   API Server │    │  Dashboard   │    │    Chat Interface    │  │
│   │   :8642      │    │  :9119       │    │    :3000             │  │
│   └──────┬───────┘    └──────┬───────┘    └──────────┬───────────┘  │
│          │                  │                        │              │
│          └──────────────────┼────────────────────────┘              │
│                             │                                      │
│                    ┌────────▼────────┐                              │
│                    │  Docker Network │                              │
│                    │   hermes-net    │                              │
│                    └────────┬────────┘                              │
│                             │                                      │
│                    ┌────────▼────────┐     ┌────────────────────┐   │
│                    │   MySQL 8.0     │────▶│   MySQL Dump       │   │
│                    │   Backup/       │     │   hermes_dump.sql  │   │
│                    │   Restore       │     │   (auto-updated)   │   │
│                    └────────┬────────┘     └────────────────────┘   │
│                             │                                      │
│                    ┌────────▼──────────────────────┐                │
│                    │  state.db (SQLite ↔ MySQL)    │                │
│                    │  Synchronized on every start  │                │
│                    └───────────────────────────────┘                │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## ✨ Features

| Feature | Description | Why It Matters |
|---------|-------------|----------------|
| **🎯 Zero Configuration** | Edit 5 variables in a single batch file, double-click, done | No YAML fiddling, no scripting |
| **💾 MySQL Auto-Backup** | Every start: syncs state.db → MySQL → creates `hermes_dump.sql` | Never lose a conversation |
| **🔄 Reverse Sync** | Restore `state.db` from MySQL dump after disaster | Full disaster recovery in 5 commands |
| **🌐 Open WebUI** | Beautiful ChatGPT-style interface at `http://localhost:3000` | Familiar chat experience |
| **📊 Hermes Dashboard** | Monitor agent status at `http://localhost:9119` | Real-time system overview |
| **🔒 Local First** | No cloud, no telemetry, no third-party storage | Your data = your property |
| **🔌 Any AI Provider** | OpenRouter, Anthropic, OpenAI, DeepSeek, or custom | Freedom of choice |
| **📁 Drive Mounting** | Mount project folders into containers | Work directly on your code |
| **🔐 Privacy by Design** | No cookies, no CDNs, no external trackers | DSGVO/GDPR compliant architecture |

---

## 📋 Requirements

| Requirement | Minimum | Recommended | Notes |
|-------------|---------|-------------|-------|
| **OS** | Windows 10 Pro 22H2 | Windows 11 Pro | WSL 2 required |
| **RAM** | 16 GB | 32 GB | More RAM = faster AI responses |
| **CPU** | 4 cores, virtualization enabled | 8+ cores | Intel VT-x or AMD-V |
| **Disk** | 50 GB free | 100+ GB SSD | Docker images ~2 GB |
| **Docker** | Desktop 4.x | Latest | WSL 2 backend |
| **WSL** | Ubuntu 22.04 | Ubuntu 24.04 | Default distribution |

---

## ⚡ Quick Start

```powershell
# 1. Install prerequisites (Docker Desktop + WSL 2)
#    See INSTALLATION.md for detailed steps

# 2. Clone this repository (any drive: C:, D:, USB — works everywhere)
git clone https://github.com/delkim2003/hermes-install.git C:\hermes

# 3. Edit just 5 variables in the batch file
notepad C:\hermes\hermes_start.bat
#   → Set: API_KEY, MPASS, PROVIDER, MODEL, WEBUI_NAME

# 4. Build the Docker image (one-time, ~10 minutes)
cd C:\hermes
docker build -t hermes-agent:latest .

# 5. Launch everything
C:\hermes\hermes_start.bat
```

**Open your browser to [http://localhost:3000](http://localhost:3000)** and start chatting with your autonomous AI agent. That's it.

---

## 📦 What's Inside

| File | Purpose | Must Edit? |
|------|---------|-----------|
| `hermes_start.bat` | One-click launcher — deploys all 4 containers | ✅ Yes (5 variables) |
| `Dockerfile` | Builds the Hermes Agent container image | ❌ No |
| `mysql_sync.py` | Synchronizes state.db ↔ MySQL (bidirectional) | ❌ No |
| `INSTALLATION.md` | Step-by-step guide (30–45 min first setup) | — Read once |
| `RECOVERY.md` | Complete disaster recovery procedure | — Print & file |
| `.gitignore` | Keeps secrets and databases out of Git | ❌ No |

---

## 💽 Backup Strategy

```
  Every system start (automatic):

     state.db  ──sync──▶  MySQL  ──dump──▶  hermes_dump.sql
        (SQLite)        (Container)        (On your drive)

  Disaster recovery (manual):

     hermes_dump.sql  ──restore──▶  MySQL  ──reverse-sync──▶  state.db
```

| What | When | Where | How |
|------|------|-------|-----|
| **MySQL dump** | Every batch start (automatic) | `%DUMP_DIR%\hermes_dump.sql` | Contains ALL sessions, messages, memory |
| **Hermes config** | On changes | `%USERPROFILE%\.hermes\config.yaml` | Manual backup |
| **Docker volumes** | Every few months | `docker volume inspect hermes_mysql_data` | Manual backup |

> 💡 **Copy `%DUMP_DIR%\hermes_dump.sql` to a USB drive regularly.** This single file contains your entire Hermes brain — conversations, agent sessions, and memory. Everything else can be rebuilt from this repository.

---

## 🔒 Security Philosophy

| Principle | Implementation |
|-----------|---------------|
| **No cloud dependency** | Everything runs in Docker on your local machine |
| **No data exfiltration** | AI queries go directly to your chosen provider (OpenRouter, etc.) |
| **No telemetry** | Zero tracking, zero analytics, zero cookies |
| **No tunnel** | No Cloudflare, no ngrok — no remote access points (by design) |
| **Encrypted at rest** | MySQL volume + optional Cryptomator vault support |
| **API authentication** | Hermes ↔ Open WebUI secured with your own API key |

Designed for **DSGVO/GDPR-compliant deployments** where data sovereignty is non-negotiable.

---

## 🛡 Security Checklist

- [ ] API key is a strong, unique password
- [ ] MySQL password is different from API key
- [ ] No secrets committed to Git (`.gitignore` handles this)
- [ ] No cloud tunnels or remote access enabled
- [ ] Provider API key stored as Windows environment variable (not in batch file)
- [ ] External backup of `hermes_dump.sql` configured

---

## 🧰 Tools & Integrations

Hermes Agent comes with built-in tools that Just Work:

| Tool | Purpose | Available |
|------|---------|-----------|
| `terminal` | Run shell commands | ✅ |
| `web_search` | Search the internet | ✅ |
| `file` | Read/write files | ✅ |
| `browser` | Navigate web pages | ✅ |
| `vision` | Analyze images | ✅ |
| `memory` | Persistent cross-session memory | ✅ |
| `skills` | Reusable task workflows | ✅ |
| `cronjob` | Scheduled tasks | ✅ |

---

## ❓ Frequently Asked Questions

**Q: Can I run this on a different drive?**  
A: Yes. Clone the repo to C:\, D:\, USB drive, or network drive. The batch file auto-detects its own location.

**Q: Do I need an internet connection?**  
A: Only for the initial build (Docker images + PyPI packages) and for AI queries. After setup, Docker runs fully offline.

**Q: How do I update Hermes Agent?**  
A: Re-run `docker build --no-cache -t hermes-agent:latest .` in the repo directory. The batch file uses the latest built image.

**Q: Can I use multiple AI providers?**  
A: Yes. Change `PROVIDER` and `MODEL` in the batch file, also set the corresponding API key as a Windows environment variable. Restart the API server with `docker restart hermes-agent`.

**Q: How do I access my old chat sessions after recovery?**  
A: The reverse sync (Step 6 in RECOVERY.md) restores all sessions and messages into `state.db`. Open WebUI will show them in the sidebar.

---

## 📚 Documentation

| Document | Language | Content |
|----------|----------|---------|
| [INSTALLATION.md](INSTALLATION.md) | 🇬🇧 English | Step-by-step setup guide |
| [INSTALLATION.de.md](INSTALLATION.de.md) | 🇩🇪 German | Vollständige Installationsanleitung |
| [RECOVERY.md](RECOVERY.md) | 🇬🇧 English | Disaster recovery procedure |
| [README.de.md](README.de.md) | 🇩🇪 German | Diese Seite auf Deutsch |

---

## 📞 Support

Built with ❤️ by **Philipp Schlemmer**

| Contact | Details |
|---------|---------|
| **Agency** | [einfach-online.dev](https://einfach-online.dev) |
| **Email** | info@einfach-online.dev |
| **Phone** | +43 664 2550 779 |
| **Location** | Austria (EU) |
| **Expertise** | DSGVO-compliant web infrastructure, AI deployment, Local First architecture |

Need a custom deployment or enterprise support? [Get in touch](mailto:info@einfach-online.dev).

---

## 📄 License

[Apache 2.0](https://github.com/nousresearch/hermes-agent/blob/main/LICENSE)

Built on top of [Hermes Agent](https://github.com/nousresearch/hermes-agent) by Nous Research.  
Deployment system, documentation, and automation by [einfach-online.dev](https://einfach-online.dev).

---

<p align="center">
  <sub>Local First. Performance Driven. Privacy Centric.</sub>
  <br/>
  <sub>© 2024–2025 einfach-online.dev | Philipp Schlemmer | All rights reserved.</sub>
</p>
