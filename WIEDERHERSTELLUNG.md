# Hermes Agent – Notfall-Wiederherstellung

Diese Anleitung beschreibt, wie Hermes Agent **komplett von Null** wieder aufgebaut
wird – egal ob Windows neu installiert, die Festplatte kaputt oder WSL zerschossen ist.
**Voraussetzung:** Du hast noch den MySQL-Dump `D:\hermes-db-backup\hermes_dump.sql`
(oder eine Kopie davon auf einem anderen Laufwerk / in der Cloud).

---

## Was ist passiert? – Das Szenario

- Windows wurde neu installiert
- Oder WSL ist defekt und lässt sich nicht reparieren
- Oder der ganze Rechner wurde ausgetauscht

**Was du hast:** Den MySQL-Dump `hermes_dump.sql`.
**Was du nicht hast:** Docker, WSL, Container, Hermes-Config, NICHTS.

**Kein Dump vorhanden?** Kein Problem – Hermes startet auch ohne. Du verlierst nur
die alten Chats und Memory-Einträge. Das System selbst läuft sofort.

---

## Phase 1 – Grundsystem aufbauen

### 1. WSL aktivieren

**Dauer: ~5 Minuten**

PowerShell als Administrator:

```powershell
wsl --install -d Ubuntu
```

Nach Neustart: Ubuntu-Benutzernamen und Passwort festlegen (merken!).

**Check:**
```powershell
wsl -l -v
```
→ `Ubuntu` muss `Running` mit `Version 2` anzeigen.

---

### 2. Docker Desktop installieren

**Dauer: ~10 Minuten**

https://www.docker.com/products/docker-desktop/

Installieren, nach dem Start:
- Settings → Resources → WSL Integration → **Ubuntu** einschalten
- Apply & Restart

**Check:**
```powershell
docker --version
```
→ Versionsnummer, kein Fehler

---

### 3. GitHub Repo klonen

**Dauer: ~2 Minuten**

```powershell
cd D:\
git clone https://github.com/delkim2003/hermes-install.git hermes
cd D:\hermes
```

---

### 4. Backup-Dateien bereitstellen

**Dauer: ~2 Minuten**

Lege den **MySQL-Dump** an seinen Platz:

```powershell
mkdir D:\hermes-db-backup -Force
```

Kopiere deine gesicherte `hermes_dump.sql` hier rein (z.B. vom USB-Stick, von der NAS
oder aus der Cloud).

**Kein Dump vorhanden?** Überspringe diesen Schritt – Hermes startet frisch.

---

### 5. Hermes Docker-Image bauen

**Dauer: ~10-20 Minuten**

```bash
wsl cd /mnt/d/hermes && docker build -t hermes-agent:latest .
```

Oder falls das Repo kein Dockerfile hat:

```bash
wsl git clone https://github.com/nousresearch/hermes-agent.git /tmp/hermes
wsl docker build -t hermes-agent:latest /tmp/hermes
```

---

### 6. Hermes-Config vorbereiten

**Dauer: ~2 Minuten**

```powershell
mkdir %USERPROFILE%\.hermes -Force
```

Falls du eine gesicherte `config.yaml` hast → jetzt reinkopieren.
Falls nicht → kein Problem, die Batch erstellt beim ersten Start eine.

---

## Phase 2 – Wiederherstellung

### 7. MySQL starten und Dump einspielen

**Dauer: ~2 Minuten**

Jetzt starten wir **nur** MySQL, ohne die anderen Container:

```powershell
:: Docker Netzwerk
docker network create hermes-net 2>nul

:: MySQL Container starten
docker run -d --restart=unless-stopped --network=hermes-net ^
    --name=hermes-agent-mysql -h hermes-agent-mysql ^
    -e MYSQL_ROOT_PASSWORD=DEIN_PASSWORT ^
    -v hermes_mysql_data:/var/lib/mysql ^
    mysql:8.0

:: Warten bis MySQL bereit ist (dauert ~30s)
:wait_mysql
timeout /t 3 /nobreak >nul
docker exec hermes-agent-mysql mysqladmin ping -uroot -pDEIN_PASSWORT --silent >nul 2>&1
if not !errorlevel! equ 0 goto wait_mysql

:: Dump einspielen – DAS IST DER ENTSCHEIDENDE SCHRITT
type D:\hermes-db-backup\hermes_dump.sql | docker exec -i hermes-agent-mysql mysql -uroot -pDEIN_PASSWORT
```

**Hinweis:** Ersetze `DEIN_PASSWORT` durch dein MySQL-Passwort (entspricht `MPASS`
aus der Batch).

**Das war der wichtigste Befehl** – jetzt ist dein ganzes Hermes-Gehirn wieder
in der MySQL-Datenbank.

---

### 8. Hermes-Config anpassen

**Dauer: ~2 Minuten**

Bearbeite die Config-Datei mit dem richtigen Provider und Modell:

```
notepad %USERPROFILE%\.hermes\config.yaml
```

Minimaler Inhalt:
```yaml
provider: DEIN_PROVIDER
model: DEIN_MODELL
api_key: DEIN_API_KEY
```

---

### 9. Restliche Container starten

**Dauer: ~2 Minuten**

Wenn MySQL läuft und der Dump eingespielt ist:

```powershell
:: API Server
docker run -d --restart=unless-stopped --network=hermes-net ^
    --name=hermes-agent -h hermes-agent ^
    -v "%USERPROFILE%\.hermes:/root/.hermes" ^
    -e HERMES_PROVIDER_OVERRIDE=DEIN_PROVIDER ^
    -e HERMES_MODEL_OVERRIDE=DEIN_MODELL ^
    -p 8642:8642 ^
    hermes-agent:latest ^
    hermes api-server --host 0.0.0.0 --port 8642

:: Dashboard
docker run -d --restart=unless-stopped --network=hermes-net ^
    --name=hermes-dashboard -h hermes-dashboard ^
    -v "%USERPROFILE%\.hermes:/root/.hermes" ^
    -p 9119:9119 ^
    hermes-agent:latest ^
    hermes dashboard --host 0.0.0.0 --port 9119

:: Open WebUI
docker run -d --restart=unless-stopped --network=hermes-net ^
    --name=open-webui -h open-webui ^
    -e OPENAI_API_BASE_URL="http://hermes-agent:8642/v1" ^
    -e OPENAI_API_KEY=DEIN_API_KEY ^
    -p 3000:8080 ^
    ghcr.io/open-webui/open-webui:main
```

---

### 10. `state.db` aus MySQL wiederherstellen

**Dauer: ~2 Minuten**

Das Sync-Script kann **rückwärts** arbeiten: MySQL → SQLite.

```powershell
:: Sync-Script ins Repo kopieren (falls vom Repo)
docker cp D:\hermes\mysql_sync.py hermes-agent:/opt/data/home/scripts/mysql_sync.py

:: pymysql installieren
docker exec hermes-agent pip install pymysql -q

:: Reverse-Sync: MySQL -> state.db
docker exec ^
    -e MYSQL_HOST=hermes-agent-mysql ^
    -e MYSQL_PASS=DEIN_PASSWORT ^
    -e MYSQL_DB=hermes ^
    -e SQLITE_PATH=/root/.hermes/state.db ^
    -e SYNC_DIRECTION=reverse ^
    hermes-agent python3 /opt/data/home/scripts/mysql_sync.py
```

Danach ist `state.db` wieder vollständig – exakt so wie vor dem Crash.

---

### 11. Normalsync einmal durchlaufen

**Dauer: ~1 Minute**

Ein letzter Lauf in normaler Richtung, damit alles konsistent ist:

```powershell
docker exec ^
    -e MYSQL_HOST=hermes-agent-mysql ^
    -e MYSQL_PASS=DEIN_PASSWORT ^
    -e MYSQL_DB=hermes ^
    hermes-agent python3 /opt/data/home/scripts/mysql_sync.py
```

---

### 12. Fertig – alles testen

**Dauer: ~3 Minuten**

| Prüfung | Befehl | Erwartet |
|---------|--------|----------|
| API erreichbar | `curl http://localhost:8642/v1/models` | JSON-Liste |
| MySQL-Daten | `docker exec hermes-agent-mysql mysql -uroot -pDEIN_PASSWORT hermes -e "SELECT COUNT(*) FROM sessions"` | Alte Anzahl |
| Open WebUI | http://localhost:3000 | Login-Maske |
| Dashboard | http://localhost:9119 | Dashboard |

**Letzter Test:** Eine Nachricht an Hermes schreiben. Er sollte antworten.
Wenn die alten Chats in Open WebUI sichtbar sind, war die Wiederherstellung erfolgreich.

---

## Kurzfassung (für Profis)

```powershell
:: 1. System vorbereiten
wsl --install -d Ubuntu
# Docker Desktop installieren + WSL Integration aktivieren

:: 2. Repo klonen
cd D:\
git clone https://github.com/delkim2003/hermes-install.git hermes

:: 3. Image bauen
wsl docker build -t hermes-agent:latest /mnt/d/hermes

:: 4. MySQL + Dump einspielen
docker network create hermes-net
docker run -d --network=hermes-net --name=hermes-agent-mysql -e MYSQL_ROOT_PASSWORD=MPASS mysql:8.0
timeout /t 30
type D:\hermes-db-backup\hermes_dump.sql | docker exec -i hermes-agent-mysql mysql -uroot -pMPASS

:: 5. Container starten
docker run -d --network=hermes-net --name=hermes-agent -v "%USERPROFILE%\.hermes:/root/.hermes" -p 8642:8642 hermes-agent:latest hermes api-server --host 0.0.0.0 --port 8642
docker run -d --network=hermes-net --name=hermes-dashboard -v "%USERPROFILE%\.hermes:/root/.hermes" -p 9119:9119 hermes-agent:latest hermes dashboard --host 0.0.0.0 --port 9119
docker run -d --network=hermes-net --name=open-webui -e OPENAI_API_BASE_URL="http://hermes-agent:8642/v1" -e OPENAI_API_KEY=KEY -p 3000:8080 ghcr.io/open-webui/open-webui:main

:: 6. Reverse-Sync
docker cp D:\hermes\mysql_sync.py hermes-agent:/opt/data/home/scripts/
docker exec hermes-agent pip install pymysql -q
docker exec -e MYSQL_HOST=hermes-agent-mysql -e MYSQL_PASS=MPASS -e SYNC_DIRECTION=reverse hermes-agent python3 /opt/data/home/scripts/mysql_sync.py

:: 7. Normalsync zum Abschluss
docker exec -e MYSQL_HOST=hermes-agent-mysql -e MYSQL_PASS=MPASS hermes-agent python3 /opt/data/home/scripts/mysql_sync.py
```

---

## Fehlerbehebung

### "Access denied for user 'root'"
Falsches Passwort. Prüfe das Passwort in der Batch (`MPASS`) und beim `docker exec`-Befehl.

### "Table 'hermes.sessions' doesn't exist"
Der Dump wurde nicht eingespielt oder war leer. Wiederhole Schritt 7.

### "Can't connect to local MySQL server"
MySQL Container läuft nicht. Prüfe:
```powershell
docker ps -a | findstr mysql
docker logs hermes-agent-mysql
```

### "state.db is not a valid SQLite database"
1. Hermes-Container stoppen: `docker stop hermes-agent`
2. `state.db` löschen: `docker exec hermes-agent rm /root/.hermes/state.db`
3. Reverse-Sync erneut ausführen (Schritt 10)

### "Nicht alle alten Nachrichten sind da"
Manchmal wurden einige Sessions noch nicht in den letzten Dump gesynct.
Einfach den Batch-Neustart abwarten – der nächste Sync aktualisiert alles.

---

## Checkliste für den Notfall

- [ ] WSL installiert und läuft
- [ ] Docker Desktop installiert + WSL Integration aktiv
- [ ] GitHub Repo geklont
- [ ] Hermes-Image gebaut
- [ ] MySQL-Dump liegt in `D:\hermes-db-backup\`
- [ ] MySQL läuft, Dump eingespielt
- [ ] `config.yaml` mit Provider/Model vorhanden
- [ ] Alle Container laufen (hermes-agent, -mysql, -dashboard, open-webui)
- [ ] Reverse-Sync ausgeführt
- [ ] API antwortet (curl http://localhost:8642/v1/models)
- [ ] Open WebUI zeigt alte Chats
- [ ] Batch läuft sauber durch

---

**Letzte Sicherung:** Immer die `D:\hermes-db-backup\` auf einen zweiten Datenträger
sichern! Das ist dein komplettes Hermes-Gehirn in einer einzigen Datei.
**Ohne diesen Dump gibt es keine Wiederherstellung der Chat-Verläufe.**
