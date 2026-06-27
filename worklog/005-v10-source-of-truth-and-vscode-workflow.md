# 005 Uniface 10 Source of Truth & Using VSCode as an Editor

**Date:** 2026-06-27
**Sequence:** 001 (Claude setup) → 002 (CEF IDE) → 003 (spaces-in-paths) →
004 (environment definitions) → **005 (source-of-truth & VSCode workflow)**.
**Question driving this entry (the "big one"):** A veteran who built apps in IDF
(v5–8) wants to use **VSCode as the native editor** for Uniface 10. What MUST be
done in the IDE, and what CAN be done in an external editor?
**Basis:** Public Rocket docs (search snippets), public community guides, and the
local install. Confidence: ✅ verified locally, 📘 Rocket docs/community, ⚠️
best-practice guidance. Authoritative gated docs still to be pasted in (see
[[reference-rocket-docs-login]]).

---

## 1. The reframe: the repository database is the source of truth

The decisive architectural fact in Uniface 10:

> **Development objects — the application model, components, ProcScript, projects,
> and libraries — live inside the repository database, not in files.** 📘

For this CE install that repository is the bundled **SQLite** `.\dbms\usys.db`
(via the `SLE` driver — verified in `dbms.asn`, see
[004](004-ide-environment-definitions-and-asn-guidance.md)). The IDE edits objects
*in the repository* through structured editors.

Files on disk (XML exports) are a **serialization** for exchange / version control
/ backup — **not** the live editing format. This is the single fact that decides
how far VSCode can go: VSCode cannot be a *live* editor of Uniface objects the way
it is for a JavaScript project, because the objects are not files. It can, however,
be a powerful **companion** around an export → edit → import loop, and the primary
editor for genuinely file-based artifacts.

There is **no official VSCode extension that live-edits Uniface objects.** The
Uniface IDE plugin SDK extends the *IDE* (CEF), not VSCode
(<https://github.com/uniface/plugin-samples>). 📘

---

## 2. MUST be done in the IDE (CEF)

| Task | Why it is IDE-only |
| --- | --- |
| Application Model — entities, fields, keys, relationships, inheritance | Structured repository objects; edited via model editors. ✅ |
| Component definition + **Form layout** (Design Layout / painter) | Visual/structured; no text-file equivalent. ✅ |
| Define-Structure / Define-Frames structured worksheets | Repository-backed structured editing. ✅ |
| Writing into the repository (the authoritative write-back) | Final import/commit-to-repo step (also scriptable — §4). 📘 |

---

## 3. CAN be done in VSCode / outside the IDE

| Task | Confidence |
| --- | --- |
| `.asn` / `.ini` / config (use `pathscrambler.exe` for credentials in `.asn`) | ✅ pure text |
| Review / diff / merge **exported XML** in Git | ✅ |
| ProcScript-heavy **library** objects (Global ProcScript, Include, Snippets) — export → edit text → import | ⚠️ practical; XML wrapper is awkward |
| Static **DSP / USP web assets** (HTML / CSS / JS) | ⚠️ likely file-based; confirm location |
| **Compile / import / export automation** via CLI + `$ude("export"/"import")` | ✅ exists; ⚠️ exact switch letters |
| Git, code review, build scripts, **CI/CD** producing **UAR** packages | ✅ fully external |

---

## 4. The bridge — how files and the repository round-trip

Confirmed against the gated *Export and Import Facilities* doc (saved locally
2026-06-27). Key reason this facility is mandatory: **the definition of one
development object may be spread over several repository entities**, so you cannot
safely hand-edit the database — the export/import facility preserves that
integrity. 📘

Three interchangeable access methods:

1. **IDE UI:** Main Menu (≡) or **Actions** menu → Export / Import; select objects
   with a **retrieve profile**. 📘
2. **ProcScript:** `$ude("export")` / `$ude("import")` — produces **XML**,
   optionally zipped (e.g. `"xml:archive.zip:objects.xml"`). Requires running under
   `ide.exe` or having `usys:ide.uar` in the application's resources. 📘
3. **Command line:** **`/imp FileName`** performs import (exit code **0** success /
   **1** failure — scriptable for CI). 📘 **There is no command-line *export*
   switch** — confirmed against the full switch reference; scripted export is via
   `$ude("export")` or the IDE. (Two hypotheses from the index-only pass were
   **wrong**: `/ex` is "exclusive Uniface Server", not export; `/pkg` is a Java
   call-in package name, not UAR packaging. Lesson: switch *names* aren't
   self-evident — the descriptions matter.)

> **Don't confuse with Data Copy.** The **Data Copy** facility (`/cpy`,
> `$ude("copy")`) is a *different* mechanism. Files it creates **cannot** be
> imported with `/imp` or `$ude("import")`, and you cannot append export data to a
> copy file. Use export/import (not copy) for version control. 📘

### XML export/import characteristics (📘)
- Well-formed, well-defined XML; objects with aggregation relationships are
  **nested**. The schema is documented as **"Uniface XML Constructs."**
- Export honors **referential integrity** (unlike a raw data copy) so a full,
  consistent definition is captured.
- Appending to an existing export file requires the **Repository version
  attributes to match exactly**.
- Import checks Uniface + Repository version and **auto-migrates** if compatible;
  **incompatible or copy-created** data is rejected.
- Old proprietary `.dol` / `.urr` formats are gone; compiled output is now **UAR**.

---

## 5. Recommended VSCode-centric workflow (⚠️ best practice)

1. **Edit structured objects in the IDE**; treat the repository as the live truth.
2. **Export to XML** on a cadence or pre-commit (`$ude("export")` or CLI), one file
   per object where possible. **Commit the XML to Git**; review/diff in VSCode.
3. **Use VSCode directly** for `.asn` / `.ini`, automation scripts, static web
   assets, and small ProcScript edits inside exported XML.
4. **Round-trip** edits back via import; **compile via CLI**; **package UAR** in CI.
5. **Team hygiene:** everyone on the **same DB collation** so XML/Git diffs stay
   clean and meaningful. 📘

### A concrete shape for this repo
- `components/`, `src/` → committed **XML exports** (the VCS-visible serialization).
- `.asn` / config → hand-edited in VSCode, secrets scrambled / injected at deploy.
- `scripts/` → wrappers around the verified CLI (all via `ide.exe`):
  - Import sources to repo: `ide.exe /imp components\*.xml` (check `%errorlevel%`).
  - Production compile: `ide.exe /all /nodebug` (→ UAR in `$RESOURCES_OUTPUT`).
  - Targeted compile: `ide.exe /svc *VAL` / `ide.exe /cpt /aft=<date>`.
  - Target-DBMS schema: `ide.exe /gensql createTable *.MYMODEL ora`.
  - **Export is not a CLI switch** — script it with a tiny `$ude("export")`
    component run under `ide.exe`, or export from the IDE.
- **CI caveat:** if the repo has unmigrated/incompatible data, CLI runs fail —
  open the interactive IDE once to migrate first.

---

## 6. Honest bottom line

You cannot make VSCode the place you *build* components the way IDF felt — the
structured editors and the repository are mandatory for object editing. You **can**
make VSCode the hub for everything around it: version control, review, config,
scripting, CI/CD, and text/library/ProcScript edits via round-trip, with compile/
import/export driven from the command line. That is the realistic
"VSCode-as-native-editor-as-far-as-possible" model for Uniface 10.

---

## 7. Resolved this pass + still open

**Resolved** from the saved gated PDFs (2026-06-27, switch detail pass):
- ✅ Export/import access methods, integrity rationale, Data Copy distinction, XML
  behavior (§4).
- ✅ **Import** = `/imp` (exit 0/1); **no command-line export switch** exists
  (export via IDE / `$ude("export")`). Corrected: `/ex` = exclusive server,
  `/pkg` = Java call-in package — neither is export/packaging.
- ✅ **Compile** = `/all` (everything) or `/cpt` (components) or per-type
  (`/frm /rpt /svc /dsp /usp /esv /ssv`); sub-switches `/nodebug` (production),
  `/cmi`, `/sym`, `/aft=`/`/bef=`.
- ✅ **Component types** fully defined: ESV = Entity Service, SSV = Session Service,
  DSP = Dynamic SP, USP = Static SP, FRM/RPT/SVC, CPT = all components.
- ✅ **`/genSql`** generates target-DBMS DDL (e.g. SQLite-dev → Oracle-prod).
- ✅ The `?` argument = command-line dialog; `urouter.asn [SERVERS]` defines servers.

**Still open** (need the live IDE UI, not file/doc-derivable):
1. **Export granularity** — one file per object, or grouped? (Do an Export in the IDE.)
2. Where **DSP/SSP web assets** live on disk and whether they're directly editable.
3. Whether ProcScript libraries can be **`#file`-included from disk** vs. repository
   `#include`.
4. The IDE **deploy/export-to-target** wizard name (CLI path already covers it).

> Saved source PDFs live in the gitignored `webfetched/` folder (Rocket
> proprietary — not committed). See [[reference-rocket-docs-login]].

---

## References
- **Saved locally (gitignored `webfetched/`, Rocket proprietary, 2026-06-27):**
  *Export and Import Facilities*, *Command Line Switches Reference* (landing only),
  *Uniface Reference* (index). Source: the gated Rocket Uniface Library 10.4.
- Export and Import Facilities (gated): <https://docs.rocketsoftware.com/bundle/uniface2_104/>
- Uniface Command Line Interface (gated; 301 from www3): <https://www3.rocketsoftware.com/rocketd3/support/documentation/Uniface/10/uniface/tools/commandLine/commandLineInterface.htm>
- $ude("export") guide (public): <https://dev.to/petercode/unlocking-uniface-a-practical-guide-to-the-udeexport-function-2hkn>
- $ude("import") guide (public): <https://dev.to/petercode/unlocking-uniface-a-simple-guide-to-the-udeimport-function-58l6>
- 9.7 → 10.4 migration guide (public): <https://dev.to/petercode/migrating-from-uniface-97-to-104-a-survivors-guide-1ood>
- Uniface IDE plugin samples: <https://github.com/uniface/plugin-samples>
- Related in-repo: [../docs/uniface-10-onboarding.md](../docs/uniface-10-onboarding.md), [004-ide-environment-definitions-and-asn-guidance.md](004-ide-environment-definitions-and-asn-guidance.md)
