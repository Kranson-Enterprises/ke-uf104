# 027 First WorkArea round-trip (Hello World) — WorkArea export ≠ IDE export, and Import is destructive

**Date:** 2026-07-01
**Sequence:** … → 024 (Phase D + project-setup skill) → 025 (export/import exceptions) →
026 (`ide.asn` `#FILE` inheritance) →
**027 (first real Export→Import round-trip through the wired-in plugin)**.
**Purpose:** Record the first end-to-end WorkArea round-trip of the actual project objects
(`HELLO_WORLD` cpt + `MYPROJECT` prj) through the plugin wired into MYPROJECT (Stage 2,
worklog 024). Two findings matter: (1) the **WorkArea Export is intentionally different
from — and better than — the plain IDE Export** for a VCS serialization, and (2) the
plugin's **Import is a destructive, no-preview `delete → import` replace**. Executed on
this install; log-verified.
Confidence: ✅ Observed directly (IDE message log + on-disk byte/hash diff).

---

## 1. What we did

With the plugin wired into MYPROJECT (`uniface\project\ide.asn`: `#file usysadm:ide.asn`
→ `[RESOURCES]`→`VersionControl.uar` → `IDE_DEFINE_USERMENUS=VC_UPDATED` +
`WAS_ROOT_FOLDER=…\ke-uf104\workarea`), we ran the full loop:

1. **Export** (repository → `workarea/`) via burger ☰ → **WorkArea Export**, selecting
   **only** `HELLO_WORLD` and `MYPROJECT` (per-object, **not** "Export All", per the
   system-object hygiene rule).
2. **Import** (`workarea/` → repository) via burger ☰ → **Import WorkArea**.

Baseline before Export (from the worklog-018 hand-export):
`HELLO_WORLD.xml` = 30 378 B, `MYPROJECT.xml` = 4 109 B, tree git-clean.

## 2. Finding 1 — WorkArea Export is *intentionally* leaner than IDE Export (and better for VCS)

After Export, `HELLO_WORLD.xml` **shrank 30 378 → 25 939 B** (−4 439 B; diff = 4 insertions,
79 deletions); `MYPROJECT.xml` was **byte-identical**. No `U*`/`USYS*` sidecar files
appeared. The removed 79 lines were **exactly two `system="S"` meta-dictionary tables** —
`<DSC name="UPROJECT" model="DICT" system="S">` and `UREFCPT` — plus the `MYPROJECT`
project *occurrence* and `varinfo` runtime attributes. The component's own content
(`UFORM`/`UXGROUP`, the painted `GREETING` entity) was fully retained.

**Why this is a real, intended difference — not a lossy one:**

- **Plain IDE Export** (Main Menu → Export, worklog 018) serves *definition exchange*. With
  its retrieve profile it pulled **related system tables** (`UPROJECT`, `UREFCPT`) and their
  occurrence data **into the component file** — everything needed to reconstitute the object
  in isolation, including meta-dictionary scaffolding and `varinfo`.
- **WorkArea Export** (the WAS plugin) serves *file↔repository VCS serialization*. It writes
  the **object's own definition, scoped to the object**, and leaves Uniface's delivered
  `system="S"` registries out — because those belong to Uniface / to the *project*, not to
  the *component*. The proof is in the **import mapping** (§3): `UPROJECT`/`UREFCPT` map from
  **`prj/MYPROJECT.xml`**, i.e. they are the **project's** tables. The hand-export had
  **bled project/system tables into the component file**; the WorkArea export doesn't.

So the WorkArea format is the **correct canonical serialization** for `workarea/`: smaller,
per-object, no system/cross-object bleed — cleaner Git diffs and no duplication of
Uniface-delivered content. This is the file-level embodiment of the "export project objects
only, never `USYS*`/`U*` system objects" hygiene rule (worklog 024). We adopted it as the
tracked form (commit `838e03f`).

> Rule of thumb: **IDE Export = portable, self-contained definition dump** (good for handing
> an object to someone with no context). **WorkArea Export = minimal per-object VCS delta**
> (good for Git). Use the WorkArea export for the `workarea/` tree; don't "upgrade" it back
> to a full IDE export.

## 3. Round-trip result (Import) — success, via delete-then-import

The IDE message log for **Import WorkArea**:

```
Delete cpt HELLO_WORLD.  Import cpt HELLO_WORLD.
  → IDF:UFORM.DICT (1), IDF:UXGROUP.DICT (1)     Successfully imported 2 records.
Delete prj MYPROJECT.    Import prj MYPROJECT.
  → IDF:UPROJECT.DICT (1), IDF:UREFCPT.DICT (1)  Successfully imported 2 records.
```

Both objects re-imported cleanly and mapped to the right dictionary tables. Import did
**not** rewrite the on-disk files (it reads files → repository). The `UPROJECT`/`UREFCPT`
mapping from `MYPROJECT.xml` confirms §2: those tables are the **project's**, correctly
absent from the leaner component file.

## 4. Finding 2 — Import is a destructive, no-preview, no-scope replace

The Import gives **no selection, no preview, no dry-run, no confirmation**. The console
shows only "Importing from Workarea", and for **every** object under `WAS_ROOT_FOLDER` it
performs **`Delete <class> <name>` then `Import <class> <name>`** — a hard **delete-then-
replace** of the repository object from the file version.

Implications:
- On a **shared repository**, Import would **silently overwrite/blow away uncommitted
  repository edits** with whatever is on disk — no "these N objects will change / be
  deleted" step to abort on. The `delete` phase means a mid-import failure could even leave
  an object *gone*.
- It is **unscoped** — it imports **everything** under the WorkArea root, the same gap as
  Export's missing filter.

**Contrast with our emulation.** The [uniface-workarea-sync](../.claude/rules/uniface-workarea-sync.md)
command is **dry-run-by-default, preview-first, deletions-flagged-not-applied**. This
round-trip proves the emulation's caution is the *right* model and the real plugin is the
cautionary tale: treat **Import WorkArea as a repository-mutating action** — commit/backup
the repo state first, and only run it when the on-disk tree is known-good.

## 5. Outcome & follow-ups

- **Adopted** the WAS-format `HELLO_WORLD.xml` as the canonical serialization (commit
  `838e03f`). Round-trip green.
- **Documented** the destructive/no-preview/no-scope Import behaviour in the WorkArea
  plugin **feedback** doc (self-contained for external submission) and added an
  **Import-is-destructive caution** to the workarea-sync rule.
- Still deferred: native `WASListener.exe` live watcher; a scoping filter / safe-import are
  product gaps (see feedback).

## Related

- [worklog/024](024-was-phase-d-and-project-setup-skill.md) (Stage-2 wiring),
  [worklog/018](018-workarea-first-push-helloworld.md) (the original hand-export we replaced),
  [worklog/020](020-gitattributes-byte-faithful-xml.md) (byte-faithful XML pinning).
- Rules: [uniface-workarea-sync](../.claude/rules/uniface-workarea-sync.md),
  [uniface-repository-source-of-truth](../.claude/rules/uniface-repository-source-of-truth.md).
- Feedback: [docs/feedback-workarea-plugin-export-import.md](../docs/feedback-workarea-plugin-export-import.md).
