# 🤖 Hermes Agent Deployment Kit

<p align="center">
  <img src="https://einfach-online.dev/logo.png" alt="Einfach Online Logo" width="200"/>
  <br/>
  <strong>Entwickelt von <a href="https://einfach-online.dev">einfach-online.dev</a></strong>
  <br/>
  <em>Local First. Performance Driven. Privacy Centric.</em>
</p>

<p align="center">
  [![Docker](https://img.shields.io/badge/docker-bereit-2496ED?logo=docker&logoColor=white)](https://www.docker.com)
  [![MySQL](https://img.shields.io/badge/mysql-8.0-4479A1?logo=mysql&logoColor=white)](https://www.mysql.com)
  [![WSL](https://img.shields.io/badge/wsl-2-0E7A0D?logo=linux&logoColor=white)](https://learn.microsoft.com/de-de/windows/wsl/)
  [![Hermes Agent](https://img.shields.io/badge/hermes-agent-8B5CF6?logo=python&logoColor=white)](https://hermes-agent.nousresearch.com)
  [![Lizenz](https://img.shields.io/badge/Lizenz-Apache%202.0-blue)](LICENSE)
  [![GitHub](https://img.shields.io/badge/GitHub-delkim2003/hermes--install-181717?logo=github&logoColor=white)](https://github.com/delkim2003/hermes-install)
</p>

---

## 🚀 Überblick

Das **Hermes Agent Deployment Kit** ist ein produktionsreifes, **null-Konfiguration Deployment-System** für [Hermes Agent](https://hermes-agent.nousresearch.com) von Nous Research — den autonomen KI-Agenten für Entwickler.

Alles läuft **lokal in Docker**. Keine Cloud-Abhängigkeit. Keine Daten verlassen deinen Rechner.

> **Entwickelt von [Philipp Schlemmer](https://einfach-online.dev) bei einfach-online.dev — einer österreichischen Web-Agentur für DSGVO-konforme, local-first Infrastruktur.**

---

## 🏗 Architektur

```
┌─────────────────────────────────────────────────────────────────────┐
│                                                                     │
│   ┌──────────────┐    ┌──────────────┐    ┌──────────────────────┐  │
│   │   Hermes     │    │  Hermes      │    │    Open WebUI        │  │
│   │   API Server │    │  Dashboard   │    │    Chat-Oberfläche   │  │
│   │   :8642      │    │  :9119       │    │    :3000             │  │
│   └──────┬───────┘    └──────┬───────┘    └──────────┬───────────┘  │
│          │                  │                        │              │
│          └──────────────────┼────────────────────────┘              │
│                             │                                      │
│                    ┌────────▼────────┐                              │
│                    │  Docker Netzwerk │                              │
│                    │   hermes-net    │                              │
│                    └────────┬────────┘                              │
│                             │                                      │
│                    ┌────────▼────────┐     ┌────────────────────┐   │
│                    │   MySQL 8.0     │────▶│   MySQL Dump       │   │
│                    │   Backup/       │     │   hermes_dump.sql  │   │
│                    │   Wiederherst.  │     │   (auto-aktuell)   │   │
│                    └────────┬────────┘     └────────────────────┘   │
│                             │                                      │
│                    ┌────────▼──────────────────────┐                │
│                    │  state.db (SQLite ↔ MySQL)    │                │
│                    │  Synchronisiert bei jedem Start│               │
│                    └───────────────────────────────┘                │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## ✨ Funktionen

| Funktion | Beschreibung | Warum wichtig |
|----------|-------------|---------------|
| **🎯 Null Konfiguration** | 5 Variablen in einer Batch-Datei editieren, Doppelklick, fertig | Kein YAML-Gefummel |
| **💾 MySQL Auto-Backup** | Jeder Start: state.db → MySQL → `hermes_dump.sql` | Nie wieder Datenverlust |
| **🔄 Reverse Sync** | `state.db` aus MySQL-Dump wiederherstellen | Komplette Notfall-Wiederherstellung |
| **🌐 Open WebUI** | ChatGPT-ähnliches Interface unter `http://localhost:3000` | Vertraute Chat-Umgebung |
| **📊 Hermes Dashboard** | Agenten-Status unter `http://localhost:9119` | Echtzeit-Überblick |
| **🔒 Local First** | Keine Cloud, kein Telemetrie, kein Drittanbieter | Deine Daten = Dein Eigentum |
| **🔌 Jeder KI-Anbieter** | OpenRouter, Anthropic, OpenAI, DeepSeek oder Custom | Freie Wahl |
| **📁 Laufwerks-Mounts** | Projektordner in Container einbinden | Direkt am Code arbeiten |
| **🔐 Privacy by Design** | Keine Cookies, keine CDNs, keine Tracker | DSGVO-konforme Architektur |

---

## 📋 Systemvoraussetzungen

| Anforderung | Minimum | Empfohlen | Hinweise |
|-------------|---------|-----------|----------|
| **Betriebssystem** | Windows 10 Pro 22H2 | Windows 11 Pro | WSL 2 erforderlich |
| **RAM** | 16 GB | 32 GB | Mehr RAM = schnellere KI-Antworten |
| **CPU** | 4 Kerne, Virtualisierung an | 8+ Kerne | Intel VT-x oder AMD-V |
| **Festplatte** | 50 GB frei | 100+ GB SSD | Docker-Images ~2 GB |
| **Docker** | Desktop 4.x | Aktuelle Version | WSL 2 Backend |
| **WSL** | Ubuntu 22.04 | Ubuntu 24.04 | Standard-Distribution |

---

## ⚡ Schnellstart

```powershell
# 1. Voraussetzungen installieren (Docker Desktop + WSL 2)
#    Siehe INSTALLATION.de.md für Details

# 2. Repository klonen (jedes Laufwerk: C:, D:, USB — funktioniert überall)
git clone https://github.com/delkim2003/hermes-install.git C:\hermes

# 3. Nur 5 Variablen in der Batch-Datei editieren
notepad C:\hermes\hermes_start.bat
#   → Setzen: API_KEY, MPASS, PROVIDER, MODEL, WEBUI_NAME

# 4. Docker-Image bauen (einmalig, ~10 Minuten)
cd C:\hermes
docker build -t hermes-agent:latest .

# 5. Alles starten
C:\hermes\hermes_start.bat
```

**Browser öffnen → [http://localhost:3000](http://localhost:3000)** und loschatten. Das war's.

---

## 📦 Was im Repo ist

| Datei | Zweck | Muss editiert werden? |
|-------|-------|----------------------|
| `hermes_start.bat` | 1-Klick-Starter — startet alle 4 Container | ✅ Ja (5 Variablen) |
| `Dockerfile` | Baut das Hermes Agent Container-Image | ❌ Nein |
| `mysql_sync.py` | Synchronisiert state.db ↔ MySQL (bidirektional) | ❌ Nein |
| `INSTALLATION.de.md` | Schritt-für-Schritt Anleitung (30–45 Min) | — Einmal lesen |
| `RECOVERY.md` | Notfall-Wiederherstellung | — Ausdrucken |
| `.gitignore` | Schützt Secrets und Datenbanken vor Git | ❌ Nein |

---

## 💽 Backup-Strategie

```
  Bei jedem Systemstart (automatisch):

     state.db  ──sync──▶  MySQL  ──dump──▶  hermes_dump.sql
        (SQLite)        (Container)        (Auf deiner Festplatte)

  Notfall-Wiederherstellung (manuell):

     hermes_dump.sql  ──restore──▶  MySQL  ──reverse-sync──▶  state.db
```

| Was | Wann | Wo | Wie |
|-----|------|----|-----|
| **MySQL Dump** | Jeder Batch-Start (automatisch) | `%DUMP_DIR%\hermes_dump.sql` | Enthält ALLE Sessions, Messages, Memory |
| **Hermes Config** | Bei Änderungen | `%USERPROFILE%\.hermes\config.yaml` | Manuelles Backup |
| **Docker Volumes** | Alle paar Monate | `docker volume inspect hermes_mysql_data` | Manuelles Backup |

> 💡 **Kopiere `%DUMP_DIR%\hermes_dump.sql` regelmäßig auf einen USB-Stick.** Diese eine Datei enthält das gesamte Hermes-Gehirn — Unterhaltungen, Agenten-Sessions und Erinnerungen. Alles andere kann aus diesem Repository neu gebaut werden.

---

## 🔒 Sicherheitsphilosophie

| Prinzip | Umsetzung |
|----------|-----------|
| **Keine Cloud-Abhängigkeit** | Alles läuft in Docker auf deinem lokalen Rechner |
| **Keine Datenexfiltration** | KI-Anfragen gehen direkt zu deinem Anbieter (OpenRouter u.a.) |
| **Kein Telemetrie** | Null Tracking, Null Analytics, Null Cookies |
| **Kein Tunnel** | Kein Cloudflare, kein ngrok — kein Remote-Zugriff (absichtlich) |
| **Verschlüsselt** | MySQL Volume + optionaler Cryptomator-Vault-Support |
| **API-Authentifizierung** | Hermes ↔ Open WebUI mit eigenem API-Key gesichert |

Entwickelt für **DSGVO-konforme Deployments**, bei denen Datensouveränität nicht verhandelbar ist.

---

## 🛡 Sicherheits-Checkliste

- [ ] API-Key ist ein starkes, einzigartiges Passwort
- [ ] MySQL-Passwort unterscheidet sich vom API-Key
- [ ] Keine Secrets in Git committet (`.gitignore` erledigt das)
- [ ] Kein Cloudflare-Tunnel oder Remote-Zugriff aktiviert
- [ ] Anbieter-API-Key als Windows-Umgebungsvariable (nicht in der Batch-Datei)
- [ ] Externes Backup von `hermes_dump.sql` konfiguriert

---

## ❓ Häufig gestellte Fragen

**F: Kann ich das auf einem anderen Laufwerk ausführen?**  
A: Ja. Klone das Repo auf C:\, D:\, USB-Stick oder Netzwerklaufwerk. Die Batch-Datei erkennt ihren eigenen Speicherort automatisch.

**F: Brauche ich eine Internetverbindung?**  
A: Nur für den initialen Build (Docker-Images + PyPI-Pakete) und für KI-Anfragen. Nach dem Setup läuft Docker vollständig offline.

**F: Wie aktualisiere ich Hermes Agent?**  
A: Führe `docker build --no-cache -t hermes-agent:latest .` im Repo-Verzeichnis aus. Die Batch-Datei verwendet das aktuellste Image.

**F: Kann ich mehrere KI-Anbieter nutzen?**  
A: Ja. Ändere `PROVIDER` und `MODEL` in der Batch-Datei und setze den entsprechenden API-Key als Windows-Umgebungsvariable. Starte den API-Server mit `docker restart hermes-agent` neu.

**F: Wie komme ich nach einer Wiederherstellung an meine alten Chats?**  
A: Der Reverse Sync (Schritt 6 in RECOVERY.md) stellt alle Sessions und Messages in `state.db` wieder her. Open WebUI zeigt sie dann in der Seitenleiste an.

---

## 📚 Dokumentation

| Dokument | Sprache | Inhalt |
|----------|---------|--------|
| [INSTALLATION.de.md](INSTALLATION.de.md) | 🇩🇪 Deutsch | Vollständige Installationsanleitung |
| [INSTALLATION.md](INSTALLATION.md) | 🇬🇧 English | Step-by-step setup guide |
| [RECOVERY.md](RECOVERY.md) | 🇬🇧 English | Disaster recovery procedure |
| [README.md](README.md) | 🇬🇧 English | This page in English |

---

## 📞 Support

Entwickelt mit ❤️ von **Philipp Schlemmer**

| Kontakt | Details |
|---------|---------|
| **Agentur** | [einfach-online.dev](https://einfach-online.dev) |
| **E-Mail** | info@einfach-online.dev |
| **Telefon** | +43 664 2550 779 |
| **Standort** | Österreich (EU) |
| **Expertise** | DSGVO-konforme Web-Infrastruktur, KI-Deployment, Local First Architektur |

Brauchst du ein massgeschneidertes Deployment oder Enterprise-Support? [Schreib mir](mailto:info@einfach-online.dev).

---

## 📄 Lizenz

[Apache 2.0](https://github.com/nousresearch/hermes-agent/blob/main/LICENSE)

Basiert auf [Hermes Agent](https://github.com/nousresearch/hermes-agent) von Nous Research.  
Deployment-System, Dokumentation und Automatisierung von [einfach-online.dev](https://einfach-online.dev).

---

<p align="center">
  <sub>Local First. Performance Driven. Privacy Centric.</sub>
  <br/>
  <sub>© 2024–2025 einfach-online.dev | Philipp Schlemmer | Alle Rechte vorbehalten.</sub>
</p>
