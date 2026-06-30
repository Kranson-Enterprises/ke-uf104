# 018 First WorkArea push — Hello World (MYPROJECT) into `workarea/`

**Date:** 2026-06-30
**Sequence:** … → 016 (security review) → 017 (URD_MW_ERROR fix) →
**018 (first WorkArea push)**.
**Purpose:** First *live* exercise of the WorkArea integration designed in
[012](012-workarea-introduction.md) / [docs/uniface-workarea.md](../docs/uniface-workarea.md):
serialize the completed Hello-World DSP (`MYPROJECT`) from the repository into the
Git-tracked **`workarea/`** tree as per-object XML. Populates the previously
scaffold-only tree.
Confidence: ✅ files verified by inspection; ⚠️ pull/`/imp` round-trip not yet run.

---

## 1. What was done

- The DSP `HELLO_WORLD` (project `MYPROJECT`) was built/run in the IDE
  (web endpoint; the router fix in [017](017-urouter-mw-error-25-diagnosis.md) unblocked
  the Test).
- **`push` = IDE per-object Export** (there is **no CLI export switch** — only `/imp`
  imports). Exported from the IDE to staging (`C:\temp`):
  - `myproject.xml` — the **project** object.
  - `myproject-helloworld.xml` — the **component**.
- Placed into the **WAS-compatible** layout by **exact-byte copy** (no reformatting):
  - `workarea/prj/MYPROJECT.xml`   (4,109 bytes)
  - `workarea/cpt/HELLO_WORLD.xml` (30,378 bytes)

## 2. What we learned (verified from the XML)

- **Uniface export XML is table-structured, not per-object-sliced.** One `<UNIFACE>`
  root → many `<TABLE>` (meta-tables `UFORM`, `UPROJECT`, `UREFCPT`, `UXGROUP`, …) →
  `<DSC>` schema + `<OCC>`/`<DAT>` rows. A *project-level* export was 37 tables /
  ~28k lines binding **all** objects together. **A single logical object's definition
  spans many tables**, so you **cannot safely split a combined dump into per-object
  files** — that would break referential integrity (exactly what
  [uniface-repository-source-of-truth](../.claude/rules/uniface-repository-source-of-truth.md)
  warns against). The per-object WAS layout must come from **per-object IDE exports**,
  each its own complete file. ✅
- **`GREETING` is a non-DBMS, component-painted entity**, not a modeled `ent` object.
  It lives **inside** the component export (`UXGROUP` row with `UFORM=HELLO_WORLD`), so
  there is **no `ent/GREETING.xml`** — the component file is self-contained. ✅ (This is
  the character/web-endpoint reality: a structless entity painted on the component, not
  a dictionary entity.)
- `prj/MYPROJECT.xml` is cleanly project-scoped: the `UPROJECT` record + a `UREFCPT`
  membership reference to `HELLO_WORLD` — no cascaded component definition. The IDE
  produced the right per-object granularity when each object was exported individually.

## 3. Layout result

```
workarea/
  prj/MYPROJECT.xml      project record + membership (→ HELLO_WORLD)
  cpt/HELLO_WORLD.xml    DSP component incl. embedded GREETING (non-DBMS) entity
  README.md
```

One `<UNIFACE release="10.4" repversion="8">` wrapper per file (open=close=1 each).

## 4. Hygiene observed

- **No `/cpy`**; export/import XML only.
- **No split / no hand-edit** of exports — exact-byte copy preserves integrity.
- Only **repository XML** entered `workarea/` — the generated `resources/dsp/*.dsp` and
  `dspjs/*.js` web output stayed out (rebuilt on compile).
- Staging files remain in `C:\temp` (`hello_world_export.xml` — the unused 1 MB
  project-granular dump — plus the two per-object files); they're outside the repo and
  can be deleted.

## 5. Deferred (next pass)

- **Exercise `pull`:** dry-run `/imp` of `cpt/HELLO_WORLD.xml` back over itself
  (preview → confirm, exit 0/1 gate) to prove the import half of the round-trip closes.
- Live watcher / dirty-guard / accept-revert (real WAS) — still designed-not-built
  ([docs/uniface-workarea.md §5](../docs/uniface-workarea.md)).
- Fold the older flat `components/` + `src/` convention into `workarea/`.

## References
- Design: [docs/uniface-workarea.md](../docs/uniface-workarea.md); rule:
  [uniface-workarea-sync](../.claude/rules/uniface-workarea-sync.md); command:
  [/uniface-workarea-sync](../.claude/commands/uniface-workarea-sync.md).
- Prior: [012](012-workarea-introduction.md) (WorkArea introduction),
  [017](017-urouter-mw-error-25-diagnosis.md) (router fix that unblocked the Test).
