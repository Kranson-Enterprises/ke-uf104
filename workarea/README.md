# `workarea/` — the Uniface WorkArea (file ↔ repository serialization)

This directory is the project's **WorkArea**: the Git-tracked, diffable serialization
of Uniface development objects, laid out **WAS-compatibly** so Rocket's Work Area
Support tooling (`VersionControl.uar` + `WASListener.exe`) could later watch it
unchanged. Design + rationale: [docs/uniface-workarea.md](../docs/uniface-workarea.md).

The **repository database is the master of record**; these files are the
exchange/VCS form. Round-trip via Export/Import only — **never `/cpy`** for
definitions (see [uniface-repository-source-of-truth](../.claude/rules/uniface-repository-source-of-truth.md)).

## Layout contract

**One subfolder per object class** (3-letter class code), **one `.xml` Uniface export
per object** inside it:

| Subfolder | Object class |
| --- | --- |
| `aps/` | application shells |
| `cpt/` | components (form / DSP / USP / service / report …) |
| `ent/` | model entities / dictionary |
| `prj/` | project objects |
| `libinc/` | include libraries |
| `libprc/` | global ProcScript libraries |
| `libsnp/` | snippet libraries |

Add further `lib*` / class folders as objects are exported. Files are plain Uniface
XML exports (`<UNIFACE release="10.4" repversion="…">`), **one object per file** so
SCM history and review stay per object.

## Scope: project objects only — no Uniface system objects

This tree holds **your project's** objects, **not** Uniface's delivered `USYS*` / `U*`
system objects (e.g. `USYSUPALETTE_FRM`, `USYSUPALETTE_RPT`, `USYSSTAT`). Those ship in
every repository and the WAS WorkArea Export form lists them all as "new" on first use —
**do not "Export All"**; export only your own objects. Never *delete* the `U*`/`USYS*`
objects to tidy the list either: the `U` prefix is Uniface's reserved namespace, and
removing them deletes repository definitions and can break the IDE. Rationale +
non-destructive filtering: [uniface-workarea-sync](../.claude/rules/uniface-workarea-sync.md);
plugin Export/Import feedback: [docs/feedback-workarea-plugin-export-import.md](../docs/feedback-workarea-plugin-export-import.md).

## Status

**First objects populated (2026-06-30 — `MYPROJECT` Hello World DSP).** First live
`push` (IDE per-object Export, no CLI export) — worklog
[018](../worklog/018-workarea-first-push-helloworld.md):

| File | Object | Notes |
| --- | --- | --- |
| `prj/MYPROJECT.xml` | project | project record + membership ref to `HELLO_WORLD` |
| `cpt/HELLO_WORLD.xml` | DSP component | self-contained; the **`GREETING` entity is a non-DBMS, component-painted entity embedded in the component** (UXGROUP `UFORM=HELLO_WORLD`) — there is **no standalone `ent/` object** to export |

Each file is a complete, integrity-preserving `<UNIFACE release="10.4">` export placed
by exact-byte copy (**never split** a combined dump — a definition's integrity spans
many meta-tables). The pull/`/imp` round-trip is **not yet exercised** — deferred to the
next pass (see the "designed-but-deferred" section of the design doc). Still no live
watcher.

> Migration note: the older flat `components/` + `src/` export folders still exist;
> folding them into this tree is a tracked follow-up, not yet done.
