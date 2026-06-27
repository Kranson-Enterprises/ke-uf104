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
- **The repository is the source of truth** — edit objects in the IDE; round-trip
  via XML Export/Import for version control; never use `/cpy` for definitions.
  [.claude/rules/uniface-repository-source-of-truth.md](.claude/rules/uniface-repository-source-of-truth.md).
- **Uniface CLI & build hygiene** — prefer the `/uniface-*` commands; resolve paths
  from `usys.ini [install]`; production compiles use `/all /nodebug`; check exit
  codes; migrate the repo before batch CLI.
  [.claude/rules/uniface-cli-and-build-hygiene.md](.claude/rules/uniface-cli-and-build-hygiene.md).
- **Keep secrets & proprietary content out of git** — no credentials in `.asn`;
  Rocket docs stay in gitignored `webfetched/`; scan `git status`/`diff` before
  committing. [.claude/rules/protect-secrets-and-proprietary.md](.claude/rules/protect-secrets-and-proprietary.md).
- **DSP web-component conventions** — the page layout is a repository object (never
  hand-edit generated `.dsp`/`dspjs` output); use the real `uniface` JS API
  (`getValue`/`setValue`, `activate`/`createInstance` Promises, `webactivate`);
  `OnChange` fires on interactive change only; author HTML5 and target evergreen
  browsers (ES2015 floor).
  [.claude/rules/uniface-dsp-web-conventions.md](.claude/rules/uniface-dsp-web-conventions.md).

## Conventions

- Reference files as clickable links, e.g. [build.bat](scripts/build.bat).
- Keep changes scoped; confirm before destructive or outward-facing actions.
