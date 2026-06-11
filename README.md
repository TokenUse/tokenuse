# TokenUse CLI

Track and analyze Claude Code and Codex usage.

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

Visit the [documentation](https://github.com/tokenuse/tokenuse-cli#readme) for full details.

## Support

- Website: [tokenuse.ai](https://tokenuse.ai)
- Email: support@tokenuse.ai
