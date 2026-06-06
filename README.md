
  ___  ___  ___  ___  ___  _  _  ___
 | _ \| _ \/ _ \| _ \| __| \| |/ __|
 |  _/|  _/ (_) |  _/| _|| .` | (_ |
 |_|  |_|  \___/|_|  |___|_|\_|\___|

Hermes Agent – Komplett-Installation für Kunden

<p align="center">
  <b>Local First · Performance Driven · Privacy Centric</b>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-WSL%202-blue?logo=windows" alt="WSL 2">
  <img src="https://img.shields.io/badge/Runtime-Docker-2496ED?logo=docker" alt="Docker">
  <img src="https://img.shields.io/badge/Database-MySQL%208.0-4479A1?logo=mysql" alt="MySQL">
  <img src="https://img.shields.io/badge/WebUI-Open%20WebUI-FF6B6B" alt="Open WebUI">
  <img src="https://img.shields.io/badge/License-MIT-green" alt="MIT">
  <img src="https://img.shields.io/badge/State-stable-success" alt="Stable">
</p>

---

## Was ist das?

Dieses Repository enthält alles, um **Hermes Agent** auf einem
Windows-Kunden-System von Null an zu installieren – inklusive:

- Docker-Container-Orchestrierung
- MySQL-Datenbank-Sicherung
- Automatischem Sync zwischen Hermes und MySQL
- Notfall-Wiederherstellungsplan

**Kein Cloud-Zwang, kein Vendor-Lock-in, alles läuft lokal.**

---

## System-Architektur

```
┌──────────────────────────────────────────────────────────────┐
│                        Windows 10/11                         │
│                                                              │
│   ┌─────────────┐    ┌──────────────┐    ┌───────────────┐  │
│   │ Hermes API  │    │  Dashboard   │    │  Open WebUI   │  │
│   │ Port 8642   │    │  Port 9119   │    │  Port 3000    │  │
│   └──────┬──────┘    └──────┬───────┘    └───────┬───────┘  │
│          │                  │                     │          │
│          └──────────────────┼─────────────────────┘          │
│                             │                                │
│                    ┌────────▼────────┐                       │
│                    │  Docker Network │                       │
│                    │   hermes-net    │                       │
│                    └────────┬────────┘                       │
│                             │                                │
│                    ┌────────▼────────┐                       │
│                    │     MySQL       │                       │
│                    │  hermes-agent-  │                       │
│                    │     mysql       │                       │
│                    │    Port 3306    │                       │
│                    └────────┬────────┘                       │
│                             │                                │
│                    ┌────────▼────────┐                       │
│                    │   hermes_dump   │                       │
│                    │ D:\hermes-db-   │                       │
│                    │ backup\         │                       │
│                    └─────────────────┘                       │
└──────────────────────────────────────────────────────────────┘
```

---

## Backup-Strategie (das Herzstück)

So läuft die Sicherung deines Hermes-Gehirns:

```
                        Normalbetrieb
state.db ───Sync──▶ MySQL ──Dump──▶ D:\hermes-db-backup\hermes_dump.sql

                      Wiederherstellung
D:\hermes-db-backup\hermes_dump.sql ──Restore──▶ MySQL ──Reverse-Sync──▶ state.db
```

**Ein Dump pro Start – der alte wird überschrieben.**
Das reicht, weil der Dump beim nächsten Start automatisch neu erzeugt wird.

---

## Schnellstart (für Fortgeschrittene)

```powershell
:: 1. WSL installieren
wsl --install -d Ubuntu

:: 2. Docker Desktop installieren (von https://docker.com)
::    → WSL Integration für Ubuntu aktivieren!

:: 3. Repo klonen
cd D:\
git clone https://github.com/delkim2003/hermes-install.git hermes

:: 4. Hermes-Image bauen
wsl docker build -t hermes-agent:latest /mnt/d/hermes

:: 5. Anpassen (API-Key, Passwörter, Modell)
notepad D:\hermes\hermes_start.bat

:: 6. Starten
D:\hermes\hermes_start.bat
```

---

## Dateien im Überblick

| Datei | Beschreibung |
|-------|-------------|
| `INSTALLATION.md` | Schritt-für-Schritt-Installation von Windows Blank bis Hermes bereit |
| `WIEDERHERSTELLUNG.md` | Notfall-Wiederherstellung nach Totalausfall |
| `hermes_start.bat` | Start-Batch – Docker-Container orchestrieren und DB syncen |
| `mysql_sync.py` | Synchronisation zwischen Hermes (SQLite) und MySQL |

---

## Was läuft wo?

| Dienst | Port | Beschreibung |
|--------|------|-------------|
| **Hermes API** | 8642 | KI-API-Endpunkt (OpenAI-kompatibel) |
| **Hermes Dashboard** | 9119 | Web-Dashboard für Hermes |
| **Open WebUI** | 3000 | Chat-Oberfläche |
| **MySQL** | 3306 (intern) | Docker-Container, kein Host-Port |

---

## Sicherheit

| Bereich | Status |
|---------|--------|
| Datenhaltung | **Komplett lokal** – kein Cloud-Sync |
| Verschlüsselung | Cryptomator Vault (optional) |
| Netzwerk | Docker-intern – nur localhost exponiert |
| Passwörter | In der Batch-Datei konfigurierbar |
| API-Zugriff | Per API-Key geschützt |

---

## Voraussetzungen

| Komponente | Min. Version |
|------------|-------------|
| Windows | 10 Pro 22H2 |
| WSL | 2 |
| Docker Desktop | 4.x |
| RAM | 16 GB |
| Festplatte | 50 GB frei |

---

## Wartung

- **Matrix-Update:** Hermes-Image alle paar Monate neu bauen
- **Dump-Sicherung:** Regelmäßig `D:\hermes-db-backup\` extern sichern
- **Docker-Update:** Docker Desktop-Updates installieren
- **Logs prüfen:** `docker logs hermes-agent` bei Problemen

---

## Lizenz

MIT – machen damit was du willst.

---

<p align="center">
  <sub>Built with ❤️ for einfach-online.dev</sub>
</p>
