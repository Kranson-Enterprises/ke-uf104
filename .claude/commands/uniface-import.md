---
description: Import XML Repository definitions into the Uniface repository (/imp) with exit-code check
argument-hint: "<XML file or wildcard, e.g. components\\*.xml>"
allowed-tools: Read, PowerShell
---

Import development-object definitions from XML into the repository using `/imp`.

Steps:
1. Resolve exe / adm / project (read `usys.ini [install]`).
2. Run, quoting spaced paths:
   ```
   & "<root>\common\bin\ide.exe" "/adm=<root>\uniface\adm" /imp $ARGUMENTS
   ```
   Useful sub-switches: `/nos` (no supersede), `/com=N` (commit freq), `/int=N`.
3. Check `$LASTEXITCODE`: **0 = success, 1 = failure** (read the transcript/log
   for detail).

Warnings:
- `/imp` only accepts files made by Uniface **export** — files from **Data Copy**
  (`/cpy`, `$ude("copy")`) are rejected; never use `/cpy` for definitions
  (Repository corruption risk).
- If repo data is unmigrated/incompatible, run the interactive IDE first.

In this repo, imported sources live in `components\` and `src\`.
