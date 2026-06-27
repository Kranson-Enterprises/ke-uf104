---
description: Review a Uniface .asn for development-vs-production readiness
argument-hint: "[path to .asn] (default: scan project + uniface\\adm)"
allowed-tools: Read, Glob, Grep
---

Review the given `.asn` (or all in scope) against the dev→prod checklist from
worklog/004 §5. Report findings as a table: **setting → current → recommendation**.

Check:
- **Debuggable compiles** — `$NO_DEBUG` should be `1` for prod; compile with `/nodebug`.
- **`$test_mode_components`** — must be **removed** in prod (perf killer).
- **DBMS** — real connector in `[DRIVER_SETTINGS]` / `[PATHS]`; credentials **not**
  inline.
- **`[NET_SETTINGS]`** — TLS via `CERT_PROFILE` for prod; real Router host/port.
- **`[RESOURCES]`** — packaged read-only **UAR** vs dev `.\resources`.
- **Logging** — managed `$PUTMESS_LOGFILE` path; no secrets in logs.
- **Licensing** — Enterprise file/central vs CE cloud (Sentinel).
- **Secrets** — no DB passwords / certs committed; inject at deploy
  (`pathscrambler.exe` to obscure values in `.asn`).

Always quote spaced paths in any commands you run. $ARGUMENTS = the `.asn` to review.
