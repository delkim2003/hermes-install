# Hermes Agent Deployment Kit

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

## What is this?

**Hermes Agent Deployment Kit** lets you set up a fully autonomous AI agent on your Windows machine in under 2 minutes. One batch file starts everything: API server, chat interface, MySQL database, and automated backups.

**[Hermes Agent](https://hermes-agent.nousresearch.com)** is an open-source AI agent by Nous Research. It can browse the web, run terminal commands, read and write files, search your codebase, and delegate tasks to sub-agents -- all through natural conversation.

This kit makes it dead simple to deploy. No Docker Compose, no manual config, no missing steps.

---

## How it works

You run **one file** (`hermes_start.bat`). It does the rest:

| # | What happens |
|---|-------------|
| 1 | Creates a Docker network (`hermes-net`) |
| 2 | Asks if you want to mount folders into containers |
| 3 | Writes Hermes config file (`~/.hermes/config.yaml`) |
| 4 | Starts Hermes Dashboard (port 9119) |
| 5 | Starts Hermes API Server (port 8642) |
| 6 | Starts Open WebUI chat interface (port 3000) |
| 7 | Starts MySQL 8.0 + syncs state.db + creates dump |
| 8 | Shows running containers and URLs |

Total time: ~90 seconds. No manual steps.

---

## Architecture

```
  +------------------+    +------------------+    +--------------------+
  |   Hermes         |    |  Hermes          |    |    Open WebUI      |
  |   API Server     |    |  Dashboard       |    |    Chat Interface  |
  |   :8642          |    |  :9119           |    |    :3000           |
  +--------+---------+    +--------+---------+    +---------+----------+
           |                       |                         |
           +-----------------------+-------+-----------------+
                                           |
                                   +-------+--------+
                                   |    MySQL 8.0   |
                                   |  state backup  |
                                   +----------------+
                                           |
                                   +-------+--------+
                                   |  mysqldump     |
                                   |  hermes_dump.sql|
                                   +----------------+
```

---

## Features

| Component | Description |
|-----------|-------------|
| Hermes API Server | Core AI agent, OpenAI-compatible API on port 8642 |
| Hermes Dashboard | Web-based dashboard for monitoring at port 9119 |
| Open WebUI | Full chat interface at port 3000 |
| MySQL 8.0 | Persistent session and memory storage |
| Automated Dump | `mysqldump` creates a full backup on every start |
| Sub-agent Support | Hermes can spawn autonomous sub-agents for parallel work |
| Recovery Ready | Reverse-sync restores everything from a single SQL dump |

---

## Requirements

| Requirement | Version | Notes |
|-------------|---------|-------|
| Windows 10/11 | Pro or Home | WSL2 support required |
| Docker Desktop | 4.x+ | [Download](https://www.docker.com/products/docker-desktop/) |
| WSL2 | Enabled | [Guide](https://learn.microsoft.com/en-us/windows/wsl/install) |
| RAM | 4 GB+ | Hermes ~200 MB, MySQL ~200 MB |
| Disk | 2 GB | Docker images, MySQL volume |

---

## Quick Start

```powershell
# 1. Clone
git clone https://github.com/delkim2003/hermes-install.git D:\hermes

# 2. Edit config
notepad D:\hermes\hermes_start.bat
# Change: API_KEY, MPASS, PROVIDER, MODEL, WEBUI_NAME

# 3. Build Docker image
docker build -t hermes-agent:latest D:\hermes

# 4. Run
hermes_start.bat
```

That's it. After a few minutes you have:
- Hermes API at http://localhost:8642
- Hermes Dashboard at http://localhost:9119
- Open WebUI at http://localhost:3000
- Automated MySQL backup at `backups\hermes_dump.sql`

---

## Backup Strategy

The backup pipeline runs automatically on every start:

```
state.db (SQLite)  ----sync---->  MySQL 8.0  ----dump---->  backups\hermes_dump.sql
     |                                                              |
  live data                                                   recovery file
  (Hermes reads                                               (keep safe,
   from here)                                                  version it)
```

**On disaster:** restore the SQL dump into MySQL, run the reverse sync, and your Hermes is back with all sessions and memory intact. See [RECOVERY.md](RECOVERY.md).

---

## Security

- All data stays local -- no cloud, no third-party API calls for storage
- No telemetry, no tracking, no phone-home
- MySQL runs on an internal Docker network, not exposed to the host
- API key is set as environment variable, never hardcoded in scripts
- WSL2 provides hardware-level isolation between Windows and the container runtime

---

## FAQ

**Q: Do I need a GPU?**
A: No. Hermes connects to remote AI providers (OpenRouter, DeepSeek, etc.). You only need an internet connection for the API calls.

**Q: Can I run this on a laptop?**
A: Yes. Hermes itself uses minimal resources (~200 MB RAM). MySQL adds another ~200 MB. Any modern laptop handles it easily.

**Q: What if my provider goes down?**
A: Change the `PROVIDER` and `MODEL` variables and restart. Your MySQL backup is provider-independent.

**Q: Does this work with Linux natively?**
A: The deployment kit is designed for Windows + WSL2 + Docker Desktop. For native Linux, you'd adapt the Docker Compose approach.

**Q: How do I update Hermes?**
A: Rebuild the Docker image: `docker build --no-cache -t hermes-agent:latest .` then restart.

**Q: Can I run multiple instances?**
A: Yes. Clone the repo to a second directory, change port mappings in the batch file, and run independently.

---

## Documentation

| Language | File | Content |
|----------|------|---------|
| [EN] | [INSTALLATION.md](INSTALLATION.md) | Full installation guide from blank Windows |
| [EN] | [RECOVERY.md](RECOVERY.md) | Disaster recovery instructions |
| [DE] | [INSTALLATION.de.md](INSTALLATION.de.md) | Full installation guide in German |
| [DE] | [README.de.md](README.de.md) | This README in German |

---

## License

Apache 2.0 -- free to use, modify, and distribute.

---

Built with care by [einfach-online.dev](https://einfach-online.dev) -- Local First. Performance Driven. Privacy Centric.
