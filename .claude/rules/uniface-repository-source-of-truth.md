# Rule: the repository is the source of truth — round-trip via Export/Import

**Scope:** All work on Uniface development objects (model, components, ProcScript,
libraries) and how they enter version control.

## Rule

- The **repository database is the source of truth**, not files. Edit objects in
  the **IDE** (structured editors). Do **not** hand-edit repository internals.
- The **filesystem bridge is XML Export/Import**:
  - Export via the IDE (Main Menu ≡ / Actions → Export, with a retrieve profile)
    or `$ude("export")`. **There is no command-line export switch** for
    repository definitions. (The `/sto /mwr=ws|com` / `/sto /lan=jav` switches
    export *deployment artifacts* — WSDL / COM DLL / Java wrappers — from
    signatures; that is packaging, not the VCS XML round-trip, and its output is
    not `/imp`-importable.)
  - Import via `/imp` (exit 0/1) or `$ude("import")`.
- **Never use Data Copy (`/cpy`, `$ude("copy")`) for Repository definitions** — it
  performs a physical copy that ignores referential integrity and **can corrupt
  the Repository**. `/cpy` is for entity *occurrences* (data) only, and its files
  are rejected by `/imp`.
- Commit the **XML exports** as the VCS-visible serialization: one file per object under
  the **WAS-compatible** [`workarea/`](../../workarea/README.md) tree (class subfolders).

## Why

A single development object's definition is spread across several repository
entities; only the export/import facility preserves that integrity. Treating
files as the source of truth, or using `/cpy` for definitions, leads to corruption
or lost relationships.

## How to apply

- When asked to "edit" an object for VCS: export → edit the XML (or edit in the
  IDE) → import; don't pretend a file is the live object.
- Keep a **consistent DB collation** across the team so XML/Git diffs stay clean.
- See [docs/uniface-10-onboarding.md](../../docs/uniface-10-onboarding.md) §1.4 and
  [worklog/005](../../worklog/005-v10-source-of-truth-and-vscode-workflow.md).
