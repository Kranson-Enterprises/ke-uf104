# 001 Claude Integration Setup

**Date:** 2026-06-26
**Session goal:** Stand up project-local Claude Code integration for the
`ke-uf104` Uniface 10 workspace, and seed initial memory.

## Outcome at a glance

Established a committed-but-private split: shared Claude config goes into git so
the team baseline travels with the repo, while personal memories and machine
overrides stay local (gitignored). Seeded three memories from existing worklog
notes and this session's discussion.

## What was created

```
ke-uf104/
├── CLAUDE.md                         # committed — auto-loaded each session; points to local memory
├── .gitignore                        # updated — ignores memories + personal settings
└── .claude/
    ├── settings.json                 # committed — shared team config (safe read-only perms)
    ├── settings.local.json           # LOCAL — personal overrides (gitignored)
    ├── memory/                       # LOCAL — memories (gitignored)
    │   ├── INDEX.md                  #   index loaded into context via CLAUDE.md
    │   ├── README.md                 #   memory file format/convention
    │   ├── project-goal-claude-uniface-tooling.md
    │   ├── user-uniface-context.md
    │   └── feedback-stepwise-documentation-style.md
    ├── commands/                     # committed — project slash commands
    │   ├── README.md
    │   └── build.md                  #   /build → setup-env.bat + build.bat
    ├── agents/                       # committed — custom subagents (README only)
    └── hooks/                        # committed — event scripts (README only)
```

## Git policy (verified with `git check-ignore`)

- **Ignored / stays local:** `.claude/memory/`, `.claude/settings.local.json`
- **Committed / shared on clone:** `CLAUDE.md`, `.claude/settings.json`, and the
  `commands/`, `agents/`, `hooks/` READMEs + `commands/build.md`

## Memories seeded

1. **project-goal-claude-uniface-tooling** (project) — integrate Claude into the
   IDE to manage workflow, monitoring, and delivery of *multiple* client-hosted
   Uniface apps; Uniface 10.4.03 Community Edition; prompted by the June 2026
   deprecation of online Uniface AI.
2. **user-uniface-context** (user) — veteran of Uniface v5–8, recently
   re-engaged at v10; assume strong fundamentals, focus guidance on v10 changes.
3. **feedback-stepwise-documentation-style** (feedback) — work step-wise, produce
   teachable docs, best-of-class solutions, and productivity tips for AI + human.

## Key decisions & rationale (for the next setup)

- **Memory mechanism:** Claude Code's built-in memory tool writes to a global
  per-project path, which can't be redirected into the repo. The in-workspace
  approach instead routes through `CLAUDE.md` → `.claude/memory/INDEX.md`, which
  loads each session because `CLAUDE.md` is auto-read. This is the lever that
  makes "memories live in the workspace" actually work.
- **Commit-shared / memories-local** was chosen over committing everything or
  keeping everything local — team gets the config baseline, personal notes stay
  private.
- **Placeholder folders** (`agents/`, `hooks/`) ship with explanatory READMEs
  rather than empty dirs, so the structure is self-documenting on clone.

## Baseline metrics to compare future setups against

- Folders scaffolded: 4 (`memory`, `commands`, `agents`, `hooks`)
- Committed config files: 6 (`CLAUDE.md`, `settings.json`, 3 READMEs, `build.md`)
- Local-only files: 4 (`settings.local.json`, `INDEX.md`, `README.md`, 3 memories)
- Working slash commands defined: 1 (`/build`)
- Subagents defined: 0 · Hooks wired: 0

## Open follow-ups

- Commit the shared config to git (memories remain uncommitted).
- Draft a v10 onboarding doc in `docs/` for training another individual.
- Seed memories for client-site delivery constraints and target Uniface apps.
- Wire a real hook (e.g. build/format) and add project subagents as needs emerge.
