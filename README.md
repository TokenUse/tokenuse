# TokenUse CLI

![TokenUse brand banner](https://assets.tokenuse.ai/branding/readme-banner-v2.png)

[![npm version](https://img.shields.io/npm/v/tokenuse?label=npm)](https://www.npmjs.com/package/tokenuse)
[![Homebrew tap version](https://img.shields.io/badge/homebrew-v0.4.4-fbb040?logo=homebrew&logoColor=white)](https://github.com/tokenuse/homebrew-tap/blob/main/Formula/tokenuse.rb)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue)](LICENSE)
![Platform: macOS and Linux](https://img.shields.io/badge/platform-macOS%20%7C%20Linux-24292f)

Track and analyze Claude Code and OpenAI Codex usage and costs.

![TokenUse dashboard preview](https://assets.tokenuse.ai/branding/readme-dashboard-v1.png)

## Installation

### Homebrew (macOS/Linux)

```bash
brew tap tokenuse/tap
brew install tokenuse
```

### npm/npx

```bash
npx tokenuse@latest
# or
npm install -g tokenuse@latest
# verify
tokenuse version
```

### curl (macOS/Linux)

```bash
curl -fsSL https://raw.githubusercontent.com/tokenuse/tokenuse/main/install.sh | bash
```

## Upgrade

```bash
# curl installs
curl -fsSL https://raw.githubusercontent.com/tokenuse/tokenuse/main/install.sh | bash

# Homebrew installs
brew upgrade tokenuse

# npm installs
npm install -g tokenuse@latest
```

## Usage

```bash
# Login and start tracking
tokenuse login

# Check status
tokenuse status

# Sign out
tokenuse logout
```

## Uninstall

Run the TokenUse uninstall command before removing a brew, npm, or curl install:

```bash
tokenuse uninstall
```

This stops and removes the background tracker service, removes the managed daemon binary, and asks whether to delete local TokenUse data such as config, credentials, queued events, prompts, cursors, cache, and logs. Use `tokenuse uninstall --purge` to remove local data without prompting, or `tokenuse uninstall --keep-data` to stop the tracker while keeping local data.

If your installed version does not have `tokenuse uninstall`, run `tokenuse logout` first and type `delete` when prompted, then remove the package with brew, npm, or your install method.

Manual fallback paths:

- `~/Library/LaunchAgents/ai.tokenuse.tracker.plist` on macOS
- `~/.config/systemd/user/tokenuse-tracker.service` on Linux
- `~/.local/share/tokenuse/bin/tokenuse`
- `~/.config/tokenuse/`
- `~/.local/share/tokenuse/`
- `~/.cache/tokenuse/`

## Privacy

TokenUse tracks usage metadata and, **on by default**, the text of the prompts you run and the paths they ran in, to power per-prompt analytics. Detected secrets are scrubbed on a best-effort basis before upload; prompts are retained per your retention setting and deleted on request. We never collect model responses or your file contents. Turn prompt capture off anytime with `tokenuse config set prompts.enabled=false` or in the dashboard under Settings → Data.

## Documentation

Visit the [documentation](https://tokenuse.ai/docs) for full details.

Release notes are published at [TokenUse Releases](https://github.com/tokenuse/tokenuse/releases).

## Support

- Website: [tokenuse.ai](https://tokenuse.ai)
- Security: [SECURITY.md](SECURITY.md)
- Email: support@tokenuse.ai
