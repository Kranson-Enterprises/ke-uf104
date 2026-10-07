# Product Feedback — WorkArea Export/Import: no scoping filter, and Import is a destructive no-preview replace

**To:** Rocket Uniface product team / WAS (Work Area Support) maintainers
**From:** Uniface 10 workspace evaluation
**Date:** 2026-07-01
**Component:** WAS WorkArea IDE plugin (`VersionControl.uar`, built from `github.com/uniface/WASListener`), Uniface 10.4.03 Community Edition IDE (`common\bin\ide.exe`)
**Category:** WorkArea / VCS usability & safety

> This report is self-contained — all evidence is reproduced inline so it can be read
> without access to the originating workspace.

## Summary

Two gaps were found while using the WorkArea plugin to serialize a project to a
Git-tracked folder and round-trip it back:

1. **WorkArea Export has no way to exclude Uniface-delivered system objects.** The Export
   form lists **every** development object in the repository — including Uniface's own
   `USYS*` / `U*` system objects — with no checkbox, retrieve profile, or name filter to
   scope the export to the developer's own objects.
2. **Import WorkArea is a destructive, no-preview, unscoped replace.** It shows no
   selection, no preview, and no confirmation; for every object under the WorkArea root it
   performs **`Delete <object>` then `Import <object>`**, hard-replacing the repository
   object from the file. On a shared repository this silently overwrites (or, on a
   mid-import failure, deletes) repository work with no chance to abort.

Both are safety/usability issues for the exact audience the WAS tooling targets: teams
keeping object definitions in source control.

## Context (how we hit it)

The plugin (`VersionControl.uar`) was wired into a project IDE via assignment-file logicals
`IDE_DEFINE_USERMENUS=VC_UPDATED` and `WAS_ROOT_FOLDER=<git-tracked folder>`. The project is
tiny — **two authored objects**: a component `HELLO_WORLD` (a DSP) and a project
`MYPROJECT`. We used **WorkArea Export** to write the two objects to the folder, then
**Import WorkArea** to read them back.

---

## Issue 1 — Export lists Uniface system objects with no filter

### Observed

- The Export form listed the two authored objects **and** Uniface-delivered system objects.
  Confirmed present in the repository (reserved `U*` namespace): **`USYSUPALETTE_FRM`,
  `USYSUPALETTE_RPT`, `USYSSTAT`**, among others.
- There is **no** "exclude Uniface system objects" checkbox, **no** retrieve profile, and
  **no** name/source/pattern filter on the form. The only choices are **per-object
  hand-selection** or **Export All**.
- **Export All writes the delivered system objects into the WorkArea folder** — i.e. into
  version control, where Rocket-delivered content is both noise (identical across every
  install) and arguably out of place.

### Why it matters

- **VCS pollution:** `Export All` drags Uniface-delivered objects into the team's Git tree.
- **Dangerous "cleanup" reflex:** because the system objects clutter the list, the natural
  instinct is to **delete them to tidy up** — but the WorkArea Revert/Remove path deletes
  **repository definitions**, and the `U` prefix is Uniface's own reserved namespace
  (Uniface up-cases names and reserves `U*` for its widgets/objects). Removing e.g.
  `USYSUPALETTE_*` can break IDE features or repository integrity. The UI makes the wrong
  action (delete) look as available as the right one (exclude).
- **Toil at scale:** hand-selecting your own objects every baseline does not scale.

## Issue 2 — Import is destructive, with no preview / no scope

### Observed

Pressing **Import WorkArea** produced only `Importing from Workarea` in the Messages
console — no object selection, no preview, no confirmation dialog. The IDE message log shows
a **delete-then-import** per object (reproduced verbatim, paths shortened):

```
Importing from Workarea
Delete cpt HELLO_WORLD.
Import cpt HELLO_WORLD.
8079 - Map from '…\workarea\cpt\HELLO_WORLD.xml' to 'IDF:UFORM.DICT'.
8075 - Mapped … total records/rows 1.
8079 - Map from '…\workarea\cpt\HELLO_WORLD.xml' to 'IDF:UXGROUP.DICT'.
8075 - Mapped … total records/rows 1.
Import summary … Successfully imported 2 records.
Delete prj MYPROJECT.
Import prj MYPROJECT.
8079 - Map from '…\workarea\prj\MYPROJECT.xml' to 'IDF:UPROJECT.DICT'.
8075 - Mapped … total records/rows 1.
8079 - Map from '…\workarea\prj\MYPROJECT.xml' to 'IDF:UREFCPT.DICT'.
8075 - Mapped … total records/rows 1.
Import summary … Successfully imported 2 records.
```

Note the explicit **`Delete cpt HELLO_WORLD.` / `Delete prj MYPROJECT.`** before each import.

### Why it matters

- **Silent overwrite of repository work.** On a shared repository, Import replaces each
  object with the on-disk version with **no "these N objects will be changed/deleted" step
  to review or cancel**. Uncommitted repository edits are lost without warning.
- **Delete-phase exposure.** Because each object is *deleted* before it is re-imported, an
  interruption or a bad file mid-run can leave an object **removed** from the repository.
- **Unscoped.** Import processes **everything** under the WorkArea root — the same missing
  scoping as Issue 1, now on the repository-mutating side.

## Steps to reproduce (both issues)

1. Point the plugin at any repository via `IDE_DEFINE_USERMENUS=VC_UPDATED` +
   `WAS_ROOT_FOLDER=<folder>` (even a fresh repo with 1–2 authored objects).
2. Burger (≡) menu → **WorkArea Export**: observe the list includes Uniface `USYS*` / `U*`
   objects and there is **no** control to filter/exclude them (Issue 1).
3. Burger (≡) menu → **Import WorkArea**: observe there is **no** selection/preview/confirm,
   and the message log shows **Delete-then-Import** for every object (Issue 2).

## Suggested improvements

**For Export (Issue 1):**
1. Add an **"Exclude Uniface system objects" checkbox** (default **on**) that omits the
   delivered `USYS*` / `U*` reserved-namespace objects. Solves the common case alone.
2. Support a **retrieve profile / filter** — by object-name pattern (include/exclude, e.g.
   exclude `U*`), by source/collection, or by **active-project membership**.
3. **Guard the delete/Revert path** for reserved-namespace objects (confirm-with-warning or
   disable) so "tidying the list" can't silently remove delivered system definitions.

**For Import (Issue 2):**
4. Add a **preview / dry-run** step: list the objects that would be **added / changed /
   deleted** and require explicit confirmation before any repository write.
5. **Do not delete before import as the default** — prefer an in-place update, or at least
   make the delete-then-import behavior explicit and opt-in.
6. **Scope the import** (same filter as Export) and **flag deletions** rather than applying
   them automatically.
7. Surface a **completion summary** in the UI (objects added/updated/skipped/failed), not
   only in the message log.

## Environment

| Item | Value |
| --- | --- |
| Product | Uniface 10.4.03 Community Edition |
| IDE | `common\bin\ide.exe` (build 2026-05-13, `10.4.03.042`) |
| Plugin | WAS `VersionControl.uar`, compiled from source at `github.com/uniface/WASListener` (non-commercial license) |
| Repository | SQLite, small project — 2 authored objects + Uniface-delivered `USYS*` objects |
| System objects seen | `USYSUPALETTE_FRM`, `USYSUPALETTE_RPT`, `USYSSTAT`, … (`U*` reserved namespace) |
| Export evidence | `HELLO_WORLD.xml` 30 378 B (plain IDE Export) vs 25 939 B (WorkArea Export) |
| Import evidence | message-log `Delete <class> <name>` → `Import <class> <name>`, "Successfully imported 2 records" per file |

## Note on WorkArea Export vs. plain IDE Export (not a defect — context for the team)

The WorkArea Export is correctly **leaner** than the plain IDE Main-Menu Export: for the
same component it omitted two `system="S"` meta-dictionary tables (`UPROJECT`, `UREFCPT`)
and `varinfo` runtime attributes that the plain IDE Export had bundled into the component
file (those tables legitimately belong to the *project* object, and mapped from the project
file on import). This per-object scoping is exactly right for a VCS serialization; the two
requests above (a system-object filter, and a safe/preview import) would make that clean
serialization safe to operate as a team workflow.
