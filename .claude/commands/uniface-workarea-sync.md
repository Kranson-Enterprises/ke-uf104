---
description: Sync Uniface objects between the repository and the workarea/ tree (status/pull/push — dry-run by default, WAS-emulation skeleton)
argument-hint: "status | pull | push  [object/class selection]"
allowed-tools: Read, PowerShell, Bash, Write
---

Emulate the Uniface **Work Area Support (WAS)** file↔repository sync with the
export/import facility, against the Git-tracked **`workarea/`** tree. Architecture:
[docs/uniface-workarea.md](../../docs/uniface-workarea.md); hygiene rule:
[.claude/rules/uniface-workarea-sync.md](../rules/uniface-workarea-sync.md).

> **Skeleton (increment 1): DRY-RUN BY DEFAULT.** Preview what would change and
> **require explicit confirmation** before any repository write. No live watcher, no
> auto-delete, no accept/revert yet — those are deferred (see the design doc).
> The repository is the master of record; `workarea/` is the serialization.

## Subcommands ($1)

### `status` (default — read-only, safe)
1. Resolve `exe` / `adm` / `project` from `usys.ini [install]` (quote spaced tokens).
2. Compare the **`workarea/`** XML files against what's in the repository and report,
   per object class (`aps/ cpt/ ent/ prj/ lib*/`):
   - files **ADDED / MODIFIED** in `workarea/` (would import on `pull`),
   - files **REMOVED** (would delete — **flagged only**, never auto-applied here),
   - objects changed in the IDE but not exported (would export on `push`),
   - any **"dirty"/orphan** risk (uncommitted IDE change over an incoming file —
     the WAS `oprStatus==2` case). Surface it; do not plan a force-replay.
3. Print the plan. **Do nothing else.**

### `pull`  (import ← WorkArea — replay; preview, then confirm)
- Show the exact per-file import plan from `status`, then **stop for confirmation.**
- On confirm, import each ADDED/MODIFIED file:
  `& "<root>\common\bin\ide.exe" "/adm=<root>\uniface\adm" /imp "<workarea\class\obj.xml>"`
  checking `$LASTEXITCODE` (**0** ok / **1** fail) per file; stop on first failure.
- **REMOVED** files are reported, **not** deleted from the repository in this pass.

### `push`  (export → WorkArea; preview, then confirm)
- **There is no CLI export switch.** Export via the IDE **Export** action or a small
  `$ude("export")` snippet run under `ide.exe`, writing **one `.xml` per object** into
  the matching `workarea/<class>/` folder.
- Preview which objects/classes would be written; confirm before writing files.

## Always
- **Never `/cpy`** for definitions (corruption; rejected by `/imp`).
- Keep the **WAS-compatible layout**: one subfolder per object class, one `.xml` per
  object ([workarea/README.md](../../workarea/README.md)).
- If the repository is unmigrated/incompatible, `/imp` fails — open the interactive
  IDE once to migrate first.
- `$ARGUMENTS`: `$1` = subcommand, `$2…` = object/class selection.
