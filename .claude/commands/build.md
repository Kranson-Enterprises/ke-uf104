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
   `UNIFACE_HOME` at the real install root (this machine: `C:\ref`). It derives
   `IDE_EXE` and `UNIFACE_ADM` from that, and reads `UNIFACE_PROJECT` from
   `usys.ini [install] project=` (falling back to the in-repo `uniface\project`).
2. Run the build. `build.bat` calls `setup-env.bat` itself, so one command does
   it. Paths are quoted as whole tokens regardless (defensive — client installs
   often live under spaced paths even though this machine's `C:\ref` does not):
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
