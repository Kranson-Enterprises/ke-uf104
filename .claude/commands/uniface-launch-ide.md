---
description: Launch the Uniface 10 IDE with correctly quoted /adm and the project working dir (add --was for the WorkArea plugin)
allowed-tools: Read, PowerShell, Bash
---

Launch the Uniface 10 IDE (a CEF/Chromium shell). Apply the workspace rule:
spaced paths MUST be quoted as whole tokens, or the IDE can't find `usys.ini` and
exits immediately (see [.claude/rules/quote-paths-with-spaces.md](../rules/quote-paths-with-spaces.md)
and worklog/002).

## Mode selection (read `$ARGUMENTS` first)

- **Default (no flag):** launch the MYPROJECT IDE — the numbered steps below.
- **`--was`** → **WAS plugin sandbox build launch** (Stage 1, Phase A of the WorkArea
  plugin integration — see [docs/uniface-was-plugin-integration.md](../../docs/uniface-was-plugin-integration.md)
  and [worklog/021](../../worklog/021-was-plugin-discovery-integration.md)). Use the
  **`--was` steps** at the bottom instead of the default steps. This launches the IDE
  into the cloned `IdePlugin\` sandbox so its **own** repository is created/migrated at
  `IdePlugin\dbms\usys.db` — isolated from MYPROJECT because `dbms.asn` resolves the repo
  as the working-dir-relative `.\dbms\usys.db`.

## Default steps (MYPROJECT)
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

## `--was` steps (WorkArea plugin sandbox — Phase A)

Precondition: the clone exists at `C:\Users\Bob\source\uniface\WASListener` with an
`IdePlugin\` folder holding its own `ide.asn`, `dbms\`, and `WorkArea\`. The sandbox
`ide.asn` chains the install's via `#file usysadm:ide.asn` and sets `.\resources`.

1. Resolve + verify (quote everything defensively — none of these have spaces on this
   machine, but client installs do):
   - exe  = `C:\ref\common\bin\ide.exe`
   - adm  = `C:\ref\uniface\adm`
   - sandbox = `C:\Users\Bob\source\uniface\WASListener\IdePlugin`
   - Confirm exe, adm, and the sandbox all exist. Confirm `IdePlugin\dbms\usys.db`
     does **not** yet exist (Phase A creates it) — if it already exists, the repo was
     already migrated; skip to Phase B/C.
2. Launch into the sandbox with `/dir=` **and** a matching working dir, so the
   working-dir `ide.asn`, `.\dbms`, and `.\resources` all resolve inside `IdePlugin\`:
   ```
   Start-Process "C:\ref\common\bin\ide.exe" `
     -ArgumentList '"/dir=C:\Users\Bob\source\uniface\WASListener\IdePlugin" "/adm=C:\ref\uniface\adm" ?' `
     -WorkingDirectory "C:\Users\Bob\source\uniface\WASListener\IdePlugin" -PassThru
   ```
   The trailing `?` opens the command-line dialog (mirrors Rocket's `IDE.lnk`). A
   `.\resources` not-found warning is **expected** pre-compile — ignore it.
3. Confirm `ide.exe` + `cefrender` children are running; report PIDs.
4. Hand off to the operator: the IDE will prompt to **create & migrate** the sandbox
   repository — accept it. When `IdePlugin\dbms\usys.db` appears, Phase A is done and
   Phase B (batch `/imp` of the 178 `IdePlugin\WorkArea\**\*.xml`, order
   ent → lib\* → cpt → aps → prj) can start.

⚠️ Open item: exact asn-selection precedence for this install (working-dir `ide.asn`
vs `/adm`) — confirmed working via the sandbox's chained `ide.asn`; revisit if the
plugin resources don't load in Stage 2. A future **`--was-project`** mode will launch
MYPROJECT with a project-local was-enabled asn (Stage 2 wiring).
