# Privacy & Data Protection — Hermes Agent Deployment Kit

> **Language:** English — [Deutsche Version](PRIVACY.de.md)

This document explains where your data lives, where it goes, and what privacy guarantees you get depending on your provider choice.

---

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [What Stays Local (Always)](#what-stays-local-always)
- [Provider Choice & DSGVO/GDPR Implications](#provider-choice--dsgvogdpr-implications)
- [Option 1: Local Model (100 % Privacy)](#option-1-local-model-100--privacy)
- [Option 2: EU-Hosted Provider (DSGVO Compliant)](#option-2-eu-hosted-provider-dsgvo-compliant)
- [Option 3: Direct API (Budget Choice)](#option-3-direct-api-budget-choice)
- [Comparison Table](#comparison-table)
- [Technical Privacy Measures](#technical-privacy-measures)
- [Austrian Data Protection (DSG) Context](#austrian-data-protection-dsg-context)
- [FAQ](#faq)
- [Contact](#contact)

---

## Architecture Overview

``` 
  Your Windows Machine
  +-------------------------------+
  | Hermes Agent (local runtime)  |   ← NEVER leaves your machine
  | Dashboard (local container)   |   ← NEVER leaves your machine
  | MySQL DB (local container)    |   ← NEVER leaves your machine
  | state.db (SQLite on disk)     |   ← NEVER leaves your machine
  | Cryptomator encryption        |   ← Local encryption layer
  +-------------------------------+
            |
            |  ONLY the LLM API call leaves your machine
            v
  +-------------------------------+
  | AI Provider of YOUR choice    |
  | (Local / EU / USA / China)    |
  +-------------------------------+
```

**Key insight:** Everything except the LLM API call stays on your machine. Your chat history, your memory, your database backups — all local. Only the text of your prompt (and the last few messages for context) is sent to the AI provider.

---

## What Stays Local (Always)

| Component | Data | Stays Local? |
|-----------|------|:------------:|
| Chat history | Every message you send and receive | ✅ YES |
| Hermes memory | Facts the agent remembers about you | ✅ YES |
| Sessions & messages database | Full conversation archive | ✅ YES |
| MySQL backups | Dump of all sessions, messages, memory | ✅ YES |
| Configuration | API keys, model names, user preferences | ✅ YES |
| Tools output | Terminal results, file reads, web searches | ✅ YES |
| **Your prompt text** | The message you type to Hermes | ⚠️ Sent to LLM provider |

**The only data that leaves your machine** is the text of your current conversation prompt, sent to the AI provider you chose. No metadata, no logs, no database dumps — just the prompt.

---

## Provider Choice & DSGVO/GDPR Implications

### The Legal Framework

Under the **GDPR (General Data Protection Regulation**, EU 2016/679) and the Austrian **DSG (Datenschutzgesetz)**, any processing of personal data must have:
- A legal basis (Art. 6 GDPR)
- An appropriate level of data protection (Art. 44-49 GDPR for third-country transfers)
- A Data Processing Agreement (DPA / **Auftragsverarbeitungsvertrag, AVV**) with the processor

**Your choice of AI provider determines whether your setup is GDPR-compliant.**

---

## Option 1: Local Model (100 % Privacy)

Run a local LLM via **llama.cpp** or **ollama**. No data ever leaves your machine.

**Providers:** ollama, llama.cpp, vLLM (local), LM Studio
**Model examples:** Llama 4, DeepSeek V4 Flash (self-hosted), Mistral, Qwen

**Privacy level:** MAXIMUM — no data transfer at all.
**GDPR:** Fully compliant. No third-country transfer. No DPA needed.
**Cost:** $0 per token (electricity only).
**Hardware:** DeepSeek V4 Flash (284B, 13B active) runs on consumer GPUs. Smaller models run on CPU + RAM.

**How to configure:**
```batch
set "PROVIDER=custom"
set "MODEL=local-model-name"
set "CUSTOM_API_BASE=http://localhost:1234/v1"
```
Then set your local model server as the Hermes API endpoint via `CUSTOM_API_BASE`.

**Downside:** Local models are less capable than cloud models for complex reasoning tasks.

---

## Option 2: EU-Hosted Provider (DSGVO Compliant)

Use a European AI provider. Your prompts leave your machine but never leave the EU.

### Recommended: cortecs.ai

| Detail | Value |
|--------|-------|
| **Headquarters** | Vienna, Austria (EU) |
| **DPA / AVV** | Available on request |
| **Data location** | EU data centers |
| **Models available** | DeepSeek V4 Flash, Claude, GPT, Llama, Mistral, and many more |
| **API** | OpenAI-compatible — works 1:1 with Hermes |
| **Price (DeepSeek V4 Flash)** | ~$0.20 / $0.80 per 1M tokens (slightly higher than direct) |

**How to configure:**
```batch
set "PROVIDER=openrouter"
set "MODEL=deepseek/deepseek-v4-flash"
set "CUSTOM_API_BASE=https://api.cortecs.ai/v1"
```

Alternative EU providers:
- **DeepInfra** (US company, EU data centers available)
- **NovitaAI** (EU data centers)
- **Leap** (EU-based)

All of these offer DPAs on request.

**GDPR:** Compliant with a signed DPA / AVV. Data stays within the EU.

---

## Option 3: Direct API (Budget Choice)

Connect directly to a non-EU provider. Cheapest option, but data leaves the EU.

### DeepSeek Direct (China)

| Detail | Value |
|--------|-------|
| **Price** | $0.10 / $0.20 per 1M tokens — **cheapest option** |
| **Cache hit** | $0.003 / 1M tokens (98 % cheaper) |
| **Data location** | China |
| **DPA** | Not available for private users |
| **GDPR status** | ⚠️ Not GDPR-compliant without additional measures |

**Example monthly cost:** At 100M tokens/month (heavy usage), DeepSeek V4 Flash costs ~$1.28. Equivalent GPT-5.5 usage would cost ~$48.58 — **97 % savings.**

**How to configure:**
```batch
set "PROVIDER=deepseek"
set "MODEL=deepseek-v4-flash"
```

### OpenRouter (USA)

| Detail | Value |
|--------|-------|
| **Price** | Slightly higher than direct ($0.20 / $0.80) |
| **Data location** | Depends on backend provider |
| **DPA** | Not available for free tier |
| **GDPR status** | Grey zone — data may transit through the US |

**How to configure:**
```batch
set "PROVIDER=openrouter"
set "MODEL=deepseek/deepseek-v4-flash"
```

---

## Comparison Table

| Criterion | Local Model | EU Provider (cortecs.ai) | Direct API (DeepSeek) |
|-----------|:-----------:|:------------------------:|:---------------------:|
| **Data leaves your machine?** | ❌ Never | ✅ Only prompts | ✅ Only prompts |
| **Data leaves the EU?** | ❌ No | ❌ No | ✅ Yes (China) |
| **GDPR/DSGVO compliant?** | ✅ Yes | ✅ Yes (with DPA) | ⚠️ User responsibility |
| **DPA / AVV required?** | ❌ No | ✅ Yes (available) | ❌ Not available |
| **Cost per 1M tokens** | $0 (electricity) | ~$0.20 / $0.80 | $0.10 / $0.20 |
| **Monthly cost (100M tokens)** | $0 | ~$3.50 | ~$1.28 |
| **Model quality** | Limited by hardware | Cloud-grade | Cloud-grade |
| **Internet required?** | ❌ No | ✅ Yes | ✅ Yes |
| **Setup complexity** | Medium (local LLM) | Low (API key only) | Low (API key only) |

---

## Technical Privacy Measures

Beyond provider choice, this kit includes built-in privacy features:

| Measure | Description |
|---------|-------------|
| **No telemetry** | Hermes Agent has no phone-home, no tracking, no analytics. |
| **No cloud storage** | All data (config, DB, backups) stays on your local disk. |
| **Docker isolation** | MySQL runs on an internal Docker network — not exposed to the host or internet. |
| **Cryptomator support** | The batch file can mount a Cryptomator encrypted vault before starting services. |
| **API key separation** | Your LLM provider's API key is an environment variable, never hardcoded in scripts. |
| **WSL2 isolation** | Windows Subsystem for Linux provides hardware-level process isolation. |
| **No external DNS lookups** | Only outbound connections are to your AI provider's API endpoint. |
| **Data minimization** | Only the current conversation context is sent to the LLM — not the full database. |

---

## Austrian Data Protection (DSG) Context

This kit was built by an Austrian company (**einfach-online.dev**) and is designed with the Austrian DSG 2000 in mind:

- **DSG 6:** Data minimization — only necessary data is processed
- **DSG 7:** Data security — technical measures described above
- **DSG 12-13:** Data subject rights — since all data is local, you have full control
- **DSG 34-35:** Data breach notification — no data at the provider means nothing to breach
- **AVV (§ 7 DSG):** Required when using an external processor — cortecs.ai provides one

> **Recommendation for Austrian businesses:** Use a local model (100 % DSGVO) or cortecs.ai (EU-hosted with DPA). Direct DeepSeek is suitable for private experimentation, but for client data you should use Option 1 or 2.

---

## FAQ

**Q: Does Hermes itself send data anywhere?**
A: No. Hermes Agent is fully local. It only connects to the AI provider to send your conversation text for processing.

**Q: Can I be sure no data leaks via Hermes plugins?**
A: Hermes plugins execute locally. No plugin has network access unless you explicitly configured a tool like `web_search`.

**Q: What about the MySQL backup file?**
A: The `.sql` dump is generated locally and saved to your local disk. You control where it goes.

**Q: Can I delete my data?**
A: Yes. Delete the `state.db` and `~/.hermes/` directory. Everything is there.

**Q: Do I need a VPN?**
A: Not for privacy reasons — but if you're using a non-EU provider, a VPN masks your IP.

**Q: Is this setup DSGVO-compliant for my company?**
A: It depends on your provider choice and whether you have a DPA/AVV with them. See the [comparison table](#comparison-table) above.

---

## Contact

<p align="center">
  <strong>Built by <a href="https://einfach-online.dev">einfach-online.dev</a></strong><br/>
  info@einfach-online.dev<br/>
  <em>Local First. Performance Driven. Privacy Centric.</em>
</p>

Privacy questions? [Send me an email](mailto:info@einfach-online.dev).
