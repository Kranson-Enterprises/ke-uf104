---
description: Compile Uniface objects from the command line (production build by default)
argument-hint: "[switches/profile, e.g. '/svc *VAL' or '/all /aft=15-09-2024'] — default '/all /nodebug'"
allowed-tools: Read, PowerShell
---

Compile via `ide.exe` command line. Default to a **production** compile:
`/all /nodebug` (non-debuggable shells/components/global ProcScript).

Steps:
1. Resolve exe / adm / project as in [/uniface-launch-ide](uniface-launch-ide.md)
   (read `usys.ini [install]`).
2. Run from the project working dir, quoting spaced paths:
   ```
   & "<root>\common\bin\ide.exe" "/adm=<root>\uniface\adm" <SWITCHES>
   ```
   - Default `<SWITCHES>` = `/all /nodebug` (compiles everything =
     `/obj /sig /dsp /usp /frm /rpt /svc /esv /ssv /ceo /app /dtd`).
   - Targeted: `/cpt` (all components), `/svc *VAL`, `/frm *list`, `/all /aft=<date>`.
   - Verbosity/extras: `/inf` `/war` `/lis` `/cmi=1` `/sym`.
3. Check `$LASTEXITCODE` and report compiler errors.

Caveats:
- If the Repository has **unmigrated/incompatible** data, CLI compile FAILS — open
  the interactive IDE once to migrate first.
- Output lands in `$RESOURCES_OUTPUT` (`.\resources`), packaged as **UAR**.

$ARGUMENTS overrides the switches.
