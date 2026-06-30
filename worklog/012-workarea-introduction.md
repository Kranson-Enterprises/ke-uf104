# 012 WorkArea introduction — design + non-destructive skeleton

**Date:** 2026-06-30
**Sequence:** … → 009 (DSP capabilities) → 010 (plan: tutorials + WorkArea) →
011 (re-baseline + tutorial review) → **012 (WorkArea introduction)**.
**Purpose:** Execute Phase B + Phase C of the [010 plan](010-plan-tutorials-and-workarea.md):
research the real Uniface **Work Area Support (WAS)** workflow, design how this repo
**emulates** it with the export/import facility, and scaffold a **non-destructive**
WorkArea command + rule + directory. No live sync, hook, or agent this pass.
Confidence: ✅ documented (README/source) · 📘 community · ⚠️ inferred / not documented.

---

## 1. Key correction up front: UD6 ≠ WAS

The 010 plan (and common shorthand) treated "UD6" and "WAS" as one thing. Research
([WASListener](https://github.com/uniface/WASListener) source +
[community utility page](https://community.rocketsoftware.com/uniface-samples-111/work-area-support-utility-27362))
shows they are **two different, independent tools**:

- **WAS (Work Area Support)** — **Rocket's MIT-licensed sample**; the tool the user
  pointed to and the one we emulate. ✅
- **UD6** — a **third-party commercial** repository *driver* from **March Hare
  Software**; **not** a Rocket product, **not** bundled with Community Edition. ⚠️

Saved as memory `reference-uniface-workarea-was` so it isn't re-conflated. A correction
note was added to [worklog/010](010-plan-tutorials-and-workarea.md).

## 2. How WAS works (the thing we emulate) ✅

**Two parts:** `VersionControl.uar` (IDE plugin — project `VERSIONCONTROL`, component
`VC_MAIN`; does the repository import/delete + per-object change tracking) and
`WASListener.exe` (native Win32 tray watcher).

**Sync loop** (from `WASListener.cpp`/`Uniface.cpp`): the listener boots a Uniface
runtime, instantiates `VC_MAIN`, asks it for the WorkArea path via **`GETWASFOLDER`**,
then a `CFolderWatcher` watches that **local** folder. File events → `(bDelete,
bImport)`: ADDED→import, REMOVED→delete, MODIFIED→delete+import → call
**`VC(file,bDelete,bImport)`** which imports/deletes that one object. **Orphan guard:**
`VC` returns **`oprStatus==2` ("dirty")** when the developer has uncommitted IDE
changes — the listener **notifies instead of overwriting**. Single-instance via
`.WASListener.lock`; WorkArea **must be local** (network paths aren't watched).

**Accept/revert** (IDE plugin menu, `IDE_DEFINE_USERMENUS=VC_UPDATED`): *WorkArea
Export/Revert*, *Import WorkArea*, *Mark all ready / Export All* (first-time full dump).

**Layout (verified from the plugin's own sample WorkArea):** one subfolder per
**3-letter object class** (`aps/ cpt/ ent/ prj/ libinc/ libprc/ libsnp/ …`), **one
`.xml` Uniface export per object**.

**Relationship to export/import:** WAS is built on the **standard XML Export/Import**
facility (it never uses `/cpy`); it *automates* incremental per-file import + adds
change tracking + dirty-guard + accept/revert that raw `/imp` lacks. Mechanically it
drives the IDE plugin's ProcScript (which wraps `$ude`/the repository API ⚠️) rather
than shelling out to `/imp`.

**Sandbox-per-developer:** each dev has a local IDE + local repository DB; the Git
**WorkArea XML is the shared source of truth**, the repo DB a personal cache — exactly
the [repository-is-source-of-truth](../.claude/rules/uniface-repository-source-of-truth.md)
model, and the **target client's** infra shape.

## 3. Design — "emulate now, WAS-ready"

Full architecture in **[docs/uniface-workarea.md](../docs/uniface-workarea.md)**. We
reproduce the **WAS shape** with the export/import CLI already wrapped by
`/uniface-export` + `/uniface-import`:

| WAS | Our emulation (increment 1) |
| --- | --- |
| WorkArea folder | committed `workarea/` (per-object XML, class subfolders) |
| `WASListener.exe` watch loop | **explicit** `/uniface-workarea-sync` (no live watcher yet) ⚠️ |
| ADDED/MODIFIED → import | `pull`: `/imp <file>` per changed file (exit 0/1) |
| REMOVED → delete | **flagged only**, not auto-applied |
| Export All / per-object push | `push`: export → `workarea/` (IDE / `$ude("export")` — no CLI export) |
| `oprStatus==2` dirty guard | `status` warns; **dry-run by default**, explicit confirm to write |
| accept / revert | **deferred** |

## 4. Scaffolded this pass (non-destructive)

- **[docs/uniface-workarea.md](../docs/uniface-workarea.md)** — the design doc.
- **[workarea/](../workarea/)** — the WorkArea root + `README.md` layout contract.
  **No objects exported yet** (scaffold only).
- **[.claude/rules/uniface-workarea-sync.md](../.claude/rules/uniface-workarea-sync.md)**
  — WorkArea hygiene (master-of-record, dry-run default, no `/cpy`, dirty guard,
  WAS-compatible layout). Wired into [CLAUDE.md](../CLAUDE.md) "Rules (always apply)".
- **[.claude/commands/uniface-workarea-sync.md](../.claude/commands/uniface-workarea-sync.md)**
  — `status`/`pull`/`push` skeleton, **dry-run by default, no write without
  confirmation**; composes the existing export/import commands. Listed in the
  [commands README](../.claude/commands/README.md).
- **Memory** `reference-uniface-workarea-was` + INDEX line (the UD6≠WAS distinction).

**Safety:** nothing here executes Uniface or writes the repository; the command
previews and gates on confirmation, uses only `/imp` (never `/cpy`), and the live
watcher / accept-revert remain deferred.

## 5. Deferred to next approved pass
- **Live sync** (real per-file import/delete end-to-end, or a watcher).
- **Dirty/orphan guard + accept/revert** beyond a `status` warning.
- A **safety hook** (block `/cpy` on definitions; warn before destructive replay)
  beside [check-quoted-paths.ps1](../.claude/hooks/check-quoted-paths.ps1).
- A **`uniface-workarea` subagent** for multi-step sync/review.
- **Migration** of `components/` + `src/` into `workarea/`.
- **Open questions** (gated docs / local install): WAS in CE?; full
  `VC`/`GETWASFOLDER` `oprStatus` contract; `$ude` vs lower-level API inside the
  plugin; branch/merge/conflict policy; exact `WAS_ROOT_FOLDER` asn wiring.

## References
- **WorkArea / WAS — primary sources:**
  - Work Area Support Utility (Rocket community):
    <https://community.rocketsoftware.com/uniface-samples-111/work-area-support-utility-27362>
  - WASListener (GitHub, MIT, `master_10.4`): <https://github.com/uniface/WASListener>
  - IDE plugin model: <https://github.com/uniface/plugin-samples>
- UD6 background (third-party): <https://march-hare.com/library/html/ud6blurb.htm>;
  Rocket community "Uniface Version Control (UD6), VS Code and more!"
- In-repo: [docs/uniface-workarea.md](../docs/uniface-workarea.md),
  [010](010-plan-tutorials-and-workarea.md),
  [011](011-rebaseline-and-tutorial-review.md),
  [005](005-v10-source-of-truth-and-vscode-workflow.md).
