# Hermes Agent – Komplette Installation auf einem Kunden-System

Dieses Dokument beschreibt die **vollständige Erstinstallation** von Hermes Agent
auf einem Windows-System. Folge der Reihenfolge – jeder Schritt baut auf dem
vorherigen auf.

---

## Voraussetzungen

| Anforderung | Mindestens | Empfohlen |
|-------------|-----------|-----------|
| Betriebssystem | Windows 10 Pro 22H2 | Windows 11 Pro |
| Arbeitsspeicher | 16 GB RAM | 32 GB RAM |
| Prozessor | 4 Kerne | 8+ Kerne |
| Festplatte | 50 GB frei | 100+ GB SSD |
| Internet | Ja (für Downloads) | 50+ Mbit/s |
| CPU-Virtualisierung | Aktiviert (BIOS) | – |

**Vorinstallierte Software (wird später eingerichtet):** Keine.

---

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
│                    ┌────────▼────────┐      ┌─────────────┐  │
│                    │     MySQL       │      │  Gemountete  │  │
│                    │  hermes-agent-  │      │  Laufwerke   │  │
│                    │     mysql       │      │  /mnt/data   │  │
│                    │    Port 3306    │      └─────────────┘  │
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

## Phase 1 – Grundsystem einrichten

### Schritt 1: WSL aktivieren

**Dauer: ~5 Minuten**

Öffne **PowerShell als Administrator** und führe aus:

```powershell
wsl --install -d Ubuntu
```

Nach dem Befehl:
- System startet ggf. neu
- Nach dem Neustart öffnet sich automatisch ein Ubuntu-Terminal
- **Benutzername und Passwort für Ubuntu festlegen** (merken!)
- Dies ist dein WSL-Linux-Benutzer, nicht dein Windows-Benutzer

**Prüfen ob erfolgreich:**

```powershell
wsl -l -v
```

Ausgabe sollte zeigen:
```
  NAME      STATE           VERSION
* Ubuntu    Running         2
```

**Fehlerbehebung:** Falls `wsl` nicht gefunden wird, muss das Windows-Subsystem aktiviert werden:

```powershell
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
```

Danach **Windows NEU STARTEN**, dann `wsl --install -d Ubuntu` wiederholen.

---

### Schritt 2: Docker Desktop installieren

**Dauer: ~10 Minuten**

1. Lade Docker Desktop herunter: https://www.docker.com/products/docker-desktop/
2. **Installiere Docker Desktop** (Standardeinstellungen übernehmen)
3. Nach der Installation:
   - Hake **"Use WSL 2 instead of Hyper-V"** an
   - Docker Desktop startet automatisch
   - Warte bis unten links "Engine running" steht

**Prüfen ob erfolgreich:**

```powershell
docker --version
docker compose version
```

Beide sollten eine Versionsnummer ausgeben, kein Fehler.

**Wichtig:** Docker Desktop muss nach jedem Windows-Neustart einmal manuell gestartet werden (oder als Autostart eingerichtet).

---

### Schritt 3: Docker in WSL integrieren

**Dauer: ~2 Minuten**

Öffne Docker Desktop → Einstellungen (Zahnrad) → **Resources → WSL Integration**

- Schalte den Schalter für **Ubuntu** ein
- Klicke **Apply & Restart**

**Prüfen ob erfolgreich:**

```powershell
wsl docker ps
```

Muss eine leere Liste anzeigen (kein Fehler).

---

### Schritt 4: GitHub Repository klonen

**Dauer: ~2 Minuten**

```powershell
cd D:\
git clone https://github.com/delkim2003/hermes-install.git hermes
cd D:\hermes
```

**Ergebnis:** Ordner `D:\hermes\` mit allen Installationsdateien:

| Datei | Beschreibung |
|-------|-------------|
| `INSTALLATION.md` | Diese Anleitung |
| `WIEDERHERSTELLUNG.md` | Notfall-Wiederherstellung |
| `hermes_start.bat` | Start-Batch für den täglichen Betrieb |
| `mysql_sync.py` | Synchronisation state.db ↔ MySQL |
| `.gitignore` | Schützt sensible Dateien |

---

### Schritt 5: Hermes Docker-Image bauen

**Dauer: ~10-20 Minuten (abhängig von Internetgeschwindigkeit)**

```powershell
:: Vom geklonten Repo aus (wenn Dockerfile vorhanden)
docker build -t hermes-agent:latest D:\hermes

:: Oder falls das Repo kein Dockerfile enthält:
git clone https://github.com/nousresearch/hermes-agent.git C:\temp\hermes-agent
docker build -t hermes-agent:latest C:\temp\hermes-agent
```

---

## Phase 2 – Konfiguration anpassen

### Schritt 6: Konfigurationsdateien vorbereiten

**Dauer: ~5 Minuten**

Öffne `D:\hermes\hermes_start.bat` im Editor und passe diese Variablen an:

```batch
set "API_KEY=mein-sicherer-api-key"      :: Beliebiges Passwort
set "MPASS=mein-mysql-root-passwort"     :: MySQL Passwort (frei wählbar)
set "PROVIDER=openrouter"                :: KI-Anbieter
set "MODEL=anthropic/claude-sonnet-4"    :: KI-Modell
set "WEBUI_NAME=Meine Firma - Hermes"   :: Open WebUI Titel
```

**Erklärung der Variablen:**

| Variable | Pflicht | Beschreibung |
|----------|---------|-------------|
| `API_KEY` | ✅ | Beliebiges Passwort für den Hermes-API-Zugriff. Open WebUI braucht es zur Verbindung. |
| `MPASS` | ✅ | MySQL Root-Passwort. Wird für den Datenbank-Container und den Dump gebraucht. |
| `PROVIDER` | ✅ | Dein KI-Anbieter: `openrouter`, `anthropic`, `openai`, `deepseek` oder `custom`. |
| `MODEL` | ✅ | Das KI-Modell, z.B. `anthropic/claude-sonnet-4`, `gpt-4o` oder `deepseek-v4-flash`. |
| `WEBUI_NAME` | ❌ | Anzeigename in Open WebUI (oben links in der Leiste). |
| `DUMP_DIR` | ❌ | Pfad für MySQL-Dump-Backup. Standard: `D:\hermes-db-backup`. |

**Mehrere Konfigurationen:** Lege einfach mehrere Batch-Dateien an:
- `hermes_kunde1_start.bat`
- `hermes_kunde2_start.bat`

Jede mit eigenem API-Key, Passwort und Modell.

**Wichtig:** Dein API-Key für den KI-Anbieter (z.B. OpenRouter) muss separat in einer
Umgebungsvariable gesetzt oder in der `config.yaml` hinterlegt werden. Siehe Schritt 8.

---

### Schritt 7: Laufwerke konfigurieren (optional)

**Dauer: ~2 Minuten**

Beim ersten Start der Batch fragt sie, ob du zusätzliche Ordner in die Container mounten willst:

```
Moechtest du Ordner in den Container mounten? (j/n): j
Pfad eingeben (z.B. D:\Projekte): D:\Kundenprojekte
```

Der gemountete Ordner ist dann im Hermes-Container unter `/mnt/data/` verfügbar.
Hermes kann dort Dateien lesen und schreiben.

**Tipp:** Wenn der Kunde Projekte oder Vorlagen auf einem separaten Laufwerk hat,
hier den Pfad angeben. Muss nicht sein – Hermes läuft auch ohne.

---

### Schritt 8: Hermes-Setup und Provider einrichten

**Dauer: ~10 Minuten**

**A) Provider-API-Key setzen**

Hermes braucht einen gültigen API-Key für deinen KI-Anbieter. Setze ihn als
Windows-Umgebungsvariable:

```powershell
:: Für OpenRouter
setx HERMES_PROVIDER_OVERRIDE "openrouter"
setx HERMES_MODEL_OVERRIDE "anthropic/claude-sonnet-4"

:: API-Key für den Anbieter setzen
setx OPENROUTER_API_KEY "sk-or-v1-dein-echter-key"

:: Alternativ: Direkt den Hermes-API-Key setzen
setx HERMES_API_KEY "dein-sicherer-api-key"

:: PowerShell neu starten oder CMD neu öffnen nach setx
```

**B) Oder per Config-Datei (Batch macht das automatisch)**

Die Batch erstellt beim Start automatisch die Datei `%USERPROFILE%\.hermes\config.yaml`:

```yaml
provider: openrouter
model: anthropic/claude-sonnet-4
api_key: dein-sicherer-api-key
tools:
  - terminal
  - web_search
  - file
  - browser
  - vision
```

Du kannst die Datei nach dem ersten Start manuell erweitern, z.B. mit:

```yaml
# Custom Provider hinzufügen
custom_providers:
  - name: mein-ollama
    base_url: http://localhost:11434/v1
    api_key: dummy
```

**C) Skills aktivieren**

Nach dem ersten Start in einer Hermes-Session:

```
Lade das hermes-agent Skill mit skill_view(name='hermes-agent')
```

Oder direkt per Terminal (im Hermes-Container):

```bash
hermes skill enable test-driven-development
hermes skill enable systematic-debugging
hermes skill enable plan
hermes skill enable workspace-reconnaissance
hermes skill enable project-discovery
```

---

## Phase 3 – Erster Start

### Schritt 9: System starten

**Dauer: ~5 Minuten (beim ersten Mal länger wegen MySQL-Image-Pull)**

1. Docker Desktop starten (falls nicht schon)
2. `D:\hermes\hermes_start.bat` ausführen (Doppelklick oder als Administrator)
3. Die Batch startet automatisch alle Container in dieser Reihenfolge:

```
[1/8] Docker-Netzwerk      → hermes-net anlegen
[2/8] Laufwerke konfig.    → Optional: Ordner mounten
[3/8] Config erstellen     → %USERPROFILE%\.hermes\config.yaml
[4/8] Dashboard starten    → Port 9119
[5/8] API Server starten   → Port 8642
[6/8] Open WebUI starten   → Port 3000
[7/8] MySQL + Sync + Dump  → DB, Sync, Backup
[8/8] Zusammenfassung
```

**Beim ersten Start** muss MySQL das Image herunterladen (~450 MB).
Das dauert ~2 Minuten. Die Batch wartet automatisch bis MySQL bereit ist.

---

### Schritt 10: Alles testen

**Dauer: ~5 Minuten**

Nach erfolgreichem Batch-Durchlauf:

| Dienst | URL | Erwartet |
|--------|-----|----------|
| **Hermes API** | http://localhost:8642/v1/models | JSON mit Modell-Liste |
| **Open WebUI** | http://localhost:3000 | Anmeldemaske |
| **Dashboard** | http://localhost:9119 | Hermes Dashboard |

**API-Test:**
```powershell
curl http://localhost:8642/v1/models
```

Sollte eine Liste mit Modellen zurückgeben.

**Open WebUI Anmeldung:**
- Beim ersten Besuch: Registrierung (Benutzername + Passwort frei wählbar)
- Bei bestehendem Konto: Einloggen
- Oben links sollte der konfigurierte `WEBUI_NAME` stehen

**Dashboard Check:**
- Öffne http://localhost:9119
- Sollte den Hermes-Dashboard mit Status "running" oder "healthy" zeigen

**Erste Chat-Nachricht:**
1. Open WebUI öffnen
2. Neuen Chat starten
3. Text eingeben → Hermes sollte antworten

---

### Schritt 11: MySQL Sync prüfen

**Dauer: ~2 Minuten**

```powershell
docker exec hermes-agent-mysql mysql -uroot -pDEIN_PASSWORT hermes -e "SELECT COUNT(*) as sessions FROM sessions"
```

Erwartet: Anzahl der Sessions (0 bei Erstinstallation, mehr nach Nutzung).

```powershell
docker exec hermes-agent-mysql mysql -uroot -pDEIN_PASSWORT hermes -e "SELECT COUNT(*) as messages FROM messages"
```

Erwartet: 0 bei Erstinstallation, sonst Anzahl.

```powershell
dir D:\hermes-db-backup\
```

Sollte eine `hermes_dump.sql` enthalten.

---

## Phase 4 – Produktivbetrieb

### Täglicher Start

1. Docker Desktop starten (oder als Autostart einrichten)
2. `D:\hermes\hermes_start.bat` ausführen
3. Nach ~2 Minuten ist alles bereit

**Tipp:** Erstelle eine Desktop-Verknüpfung zu `D:\hermes\hermes_start.bat`.

---

### Backup-Strategie

| Was | Wann | Wohin |
|-----|------|-------|
| MySQL-Dump | **Jeder Start** automatisch | `%DUMP_DIR%\hermes_dump.sql` (Standard: `D:\hermes-db-backup\`) |
| Hermes-Config | Manuell bei Änderung | `%USERPROFILE%\.hermes\` |
| Docker-Volumes | Manuell (alle paar Monate) | `docker volume backup` |

**Wichtigster Backup-Punkt:** Der MySQL-Dump auf `%DUMP_DIR%` (standardmässig
`D:\hermes-db-backup\`) enthält dein komplettes Hermes-Gehirn (Sessions, Messages, Memory).

---

### Sicherheitshinweise

- **API-Key** und **MySQL-Passwort** sollten nicht in öffentlichen Repos landen
- Der `hermes-db-backup`-Ordner enthält sensible Chat-Verläufe
- Exportiere die Batch nur ohne die Passwort-Zeilen, wenn du sie teilst
- Dein Hermes läuft **komplett lokal** – keine Daten verlassen dein Netzwerk
- Nur die KI-Anfragen gehen an deinen API-Provider (OpenRouter, Anthropic, etc.)

---

## Fehlerbehebung

### "Docker" wird nicht erkannt
→ Docker Desktop installieren und starten

### "WSL" wird nicht erkannt
→ `wsl --install -d Ubuntu` in PowerShell als Admin

### MySQL Container startet nicht
```powershell
docker logs hermes-agent-mysql
```

### MySQL Sync schlägt fehl
```powershell
docker exec -e MYSQL_HOST=hermes-agent-mysql -e MYSQL_PASS=DEIN_PASSWORT hermes-agent python3 /opt/data/home/scripts/mysql_sync.py
```

### API Server gibt keine Models zurück
→ Prüfe ob `%USERPROFILE%\.hermes\config.yaml` existiert und `provider`/`model` gesetzt sind

### Open WebUI zeigt "No model selected"
→ Oben links in Open WebUI: Modell auswählen (es sollte dein konfiguriertes Modell da sein)
→ Falls nicht: API Server neustarten: `docker restart hermes-agent`

---

## Nächste Schritte nach der Installation

- [ ] Open WebUI mit Kunden-Branding einrichten (Logo, Name über `WEBUI_NAME`)
- [ ] API-Provider-Key in Umgebungsvariable setzen (z.B. `OPENROUTER_API_KEY`)
- [ ] Erste Test-Konversation führen – Hermes sollte antworten
- [ ] Skills für die Branche des Kunden aktivieren
- [ ] Desktop-Verknüpfung für die Batch erstellen
- [ ] Wiederherstellungs-Anleitung ausdrucken und ins Handbuch legen
- [ ] `D:\hermes-db-backup\` extern sichern (USB-Stick, NAS, Cloud)
