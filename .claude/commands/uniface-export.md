---
description: Export development objects to XML for version control (IDE / $ude — there is no CLI export switch)
argument-hint: "[object selection / retrieve profile]"
allowed-tools: Read, PowerShell, Write
---

Export repository definitions to XML so they can be committed to Git.

**Important:** there is **no command-line export switch** (`/ex` is "exclusive
server", not export). Use one of:
1. **IDE:** Main Menu (≡) / Actions → **Export**, selecting objects with a
   **retrieve profile**.
2. **ProcScript:** `$ude("export")` run under `ide.exe` (scriptable). XML may be
   zipped, e.g. `"xml:archive.zip:objects.xml"`. Requires `usys:ide.uar` in
   resources when run from a deployed app.

Guidance:
- Write exports into `components\` (components) and `src\` (model, libraries) as
  the VCS-visible serialization. The repository DB remains the source of truth.
- For a team, keep a **consistent DB collation** so XML/Git diffs stay clean.
- **Never** use `/cpy` (Data Copy) to export definitions — corruption risk.
- If asked, scaffold a small `$ude("export")` service/snippet to automate it.

$ARGUMENTS = which objects to export.
