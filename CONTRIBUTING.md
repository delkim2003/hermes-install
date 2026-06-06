# Contributing to Hermes Agent Deployment Kit

Thank you for your interest in contributing! This project is maintained by [einfach-online.dev](https://einfach-online.dev).

## How to Contribute

### Reporting Issues

1. Check if the issue already exists in [GitHub Issues](https://github.com/delkim2003/hermes-install/issues)
2. If not, create a new issue with:
   - A clear title and description
   - Steps to reproduce (if applicable)
   - Your environment (Windows version, Docker version)
   - Screenshots or logs if helpful

### Suggesting Enhancements

Open an issue with the label `enhancement` and describe:
- What you'd like to see added or changed
- Why it would be useful
- Any implementation ideas

### Pull Requests

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/your-feature`)
3. Make your changes
4. Test your changes locally
5. Commit with a clear message (`git commit -m "feat: add your feature"`)
6. Push to your fork (`git push origin feature/your-feature`)
7. Open a Pull Request

## Development Setup

1. Clone the repo: `git clone https://github.com/delkim2003/hermes-install.git`
2. Edit `hermes_start.bat` to configure your API key and model
3. Run `hermes_start.bat` to test

## Code Style

- Keep batch scripts readable with clear section headers
- Document configuration variables with inline comments
- Use `setlocal enabledelayedexpansion` for variable safety
- Markdown files should use English (add `.de.md` for German versions)

## License

By contributing, you agree that your contributions will be licensed under the Apache License, Version 2.0.
