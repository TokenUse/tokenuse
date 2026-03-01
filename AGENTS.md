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
