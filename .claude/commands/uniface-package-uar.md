---
description: Package compiled Uniface objects into a deployable .uar (compile-to-UAR or urm), with verification
argument-hint: "[<uar name, default <project>.uar>] [--method=compile|urm] [--dir=<workdir>]"
allowed-tools: Read, PowerShell, Bash, Edit
---

Produce a deployable **Uniface Archive (`.uar`)** from compiled objects. Grounded in
[uniface-uar-packaging-and-hardening](../rules/uniface-uar-packaging-and-hardening.md)
and [worklog/023](../../worklog/023-uar-packaging-methodology-and-hardening.md). A `.uar`
is a ZIP of the compiled objects in Uniface's standardized type-subdirs (`svc/ frm/ sig/
edc/ …`).

Resolve exe/adm/workdir from `usys.ini [install]` (or `--dir`). Quote spaced paths as
whole tokens. **`ide.exe` is a GUI-subsystem exe → use `Start-Process -Wait -PassThru` and
read `.ExitCode`** (a bare `&` leaves `$LASTEXITCODE` blank; see
[/uniface-compile](uniface-compile.md)).

## Method A — compile directly to a UAR (default; clean from-source artifact)

1. In the workdir `.asn` `[SETTINGS]`, set `$RESOURCES_OUTPUT` to the target `.uar`.
   **⚠️ No trailing `;` inline comment on the value line** — `[SETTINGS]` swallows it into
   the path (*"Cannot create directory"*). Comment on its own line; value clean + ASCII.
   Back the asn up first; **revert it after** so config stays pristine.
   ```powershell
   Copy-Item "$dir\ide.asn" "$dir\ide.asn.bak" -Force
   # edit [SETTINGS]: $resources_output .\<Name>.uar   (own-line comments only)
   ```
2. Compile with the IDE **closed** (repo lock), from the workdir:
   ```powershell
   $p = Start-Process "<root>\common\bin\ide.exe" `
     -ArgumentList "/dir=$dir","/adm=<root>\uniface\adm","/all" `
     -WorkingDirectory $dir -Wait -PassThru -NoNewWindow `
     -RedirectStandardOutput "$env:TEMP\pkg.out" -RedirectStandardError "$env:TEMP\pkg.err"
   $p.ExitCode   # 0 = success
   ```
   (For production use `/all /nodebug`. Targeted: `/cpt`, `/frm MY*`, etc. — the UAR then
   contains only those types.) Read the message log under `usyslog:` on failure.
3. **Revert the asn** from the backup; remove the `.bak`.

## Method B — urm copy (no recompile; pack an existing resources folder)

```powershell
& "<root>\common\bin\urm.exe" copy "$dir\resources\*\*" "$dir\<Name>.uar:/*/*"
```
Use when objects are already compiled to a folder. `urm split` / `-after=YYYYMMDD` for
partial/incremental archives.

## Verify (always)

Confirm the archive exists and has the standardized structure:
```powershell
Add-Type -AssemblyName System.IO.Compression.FileSystem
$z=[System.IO.Compression.ZipFile]::OpenRead("$dir\<Name>.uar")
$z.Entries | Group-Object { ($_.FullName -split '/')[0] } | Select Name,Count
$z.Dispose()
```
Expect type-subdirs (`svc/ frm/ sig/ edc/ …`) and a non-trivial entry count.

## Release hardening (client deliverables only — not dev/skill-refresh)

- **`cert.exe`** — certify the UAR with a key pair (tamper protection). OpenSSL is in
  `<root>\common\bin`.
- **`pathscrambler.exe`** — encrypt asn secrets (`[ENCRYPTED_PATHS]`).
See [uniface-uar-packaging-and-hardening](../rules/uniface-uar-packaging-and-hardening.md).

For the WAS plugin sandbox specifically, use [/was-package](was-package.md) (wraps Method A
with the sandbox paths and auto-revert).
