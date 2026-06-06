# Security Policy

## Supported Versions

This project is currently in active development. Security updates are provided for the latest version on the `main` branch.

| Version | Supported |
|---------|-----------|
| main (latest) | ✅ Active |
| Older releases | ❌ Not supported |

## Reporting a Vulnerability

We take security seriously. If you discover a security vulnerability, please report it privately before disclosing it publicly.

**Contact:** **info@einfach-online.dev**

Please include:
- A description of the vulnerability
- Steps to reproduce
- Potential impact
- Any suggested fixes (optional)

### What to expect

- **Acknowledgment:** within 48 hours
- **Initial assessment:** within 5 business days
- **Fix timeline:** depends on severity, typically 7-30 days
- **Disclosure:** after a fix is released

## Security Considerations

This deployment kit runs AI agents on your local machine. Key security notes:

- **API keys** are stored in the batch file — keep it secure
- **Network exposure**: Hermes Dashboard and API Server bind to `localhost` by default
- **MySQL** runs in a Docker container with a password you choose
- **Third-party models**: conversation data leaves your machine only when sent to your chosen LLM provider
- **Docker containers** run with `unless-stopped` restart policy

For privacy details, see [PRIVACY.md](PRIVACY.md).
