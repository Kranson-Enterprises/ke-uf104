# 020 Byte-faithful Uniface XML exports — `.gitattributes` (`-text`)

**Date:** 2026-06-30
**Sequence:** … → 018 (first WorkArea push) → 019 (export staging / `scratch/`) →
**020 (.gitattributes byte-faithfulness)**.
**Purpose:** Stop Git from rewriting Uniface XML export bytes across platform moves
(Windows IDE ⇄ Unix/Linux target) — EOL and encoding drift is a classic cause of
import/export breakage and diff noise. Pin the WorkArea / export serialization to exact
bytes.
Confidence: ✅ implemented + `check-attr` verified; committed XML unchanged.

---

## 1. Why this matters

Platform movement has classically broken Uniface file import/export. The two culprits:

- **Line endings.** Git's `autocrlf` can silently convert **CRLF⇄LF** on commit/checkout.
  A Windows IDE export is CRLF; a Unix/Linux export is LF. If Git normalizes, the bytes
  the engine produced are not the bytes on disk — and the *same* object re-exported on a
  different OS diffs as **every line changed** (pure EOL noise that buries real changes).
- **Encoding / BOM.** Uniface exports are UTF-8 and may carry a **UTF-8 BOM** (the
  project-level dump did). Byte-level rewriting risks BOM/encoding surprises.

And it had **already bitten us silently.** This repo has `core.autocrlf=true`, so the
WorkArea XML committed in [018](018-workarea-first-push-helloworld.md) was **LF-normalized
in the stored blob** even though the working tree is CRLF:

| File | blob (committed) | worktree (Uniface export) |
| --- | --- | --- |
| `cpt/HELLO_WORLD.xml` | 29 848 B (LF) | 30 378 B (CRLF) |
| `prj/MYPROJECT.xml` | 4 035 B (LF) | 4 109 B (CRLF) |

The on-disk copy was byte-faithful (verified by `cmp` in 018), but Git's blob was not —
the courier quietly rewrote the artifact. This commit fixes that.

## 2. Decision — `-text` (faithful courier)

`.gitattributes` at repo root marks Uniface XML exports `-text`:

```
workarea/**/*.xml   -text
components/**/*.xml  -text
src/**/*.xml         -text
```

- **`-text`** disables EOL normalization in **both** directions — Git stores and checks
  out the **exact bytes**, preserving native EOL and any UTF-8 BOM.
- It is **not** `binary` (which is `-text -diff`): we keep `-text` only, so **textual
  diffs still render** for review. We just never let Git *transform* the file.

## 3. Alternative considered (and why not, yet)

**Canonical LF** (`text eol=lf`) would give clean cross-platform diffs by normalizing the
repo to LF. Rejected for now because:

- The priority is **byte-faithful round-trip** to the engine, not diff aesthetics.
- Per the **XML 1.0 spec (§2.11)** an XML parser **normalizes line endings on input**, so
  Uniface's XML *import* tolerates CRLF or LF regardless — meaning we don't *need* a
  canonical EOL for correctness, and forcing one only risks surprising the byte stream.
- If cross-platform **diff noise** ever becomes a real team pain, revisit and switch the
  policy to `text eol=lf` deliberately (with a `git add --renormalize`).

So: make Git **stop interfering** first; optimize diff-cleanliness later only if needed.

## 4. Verification & repair

- `git check-attr text workarea/cpt/HELLO_WORLD.xml` → `text: unset` (i.e. `-text`).
- `git add --renormalize` flagged both `workarea/*.xml` as **modified** — proof the 018
  blobs were LF-normalized and now differ from the byte-faithful CRLF working tree. This
  commit **re-stores them verbatim** (blob → 30 378 / 4 109 B), so blob == disk ==
  Uniface output. Going forward `-text` keeps Git from re-normalizing them.

## 5. Relationship to existing guidance

- Complements [uniface-export-staging](../.claude/rules/uniface-export-staging.md) (where
  exports go) and [uniface-repository-source-of-truth](../.claude/rules/uniface-repository-source-of-truth.md)
  ("keep a consistent DB collation so XML/Git diffs stay clean" — the EOL analog).
- Reinforces the **Unix/Linux character-mode + web target** reality
  ([uniface-character-and-web-endpoints](../.claude/rules/uniface-character-and-web-endpoints.md)):
  the serialization must survive the move off Windows intact.

## 6. Deferred / open

- Revisit canonical-LF normalization **iff** cross-platform diff noise shows up in
  practice.
- Extend the attribute list if new repository round-trip artifact types/paths are added.
