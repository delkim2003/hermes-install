# Hermes Agent – Notfall-Wiederherstellung

> **Stelle alles aus einem MySQL-Dump wieder her.**
> Verwende dies, wenn das System komplett weg ist – neuer PC, Festplatten-Defekt oder vollstandige Neuinstallation.

Diese Anleitung setzt voraus:
- Du hast eine MySQL-Dump-Datei (`hermes_dump.sql`) von einem vorherigen Backup
- Du hast dieses Repository geklont (oder kannst auf GitHub darauf zugreifen)
- Du startest von einem **blanken Windows-System**

**Wiederherstellungszeit:** ~30 Minuten (hauptsachlich Downloads).

> **Pfad-Konventionen:** In dieser Anleitung bezieht sich `<REPO_DIR>` auf den Ordner, in den du dieses Repository geklont hast.
> Zum Beispiel: `C:\\hermes`, `D:\\projekte\\hermes` oder irgendwo anders.

---

## Inhaltsverzeichnis

- [Bevor du beginnst](#bevor-du-beginnst)
- [Schritt 1: Voraussetzungen](#schritt-1-voraussetzungen)
- [Schritt 2: Dump finden](#schritt-2-dump-finden)
- [Schritt 3: Klonen & Bauen](#schritt-3-klonen--bauen)
- [Schritt 4: MySQL wiederherstellen](#schritt-4-mysql-wiederherstellen)
- [Schritt 5: Hermes starten](#schritt-5-hermes-starten)
- [Schritt 6: Reverse Sync](#schritt-6-reverse-sync)
- [Schritt 7: Uberprufen](#schritt-7-ueberpruefen)
- [Kurzreferenz](#kurzreferenz)
- [Fehlerbehebung](#fehlerbehebung)

---

## Bevor du beginnst

Du benotigst diese Dinge fur die Wiederherstellung:

- [ ] Docker Desktop installiert und laufend
- [ ] WSL 2 aktiviert mit Ubuntu
- [ ] Dieses Repository geklont (`git clone https://github.com/delkim2003/hermes-install.git`)
- [ ] Hermes Docker-Image gebaut (`docker build -t hermes-agent:latest .`)
- [ ] Deine Dump-Datei: `hermes_dump.sql`
- [ ] Deine Batch-Konfiguration (API_KEY, MPASS, PROVIDER, MODEL)

> **Wenn du die Voraussetzungen noch nicht hast**, folge der [INSTALLATION.de.md](INSTALLATION.de.md) Phase 1 (Schritte 1-3) und Phase 2 (Schritte 4-5).

---

## Schritt 1: Voraussetzungen

Wenn du auf einem neuen Rechner bist, starte hier.

### 1A: WSL 2 aktivieren

```powershell
# PowerShell als Administrator
wsl --install -d Ubuntu
```

Nach dem Neustart erstellst du deinen Linux-Benutzer.

### 1B: Docker Desktop installieren

Download von: https://www.docker.com/products/docker-desktop/

Wahrend der Installation **"WSL 2 statt Hyper-V verwenden"** auswahlen.

### 1C: WSL-Integration

Docker Desktop -> Einstellungen -> Ressourcen -> WSL-Integration -> Schalter **Ubuntu** EIN -> Ubernehmen & Neustarten

---

## Schritt 2: Dump finden

Das Backup wurde erstellt unter `%DUMP_DIR%\\hermes_dump.sql`.
Ubliche Speicherorte:

| Quelle | Typischer Pfad |
|--------|----------------|
| Standard-Backup | `<REPO_DIR>\\backups\\hermes_dump.sql` |
| Deine Kopie | wo auch immer du sie gespeichert hast |

**Kopiere den Dump in deinen Repo-Ordner** fur einfachen Zugriff:

```powershell
copy <REPO_DIR>\\backups\\hermes_dump.sql <REPO_DIR>\\
:: oder von USB / Netzwerklaufwerk
copy E:\\backups\\hermes_dump.sql <REPO_DIR>\\
```

---

## Schritt 3: Klonen & Bauen

```powershell
cd <REPO_DIR>
git clone https://github.com/delkim2003/hermes-install.git .
cd <REPO_DIR>
docker build -t hermes-agent:latest .
```

> Wenn du das bereits bei der Ersteinrichtung gemacht hast, springe zu Schritt 4.

---

## Schritt 4: MySQL wiederherstellen

### 4A: Altes Volume bereinigen

Entferne zunachst das alte MySQL-Volume – ein beschadigtes oder partielles Volume kann den Import blockieren:

```powershell
docker volume rm hermes_mysql_data 2>nul
```

### 4B: MySQL-Container starten

```powershell
docker network create hermes-net 2>nul
docker run -d --restart=unless-stopped --network=hermes-net ^
    --name=hermes-agent-mysql -h hermes-agent-mysql ^
    -e MYSQL_ROOT_PASSWORD=DEIN_MPASS ^
    -v hermes_mysql_data:/var/lib/mysql ^
    mysql:8.0 ^
    --default-authentication-plugin=mysql_native_password
```

Warte ~30 Sekunden, bis MySQL initialisiert ist:

```powershell
:wait_loop
docker exec hermes-agent-mysql mysqladmin ping -uroot -pDEIN_MPASS --silent >nul 2>&1
if %errorlevel% neq 0 (timeout /t 3 /nobreak >nul & goto wait_loop)
echo MySQL ist bereit
```

### 4C: Dump importieren

```powershell
type <REPO_DIR>\\hermes_dump.sql | docker exec -i hermes-agent-mysql mysql -uroot -pDEIN_MPASS
```

**Uberprufen:**

```powershell
docker exec hermes-agent-mysql mysql -uroot -pDEIN_MPASS hermes -e "SELECT COUNT(*) AS sessions FROM sessions"
docker exec hermes-agent-mysql mysql -uroot -pDEIN_MPASS hermes -e "SELECT COUNT(*) AS messages FROM messages"
```

Diese sollten deinen Vorher-Zahlen entsprechen. Wenn sie 0 anzeigen, ist der Import fehlgeschlagen – prufe die Dump-Datei.

---

## Schritt 5: Hermes starten

### 5A: Config & Sync-Skript kopieren

```powershell
:: Config-Verzeichnis erstellen
if not exist "%USERPROFILE%\\.hermes" mkdir "%USERPROFILE%\\.hermes"

:: config.yaml schreiben
(
echo provider: DEIN_PROVIDER
echo model: DEIN_MODELL
echo api_key: DEIN_API_KEY
echo terminal:
echo   backend: local
echo api_server:
echo   enabled: true
echo   port: 8642
echo   api_key: DEIN_API_KEY
echo tools:
echo   - terminal
echo   - web_search
echo   - file
echo   - browser
echo   - vision
) > "%USERPROFILE%\\.hermes\\config.yaml"
```

### 5B: Hermes API & Dashboard starten

```powershell
:: Dashboard
docker run -d --restart=unless-stopped --network=hermes-net ^
    --name=hermes-dashboard -h hermes-dashboard ^
    -v "%USERPROFILE%\\.hermes:/root/.hermes" ^
    -p 9119:9119 ^
    hermes-agent:latest ^
    hermes dashboard --host 0.0.0.0 --port 9119

:: API Server
docker run -d --restart=unless-stopped --network=hermes-net ^
    --name=hermes-agent -h hermes-agent ^
    -v "%USERPROFILE%\\.hermes:/root/.hermes" ^
    -e HERMES_PROVIDER_OVERRIDE="DEIN_PROVIDER" ^
    -e HERMES_MODEL_OVERRIDE="DEIN_MODELL" ^
    -e HERMES_API_KEY="DEIN_API_KEY" ^
    -p 8642:8642 ^
    -p 8641:8641 ^
    hermes-agent:latest ^
    hermes api-server --host 0.0.0.0 --port 8642


```

Warte auf den API-Server:

```powershell
timeout /t 5 /nobreak >nul
```

### 5C: Sync-Skript in Container kopieren

```powershell
docker exec hermes-agent mkdir -p /opt/data/home/scripts
docker cp <REPO_DIR>\\mysql_sync.py hermes-agent:/opt/data/home/scripts/mysql_sync.py
docker exec hermes-agent pip install pymysql -q
```

---

## Schritt 6: Reverse Sync

Dies ist der kritische Schritt – er stellt `state.db` (Hermes' interne Datenbank) aus MySQL wieder her.

```powershell
docker exec ^
    -e MYSQL_HOST=hermes-agent-mysql ^
    -e MYSQL_PASS=DEIN_MPASS ^
    -e MYSQL_DB=hermes ^
    -e SYNC_DIRECTION=reverse ^
    hermes-agent python3 /opt/data/home/scripts/mysql_sync.py
```

Erwartete Ausgabe:
```
[HH:MM:SS] Reverse-Sync: MySQL -> SQLite for recovery
[HH:MM:SS]   SQLite: /root/.hermes/state.db
[HH:MM:SS]   MySQL:  root@hermes-agent-mysql:3306/hermes
[HH:MM:SS] Mode: REVERSE - MySQL -> SQLite
[HH:MM:SS]   XX sessions restored
[HH:MM:SS]   YY messages restored
[HH:MM:SS]   ZZ memory entries restored
[HH:MM:SS] Reverse sync complete: XX sessions, YY messages, ZZ memory entries restored
[HH:MM:SS] SQLite commit successful
[HH:MM:SS] Done: state.db restored from MySQL
[HH:MM:SS] === Synchronization complete ===
```

Wenn das erfolgreich ist, **hat Hermes jetzt alle deine alten Sessions und Nachrichten zuruck**.

---

## Schritt 7: Uberprufen

### 7A: API-Test

```powershell
curl http://localhost:8642/v1/models
```

Sollte deine Modell-Liste zuruckgeben.

### 7B: Container-Status

```powershell
docker ps --filter network=hermes-net
```

Alle 3 Container sollten laufen: `hermes-agent`, `hermes-dashboard`, `hermes-agent-mysql`.

### 7D: Frischen Dump erstellen

Fuhre `<REPO_DIR>\\hermes_start.bat` einmal aus, um ein frisches Backup zu erstellen.

---

## Kurzreferenz

**One-Liner-Wiederherstellung** (ausfuhren von `<REPO_DIR>` nach Erfullung der Voraussetzungen):

```powershell
:: 0. Altes MySQL-Volume bereinigen
docker volume rm hermes_mysql_data 2>nul

:: 1. MySQL starten und importieren
docker run -d --restart=unless-stopped --network=hermes-net --name=hermes-agent-mysql -h hermes-agent-mysql -e MYSQL_ROOT_PASSWORD=DEIN_MPASS -v hermes_mysql_data:/var/lib/mysql mysql:8.0 --default-authentication-plugin=mysql_native_password
timeout /t 30 /nobreak >nul
type hermes_dump.sql | docker exec -i hermes-agent-mysql mysql -uroot -pDEIN_MPASS

:: 2. Hermes starten
docker run -d --restart=unless-stopped --network=hermes-net --name=hermes-dashboard -h hermes-dashboard -v "%USERPROFILE%\\.hermes:/root/.hermes" -p 9119:9119 hermes-agent:latest hermes dashboard --host 0.0.0.0 --port 9119
docker run -d --restart=unless-stopped --network=hermes-net --name=hermes-agent -h hermes-agent -v "%USERPROFILE%\\.hermes:/root/.hermes" -e HERMES_PROVIDER_OVERRIDE="DEIN_PROVIDER" -e HERMES_MODEL_OVERRIDE="DEIN_MODELL" -e HERMES_API_KEY="DEIN_API_KEY" -p 8642:8642 -p 8641:8641 hermes-agent:latest hermes api-server --host 0.0.0.0 --port 8642
timeout /t 10 /nobreak >nul

:: 3. Reverse Sync
docker exec hermes-agent mkdir -p /opt/data/home/scripts
docker cp mysql_sync.py hermes-agent:/opt/data/home/scripts/mysql_sync.py
docker exec hermes-agent pip install pymysql -q
docker exec -e MYSQL_HOST=hermes-agent-mysql -e MYSQL_PASS=DEIN_MPASS -e MYSQL_DB=hermes -e SYNC_DIRECTION=reverse hermes-agent python3 /opt/data/home/scripts/mysql_sync.py

:: 4. Fertig
echo Hermes aus Dump wiederhergestellt.
```

---

## Fehlerbehebung

### "Access denied for user" beim Dump-Import

-> Dein MPASS im Befehl stimmt nicht mit dem MPASS wahrend des Backups uberein.

### MySQL-Container beendet sich sofort

```powershell
docker logs hermes-agent-mysql
```

Haufige Ursachen:
- Port 3306 ist bereits belegt
- Beschadigtes Volume: `docker volume rm hermes_mysql_data` dann neustarten

### Reverse Sync sagt "SQLite: /opt/data/state.db not found"

Der Hermes API-Server erstellt `state.db` automatisch beim ersten Start.
Starte den API-Server neu: `docker restart hermes-agent`, warte 10 Sekunden, dann wiederhole.

### Reverse Sync sagt "MySQL not reachable"

-> MySQL-Container lauft nicht oder das Passwort ist falsch.

```powershell
docker ps                              # Laufen MySQL?
docker exec hermes-agent-mysql mysqladmin ping -uroot -pDEIN_MPASS --silent  # Erreichbar?
```

### Dump-Datei ist leer oder beschadigt

-> Stelle von einer alteren Backup-Kopie wieder her. Prufe `%DUMP_DIR%` auf fruhere Versionen.

---

## Vorbeugung: Bewahre diese 3 Dinge sicher auf

Um einen zukunftigen Totalausfall zu vermeiden, sichere regelmassig diese **3 Dinge**:

| Was | Wo finden | Backup-Haufigkeit |
|-----|-----------|-------------------|
| **MySQL Dump** | `%DUMP_DIR%\\hermes_dump.sql` | Jeder Systemstart (automatisch) |
| **Hermes Config** | `%USERPROFILE%\\.hermes\\config.yaml` | Bei Anderungen |
| **Dieses Repo** | GitHub | Immer verfugbar |

Der MySQL-Dump ist am wichtigsten – er enthalt alles, was Hermes weiss.

---

## Support & Kontakt

<p align="center">
  <strong>Entwickelt von <a href="https://einfach-online.dev">einfach-online.dev</a></strong><br/>
  info@einfach-online.dev<br/>
  <em>Local First. Performance Driven. Privacy Centric.</em>
</p>

Dieses Wiederherstellungssystem wurde entwickelt und getestet von [einfach-online.dev](https://einfach-online.dev) — osterreichischen Spezialisten fur DSGVO-konforme, lokale KI-Infrastruktur.

Brauchst du Hilfe bei der Wiederherstellung? [Schreib mir eine E-Mail](mailto:info@einfach-online.dev).
