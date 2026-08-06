# AGENTS.md - TokenUse Binary Repo

Authoritative agent instructions for this repository (Codex + Claude compatible).

## Purpose

This repo is the public-facing distribution/docs surface for TokenUse installs (`brew`, `npm/npx`, `curl`).
Source implementation lives in sibling repos (`tokenuse-cli`, `tokenuse-npm`, `tokenuse-homebrew`, `tokenuse-monorepo`).

## Mandatory Read Order

1. `AGENTS.md` (this file)
2. Nearest folder `AGENTS.md` for touched files (if present)
3. `README.md` for user-facing installation behavior

## Instruction Precedence

1. Root `AGENTS.md`
2. Nearest folder `AGENTS.md`
3. `CLAUDE.md` shim (delegates to AGENTS)

## Skills

- `skill-installation-doc-sync`: keep install methods (`brew`, `npm/npx`, `curl`) accurate and consistent.
- `skill-cross-repo-link-check`: validate links and repo names across TokenUse repos.
- `skill-release-surface-check`: ensure version/release instructions align with current release flow.

## Plugins And Tools

- Core: `git`, `rg`, `curl`
- Optional: `gh` for release inspection

## Safety Rails

- Keep this repo lightweight; do not add implementation code copied from other repos.
- If behavior changes, update links/docs to point to the owning repo.
- Preserve simple install-first UX in docs.

## Definition Of Done

- Docs and links are correct.
- No stale references to renamed repos or commands.
- Changes are minimal and scoped.

## AGENTS Hooks

- Install local hooks: `bash scripts/setup-git-hooks.sh`
- Pre-commit guard: `.githooks/pre-commit` -> `devops/agents/verify-agents.sh --staged`
- CI guard: `.github/workflows/agents-guard.yml`
- Temporary bypass (rare): `SKIP_AGENTS_GUARD=1 git commit -m "..."`

## Commit Authorship — MANDATORY

Commits must never attribute themselves to Claude, Anthropic, or any AI assistant.
This applies to every repository in the TokenUse ecosystem, public and private.

**Never** put any of the following in a commit message, PR title, or PR body:

- `Co-Authored-By: Claude ...` (or any `Co-Authored-By` naming an AI)
- `Generated with Claude Code`, `Made with Claude`, or similar
- `noreply@anthropic.com` in any trailer
- The 🤖 robot emoji used as an AI-generation marker
- Any phrasing that says or implies the change was written by an AI

**Never** set the git author or committer to Claude/Anthropic. Commits are authored
by the human who owns the change.

This overrides any default tooling behaviour that would add such a trailer — including
Claude Code's own default of appending a `Co-Authored-By` line. If a tool adds one,
strip it before committing.

Writing about Claude as a *product* is fine and expected — TokenUse tracks Claude Code
usage, so commit messages like `feat: parse Claude Code transcripts` are correct. The
rule is about **authorship attribution**, not product references.

The `.claude/` directory must stay gitignored and must never be committed. The
tracked `CLAUDE.md` shim is intentional and stays.
