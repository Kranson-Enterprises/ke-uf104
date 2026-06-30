---
description: Launch the Uniface 10 IDE with correctly quoted /adm and the project working dir
allowed-tools: Read, PowerShell, Bash
---

Launch the Uniface 10 IDE (a CEF/Chromium shell). Apply the workspace rule:
spaced paths MUST be quoted as whole tokens, or the IDE can't find `usys.ini` and
exits immediately (see [.claude/rules/quote-paths-with-spaces.md](../rules/quote-paths-with-spaces.md)
and worklog/002).

Steps:
1. Resolve paths. This machine's install root is `C:\ref` (space-free); confirm it
   exists, or read it from `usys.ini [install] root=` (strip the trailing
   `\common`). Older/default installs may live under
   `C:\Program Files\Rocket Uniface 10 Community Edition` (spaced — quote it).
   - exe = `<root>\common\bin\ide.exe`
   - adm = `<root>\uniface\adm`
   - Read `<root>\uniface\adm\usys.ini` `[install]` for `project=` (working dir)
     and note `urouter_port` / `tomcat_port` / `udbg_port`.
2. Launch with PowerShell, quoting the WHOLE `/adm` token and the working dir:
   ```
   Start-Process "<root>\common\bin\ide.exe" `
     -ArgumentList '"/adm=<root>\uniface\adm" ?' `
     -WorkingDirectory "<project>" -PassThru
   ```
   The trailing `?` opens the command-line dialog (mirrors Rocket's `IDE.lnk`).
3. Confirm `ide.exe` and its `cefrender` children are running; report the PIDs.

$ARGUMENTS may override the install root or add switches.
