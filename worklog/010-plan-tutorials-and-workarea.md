# 010 Plan — tutorial-driven learning + WorkArea tooling (increment 1)

**Date:** 2026-06-30
**Sequence:** 001 (Claude setup) → 002 (CEF IDE) → 003 (spaces-in-paths) →
004 (environment definitions) → 005 (source-of-truth & VSCode) →
006 (CLI usage + commands) → 007 (productivity rules) →
008 (sample-driven export verification) → 009 (DSP capabilities web research) →
**010 (plan: tutorials + WorkArea)**.
**Purpose:** Record the approved plan-of-record for the next increment — re-baseline
the moved install, review a few Uniface tutorials, and stand up the first
(non-destructive) **WorkArea** tooling that emulates the file↔repository sync the
target client uses. Execution lands in **011** (re-baseline + tutorial review) and
**012** (WorkArea introduction). Plan file mirror:
`C:\Users\Bob\.claude\plans\jolly-percolating-meerkat.md`.

> **Status:** ✅ approved (auto-accept). Confidence markers below follow the repo
> convention: ✅ verified locally · 📘 Rocket/community · ⚠️ best-practice/unverified.

---

## 1. Why this increment

`ke-uf104` exists to evolve **Uniface 10 folder activity into Claude Code
instrumentation** (skills, rules, commands, agents, hooks) for managing multiple
client Uniface apps in the IDE ([[project-goal-claude-uniface-tooling]]). The repo
already encodes the **repository-is-master-of-record** model and a working
**export/import round-trip** (worklogs [005](005-v10-source-of-truth-and-vscode-workflow.md)/[008](008-sample-driven-export-verification.md),
the `uniface-repository-source-of-truth` rule, the `/uniface-export` +
`/uniface-import` commands).

The user wants to **slowly** introduce the **Uniface WorkArea** workflow — the
productized version of that round-trip:
- **UD6** — a file-based repository *driver* (stores Uniface source as text files). 📘
- **WAS / WASListener** (`github.com/uniface/WASListener`) — syncs the IDE repository
  against a directory of exports (the **WorkArea**), replaying file changes (e.g. a
  git branch checkout) into the repository, guarding against orphan definitions, and
  letting the developer accept/revert. The **sandbox-per-developer** model that
  mirrors the **target client's infra**. 📘

> **Correction (2026-06-30, post-research → [012](012-workarea-introduction.md)):**
> UD6 and WAS are **different, independent tools**, not one feature. **UD6** is a
> **third-party commercial** repository driver from **March Hare Software** (not a
> Rocket product, not bundled with Community Edition). **WAS** is Rocket's
> **MIT-licensed sample** (`VersionControl.uar` IDE plugin + `WASListener.exe` tray
> watcher) — the tool the user pointed to and the one we emulate. Read this plan's
> "UD6-ready" as **"WAS-ready"**; UD6 is just an alternative third-party path. Full
> mechanics in [012](012-workarea-introduction.md) and
> [docs/uniface-workarea.md](../docs/uniface-workarea.md).

UD6 is typically a licensed/non-CE add-on, so this increment **emulates the WorkArea
with the export/import CLI we already have, structured so UD6/WAS can drop in later**
("emulate now, UD6-ready").

## 2. Environment changed underneath us (2026-06-30, ✅ verified)

The user **reinstalled** Uniface and **moved folders**; the **MusicShop sample is
gone**. Verified from `C:\ref\uniface\adm\usys.ini` and
[uniface/log/install_info.txt](../uniface/log/install_info.txt):
- **Install root is now `C:\ref`** (deliberately **space-free** — `ide.exe` at
  `C:\ref\common\bin\ide.exe`, `[install] root=C:\ref\common`). Old root was
  `C:\Program Files\Rocket Uniface 10 Community Edition`.
- **Project dir moved *into* the repo:**
  `project=C:\Users\Bob\source\uniface\ke-uf104\uniface\project` (also space-free).
- Version **10.4.03.042**, edition **CE**; ports urouter **13001** / tomcat **8080**
  / udbg **13002**.

Consequence: `scripts/setup-env.bat` and several active commands/docs still point at
the **old** install path + a stale `%USERPROFILE%\...\project` dir (67 references
across 14 files). They must be reconciled before build/launch work, so **Phase 0**
goes first. The new spaceless layout looks chosen to defuse the very spaces problem
worklogs [002](002-ide-architecture-analysis.md)/[003](003-spaces-in-paths-guidance.md)
documented — so `quote-paths-with-spaces` stays as **defensive** guidance, but its
"the current install has spaces, so this is mandatory" premise needs softening.

## 3. Decisions locked with the user
- **Engine:** emulate via structured export/import file tree, UD6/WAS-ready.
- **Tutorial sources:** public dev.to "petercode" series + Rocket gated Getting
  Started (routed through the user — Claude can't auth, see
  [[reference-rocket-docs-login]]) + webinars/video. (Not the loaded MusicShop sample
  this pass — it no longer exists.)
- **Scope:** learn + scaffold skeleton (no destructive repo ops).

## 4. Plan

### Phase 0 — Re-baseline the environment (do first)
1. **`scripts/setup-env.bat`** — `UNIFACE_HOME` → `C:\ref`; project dir → in-repo
   `uniface\project` (better: read `project=` from `%UNIFACE_ADM%\usys.ini` so a
   future move self-heals). Keep the CI "missing install is non-fatal" behavior.
2. **Reconcile *active* guidance only** — onboarding §1.1 and any command showing a
   concrete path (`uniface-launch-ide`, `uniface-cli`, `build`, `hooks/README.md`):
   point at `C:\ref` / in-repo project, or replace the literal with "resolve from
   `usys.ini [install]`."
3. **Do NOT rewrite historical worklogs** (002–008 record what was true then) — add a
   dated reconciliation note in 011 instead.
4. **`quote-paths-with-spaces`** — soften the premise to "paths *may* contain spaces;
   the current `C:\ref` install avoids them deliberately"; keep the rule.
5. **Surface, don't auto-fix:** the repo now tracks the live install's
   `uniface\project\dbms\usys.db` (the SQLite **repository DB**), `ide_state.zip`, and
   `uniface\log\*.log` — flag for a **`.gitignore` decision**, ask before untracking.
6. Record the new baseline in **011**; refresh memory only where a durable fact changed.

### Phase A — Tutorial review (learn → distill)
- Fetch + distill the public **dev.to petercode** series (component construction,
  services, app-server shell, running apps). Webinars/video for conceptual framing
  (⚠️ where not locally verifiable). Produce a **fetch list** of the gated Getting
  Started pages for the user to drop into gitignored `webfetched/`.
- Output: **`worklog/011-rebaseline-and-tutorial-review.md`**; onboarding **§1.7
  "Building a component: the construct workflow"** + §0/§5 refresh; a memory only if a
  durable fact emerges (e.g. UD6/WAS availability in CE).

### Phase B — WorkArea design doc
- **`docs/uniface-workarea.md`** — what UD6 + WAS are; WorkArea↔repository sync;
  the "emulate now, UD6-ready" mapping onto `/uniface-export` (`$ude("export")`/IDE —
  no CLI export switch) + `/uniface-import` (`/imp`, exit 0/1); the **`workarea/`
  layout** decision (a committed WAS-style per-object tree; fold `components/`+`src/`
  in later); sandbox-per-dev = target-client workflow; and the **designed-but-deferred**
  live sync / safety hook / `uniface-workarea` subagent.

### Phase C — Scaffold skeleton (non-destructive only)
- **Rule `.claude/rules/uniface-workarea-sync.md`** — repo is master of record; sync =
  export→WorkArea / import←WorkArea; **dry-run by default**; never `/cpy` definitions;
  quote spaced paths; check exit codes.
- **Command `.claude/commands/uniface-workarea-sync.md`** — skeleton wrapping
  export/import into a WorkArea **status / pull / push** shape; **dry-run/preview by
  default, no destructive op without explicit confirm**; mirrors `uniface-export.md` +
  `uniface-import.md` (resolve paths from `usys.ini`, exit-code gating).
- **Wiring** — add the rule to `CLAUDE.md`; add the command to
  `.claude/commands/README.md`; update `.claude/memory/INDEX.md` if a memory was added.
- **`worklog/012-workarea-introduction.md`** — design + skeleton + explicit deferral.

## 5. Verification
- **Phase 0 paths resolve:** `C:\ref\common\bin\ide.exe` and the `usys.ini project=`
  dir exist; `setup-env.bat` echoes new values with no "ide.exe not found"; `git grep`
  shows the old `Program Files` path only in historical worklogs.
- **Docs/worklogs:** every tutorial claim carries ✅/📘/⚠️ + a reference; no
  gated/proprietary content committed (scan `git status` against
  `protect-secrets-and-proprietary`).
- **Skeleton is safe:** the new command is **dry-run by default**, no repository write
  without explicit confirm, composes only existing export/import steps — no `/cpy`, no
  unguarded `/imp`.
- **No execution of Uniface** this pass — skeleton + docs only; nothing touches the
  live `usys.db`.

## 6. Deferred to next approved pass (designed here, not built)
- Live WorkArea **sync** (real export→tree / import←tree replay).
- WorkArea **safety hook** (block `/cpy` on definitions; warn before destructive
  replay) alongside the existing `check-quoted-paths.ps1`.
- **`uniface-workarea` subagent** for multi-step sync/review.
- Folding `components/` + `src/` into the `workarea/` tree (migration).
- Closing the gated **Getting Started** + **PAM** items once the user supplies pages.

## References
- Plan file: `C:\Users\Bob\.claude\plans\jolly-percolating-meerkat.md`.
- Prior: [005](005-v10-source-of-truth-and-vscode-workflow.md),
  [008](008-sample-driven-export-verification.md),
  [009](009-dsp-capabilities-web-research.md).
- **WorkArea / WAS — primary sources (use these):**
  - Work Area Support Utility (Rocket community):
    <https://community.rocketsoftware.com/uniface-samples-111/work-area-support-utility-27362>
  - WASListener (GitHub): <https://github.com/uniface/WASListener>
- Related: `github.com/uniface/plugin-samples`; Rocket community "Uniface Version
  Control (UD6), VS Code and more!"
- New baseline source: `C:\ref\uniface\adm\usys.ini [install]`,
  [uniface/log/install_info.txt](../uniface/log/install_info.txt).
