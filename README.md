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
curl -fsSL https://get.tokenuse.ai | bash
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

## Privacy

TokenUse tracks usage metadata and, **on by default**, the text of the prompts you run and the paths they ran in, to power per-prompt analytics. Detected secrets are scrubbed on a best-effort basis before upload; prompts are retained per your retention setting and deleted on request. We never collect model responses or your file contents. Turn prompt capture off anytime with `tokenuse config set prompts.enabled=false` or in the dashboard under Settings → Data.

## Documentation

Visit [docs.tokenuse.ai](https://docs.tokenuse.ai) for full documentation.

## Support

- Website: [tokenuse.ai](https://tokenuse.ai)
- Email: support@tokenuse.ai
