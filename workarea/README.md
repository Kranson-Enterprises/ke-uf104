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

## Status

**Scaffold only — no objects exported yet.** Populate with
[/uniface-workarea-sync](../.claude/commands/uniface-workarea-sync.md) (`push`), which
is **dry-run by default**. This WorkArea is *not yet* a live, watched sync — see the
"designed-but-deferred" section of the design doc.

> Migration note: the older flat `components/` + `src/` export folders still exist;
> folding them into this tree is a tracked follow-up, not yet done.
