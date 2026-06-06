# Hermes Agent Deployment Kit

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

## Was ist das?

**Hermes Agent Deployment Kit** ermoglicht dir, einen vollwertigen autonomen KI-Agenten auf deinem Windows-Rechner in unter 2 Minuten einzurichten. Eine einzige Batch-Datei startet alles: API-Server, Chat-Oberflache, MySQL-Datenbank und automatische Backups.

**[Hermes Agent](https://hermes-agent.nousresearch.com)** ist ein Open-Source-KI-Agent von Nous Research. Er kann im Web surfen, Terminal-Befehle ausfuhren, Dateien lesen und schreiben, deine Codebasis durchsuchen und Aufgaben an Unter-Agenten delegieren -- alles durch naturliche Unterhaltung.

Dieses Kit macht das Deployment denkbar einfach. Kein Docker Compose, keine manuelle Konfiguration, keine ubersprungenen Schritte.

---

## Wie es funktioniert

Du fuhrst **eine Datei** aus (`hermes_start.bat`). Sie erledigt den Rest:

| # | Was passiert |
|---|-------------|
| 1 | Erstellt ein Docker-Netzwerk (`hermes-net`) |
| 2 | Fragt ob zusatzliche Ordner gemountet werden sollen |
| 3 | Schreibt die Hermes-Konfiguration (`~/.hermes/config.yaml`) |
| 4 | Startet Hermes Dashboard (Port 9119) |
| 5 | Startet Hermes API Server (Port 8642) |
| 6 | Startet Open WebUI Chat-Oberflache (Port 3000) |
| 7 | Startet MySQL 8.0 + synchronisiert state.db + erstellt Dump |
| 8 | Zeigt alle laufenden Container und URLs |

Gesamtzeit: ~90 Sekunden. Keine manuellen Schritte.

---

## Architektur

```
  +------------------+    +------------------+    +--------------------+
  |   Hermes         |    |  Hermes          |    |    Open WebUI      |
  |   API Server     |    |  Dashboard       |    |    Chat-Oberflache |
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

## Funktionen

| Komponente | Beschreibung |
|------------|--------------|
| Hermes API Server | Kern-KI-Agent, OpenAI-kompatible API auf Port 8642 |
| Hermes Dashboard | Webbasiertes Dashboard zur Uberwachung auf Port 9119 |
| Open WebUI | Vollstandige Chat-Oberflache auf Port 3000 |
| MySQL 8.0 | Permanente Speicherung von Sessions und Memory |
| Automatischer Dump | `mysqldump` erstellt bei jedem Start ein vollstandiges Backup |
| Sub-Agent Support | Hermes kann autonome Unter-Agenten fur parallele Arbeit starten |
| Recovery Ready | Reverse-Sync stellt alles aus einem einzigen SQL-Dump wieder her |

---

## Voraussetzungen

| Anforderung | Version | Hinweise |
|-------------|---------|----------|
| Windows 10/11 | Pro oder Home | WSL2-Unterstutzung erforderlich |
| Docker Desktop | 4.x+ | [Download](https://www.docker.com/products/docker-desktop/) |
| WSL2 | Aktiviert | [Anleitung](https://learn.microsoft.com/de-de/windows/wsl/install) |
| RAM | 4 GB+ | Hermes ~200 MB, MySQL ~200 MB |
| Festplatte | 2 GB | Docker-Images, MySQL-Volume |

---

## Schnellstart

```powershell
# 1. Klonen
git clone https://github.com/delkim2003/hermes-install.git D:\hermes

# 2. Konfiguration anpassen
notepad D:\hermes\hermes_start.bat
# Andern: API_KEY, MPASS, PROVIDER, MODEL, WEBUI_NAME

# 3. Docker-Image bauen
docker build -t hermes-agent:latest D:\hermes

# 4. Starten
hermes_start.bat
```

Nach wenigen Minuten laufen:
- Hermes API unter http://localhost:8642
- Hermes Dashboard unter http://localhost:9119
- Open WebUI unter http://localhost:3000
- Automatisches MySQL-Backup unter `backups\hermes_dump.sql`

---

## Backup-Strategie

Die Backup-Pipeline lauft automatisch bei jedem Start:

```
state.db (SQLite)  ----sync---->  MySQL 8.0  ----dump---->  backups\hermes_dump.sql
     |                                                              |
  Live-Daten                                                  Wiederherstellungs-Datei
  (Hermes liest                                                (sicher aufbewahren,
   hieraus)                                                     versionieren)
```

**Bei einem Totalausfall:** SQL-Dump in MySQL einspielen, Reverse-Sync ausfuhren, und dein Hermes steht mit allen Sessions und dem gesamten Memory wieder da. Siehe [RECOVERY.md](RECOVERY.md) (EN) oder [INSTALLATION.de.md](INSTALLATION.de.md) (DE).

---

## Sicherheit

- Alle Daten bleiben lokal -- keine Cloud, keine Drittanbieter-API fur Storage
- Kein Telemetrie, kein Tracking, kein Phone-Home
- MySQL lauft im internen Docker-Netzwerk, nicht zum Host exponiert
- API-Key wird als Umgebungsvariable gesetzt, niemals hartcodiert
- WSL2 bietet hardwarenahe Isolierung zwischen Windows und Container-Laufzeit

---

## FAQ

**F: Brauche ich eine GPU?**
A: Nein. Hermes verbindet sich zu externen KI-Anbietern (OpenRouter, DeepSeek, usw.). Du brauchst nur Internet fur die API-Aufrufe.

**F: Kann ich das auf einem Laptop laufen lassen?**
A: Ja. Hermes selbst braucht wenig Ressourcen (~200 MB RAM). MySQL kommt mit ~200 MB dazu. Jeder moderne Laptop schafft das.

**F: Was wenn mein Anbieter ausfallt?**
A: Andere `PROVIDER`- und `MODEL`-Variablen setzen und neustarten. Dein MySQL-Backup ist anbieterunabhangig.

**F: Funktioniert das auch nativ unter Linux?**
A: Das Deployment Kit ist fur Windows + WSL2 + Docker Desktop ausgelegt. Fur nativen Linux-Betrieb wurde man Docker Compose anpassen.

**F: Wie aktualisiere ich Hermes?**
A: Docker-Image neu bauen: `docker build --no-cache -t hermes-agent:latest .` dann neustarten.

**F: Kann ich mehrere Instanzen betreiben?**
A: Ja. Repo in ein zweites Verzeichnis klonen, Ports in der Batch-Datei anpassen, und unabhangig starten.

---

## Dokumentation

| Sprache | Datei | Inhalt |
|---------|-------|--------|
| [EN] | [INSTALLATION.md](INSTALLATION.md) | Vollstandige Installationsanleitung von blankem Windows |
| [EN] | [RECOVERY.md](RECOVERY.md) | Notfall-Wiederherstellungs-Anleitung |
| [DE] | [INSTALLATION.de.md](INSTALLATION.de.md) | Vollstandige Installationsanleitung auf Deutsch |
| [DE] | [README.de.md](README.de.md) | Deutsche Version dieser README |

---

## Lizenz

Apache 2.0 -- zur freien Nutzung, Modifikation und Weitergabe.

---

Entwickelt mit Sorgfalt von [einfach-online.dev](https://einfach-online.dev) -- Local First. Performance Driven. Privacy Centric.
