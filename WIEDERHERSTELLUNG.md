# Hermes Agent – Notfall-Wiederherstellung

Diese Anleitung beschreibt, wie Hermes Agent **komplett von Null** wieder aufgebaut
wird – egal ob Windows neu installiert, die Festplatte kaputt oder WSL zerschossen ist.

**Voraussetzung:** Du hast noch den MySQL-Dump auf einem Backup-Laufwerk
(z. B. `D:\hermes-db-backup\hermes_dump.sql`) oder in der Cloud.

---

## Was ist passiert? – Das Szenario

- Windows wurde neu installiert
- Oder WSL ist defekt und lässt sich nicht reparieren
- Oder der ganze Rechner wurde ausgetauscht

**Was du hast:** Den MySQL-Dump `hermes_dump.sql` (komplettes Hermes-Gehirn).
**Was du nicht hast:** Docker, WSL, Container, Hermes-Config, NICHTS.

---

## Phase 1 – Grundsystem

### 1. WSL aktivieren

**Dauer: ~5 Minuten**

PowerShell als Administrator:

```powershell
wsl --install -d Ubuntu
```

Nach Neustart: Ubuntu-Benutzer anlegen (Name + Passwort merken).

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
git clone https://github.com/delkim2003/hermes-db-backup hermes-db-backup
```

Bzw. falls das Installations-Repo:
```powershell
cd D:\
git clone https://github.com/delkim2003/hermes-install.git hermes
```

---

### 4. Backup-Dateien bereitstellen

Lege den **MySQL-Dump** an seinen Platz:

```powershell
mkdir D:\hermes-db-backup -Force
```

Kopiere deine gesicherte `hermes_dump.sql` hier rein.

**Fehlt der Dump?** Kein Problem – Hermes startet auch ohne, allerdings ohne
vorherige Sessions. Du startest dann einfach neu.

---

### 5. Hermes Docker-Image bauen

**Dauer: ~10-20 Minuten**

```bash
wsl
cd /mnt/d/hermes
docker build -t hermes-agent:latest .
exit
```

---

### 6. Hermes-Config vorbereiten

**Dauer: ~2 Minuten**

```powershell
mkdir %USERPROFILE%\.hermes -Force
```

Falls du eine gesicherte `config.yaml` hast → jetzt reinkopieren.
Falls nicht → die Batch legt beim ersten Start eine an.

---

## Phase 2 – Wiederherstellung

### 7. Container manuell starten (OHNE Sync)

Jetzt starten wir Hermes **ohne automatischen Sync**, weil wir zuerst den
Dump einspielen wollen:

PowerShell:
```powershell
cd D:\hermes

:: Docker Netzwerk
docker network create hermes-net 2>nul

:: MySQL Container
docker run -d --restart=unless-stopped --network=hermes-net ^
    --name=hermes-agent-mysql -h hermes-agent-mysql ^
    -e MYSQL_ROOT_PASSWORD=MEIN_PASSWORT ^
    -v hermes_mysql_data:/var/lib/mysql ^
    mysql:8.0

:: Warten bis MySQL bereit ist (kann ~30s dauern)
echo Warte auf MySQL...
:wait_mysql
timeout /t 3 /nobreak >nul
docker exec hermes-agent-mysql mysqladmin ping -uroot -pMEIN_PASSWORT --silent >nul 2>&1
if not !errorlevel! equ 0 goto wait_mysql

:: Dump einspielen – DAS IST DER ENTSCHEIDENDE SCHRITT
docker exec -i hermes-agent-mysql mysql -uroot -pMEIN_PASSWORT < D:\hermes-db-backup\hermes_dump.sql
```

**Das war der wichtigste Befehl** – jetzt ist dein ganzes Hermes-Gehirn
wieder in der MySQL-Datenbank.

---

### 8. Restliche Container starten

Wenn MySQL läuft und der Dump eingespielt ist, starte den Rest:

```powershell
:: API Server
docker run -d --restart=unless-stopped --network=hermes-net ^
    --name=hermes-agent -h hermes-agent ^
    -v "%USERPROFILE%\.hermes:/root/.hermes" ^
    -v /opt/data:/opt/data ^
    -e HERMES_API_KEY=MEIN_API_KEY ^
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
    -e OPENAI_API_KEY=MEIN_API_KEY ^
    -p 3000:8080 ^
    ghcr.io/open-webui/open-webui:main
```

---

### 9. `state.db` aus MySQL wiederherstellen

Das Sync-Script kann rückwärts arbeiten: MySQL → SQLite.

```powershell
:: Sync-Script kopieren
docker cp D:\hermes\mysql_sync.py hermes-agent:/opt/data/home/scripts/mysql_sync.py

:: Reverse-Sync: MySQL -> state.db
docker exec ^
    -e MYSQL_HOST=hermes-agent-mysql ^
    -e MYSQL_PASS=MEIN_PASSWORT ^
    -e MYSQL_DB=hermes ^
    -e SYNC_DIRECTION=reverse ^
    hermes-agent python3 /opt/data/home/scripts/mysql_sync.py
```

Danach ist `state.db` wieder vollständig – exakt so wie vor dem Crash.

---

### 10. Sync-Script fixieren

Ein letzter Lauf in normaler Richtung, damit alles konsistent ist:

```powershell
docker exec hermes-agent pip install pymysql -q
docker exec ^
    -e MYSQL_HOST=hermes-agent-mysql ^
    -e MYSQL_PASS=MEIN_PASSWORT ^
    -e MYSQL_DB=hermes ^
    hermes-agent python3 /opt/data/home/scripts/mysql_sync.py
```

---

### 11. Fertig – alles testen

| Prüfung | Befehl | Erwartet |
|---------|--------|----------|
| API erreichbar | `curl http://localhost:8642/v1/models` | JSON-Liste |
| MySQL-Daten | `docker exec hermes-agent-mysql mysql -uroot -pMEIN_PASSWORT hermes -e "SELECT COUNT(*) FROM sessions"` | Alte Anzahl |
| Open WebUI | http://localhost:3000 | Login-Maske |
| Dashboard | http://localhost:9119 | Dashboard |

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
docker exec -i hermes-agent-mysql mysql -uroot -pMPASS < D:\hermes-db-backup\hermes_dump.sql

:: 5. Container starten
docker run -d --network=hermes-net --name=hermes-agent -v "%USERPROFILE%\.hermes:/root/.hermes" -v /opt/data:/opt/data -p 8642:8642 hermes-agent:latest hermes api-server --host 0.0.0.0 --port 8642

:: 6. Reverse-Sync
docker cp D:\hermes\mysql_sync.py hermes-agent:/opt/data/home/scripts/
docker exec -e MYSQL_HOST=hermes-agent-mysql -e MYSQL_PASS=MPASS -e SYNC_DIRECTION=reverse hermes-agent python3 /opt/data/home/scripts/mysql_sync.py

:: 7. Dashboard + WebUI
docker run -d --network=hermes-net --name=hermes-dashboard -v "%USERPROFILE%\.hermes:/root/.hermes" -p 9119:9119 hermes-agent:latest hermes dashboard --host 0.0.0.0 --port 9119
docker run -d --network=hermes-net --name=open-webui -e OPENAI_API_BASE_URL="http://hermes-agent:8642/v1" -e OPENAI_API_KEY=KEY -p 3000:8080 ghcr.io/open-webui/open-webui:main
```

---

## Nächste Schritte

Nach erfolgreicher Wiederherstellung:

- [ ] Open WebUI aufrufen → alte Chats sollten wieder da sein
- [ ] Eine Testnachricht senden → Hermes sollte antworten
- [ ] Dashboard aufrufen → Sessions und Memory prüfen
- [ ] MySQL-Dump neu erstellen: Batch einmal komplett durchlaufen lassen
- [ ] Desktop-Verknüpfung für die Batch erstellen

---

## Troubleshooting

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
3. Reverse-Sync erneut ausführen (Schritt 9)

### "nicht alle alten Nachrichten sind da"

Manchmal wurden einige Sessions noch nicht in den Dump gesynct (wenn Hermes
lief und der Dump älter war). Wiederhole: Batch laufen lassen → neuer Dump.

---

**Letzte Sicherung:** Immer die `D:\hermes-db-backup\` auf einen zweiten Datenträger
sichern! Das ist dein komplettes Hermes-Gehirn in einer einzigen Datei.
