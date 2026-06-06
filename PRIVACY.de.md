# Datenschutz & DSGVO — Hermes Agent Deployment Kit

> **Sprache:** Deutsch — [English version](PRIVACY.md)

Dieses Dokument erklart, wo deine Daten leben, wohin sie gehen und welche Datenschutzgarantien du je nach Provider-Wahl bekommst.

---

## Inhaltsverzeichnis

- [Architektur-Ubersicht](#architektur-uebersicht)
- [Was bleibt lokal (immer)](#was-bleibt-lokal-immer)
- [Provider-Wahl & DSGVO-Auswirkungen](#provider-wahl--dsgvo-auswirkungen)
- [Option 1: Lokales Modell (100 % Datenschutz)](#option-1-lokales-modell-100--datenschutz)
- [Option 2: EU-gehosteter Provider (DSGVO-konform)](#option-2-eu-gehosteter-provider-dsgvo-konform)
- [Option 3: Direkt-API (Budget-Wahl)](#option-3-direkt-api-budget-wahl)
- [Vergleichstabelle](#vergleichstabelle)
- [Technische Datenschutzmassnahmen](#technische-datenschutzmassnahmen)
- [Osterreichischer DSG-Kontext](#oesterreichischer-dsg-kontext)
- [FAQ](#faq)
- [Kontakt](#kontakt)

---

## Architektur-Ubersicht

```
  Dein Windows-Rechner
  +-------------------------------+
  | Hermes Agent (lokale Laufzeit)|   ← VERLASST NIEMALS deinen Rechner
  | Open WebUI (lokaler Container)|   ← VERLASST NIEMALS deinen Rechner
  | Dashboard (lokaler Container) |   ← VERLASST NIEMALS deinen Rechner
  | MySQL DB (lokaler Container)  |   ← VERLASST NIEMALS deinen Rechner
  | state.db (SQLite auf Platte)  |   ← VERLASST NIEMALS deinen Rechner
  | Cryptomator-Verschlusselung   |   ← Lokale Verschlusselungsschicht
  +-------------------------------+
            |
            |  NUR der LLM-API-Aufruf verlasst deinen Rechner
            v
  +-------------------------------+
  | KI-Provider DEINER Wahl       |
  | (Lokal / EU / USA / China)    |
  +-------------------------------+
```

**Kern-Erkenntnis:** Alles ausser dem LLM-API-Aufruf bleibt auf deinem Rechner. Dein Chat-Verlauf, dein Memory, deine Datenbank-Backups — alles lokal. Nur der Text deiner aktuellen Anfrage wird an den KI-Provider gesendet.

---

## Was bleibt lokal (immer)

| Komponente | Daten | Bleibt lokal? |
|-----------|-------|:------------:|
| Chat-Verlauf | Jede gesendete und empfangene Nachricht | ✅ JA |
| Hermes Memory | Fakten, die der Agent uber dich weiss | ✅ JA |
| Sessions & Messages | Vollstandiges Gesprachsarchiv | ✅ JA |
| MySQL-Backups | Dump aller Sessions, Messages, Memory | ✅ JA |
| Konfiguration | API-Keys, Modellnamen, Einstellungen | ✅ JA |
| Tool-Ausgaben | Terminal-Ergebnisse, Datei-Lesevorgange | ✅ JA |
| **Dein Prompt-Text** | Die Nachricht, die du an Hermes schickst | ⚠️ Wird an LLM-Provider gesendet |

**Die einzigen Daten, die deinen Rechner verlassen,** ist der Text deiner aktuellen Konversations-Anfrage, gesendet an den von dir gewahlten KI-Provider. Keine Metadaten, keine Logs, keine Datenbank-Dumps — nur der Prompt.

---

## Provider-Wahl & DSGVO-Auswirkungen

### Der Rechtliche Rahmen

Unter der **DSGVO (Datenschutz-Grundverordnung**, EU 2016/679) und dem osterreichischen **DSG (Datenschutzgesetz)** muss jede Verarbeitung personenbezogener Daten:

- Eine Rechtsgrundlage haben (Art. 6 DSGVO)
- Ein angemessenes Datenschutzniveau bei Drittlandtransfer gewahrleisten (Art. 44-49 DSGVO)
- Einen Auftragsverarbeitungsvertrag (**AVV**) mit dem Auftragsverarbeiter haben

**Deine Wahl des KI-Providers bestimmt, ob dein Setup DSGVO-konform ist.**

---

## Option 1: Lokales Modell (100 % Datenschutz)

Betreibe ein lokales LLM via **llama.cpp** oder **ollama**. Keine Daten verlassen jemals deinen Rechner.

**Anbieter:** ollama, llama.cpp, vLLM (lokal), LM Studio
**Modell-Beispiele:** Llama 4, DeepSeek V4 Flash (self-hosted), Mistral, Qwen

**Datenschutz:** MAXIMAL — kein Datentransfer.
**DSGVO:** Vollstandig konform. Kein Drittlandtransfer. Kein AVV notig.
**Kosten:** $0 pro Token (nur Strom).
**Hardware:** DeepSeek V4 Flash (284B, 13B aktiv) lauft auf Consumer-GPUs. Kleinere Modelle laufen auf CPU + RAM.

**Konfiguration:**
```batch
set "PROVIDER=custom"
set "MODEL=local-model-name"
set "CUSTOM_API_BASE=http://localhost:1234/v1"
```

**Nachteil:** Lokale Modelle sind bei komplexen Aufgaben weniger leistungsfahig als Cloud-Modelle.

---

## Option 2: EU-gehosteter Provider (DSGVO-konform)

Nutze einen europaischen KI-Provider. Deine Prompts verlassen deinen Rechner, aber nie die EU.

### Empfohlen: cortecs.ai

| Detail | Wert |
|--------|------|
| **Sitz** | Wien, Osterreich (EU) |
| **AVV** | Auf Anfrage verfugbar |
| **Datenstandort** | EU-Rechenzentren |
| **Verfugbare Modelle** | DeepSeek V4 Flash, Claude, GPT, Llama, Mistral und viele mehr |
| **API** | OpenAI-kompatibel — funktioniert 1:1 mit Hermes |
| **Preis (DeepSeek V4 Flash)** | ~$0.20 / $0.80 pro 1M Tokens (etwas teurer als direkt) |

**Konfiguration:**
```batch
set "PROVIDER=openrouter"
set "MODEL=deepseek/deepseek-v4-flash"
set "CUSTOM_API_BASE=https://api.cortecs.ai/v1"
```

Alternative EU-Provider:
- **DeepInfra** (US-Firma, aber EU-Rechenzentren verfugbar)
- **NovitaAI** (EU-Rechenzentren)

Alle bieten AVVs auf Anfrage an.

**DSGVO:** Konform mit unterschriebenem AVV. Daten bleiben in der EU.

---

## Option 3: Direkt-API (Budget-Wahl)

Direktverbindung zu einem Nicht-EU-Provider. Die gunstigste Option, aber Daten verlassen die EU.

### DeepSeek Direkt (China)

| Detail | Wert |
|--------|------|
| **Preis** | $0.10 / $0.20 pro 1M Tokens — **gunstigste Option** |
| **Cache-Hit** | $0.003 / 1M Tokens (98 % gunstiger) |
| **Datenstandort** | China |
| **AVV** | Nicht fur Privatnutzer verfugbar |
| **DSGVO-Status** | ⚠️ Nicht DSGVO-konform ohne zusatzliche Massnahmen |

**Beispiel monatliche Kosten:** Bei 100M Tokens/Monat (viel Nutzung) kostet DeepSeek V4 Flash ~$1.28. Vergleichbare GPT-5.5-Nutzung wurde ~$48.58 kosten — **97 % Ersparnis.**

**Konfiguration:**
```batch
set "PROVIDER=deepseek"
set "MODEL=deepseek-v4-flash"
```

### OpenRouter (USA)

| Detail | Wert |
|--------|------|
| **Preis** | Etwas hoher als direkt ($0.20 / $0.80) |
| **Datenstandort** | Abhangig vom Backend-Provider |
| **AVV** | Nicht fur den Free-Tier verfugbar |
| **DSGVO-Status** | Grauzone — Daten konnten durch die USA geleitet werden |

**Konfiguration:**
```batch
set "PROVIDER=openrouter"
set "MODEL=deepseek/deepseek-v4-flash"
```

---

## Vergleichstabelle

| Kriterium | Lokales Modell | EU-Provider (cortecs.ai) | Direkt-API (DeepSeek) |
|-----------|:-----------:|:------------------------:|:---------------------:|
| **Daten verlassen Rechner?** | ❌ Nie | ✅ Nur Prompts | ✅ Nur Prompts |
| **Daten verlassen EU?** | ❌ Nein | ❌ Nein | ✅ Ja (China) |
| **DSGVO-konform?** | ✅ Ja | ✅ Ja (mit AVV) | ⚠️ Eigenverantwortung |
| **AVV erforderlich?** | ❌ Nein | ✅ Ja (verfugbar) | ❌ Nicht verfugbar |
| **Kosten pro 1M Tokens** | $0 (Strom) | ~$0.20 / $0.80 | $0.10 / $0.20 |
| **Monatskosten (100M Tokens)** | $0 | ~$3.50 | ~$1.28 |
| **Modellqualitat** | Hardware-abhangig | Cloud-Niveau | Cloud-Niveau |
| **Internet erforderlich?** | ❌ Nein | ✅ Ja | ✅ Ja |
| **Setup-Komplexitat** | Mittel (lokales LLM) | Niedrig (nur API-Key) | Niedrig (nur API-Key) |

---

## Technische Datenschutzmassnahmen

Neben der Provider-Wahl bietet dieses Kit eingebaute Datenschutzfunktionen:

| Massnahme | Beschreibung |
|-----------|-------------|
| **Keine Telemetrie** | Hermes Agent hat kein Phone-Home, kein Tracking, keine Analyse. |
| **Kein Cloud-Speicher** | Alle Daten (Config, DB, Backups) bleiben auf deiner lokalen Festplatte. |
| **Docker-Isolation** | MySQL lauft im internen Docker-Netzwerk — nicht zum Host oder Internet exponiert. |
| **Cryptomator-Support** | Die Batch-Datei kann vor dem Start einen Cryptomator-Verschlusselungs-Tresor mounten. |
| **API-Key-Trennung** | Der API-Key deines LLM-Providers ist eine Umgebungsvariable, niemals hartcodiert. |
| **WSL2-Isolation** | Windows Subsystem for Linux bietet hardwarenahe Prozess-Isolation. |
| **Keine externen DNS-Lookups** | Nur ausgehende Verbindungen zu deinem KI-Provider. |
| **Datenminimierung** | Nur der aktuelle Gesprachskontext wird ans LLM gesendet — nicht die gesamte Datenbank. |

---

## Osterreichischer DSG-Kontext

Dieses Kit wurde von einem osterreichischen Unternehmen (**einfach-online.dev**) entwickelt und mit Blick auf das osterreichische DSG 2000 gestaltet:

- **DSG 6:** Datenminimierung — nur notwendige Daten werden verarbeitet
- **DSG 7:** Datensicherheit — technische Massnahmen wie oben beschrieben
- **DSG 12-13:** Betroffenenrechte — da alle Daten lokal sind, hast du vollstandige Kontrolle
- **DSG 34-35:** Datenschutzverletzungen — keine Daten beim Provider => nichts zu melden
- **AVV (& 7 DSG):** Erforderlich bei externem Auftragsverarbeiter — cortecs.ai stellt einen zur Verfugung

> **Empfehlung fur osterreichische Unternehmen:** Nutze ein lokales Modell (100 % DSGVO) oder cortecs.ai (EU-gehostet mit AVV). Direktes DeepSeek ist fur private Experimente geeignet, aber fur Kundendaten solltest du Option 1 oder 2 wahlen.

---

## FAQ

**F: Sendet Hermes selbst Daten irgendwohin?**
A: Nein. Hermes Agent ist vollstandig lokal. Es verbindet sich nur zum KI-Provider, um deinen Gesprachstext zur Verarbeitung zu senden.

**F: Kann ich sicher sein, dass keine Daten uber Hermes-Plugins abfliessen?**
A: Hermes-Plugins werden lokal ausgefuhrt. Kein Plugin hat Netzwerkzugriff, es sei denn, du hast explizit ein Tool wie `web_search` konfiguriert.

**F: Was ist mit der MySQL-Backup-Datei?**
A: Der `.sql`-Dump wird lokal erstellt und auf deiner lokalen Festplatte gespeichert. Du kontrollierst, wohin er geht.

**F: Kann ich meine Daten loschen?**
A: Ja. Losche die `state.db` und das `~/.hermes/`-Verzeichnis. Alles ist dort.

**F: Brauche ich ein VPN?**
A: Nicht aus Datenschutzgrunden — aber wenn du einen Nicht-EU-Provider verwendest, maskiert ein VPN deine IP.

**F: Ist dieses Setup DSGVO-konform fur mein Unternehmen?**
A: Das hangt von deiner Provider-Wahl ab und ob du einen AVV mit dem Provider hast. Siehe die [Vergleichstabelle](#vergleichstabelle) oben.

---

## Kontakt

<p align="center">
  <strong>Entwickelt von <a href="https://einfach-online.dev">einfach-online.dev</a></strong><br/>
  info@einfach-online.dev<br/>
  <em>Local First. Performance Driven. Privacy Centric.</em>
</p>

Datenschutz-Fragen? [Schreib mir eine E-Mail](mailto:info@einfach-online.dev).
