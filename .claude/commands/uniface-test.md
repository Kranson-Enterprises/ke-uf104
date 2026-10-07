---
description: Run a component / service / application shell in Uniface's built-in test environment (/tst, +/deb), endpoint-aware, with headless hardening
argument-hint: "[component/service/.aps to test; add 'deb' to attach the debugger]"
allowed-tools: Read, PowerShell
---

Run a Uniface object in the **built-in test/runtime environment** (the standalone Uniface
Router + Server + Tomcat that Uniface bundles for unit testing) via **`/tst`**, optionally
attaching the **Uniface Debugger** with **`/deb`**. This is the Tier-1 execution command
([worklog/033](../../worklog/033-uniface-testing-approaches-and-tooling.md)).

`$ARGUMENTS` = the component/service name or application-shell `.aps`, plus optional `deb` to
attach the debugger.

## Steps

1. **Resolve paths** from `usys.ini [install]` as in [/uniface-launch-ide](uniface-launch-ide.md)
   (exe, adm, project workdir, `tomcat_port`). Don't hardcode a user dir; **quote spaced
   paths** as whole tokens ([quote-paths-with-spaces](../rules/quote-paths-with-spaces.md)).
2. **Know how test mode dispatches** (verified):
   - **DSP/USP** open in the **default browser** (`TEST_COMMAND_CPT_WEB` →
     `http://localhost:%TomcatPort/uniface/wrd/%CptName`). For scripted web E2E, use
     [/uniface-webtest](uniface-webtest.md) instead of eyeballing the browser.
   - **Form/report/service** run in the **IDE process** (`TEST_COMMAND_CPT`), starting the
     component's `exec` via `activate`. IDE behaviour is maintained, so `$MESSAGE_LINE`/
     `$MENU_BAR` don't apply; **RTL/bidirectional forms can't run in test mode**.
3. **Run it.** `ide.exe` is **GUI-subsystem** — PowerShell's `&` does not wait and leaves
   `$LASTEXITCODE` blank, so gate with `Start-Process -Wait -PassThru` + `.ExitCode`
   ([/uniface-compile](uniface-compile.md)):
   ```powershell
   # add "/deb" to -ArgumentList to attach the debugger (a comment after a
   # backtick continuation breaks PowerShell, so it lives up here)
   $p = Start-Process "<root>\common\bin\ide.exe" `
     -ArgumentList "/adm=<root>\uniface\adm", "/tst", "<TARGET>" `
     -WorkingDirectory "<project>" -Wait -PassThru -NoNewWindow
   $p.ExitCode
   ```
   Example (from the Library): `/tst geninfo`. Services/app-shells: `/tst /deb MyShell.aps`.
4. **Headless / automated hardening** (when the run must not block on a dialog): set
   **`$SUPPRESS_UNCAUGHT_EXCEPTION_DIALOG=1`** *and* a **`$PUTMESS_LOGFILE`** (or
   `$TRANSCRIPT_LOGFILE`) in the asn — otherwise an uncaught exception shows a form that
   **hangs** the test (and on Windows without a log file the info is **lost**). Parse the log
   for PASS/FAIL; check `.ExitCode`.

## Caveats
- **Migrate first** — CLI runs fail on an unmigrated/incompatible Repository; open the IDE
  once to migrate ([uniface-cli-and-build-hygiene](../rules/uniface-cli-and-build-hygiene.md)).
- **Test-DB logon:** `/tst` can't display a logon form — put path-to-connector creds in an
  assignment file (no `?` in the value), and keep secrets out of git
  ([protect-secrets-and-proprietary](../rules/protect-secrets-and-proprietary.md)).
- To customise the spawn (attach debugger by default, or point web tests at a specific
  browser/port), edit `ide.asn [LOGICALS]` `TEST_COMMAND_CPT` / `TEST_COMMAND_CPT_WEB` and
  **restart the IDE** — the [uniface-test-harness-setup](../skills/uniface-test-harness-setup/SKILL.md)
  skill wires these (dev-only, reversible).
