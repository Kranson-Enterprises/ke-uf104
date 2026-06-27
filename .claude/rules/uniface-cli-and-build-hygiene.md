# Rule: Uniface CLI & build hygiene

**Scope:** Any command-line invocation of Uniface (`ide`/`uniface`/`urouter`/
`userver`/`udbg`) — compile, import, DDL — and any deployment build.

## Rule

- **Prefer the project command suite** ([.claude/commands/](../commands/):
  `/uniface-compile`, `/uniface-import`, `/uniface-export`, `/uniface-gensql`,
  `/uniface-launch-ide`, `/uniface-asn-review`, `/uniface-cli`) for repeatable
  tasks instead of ad-hoc command lines.
- **Resolve paths from `usys.ini [install]`** (project dir, `urouter_port`,
  `tomcat_port`, `udbg_port`). Do **not** hardcode a user directory.
- **Quote spaced paths** as whole tokens (see
  [quote-paths-with-spaces.md](quote-paths-with-spaces.md)).
- **Production compiles use `/all /nodebug`** (non-debuggable). For a production
  assignment, set `$NO_DEBUG = 1` and **remove `$test_mode_components`**. Keep
  debuggable builds for dev only.
- **Always check exit codes** — `/imp` and the compile switches return `0`
  (success) / `1` (failure). Gate scripts/CI on them.
- **Migrate first:** CLI execution **fails if the Repository is unmigrated or an
  incompatible version** — run an interactive IDE session once to migrate before
  batch CLI.
- Compiled output is packaged as **UAR**; generate target-DBMS schema with
  `/genSql` (e.g. SQLite-dev → Oracle/SQL-Server-prod).

## Why

Prevents the common failures we hit or could hit: shipping debuggable/test-mode
builds, silent CLI failures, the unmigrated-repository abort, and re-deriving the
correct quoted invocation each time.

## How to apply

Reach for a `/uniface-*` command first; if scripting directly, mirror its shape.
Reference: [docs/uniface-10-onboarding.md](../../docs/uniface-10-onboarding.md)
§3.5 and [worklog/006](../../worklog/006-cli-usage-and-claude-command-suite.md).
