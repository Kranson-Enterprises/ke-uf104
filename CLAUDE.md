# CLAUDE.md

Project guidance for Claude Code in the **Uniface 10** workspace (`ke-uf104`).
This file is committed and loaded automatically at the start of every session.

## Project overview

- Scaffold for a Uniface 10 project on **Windows**.
- `components/` — Uniface components (`*.com`).
- `src/` — sources.
- `scripts/` — build/env batch scripts (`setup-env.bat`, `build.bat`).
- `docs/` — documentation.
- `worklog/` — running work notes.
- CI: `.github/workflows/ci.yml` runs `scripts/setup-env.bat` then `scripts/build.bat` on Windows runners.

## Environment notes

- Shell is PowerShell; a Bash (POSIX) tool is also available. Build/CI scripts are Windows `.bat`.
- Configure the Uniface installation path in `scripts/setup-env.bat` before building.

## Project memory (local, not committed)

Personal/project memories live in [.claude/memory/](.claude/memory/) and are
**gitignored** (they stay on this machine only). At the start of a session,
read [.claude/memory/INDEX.md](.claude/memory/INDEX.md) if it exists — it lists
every saved memory with a one-line hook. See
[.claude/memory/README.md](.claude/memory/README.md) for the format.

## Rules (always apply)

- **Quote paths that contain spaces** in every shell command, argument, script,
  and doc example. The Uniface install path has spaces, so this is mandatory.
  Full rule: [.claude/rules/quote-paths-with-spaces.md](.claude/rules/quote-paths-with-spaces.md).

## Conventions

- Reference files as clickable links, e.g. [build.bat](scripts/build.bat).
- Keep changes scoped; confirm before destructive or outward-facing actions.
