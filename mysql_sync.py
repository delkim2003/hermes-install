#!/usr/bin/env python3
"""
Hermes state.db -> MySQL synchronizer.
Liest die SQLite-Datenbank von Hermes und spiegelt Sessions, Messages
und Memory-Eintraege in eine MySQL-Datenbank.
Laesst sich idempotent mehrfach ausfuehren (UPSERT).
"""

import sqlite3
import pymysql
import json
import os
import sys
from datetime import datetime

# --- Konfiguration ---
SQLITE_PATH = os.environ.get("SQLITE_PATH", "/opt/data/state.db")
MYSQL_HOST = os.environ.get("MYSQL_HOST", "127.0.0.1")
MYSQL_PORT = int(os.environ.get("MYSQL_PORT", "3306"))
MYSQL_USER = os.environ.get("MYSQL_USER", "root")
MYSQL_PASS = os.environ.get("MYSQL_PASS", "hermes_root_2024")
MYSQL_DB = os.environ.get("MYSQL_DB", "hermes")
DRY_RUN = os.environ.get("DRY_RUN", "").lower() in ("1", "true", "yes")
SYNC_DIRECTION = os.environ.get("SYNC_DIRECTION", "forward").lower()


def log(msg: str):
    print(f"[{datetime.now().strftime('%H:%M:%S')}] {msg}")


def ensure_mysql_database(cursor):
    cursor.execute(f"CREATE DATABASE IF NOT EXISTS `{MYSQL_DB}` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;")
    cursor.execute(f"USE `{MYSQL_DB}`;")


def ensure_mysql_tables(cursor):
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS sessions (
            session_id        VARCHAR(64)   PRIMARY KEY,
            title             TEXT,
            source            VARCHAR(32),
            started_at        DATETIME,
            ended_at          DATETIME,
            message_count     INT DEFAULT 0,
            profile           VARCHAR(64)  DEFAULT 'default',
            raw_json          JSON,
            last_synced_at    DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    """)
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS messages (
            id                BIGINT        PRIMARY KEY,
            session_id        VARCHAR(64),
            role              VARCHAR(16),
            content           MEDIUMTEXT,
            created_at        DATETIME,
            tool_calls        JSON,
            tool_call_id      VARCHAR(64),
            raw_json          JSON,
            last_synced_at    DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            INDEX idx_messages_session (session_id),
            FOREIGN KEY (session_id) REFERENCES sessions(session_id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    """)
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS memory_entries (
            id                INT AUTO_INCREMENT PRIMARY KEY,
            entry_id          VARCHAR(128),
            target            VARCHAR(16),
            content           TEXT,
            created_at        DATETIME,
            updated_at        DATETIME,
            raw_json          JSON,
            last_synced_at    DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            UNIQUE KEY uq_memory_entry (entry_id),
            INDEX idx_memory_target (target)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    """)
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS sync_log (
            id                INT AUTO_INCREMENT PRIMARY KEY,
            started_at        DATETIME,
            finished_at       DATETIME,
            sessions_synced   INT DEFAULT 0,
            messages_synced   BIGINT DEFAULT 0,
            memory_synced     INT DEFAULT 0,
            status            VARCHAR(16) DEFAULT 'ok',
            error_message     TEXT
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    """)


def sync_sessions(sqlite_conn, mysql_cursor):
    sqlite_conn.row_factory = sqlite3.Row
    rows = sqlite_conn.execute(
        "SELECT id, title, started_at, ended_at, message_count, "
        "       COALESCE(source, 'unknown') as source, "
        "       COALESCE(profile, 'default') as profile "
        "FROM sessions ORDER BY started_at"
    ).fetchall()
    count = 0
    for r in rows:
        data = {
            "title": r["title"],
            "source": r["source"],
            "started_at": r["started_at"],
            "ended_at": r["ended_at"],
            "message_count": r["message_count"] or 0,
            "profile": r["profile"],
        }
        raw_json = json.dumps(dict(r), default=str, ensure_ascii=False)
        if DRY_RUN:
            log(f"  [DRY] Session {r['id']}: {r['title'] or '(no title)'}")
            count += 1
            continue
        mysql_cursor.execute("""
            INSERT INTO sessions (session_id, title, source, started_at, ended_at,
                                  message_count, profile, raw_json)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            ON DUPLICATE KEY UPDATE
                title         = VALUES(title),
                source        = VALUES(source),
                started_at    = VALUES(started_at),
                ended_at      = VALUES(ended_at),
                message_count = VALUES(message_count),
                profile       = VALUES(profile),
                raw_json      = VALUES(raw_json)
        """, (
            r["id"], data["title"], data["source"], data["started_at"],
            data["ended_at"], data["message_count"], data["profile"], raw_json
        ))
        count += 1
    return count


def sync_messages(sqlite_conn, mysql_cursor):
    sqlite_conn.row_factory = sqlite3.Row
    rows = sqlite_conn.execute(
        "SELECT id, session_id, role, content, created_at FROM messages ORDER BY id"
    ).fetchall()
    count = 0
    for r in rows:
        if DRY_RUN:
            count += 1
            continue
        mysql_cursor.execute("""
            INSERT INTO messages (id, session_id, role, content, created_at)
            VALUES (%s, %s, %s, %s, %s)
            ON DUPLICATE KEY UPDATE
                role       = VALUES(role),
                content    = VALUES(content),
                created_at = VALUES(created_at)
        """, (r["id"], r["session_id"], r["role"], r["content"], r["created_at"]))
        count += 1
    return count


def sync_reverse(mysql_cursor, sqlite_cursor):
    """Reverse: MySQL -> SQLite - stellt state.db aus MySQL wieder her"""
    log("Reverse-Sync: MySQL -> SQLite fuer Wiederherstellung")

    # Sessions wiederherstellen
    mysql_cursor.execute("""
        SELECT session_id, title, source, started_at, ended_at,
               COALESCE(message_count, 0), COALESCE(profile, 'default')
        FROM sessions ORDER BY started_at
    """)
    rows = mysql_cursor.fetchall()
    count = 0
    for r in rows:
        sqlite_cursor.execute("""
            INSERT OR REPLACE INTO sessions
                (id, title, source, started_at, ended_at, message_count, profile)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        """, (r[0], r[1], r[2], r[3], r[4], r[5], r[6]))
        count += 1
    log(f"  {count} Sessions wiederhergestellt")

    # Messages wiederherstellen
    mysql_cursor.execute(
        "SELECT id, session_id, role, content, created_at FROM messages ORDER BY id"
    )
    rows = mysql_cursor.fetchall()
    count = 0
    for r in rows:
        sqlite_cursor.execute("""
            INSERT OR REPLACE INTO messages (id, session_id, role, content, created_at)
            VALUES (?, ?, ?, ?, ?)
        """, r)
        count += 1
    log(f"  {count} Messages wiederhergestellt")

    return len(rows)


def sync_memory(sqlite_conn, mysql_cursor):
    mem_dir = os.path.expanduser("~/.hermes/memories")
    if not os.path.isdir(mem_dir):
        log("  Kein memories-Verzeichnis gefunden, ueberspringe.")
        return 0
    count = 0
    for fname in sorted(os.listdir(mem_dir)):
        if not fname.endswith(".json"):
            continue
        path = os.path.join(mem_dir, fname)
        try:
            with open(path, "r", encoding="utf-8") as f:
                data = json.load(f)
        except (json.JSONDecodeError, OSError) as e:
            log(f"  Warnung: konnte {fname} nicht lesen: {e}")
            continue
        target = "memory"
        entries = data if isinstance(data, list) else [data]
        for entry in entries:
            if isinstance(entry, dict):
                content = entry.get("content", "")
                entry_id = entry.get("id") or fname.replace(".json", "")
                if DRY_RUN:
                    count += 1
                    continue
                mysql_cursor.execute("""
                    INSERT INTO memory_entries (entry_id, target, content, raw_json)
                    VALUES (%s, %s, %s, %s)
                    ON DUPLICATE KEY UPDATE
                        content  = VALUES(content),
                        raw_json = VALUES(raw_json)
                """, (entry_id, target, content, json.dumps(entry, ensure_ascii=False, default=str)))
                count += 1
    return count


def main():
    log("Hermes -> MySQL Synchronisation gestartet")
    log(f"  SQLite: {SQLITE_PATH}")
    log(f"  MySQL:  {MYSQL_USER}@{MYSQL_HOST}:{MYSQL_PORT}/{MYSQL_DB}")

    if not os.path.isfile(SQLITE_PATH):
        log(f"  FEHLER: state.db nicht gefunden unter {SQLITE_PATH}")
        sys.exit(1)

    sqlite_conn = sqlite3.connect(SQLITE_PATH)

    try:
        mysql_conn = pymysql.connect(
            host=MYSQL_HOST,
            port=MYSQL_PORT,
            user=MYSQL_USER,
            password=MYSQL_PASS,
            autocommit=False
        )
    except pymysql.err.Error as e:
        log(f"  FEHLER: MySQL nicht erreichbar - {e}")
        sqlite_conn.close()
        sys.exit(2)

    cursor = mysql_conn.cursor()
    try:
        ensure_mysql_database(cursor)
        mysql_conn.database = MYSQL_DB

        if SYNC_DIRECTION in ("reverse", "backward"):
            # === REVERSE: MySQL -> SQLite (Wiederherstellung) ===
            ensure_mysql_tables(cursor)
            log("Modus: REVERSE - MySQL -> SQLite")
            if DRY_RUN:
                log("  *** DRY RUN - keine Aenderungen ***")

            reverse_sessions = sync_reverse(cursor, sqlite_conn.cursor())
            log(f"  Reverse-Sync abgeschlossen: {reverse_sessions} Sessions")

            if not DRY_RUN:
                sqlite_conn.commit()
                log("  SQLite-Commit erfolgreich")
                log(f"  Fertig: state.db wiederhergestellt aus MySQL")

        else:
            # === FORWARD: SQLite -> MySQL (Normalbetrieb) ===
            ensure_mysql_tables(cursor)
            if DRY_RUN:
                log("  *** DRY RUN - keine Aenderungen ***")

            log("Synchronisiere Sessions...")
            sessions_count = sync_sessions(sqlite_conn, cursor)
            log(f"  {sessions_count} Sessions verarbeitet")

            log("Synchronisiere Messages...")
            messages_count = sync_messages(sqlite_conn, cursor)
            log(f"  {messages_count} Messages verarbeitet")

            log("Synchronisiere Memory...")
            memory_count = sync_memory(sqlite_conn, cursor)
            log(f"  {memory_count} Memory-Eintraege verarbeitet")

            if not DRY_RUN:
                cursor.execute("""
                    INSERT INTO sync_log (started_at, finished_at, sessions_synced,
                                          messages_synced, memory_synced, status)
                    VALUES (NOW(), NOW(), %s, %s, %s, 'ok')
                """, (sessions_count, messages_count, memory_count))
                mysql_conn.commit()
                log("  MySQL-Commit erfolgreich")
                log(f"  Fertig: {sessions_count} Sessions, {messages_count} Messages, {memory_count} Memory")

    except Exception as e:
        log(f"  FEHLER: {e}")
        mysql_conn.rollback()
        try:
            cursor.execute("""
                INSERT INTO sync_log (started_at, finished_at, status, error_message)
                VALUES (NOW(), NOW(), 'error', %s)
            """, (str(e),))
            mysql_conn.commit()
        except Exception:
            pass
        sys.exit(3)
    finally:
        cursor.close()
        mysql_conn.close()
        sqlite_conn.close()

    log("=== Synchronisation abgeschlossen ===")


if __name__ == "__main__":
    main()
