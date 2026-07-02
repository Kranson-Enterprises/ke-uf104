# 029 WorkArea change round-trip — the delta is minimal (UTIMESTAMP-only churn)

**Date:** 2026-07-02
**Sequence:** … → 027 (first Export→Import round-trip) → 028 (integration day summary) →
**029 (a *change*-then-Export, to see a non-idempotent delta)**.
**Purpose:** Close the optional follow-up flagged in [028 §5](028-was-integration-day-summary.md) —
edit `HELLO_WORLD` in the IDE, WorkArea-Export it, and diff the on-disk serialization to
confirm the plugin's Export reflects a live repository edit and that the resulting Git diff
is clean and minimal. Executed on this install; byte/hash-verified.
Confidence: ✅ Observed directly (on-disk size + sha256 + `git diff`).

---

## 1. What we did

With the plugin wired into MYPROJECT (Stage 2, worklog 024), we made a single deliberate
edit to the `HELLO_WORLD` DSP in the **Design Layout** worksheet — the `<h1>` greeting —
then burger ☰ → **WorkArea Export**, selecting **only** `HELLO_WORLD` (never *Export All*,
per the system-object hygiene rule). This is the correct source-of-truth path: the layout
is a repository object, edited in the worksheet, **not** the generated `.dsp`.

**Change:** `Welcome to Uniface 10` → `Welcome to Uniface 10 WAS-Listener Verification`.

Baseline (post-027 export): `HELLO_WORLD.xml` = 25 939 B, sha256 `7e1576ed…`, git-clean.

## 2. Result — a clean, minimal, non-idempotent delta

After Export: **25 965 B (+26 B)**, sha256 `f5db3110…`. `git diff` = **2 hunks, +2 / −2**:

```
-<DAT name="UTIMESTAMP">2026-06-30T16:18:16.00</DAT>
+<DAT name="UTIMESTAMP">2026-07-02T10:24:31.00</DAT>
 ...
-Welcome to Uniface 10&lt;/h1&gt;
+Welcome to Uniface 10 WAS-Listener Verification&lt;/h1&gt;
```

- **Export reflects the repo edit** — the greeting change surfaced in the serialization,
  proving WorkArea Export is a live per-object dump of the repository object, not a static
  file. This is the "non-idempotent delta" 028 §5 wanted to see.
- **Churn is one line** — only **`UTIMESTAMP`** moved (to today's edit time). Notably
  **`UMVERSION` stayed at `3`** and `UKVERSION` at `8`: a layout-only edit bumps the
  timestamp but **not** the version counters. So the practical Git-diff cost of any export
  is exactly one unavoidable timestamp line alongside the real change.
- **Byte-faithful** — the diff is pure content; no CRLF / encoding / whitespace bleed,
  confirming the `.gitattributes` pinning (worklog 020) still holds through the plugin's
  Export path.

## 3. Outcome & follow-ups

- Committed the exported change as the round-trip proof.
- **028 §5 change-round-trip follow-up: done.** Remaining optional item: fold the legacy
  `components/` + `src/` exports into `workarea/` (WorkArea README follow-up). Still
  deferred: native `WASListener.exe` live watcher
  ([project-was-native-listener-build-prereqs](../.claude/memory/project-was-native-listener-build-prereqs.md)).

## Related

- [worklog/027](027-workarea-first-roundtrip-helloworld.md) (first round-trip; WorkArea
  Export ≠ IDE Export; Import is destructive),
  [worklog/020](020-gitattributes-byte-faithful-xml.md) (byte-faithful XML pinning),
  [worklog/028](028-was-integration-day-summary.md) (integration day summary).
- Rules: [uniface-workarea-sync](../.claude/rules/uniface-workarea-sync.md),
  [uniface-repository-source-of-truth](../.claude/rules/uniface-repository-source-of-truth.md),
  [uniface-dsp-web-conventions](../.claude/rules/uniface-dsp-web-conventions.md).
