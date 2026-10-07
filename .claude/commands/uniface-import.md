---
description: Import XML Repository definitions into the Uniface repository (/imp) with exit-code check
argument-hint: "<XML file or wildcard, e.g. components\\*.xml>"
allowed-tools: Read, PowerShell
---

Import development-object definitions from XML into the repository using `/imp`.

Steps:
1. Resolve exe / adm / project (read `usys.ini [install]`). For a non-default
   repository (e.g. a WorkArea sandbox), also pass `/dir=<workdir>` so `.\dbms\usys.db`
   resolves to that repo, and set the working dir to match.
2. Run, quoting spaced paths. **`ide.exe` is a GUI-subsystem exe: PowerShell's `&` does
   NOT wait for it and leaves `$LASTEXITCODE` blank** — use `Start-Process -Wait
   -PassThru` and read `.ExitCode` (a bare `&` gives a false/blank gate). (cmd/`.bat`
   *does* block on it, so `build.bat`'s `%ERRORLEVEL%` is fine — this trap is
   PowerShell-only.)
   ```powershell
   $p = Start-Process "<root>\common\bin\ide.exe" `
     -ArgumentList "/adm=<root>\uniface\adm","/imp","<file-or-wildcard>","/nos" `
     -WorkingDirectory "<workdir>" -Wait -PassThru -NoNewWindow `
     -RedirectStandardOutput "$env:TEMP\imp.out" -RedirectStandardError "$env:TEMP\imp.err"
   $p.ExitCode   # 0 = success, 1 = failure
   ```
   Useful sub-switches: `/nos` (allow supersede), `/com=N` (commit freq), `/int=N`.
   For a whole class-subfolder tree in dependency order, use [/uniface-import-batch](uniface-import-batch.md).
3. Check `$p.ExitCode`: **0 = success, 1 = failure**. Console is usually silent — read
   the Uniface message log under `usyslog:` (from `usys.ini`) for detail.

Warnings:
- `/imp` only accepts files made by Uniface **export** — files from **Data Copy**
  (`/cpy`, `$ude("copy")`) are rejected; never use `/cpy` for definitions
  (Repository corruption risk).
- If repo data is unmigrated/incompatible, run the interactive IDE first.

In this repo, imported sources live in `components\` and `src\`.
