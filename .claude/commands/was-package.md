---
description: "WAS plugin: build IdePlugin\\VersionControl.uar via compile-to-UAR, with automatic asn backup/revert and verification"
allowed-tools: Read, PowerShell, Bash, Edit
---

**WAS-specific** (not a default). Packages the Work Area Support IDE plugin into
`IdePlugin\VersionControl.uar` using **Method A (compile directly to a UAR)** — the exact,
verified flow from [worklog/023](../../worklog/023-uar-packaging-methodology-and-hardening.md).
Wraps the general [/uniface-package-uar](uniface-package-uar.md) with the sandbox paths and
a safe backup→build→revert cycle. Prereq: the sandbox repo is built and sources imported
(Phases A–B; see [/was-build](was-build.md)).

Fixed paths (this install): exe `C:\ref\common\bin\ide.exe`, adm `C:\ref\uniface\adm`,
sandbox `C:\Users\Bob\source\uniface\WASListener\IdePlugin`.

Steps:
1. **Close the IDE** if running (repo lock) — `Get-Process ide,cefrender | Stop-Process
   -Force`; confirm gone.
2. **Back up** `IdePlugin\ide.asn` → `ide.asn.bak`.
3. **Repoint output** — edit `[SETTINGS]`: set `$resources_output .\VersionControl.uar`
   (comment the original `.\resources` line on its **own** line; **no trailing `;`
   comment** on the value — `[SETTINGS]` would swallow it into the path).
4. **Compile** with `Start-Process -Wait -PassThru` (GUI-subsystem exit-code trap), from
   the sandbox workdir:
   ```powershell
   $dir='C:\Users\Bob\source\uniface\WASListener\IdePlugin'
   $p = Start-Process 'C:\ref\common\bin\ide.exe' `
     -ArgumentList "/dir=$dir","/adm=C:\ref\uniface\adm","/all" `
     -WorkingDirectory $dir -Wait -PassThru -NoNewWindow `
     -RedirectStandardOutput "$env:TEMP\vc_pkg.out" -RedirectStandardError "$env:TEMP\vc_pkg.err"
   $p.ExitCode   # expect 0 (last "application definition not found" is benign — no APS)
   ```
5. **Verify** `IdePlugin\VersionControl.uar` exists with type-subdirs (`svc frm sig edc`,
   ~140 KB / ~145 entries) via the zip-listing snippet in
   [/uniface-package-uar](uniface-package-uar.md).
6. **Revert** the asn from `ide.asn.bak`; delete the `.bak`. Leave the sandbox pristine.
7. Report the UAR path/size and per-type counts.

Notes:
- Certification (`cert.exe`) is **not** applied — WAS is non-commercial, skill-refresh only
  ([worklog/021](../../worklog/021-was-plugin-discovery-integration.md)).
- The plugin's `[RESOURCES]` accepts either the loose `resources\` folder **or** this
  `.uar`; the UAR is the deployable form used for Stage-2 wiring into MYPROJECT.
- Related: [uniface-uar-packaging-and-hardening](../rules/uniface-uar-packaging-and-hardening.md),
  [/was-build](was-build.md), [docs/uniface-was-plugin-integration.md](../../docs/uniface-was-plugin-integration.md).
