# Hermes Agent – Vollständige Installationsanleitung

> **🇩🇪 Deutsche Version — [English version](INSTALLATION.md)**

<p align="center">
  <img src="https://einfach-online.dev/logo.png" alt="Einfach Online Logo" width="150"/>
  <br/>
  <strong>Entwickelt von <a href="https://einfach-online.dev">einfach-online.dev</a></strong>
</p>

Diese Anleitung führt dich durch die Einrichtung von **Hermes Agent** auf einem blanken Windows-System.
Befolge die Schritte in der angegebenen Reihenfolge – jeder baut auf dem vorherigen auf.

**Geschätzte Gesamtzeit:** 30–45 Minuten (hauptsächlich Wartezeit für Downloads).

> **Pfad-Konventionen:** Alle Pfade in dieser Anleitung sind relativ zu deinem Repository-Ordner.
> Wenn du nach `C:\hermes` geklont hast, dann ist `<REPO_DIR>` = `C:\hermes`.
> Wenn du nach `D:\hermes` geklont hast, dann ist `<REPO_DIR>` = `D:\hermes`.
> Die Batch-Datei erkennt ihren eigenen Speicherort automatisch – kein manuelles Pfad-Editieren nötig.

---

## 📋 Inhaltsverzeichnis

- [Phase 1: Voraussetzungen](#phase-1-voraussetzungen)
- [Phase 2: Repository & Image](#phase-2-repository--image)
- [Phase 3: Konfiguration](#phase-3-konfiguration)
- [Phase 4: Erster Start](#phase-4-erster-start)
- [Phase 5: Überprüfung](#phase-5-ueberpruefung)
- [Phase 6: Täglicher Betrieb](#phase-6-taeglicher-betrieb)
- [Phase 7: Fehlerbehebung](#phase-7-fehlerbehebung)
---



## Phase 1: Voraussetzungen

### Schritt 1: WSL 2 aktivieren

**Dauer: ~5 Minuten**

Öffne **PowerShell als Administrator** und führe aus:

```powershell
wsl --install -d Ubuntu
```

Was passiert:
- Windows startet möglicherweise einmal neu
- Nach dem Neustart öffnet sich automatisch ein Ubuntu-Terminal
- **Du musst einen Linux-Benutzernamen und ein Passwort erstellen** – notiere dir beides!
- Das ist dein WSL-Benutzer, nicht dein Windows-Benutzer

**Überprüfen:**

```powershell
wsl -l -v
```

Erwartete Ausgabe:
```
  NAME      STATE           VERSION
* Ubuntu    Running         2
```

**Wenn `wsl` nicht gefunden wird**, aktiviere zuerst das Windows-Feature:

```powershell
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
```

Dann **Windows neu starten** und `wsl --install -d Ubuntu` erneut ausführen.

---

### Schritt 2: Docker Desktop installieren

**Dauer: ~10 Minuten**

1. Docker Desktop herunterladen: https://www.docker.com/products/docker-desktop/
2. Installer ausführen (Standardeinstellungen sind in Ordnung)
3. Während der Installation **"WSL 2 statt Hyper-V verwenden"** auswählen
4. Nach der Installation startet Docker Desktop automatisch
5. Warten bis die grüne "Engine läuft"-Anzeige unten links erscheint

**Überprüfen:**

```powershell
docker --version
docker compose version
```

Beide sollten Versionsnummern und keine Fehler anzeigen.

**Wichtig:** Docker Desktop muss nach jedem Windows-Neustart manuell gestartet werden. Du kannst den automatischen Start aktivieren unter Docker Desktop → Einstellungen → Allgemein → "Docker Desktop beim Anmelden starten".

---

### Schritt 3: WSL-Integration in Docker aktivieren

**Dauer: ~2 Minuten**

1. Docker Desktop öffnen
2. Zu **Einstellungen** (Zahnrad) → **Ressourcen** → **WSL-Integration**
3. Schalter **EIN** für **Ubuntu**
4. **Übernehmen & Neustarten** klicken

**Überprüfen:**

```powershell
wsl docker ps
```

Sollte eine leere Container-Liste anzeigen (kein Fehler).

---

## Phase 2: Repository & Image

### Schritt 4: Repository klonen

**Dauer: ~2 Minuten**

Wähle ein Verzeichnis auf deinem Computer (C:, D:, USB-Stick – alles funktioniert):

```powershell
cd C:\
git clone https://github.com/delkim2003/hermes-install.git hermes
cd C:\hermes
```

Ersetze `C:\hermes` durch dein gewünschtes Verzeichnis.

**Ergebnis:** Ordner `<REPO_DIR>\` mit allen Installationsdateien:

| Datei | Beschreibung |
|-------|-------------|
| `hermes_start.bat` | 1-Klick-Starter für den täglichen Gebrauch |
| `INSTALLATION.md` | Diese Anleitung (Englisch) |
| `INSTALLATION.de.md` | Diese Anleitung (Deutsch) |
| `RECOVERY.md` | Notfall-Wiederherstellung |
| `Dockerfile` | Bau-Datei für den Hermes-Container |
| `mysql_sync.py` | Datenbank-Synchronisationsskript |
| `README.md` | Projektübersicht (Englisch) |
| `README.de.md` | Projektübersicht (Deutsch) |
| `.gitignore` | Schützt sensible Dateien vor Git |

---

### Schritt 5: Hermes Docker-Image bauen

**Dauer: 10–20 Minuten (abhängig von der Internetgeschwindigkeit)**

```powershell
cd <REPO_DIR>
docker build -t hermes-agent:latest .
```

Docker lädt das Python-Basis-Image (~120 MB) herunter und installiert Hermes Agent von PyPI.
Das machst du nur einmal. Danach ist das Image lokal zwischengespeichert.

**Überprüfen:**

```powershell
docker images hermes-agent
```

Erwartete Ausgabe (Versionen können abweichen):
```
REPOSITORY      TAG       IMAGE ID       CREATED          SIZE
hermes-agent    latest    a1b2c3d4e5f6   2 Minuten ago    350 MB
```

**Tipp:** Wenn eine neue Version von Hermes Agent erscheint, einfach `docker build --no-cache -t hermes-agent:latest .` erneut ausführen, um zu aktualisieren.

---

## Phase 3: Konfiguration

### Schritt 6: Batch-Datei editieren

**Dauer: ~5 Minuten**

Öffne `<REPO_DIR>\hermes_start.bat` mit Notepad und editiere diese 4 Variablen:

```batch
set "API_KEY=change-me-to-a-secure-password"    -> Dein eigenes Passwort (beliebiger Text)
set "MPASS=change-me-mysql-password"            -> MySQL Root-Passwort (beliebiger Text)
set "PROVIDER=openrouter"                       -> Dein KI-Anbieter
set "MODEL=anthropic/claude-sonnet-4"           -> Dein KI-Modell
```

**Variablen-Referenz:**

| Variable | Pflicht | Beschreibung |
|----------|---------|-------------|
| `API_KEY` | ✅ Ja | Beliebiges Passwort. Wird fur API-Authentifizierung des Hermes API Servers verwendet. |
| `MPASS` | ✅ Ja | MySQL Root-Passwort. Wird fur den Datenbank-Container und Backups verwendet. |
| `PROVIDER` | ✅ Ja | KI-Anbieter. Siehe [Provider-Wahl unten](#provider-wahl-und-datenschutz). |
| `MODEL` | ✅ Ja | Modellname: `deepseek-v4-flash`, `anthropic/claude-sonnet-4`, `gpt-4o`, `local-model`, etc. |
| `DUMP_DIR` | ❌ Nein | Pfad fur MySQL-Backup. Standard: `<REPO_DIR>\\backups\\` |

---



---

## Provider-Wahl und Datenschutz

Deine Wahl des KI-Providers bestimmt **Kosten, Datenschutz und DSGVO-Konformitat**. Hermes funktioniert mit jeder OpenAI-kompatiblen API. Hier die 4 Optionen:

### Option A: EU-Provider (DSGVO-konform) — Empfohlen fur Unternehmen

**cortecs.ai** (Wien, Osterreich) hostet DeepSeek, Claude, GPT und mehr in EU-Rechenzentren. Stellt einen Auftragsverarbeitungsvertrag (AVV) auf Anfrage zur Verfugung.

```batch
set "PROVIDER=openrouter"
set "MODEL=deepseek/deepseek-v4-flash"
set "CUSTOM_API_BASE=https://api.cortecs.ai/v1"
```

- Daten bleiben in der EU   ✅
- AVV verfugbar   ✅
- Kosten: ~$0.20 / $0.80 pro 1M Tokens

### Option B: Lokales Modell (100 % privat)

Betreibe ein lokales LLM via llama.cpp oder ollama. Keine Daten verlassen jemals deinen Rechner.

```batch
set "PROVIDER=custom"
set "MODEL=local-model-name"
set "CUSTOM_API_BASE=http://localhost:1234/v1"
```

- Keine Daten verlassen deinen Rechner   ✅    ✅
- Kein Internet erforderlich   ✅
- Kosten: $0 (nur Strom)

### Option C: Direkt DeepSeek (Budget-Wahl) — Die Gunstigste

Direktverbindung zur DeepSeek-API. Extrem erschwinglich.

```batch
set "PROVIDER=deepseek"
set "MODEL=deepseek-v4-flash"
```

- Kosten: **$0.10 / $0.20** pro 1M Tokens — **97 % gunstiger als GPT-5.5**
- Monatskosten bei 100M Tokens: **~$1.28**
- Datenverarbeitung in China — deine Entscheidung
- DSGVO: Nicht konform ohne zusatzliche Massnahmen

### Option D: OpenRouter (Flexibel)

Leite uber OpenRouter, um 400+ Modelle zu nutzen. Backend kann EU-gehostet sein.

```batch
set "PROVIDER=openrouter"
set "MODEL=deepseek/deepseek-v4-flash"
```

- Etwas hohere Kosten (~$0.20 / $0.80)
- EU-Backends wahlbar (DeepInfra, NovitaAI)
- OpenRouter hat Sitz in den USA — DSGVO-Grauzone

> **Vollstandige Analyse mit rechtlichen Referenzen:** [PRIVACY.de.md](PRIVACY.de.md)

---

**Beim ersten Start musst du auch den API-Key deines Anbieters setzen:**

Dein KI-Anbieter (OpenRouter, Anthropic, etc.) benötigt einen API-Key für die Abrechnung. Setze ihn als Windows-Umgebungsvariable:

```powershell
:: Für OpenRouter
setx OPENROUTER_API_KEY "sk-or-...dein-key-hier"

:: Für Anthropic
setx ANTHROPIC_API_KEY "sk-ant-...dein-key-hier"

:: Für OpenAI
setx OPENAI_API_KEY "sk-...dein-key-hier"
```

Nachdem du `setx` ausgeführt hast, schliesse PowerShell und öffne es neu, oder starte den Computer neu, damit die Variable wirksam wird.

---

## Phase 4: Erster Start

### Schritt 7: Batch-Datei ausführen

**Dauer: ~5 Minuten (erster Start: +2 Minuten für MySQL-Image-Download)**

1. **Docker Desktop starten** (falls nicht bereits ausgeführt)
2. **Doppelklick** auf `<REPO_DIR>\hermes_start.bat`
3. Die Batch fragt nach zusätzlichen Laufwerks-Mounts (Enter drücken zum Überspringen)
4. Beobachte den Fortschritt – die Batch durchläuft 8 Schritte:

```
[1/8] Docker Netzwerk       → Erstellt hermes-net
[2/8] Optionale Mounts      → Deine Ordner in den Containern
[3/8] Config erstellen      → Schreibt %USERPROFILE%\.hermes\config.yaml
[4/8] Dashboard             → Startet Hermes Dashboard auf Port 9119
[5/8] API Server            → Startet Hermes API auf Port 8642
[7/8] MySQL + Sync + Dump   → Startet MySQL, synchronisiert DB, erstellt Dump
[8/8] Zusammenfassung       → Zeigt alle laufenden Dienste
```

**Hinweise zum ersten Start:**
- Der MySQL-Container (~450 MB) wird beim ersten Start heruntergeladen – das dauert ~2 Minuten
- Die Batch wartet automatisch, bis MySQL bereit ist, bevor es weitergeht
- Falls ein Dienst nicht startet, macht die Batch mit den restlichen Diensten weiter

---

## Phase 5: Überprüfung

### Schritt 8: Alles testen

**Dauer: ~5 Minuten**

Nach erfolgreichem Batch-Durchlauf:

| Dienst | URL | Erwartetes Ergebnis |
|--------|-----|---------------------|
| **Hermes API** | http://localhost:8642/v1/models | JSON mit Modell-Liste |
| **Hermes Dashboard** | http://localhost:9119 | Hermes-Statusseite |

**API-Test:**
```powershell
curl http://localhost:8642/v1/models
```

Sollte ein JSON-Array mit deinem konfigurierten Modell zurückgeben.

**Dashboard-Prüfung:**
- Öffne http://localhost:9119
- Sollte das Hermes-Dashboard mit Servicestatus anzeigen

---

### Schritt 9: MySQL-Backup überprüfen

**Dauer: ~2 Minuten**

Prüfe, ob die Datenbank-Synchronisation funktioniert hat:

```powershell
:: Sessions in MySQL zählen
docker exec hermes-agent-mysql mysql -uroot -pDEIN_MPASS hermes -e "SELECT COUNT(*) AS sessions FROM sessions"

:: Messages in MySQL zählen
docker exec hermes-agent-mysql mysql -uroot -pDEIN_MPASS hermes -e "SELECT COUNT(*) AS messages FROM messages"

:: Prüfen ob die Dump-Datei existiert
dir %DUMP_DIR%
```

Erwartet:
- Sessions ≥ 0 (steigt mit der Nutzung)
- Messages ≥ 0 (steigt mit der Nutzung)
- `hermes_dump.sql` existiert und ist nicht leer

---

## Phase 6: Täglicher Betrieb

### Täglicher Start

```powershell
# 1. Docker Desktop starten (oder es startet automatisch)
# 2. Batch ausführen
<REPO_DIR>\hermes_start.bat
```

Nach ~2 Minuten laufen alle Dienste.

**Desktop-Verknüpfung (optional):**
1. Rechtsklick auf den Desktop → Neu → Verknüpfung
2. Ort: `<REPO_DIR>\hermes_start.bat`
3. Name: "Hermes Agent"
4. Optional: Rechtsklick auf Verknüpfung → Eigenschaften → Erweitert → "Als Administrator ausführen"

### Container verwalten

```powershell
# Laufende Dienste anzeigen
docker ps --filter network=hermes-net

# Logs eines bestimmten Dienstes anzeigen
docker logs hermes-agent

# Alle Dienste stoppen (ohne die Batch)
docker stop hermes-agent hermes-dashboard hermes-agent-mysql
```

### Backup-Strategie

| Was | Wann | Wo |
|-----|------|----|
| **MySQL Dump** | Jeder Start (automatisch) | `%DUMP_DIR%\hermes_dump.sql` |
| **Hermes Config** | Manuell bei Änderungen | `%USERPROFILE%\.hermes\` |
| **Docker Volumes** | Manuell (alle paar Monate) | `docker volume inspect hermes_mysql_data` |

**Externes Backup:** Kopiere `%DUMP_DIR%\hermes_dump.sql` regelmässig auf einen USB-Stick oder NAS.
Diese eine Datei enthält alle deine Sessions, Messages und Memory-Einträge.

---

## Phase 7: Fehlerbehebung

### "Docker" wird nicht erkannt

→ Docker Desktop ist nicht installiert oder nicht gestartet.
Öffne Docker Desktop und warte auf "Engine läuft."

### "WSL" wird nicht erkannt

→ Als Administrator ausführen:
```powershell
wsl --install -d Ubuntu
```

### MySQL startet nicht

```powershell
docker logs hermes-agent-mysql
```

Häufige Ursachen:
- Port 3306 ist bereits belegt (ein anderes MySQL läuft)
- Nicht genügend Speicherplatz für das Volume

### MySQL-Synchronisation schlägt fehl

Führe die Synchronisation manuell aus:
```powershell
docker exec -e MYSQL_HOST=hermes-agent-mysql -e MYSQL_PASS=DEIN_MPASS hermes-agent python3 /opt/data/home/scripts/mysql_sync.py
```

Prüfe die ausführliche Ausgabe auf Fehler.

### API gibt leere Modell-Liste zurück

- Prüfe ob `%USERPROFILE%\.hermes\config.yaml` existiert und `provider` und `model` gesetzt sind
- Prüfe ob der API-Key deines Anbieters als Windows-Umgebungsvariable gesetzt ist
- Starte den API-Server neu: `docker restart hermes-agent`

### "hermes: command not found" beim Docker-Build

Das passiert, wenn pip `hermes-agent` nicht installieren konnte. Versuche:
```powershell
docker build --no-cache -t hermes-agent:latest .
```

---

## Checkliste nach der Installation

- [ ] Du kannst eine Nachricht senden und erhältst eine Antwort
- [ ] MySQL-Dump existiert in `%DUMP_DIR%`
- [ ] Desktop-Verknüpfung erstellt
- [ ] Externes Backup des Dumps konfiguriert
- [ ] `RECOVERY.md` ausgedruckt und bei der Systemdokumentation abgeheftet

---

## Nächste Schritte

- Aktiviere Hermes-Skills für deinen Anwendungsfall (Websuche, Dateioperationen, etc.)
- Richte automatische externe Backups von `%DUMP_DIR%` ein
- Drucke `RECOVERY.md` aus und verwahre es bei deiner Systemdokumentation

---

## Support & Kontakt

<p align="center">
  <strong>Entwickelt von <a href="https://einfach-online.dev">einfach-online.dev</a></strong><br/>
  info@einfach-online.dev<br/>
  <em>Local First. Performance Driven. Privacy Centric.</em>
</p>

Brauchst du Hilfe bei der Installation oder ein massgeschneidertes Deployment?
[Schreib mir eine E-Mail](mailto:info@einfach-online.dev) – ich antworte innerhalb von 24 Stunden.
