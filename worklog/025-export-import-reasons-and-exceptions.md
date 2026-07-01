# 025 Why (and when not to) export/import Uniface objects — reasons, causes, exceptions

**Date:** 2026-07-01
**Sequence:** … → 023 (UAR packaging) → 024 (WAS Phase D + project-setup skill) →
**025 (export/import rationale + the copy-vs-export exception)**.
**Purpose:** Pin down *why* you export/import Uniface development objects, the mechanisms
that do it, and the **restrictions/exceptions** — including the operator's recollection of
"an exception or two from years ago." Grounds the *repository-is-source-of-truth* round-trip
and the WorkArea sync hygiene. Verified against the offline Rocket Uniface Library 10.4
([webfetched/](../webfetched/), §"Export and Import Facilities" p.5, and the dedicated
"Export and Import Facilities" extract).
Confidence: ✅ Library-verified for current behavior; ⚠️ the *historical* exception is
flagged as recollection where the offline Library doesn't confirm a specific legacy case.

---

## 1. What export/import is actually for

The Repository holds **development object definitions**, and a single object's definition
is **spread across several Repository entities**. Uniface exports/imports those definitions
as **well-formed XML with built-in safeguards to prevent Repository corruption**; if the
data is compatible it is transparently **migrated** to the current Repository structures
(Library p.5).

Three documented reasons to use it (Library p.5):
1. **Exchange definitions between developers.**
2. **Integrate with source-code-control systems** — this is our `workarea/` / VCS model.
3. **Migrate from one Uniface version to another.**

Access paths (Library p.5):
- **IDE** — Main Menu (≡) / Actions → Export / Import.
- **ProcScript** — `$ude("export")` / `$ude("import")`.
- **Command line** — `/imp` for import. **There is no CLI switch that exports
  definitions** (our [uniface-repository-source-of-truth](../.claude/rules/uniface-repository-source-of-truth.md)
  rule; the `/sto /mwr|com|lan` switches export *deployment artifacts* — WSDL/COM/Java
  wrappers — which are **not** `/imp`-importable).

## 2. Why the facility exists at all — integrity

Because one definition spans many meta-tables, only the **export/import facility**
preserves referential integrity. The export "takes referential integrity constraints into
account, ensuring that all the data applicable to an object definition is correctly
exported" (Library p.5). This is the whole reason **files are not the master of record** —
the Repository is, and XML export is its integrity-preserving serialization.

## 3. The exceptions / restrictions (current, Library-verified)

These are the real "you can't do that" rules today (Library p.5):

1. **Copy-facility output is not importable.** *"It is not possible to use `/imp` or
   `$ude("import")` to import data created by Data Copy facilities such as `/cpy` and
   `$ude("copy")`."* Export XML and Copy output are **different formats**; `/imp` rejects
   copy files.
2. **Can't append export data to a copy file.** *"It is not possible to append export data
   to a file created with the data copy facility."*
3. **Append requires an exact version match.** *"When appending data to an existing export
   file, the Repository version attributes must match exactly."*
4. **Version compatibility gate on import.** Import checks the Uniface + Repository
   version; data is compatible if it comes from the **same** Repository version **or can be
   migrated**. Data created by a **copy facility** is treated as **incompatible** and
   **Uniface does not allow it to be imported**.

Corollary from our own rules (still current):
- **`/cpy` is for entity *occurrences* (data), not definitions**, and it *ignores*
  referential integrity — using it for definitions risks Repository corruption
  ([uniface-repository-source-of-truth](../.claude/rules/uniface-repository-source-of-truth.md)).
  So the "copy vs export" split is both a *format* incompatibility **and** a *correctness*
  boundary.

## 4. The "exception from years ago" — honest status

The operator recalls one or two export/import exceptions from older Uniface that may no
longer apply. What the **offline Library 10.4 confirms** is that the **enduring** exception
is the **copy-vs-export incompatibility** (§3.1–3.4) — that boundary has clearly survived
into 10.4. The Library does **not** enumerate a now-removed legacy exception, so I won't
assert a specific one from memory.

What is safe to say:
- The **historical shape** was a split between **physical/data copy** (fast, integrity-
  blind) and the **definition export/import** (integrity-preserving XML). Legacy footguns
  clustered on the copy side and on **cross-version** moves (no migration → hard reject).
- Uniface 10 folds in **transparent migration on import** (compatible-or-migratable),
  which *softens* the old "incompatible version = dead stop" for anything migratable — a
  plausible source of the "that exception is gone now" impression.
- **If a specific legacy exception matters** (e.g. an object type that once couldn't
  round-trip), confirm it against Rocket's **version-specific release notes / "What's New"**
  rather than an open doc page — same discipline as the DSP/PAM rule
  ([uniface-dsp-web-conventions](../.claude/rules/uniface-dsp-web-conventions.md)).

## 5. Policy exceptions (ours, not the engine's)

Distinct from what the engine *forbids*, our workspace adds **what we choose not to
round-trip**:
- **Don't version-control Uniface-delivered `USYS*` / `U*` system objects.** They export
  fine technically, but they're Rocket-delivered, identical across installs, and pollute
  the tree — export **project objects only**
  ([uniface-workarea-sync](../.claude/rules/uniface-workarea-sync.md), worklog 024;
  feedback [docs/feedback-workarea-plugin-system-object-filter.md](../docs/feedback-workarea-plugin-system-object-filter.md)).

## 6. Takeaways

- Export/import exists to **preserve definition integrity** across the many meta-tables a
  definition spans — that's why the Repository, not files, is the master of record.
- The **hard, current exception** is the **copy-vs-export boundary**: `/cpy`/`$ude("copy")`
  output can't be imported, can't be appended to export files, and reads as incompatible.
- **Never `/cpy` definitions.** Export/Import XML only.
- Any *legacy* exception is **recollection until confirmed** against release notes.

## Related

- Rules: [uniface-repository-source-of-truth](../.claude/rules/uniface-repository-source-of-truth.md),
  [uniface-workarea-sync](../.claude/rules/uniface-workarea-sync.md),
  [uniface-cli-and-build-hygiene](../.claude/rules/uniface-cli-and-build-hygiene.md).
- Companion: [worklog/026](026-ide-asn-read-and-inheritance.md) (assignment-file read &
  `#FILE` inheritance — the *config* counterpart to this *object* round-trip).
- Prior: [worklog/023](023-uar-packaging-methodology-and-hardening.md) (compile → package,
  the other half of "getting objects out").
