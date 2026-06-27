# 007 Claude Rules for Developer Productivity

**Date:** 2026-06-27
**Sequence:** 001 (Claude setup) → 002 (CEF IDE) → 003 (spaces-in-paths) →
004 (environment definitions) → 005 (source-of-truth & VSCode) →
006 (CLI usage + commands) → **007 (productivity rules)**.
**Purpose:** Distill the verified analysis into a small set of *always-apply*
rules under `.claude/rules/`, and record why each exists and how it loads.

---

## 1. Why rules (vs. commands vs. worklog)

The workspace now has three kinds of Claude artifact, each with a distinct job:
- **Rules** (`.claude/rules/`) — *always-apply* guidance/constraints Claude follows
  every session. Loaded only because **CLAUDE.md references them** (a file in
  `.claude/rules/` is not auto-read on its own).
- **Commands** (`.claude/commands/`) — on-demand *actions* (`/uniface-*`).
- **Worklog** (`worklog/`) — the dated *history/analysis* trail.

Rules capture the lessons that prevent rework or footguns, so they belong in the
always-on layer rather than a command you must remember to run.

## 2. The rule set

| Rule | Prevents / improves |
| --- | --- |
| `quote-paths-with-spaces` (existing) | The spaced-path crash (also enforced by a PreToolUse hook). |
| **`uniface-repository-source-of-truth`** | Repo corruption — edit in the IDE, round-trip via XML Export/Import, **never `/cpy` for definitions**. |
| **`uniface-cli-and-build-hygiene`** | Reuse the `/uniface-*` suite; resolve paths from `usys.ini [install]`; `/all /nodebug` for production; check exit codes; migrate the repo before batch CLI. |
| **`protect-secrets-and-proprietary`** | Credentials out of `.asn`; Rocket docs stay in gitignored `webfetched/`; scan `git status`/`diff` before committing. |

Each follows the established **Scope / Rule / Why / How to apply** format and
cross-links the others plus the onboarding doc and worklogs.

## 3. Provenance — each rule maps to something we hit

- Spaced paths → the 2026-06-27 IDE launch failure (worklog/002–003).
- `/cpy` corruption + "no CLI export" → the export/import gated docs (worklog/005).
- `/all /nodebug`, exit codes, migrate-first → the CLI switch docs (worklog/006).
- Proprietary-docs-local + secrets → the `webfetched/` gitignore decision and the
  dev→prod `.asn` checklist (worklog/004).

## 4. How they load & enforce

- **Load:** `CLAUDE.md` → *Rules (always apply)* now lists all four with links;
  CLAUDE.md is auto-read at session start.
- **Enforce:** only `quote-paths-with-spaces` is *mechanically* enforced (the
  PreToolUse hook). The others are strong guidance Claude applies; a future hook
  could add hard checks (e.g. block secrets in staged `.asn`).

---

## 5. Open / next

- Consider a `PreToolUse`/`PreCommit`-style hook to mechanically block staged
  secrets or `webfetched/` content (defense-in-depth for
  `protect-secrets-and-proprietary`).
- Revisit the rule set after the remaining live-IDE `[verify]` items are resolved.

## References
- Rules: [../.claude/rules/](../.claude/rules/); wiring in
  [../CLAUDE.md](../CLAUDE.md). Related: [006](006-cli-usage-and-claude-command-suite.md),
  [005](005-v10-source-of-truth-and-vscode-workflow.md),
  [004](004-ide-environment-definitions-and-asn-guidance.md).
