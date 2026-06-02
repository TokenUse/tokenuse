# AGENTS.md - releases

## Folder Purpose

Published CLI release artifacts (platform `.tar.gz` tarballs + `checksums.txt`) referenced
by the install methods. Produced by the `tokenuse-cli` release pipeline.

## Local Rules

- Do not hand-edit artifacts or checksums; regenerate them via the release workflow.
- Keep `checksums.txt` in sync with the tarballs present here.
