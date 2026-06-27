---
description: Build the Uniface project via the batch scripts (CLI compile -> UAR)
argument-hint: "[compile switches, e.g. '/cpt' or '/svc *VAL'] — default '/all /nodebug'"
allowed-tools: PowerShell, Read
---

Build the Uniface 10 project by running the batch wrappers in `scripts/`, which
drive `ide.exe` (a **production** `/all /nodebug` compile by default). For an
ad-hoc compile without the scripts, use [/uniface-compile](uniface-compile.md).

Steps:
1. Confirm [scripts/setup-env.bat](../../scripts/setup-env.bat) points
   `UNIFACE_HOME` at the real install root (CE default:
   `C:\Program Files\Rocket Uniface 10 Community Edition`). It derives
   `IDE_EXE`, `UNIFACE_ADM`, and `UNIFACE_PROJECT` from that.
2. Run the build. `build.bat` calls `setup-env.bat` itself, so one command does
   it (the script path has no spaces; the install paths it uses do, and the
   scripts quote those as whole tokens):
   ```
   & ".\scripts\build.bat" $ARGUMENTS
   ```
3. Check `$LASTEXITCODE` and summarize success/failure, surfacing any compiler
   errors from the output.

Caveats:
- `$ARGUMENTS` overrides the compile switches (default `/all /nodebug`).
- CLI compile FAILS if the Repository is unmigrated/incompatible — open the
  interactive IDE once to migrate first (worklog/006).
- If no Uniface install is configured, the scripts skip gracefully (exit 0) so
  CI stays green on runners without Uniface.
- Output lands in the project resources dir, packaged as **UAR**.
