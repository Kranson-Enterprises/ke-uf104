# 019 Export staging — project `scratch/`, never the Claude scratchpad

**Date:** 2026-06-30
**Sequence:** … → 017 (router fix) → 018 (first WorkArea push) →
**019 (export staging rule + `scratch/`)**.
**Purpose:** Stop Uniface IDE/engine exports from being pointed at the ephemeral Claude
scratchpad; give the workspace a stable, gitignored **`scratch/`** staging folder and a
rule that routes engine artifacts to the right place.
Confidence: ✅ implemented + gitignore behavior verified.

---

## 1. Why

In [018](018-workarea-first-push-helloworld.md) an IDE **Export** was directed at the
Claude session scratchpad (`%LOCALAPPDATA%\Temp\claude\…\<uuid>\scratchpad`). It
couldn't land there and **silently went to `C:\temp`** instead. The scratchpad is the
wrong target for Uniface output because it is:
- **Session-specific & ephemeral** — a per-session UUID in the path, auto-cleaned, so an
  export written there is lost next session;
- **Claude-internal** — the Uniface IDE/userver is a **separate process driven by the
  user**, and the deep path is error-prone to type into the Export dialog.

Workspace artifacts the engine produces belong **in the workspace**, but **not** in
version control until promoted.

## 2. What was added

- **`scratch/`** — new gitignored staging folder; tracked `scratch/README.md` documents
  its contract (so the folder + contract live in the repo, contents never do).
- **`.gitignore`** — `scratch/*` + `!scratch/README.md` (negation keeps the README while
  ignoring all artifacts). Verified: `scratch/README.md` → tracked,
  `scratch/<anything>.xml` → ignored.
- **Rule [.claude/rules/uniface-export-staging.md](../.claude/rules/uniface-export-staging.md)**
  — the routing contract (below); wired into `CLAUDE.md` and the
  [/uniface-export](../.claude/commands/uniface-export.md) +
  [/uniface-workarea-sync](../.claude/commands/uniface-workarea-sync.md) commands.

## 3. The routing contract

| Artifact | Destination |
| --- | --- |
| Uniface IDE/engine export, staging XML, `/genSql` dumps | **`scratch/`** (gitignored) |
| WorkArea objects (one XML per object) | `workarea/<class>/` (tracked, WAS layout) |
| Runtime / wasv output (`.dsp`, `dspjs`, `project/resources/`, `project/dbms/`, `*.cmi`, logs) | leave where the `.asn` puts it (gitignored) — never moved to VCS or `scratch/` |
| Claude's **own** tool-internal temp (helper scripts, analysis) | Claude session scratchpad (unchanged — harness default) |

**Promote, don't accumulate:** move a staged artifact into the tracked tree
(`workarea/`, `components/`, `src/`) by an explicit, reviewed **copy** — never `/imp` or
commit straight from `scratch/`.

## 4. Relationship to existing rules

Complements [uniface-workarea-sync](../.claude/rules/uniface-workarea-sync.md) (where
WorkArea objects go), [uniface-repository-source-of-truth](../.claude/rules/uniface-repository-source-of-truth.md)
(scratch holds, VCS tree serializes, runtime stays out), and
[quote-paths-with-spaces](../.claude/rules/quote-paths-with-spaces.md). Does **not**
change the harness rule for Claude's own temp files.

## 5. Deferred / open

- A future `push` could **auto-stage to `scratch/`** then prompt to copy into
  `workarea/` — the command currently just documents the two-step.
- Same idea applies to `/genSql` DDL output once that command is exercised.
