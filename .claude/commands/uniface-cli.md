---
description: Print the verified Uniface 10 command-line cheat-sheet (reference only, no execution)
allowed-tools: Read
---

Print a concise, **verified** cheat-sheet of Uniface 10 CLI usage (source:
onboarding §3.5 and worklog/005). **Do not execute anything.**

Include:
- **Executables:** `ide`, `uniface`, `urouter`, `userver`, `udbg`.
- **Compile:** `/all` (everything), `/cpt` (all components), per-type
  `/frm /rpt /svc /dsp /usp /esv /ssv`; sub-switches `/nodebug` (production),
  `/cmi=0|1`, `/sym=0..3`, `/aft=`/`/bef=DateTime`, `/lis` `/inf` `/war`,
  `/iap`/`/tpl`/`/plt`.
- **Import:** `/imp FileName` → exit 0 success / 1 failure.
- **Export:** none on CLI — use the IDE or `$ude("export")`.
- **Data Copy:** `/cpy` (occurrences only — NEVER for definitions).
- **DDL:** `/genSql {/meta} createTable|createScript entity.model <db>`.
- **Misc:** trailing `?` opens the command-line dialog; component types
  ESV=Entity Service, SSV=Session Service, DSP=Dynamic SP, USP=Static SP.
- **Caveat:** CLI fails if the Repository is unmigrated/incompatible — migrate via
  the interactive IDE first.
- **Quoting rule:** always quote spaced paths as whole tokens. This machine's
  install is space-free (`C:\ref\common\bin\ide.exe`), but client installs often
  are not, e.g.
  `& "C:\Program Files\Rocket Uniface 10 Community Edition\common\bin\ide.exe" "/adm=...\uniface\adm"`.
