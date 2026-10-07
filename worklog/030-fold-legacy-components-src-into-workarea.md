# 030 Fold legacy `components/` + `src/` into `workarea/` — single serialization

**Date:** 2026-07-02
**Sequence:** … → 028 (WAS integration day summary) → 029 (change round-trip delta) →
**030 (retire the legacy flat export folders; `workarea/` is now the only serialization)**.
**Purpose:** Close the last WAS follow-up flagged in [028 §5](028-was-integration-day-summary.md)
and the `workarea/` design doc — the older flat `components/` + `src/` convention is
superseded by the WAS-compatible `workarea/` tree, and this pass makes that real in the repo
and across the docs/rules.
Confidence: ✅ Executed (git rm + doc sweep verified).

---

## 1. What was there (and why "fold" ≠ "migrate")

- `components/` held a **single file, `sample_component.com`** — a hand-written placeholder
  from the original VS Code scaffold (worklog 000), **not** a Uniface repository object and
  **not** valid export XML (worklog 016 already recorded it as "placeholder, no secrets").
- `src/` was **empty** (never git-tracked; git doesn't track empty dirs).

So there was **nothing to migrate** — no real exported objects lived in the legacy folders.
The only object serializations in the repo are already the WAS-format
[`workarea/cpt/HELLO_WORLD.xml`](../workarea/cpt/HELLO_WORLD.xml) and
[`workarea/prj/MYPROJECT.xml`](../workarea/prj/MYPROJECT.xml). "Folding" therefore reduced to
**retiring the superseded scaffold folders** and repointing every forward-looking reference at
`workarea/`.

## 2. What changed

- **Deleted** `components/sample_component.com` (`git rm`) and removed the now-empty
  `components/` and `src/` directories. Per the operator's call: delete rather than keep as an
  example — a non-repository placeholder perpetuating the retired convention.
- **`.gitattributes`** — dropped the dead `components/**/*.xml` and `src/**/*.xml`
  byte-faithful lines; kept `workarea/**/*.xml -text` (worklog 020 rationale unchanged).
- **Doc/rule sweep** — repointed the forward-looking references from `components/`/`src/` to
  `workarea/` (WAS layout, one XML per object):
  - [CLAUDE.md](../CLAUDE.md) project overview, [README.md](../README.md) (incl. removing the
    "Sample component" note), [docs/README.md](../docs/README.md).
  - [docs/uniface-10-onboarding.md](../docs/uniface-10-onboarding.md) §1.4 bridge + §4 Claude-
    workflow tip.
  - Rules [uniface-repository-source-of-truth](../.claude/rules/uniface-repository-source-of-truth.md)
    and [uniface-export-staging](../.claude/rules/uniface-export-staging.md) (promote-to
    tracked-tree wording); [scratch/README.md](../scratch/README.md) promotion note.
  - [docs/uniface-workarea.md](../docs/uniface-workarea.md) — marked the supersession **done**
    and removed the migration from the "designed-but-deferred" list;
    [workarea/README.md](../workarea/README.md) migration note flipped to **retired**.
- **Not touched:** prior worklogs (append-only history — they still describe the old
  convention as it was at the time, which is correct).

## 3. Result

`workarea/` is now the **single, WAS-compatible serialization** of repository objects; there is
no competing flat-folder convention in the tree or the guidance. The repository remains the
master of record; `workarea/` is its diffable VCS form (round-trip via Export/Import only,
never `/cpy`).

## 4. Outcome & WAS plan status

- **028 §5 follow-ups: both done** — change round-trip (029) + legacy-folder fold (030).
- **Still deferred:** the native `WASListener.exe` live watcher — blocked on toolchain
  (CMake + VS C++), prereqs in
  [project-was-native-listener-build-prereqs](../.claude/memory/project-was-native-listener-build-prereqs.md).
  With that the only open item, the WAS WorkArea plan is effectively complete pending the
  watcher build.

## Related

- [worklog/029](029-workarea-change-roundtrip-delta.md),
  [worklog/028](028-was-integration-day-summary.md),
  [worklog/018](018-workarea-first-push-helloworld.md) (first push),
  [worklog/016](016-workspace-security-review.md) (the placeholder classification).
- Design: [docs/uniface-workarea.md](../docs/uniface-workarea.md);
  contract: [workarea/README.md](../workarea/README.md).
- Rules: [uniface-repository-source-of-truth](../.claude/rules/uniface-repository-source-of-truth.md),
  [uniface-export-staging](../.claude/rules/uniface-export-staging.md).
