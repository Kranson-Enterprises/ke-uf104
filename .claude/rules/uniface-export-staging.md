# Rule: Uniface export staging — project `scratch/`, never the Claude scratchpad

**Scope:** Any artifact the **Uniface IDE / engine writes to disk** — the IDE **Export**
action, `$ude("export")`, `/genSql` DDL output — when it is *staging / intermediate*
(not yet a tracked WorkArea object, not a runtime artifact). Also any time Claude tells
the user **where to save** such an export.

## Rule

- **Uniface exports must not target the Claude scratchpad.** The session scratchpad
  (`%LOCALAPPDATA%\Temp\claude\…\<uuid>\scratchpad`) is **session-specific and
  ephemeral** — it has a per-session UUID in the path and is auto-cleaned, so an export
  written there is silently lost, and the deep path is error-prone to type into the IDE
  Export dialog. Do **not** scatter exports to ad-hoc temp (`C:\temp`) either.
- **Stage Uniface engine artifacts in the project-local `scratch/` folder** (gitignored,
  contents never committed). It is stable, discoverable, and inside the workspace.
- **Route by destination — pick the right one:**
  - **WorkArea integration exports** → [`workarea/<class>/<OBJECT>.xml`](../../workarea/README.md)
    (tracked, WAS layout, one XML per object) — see
    [uniface-workarea-sync](uniface-workarea-sync.md).
  - **Runtime / wasv artifacts** (generated `.dsp` / `dspjs`, `project/resources/`,
    `project/dbms/`, logs) → leave where the install / `.asn` place them; they are
    gitignored runtime, **never** moved into VCS or into `scratch/`.
  - **Everything else** (one-off exports, inspection dumps, pre-WorkArea staging,
    `/genSql` output) → **`scratch/`**.
- **Claude's own tool-internal temp is the exception, not the rule here.** Helper
  scripts and intermediate analysis Claude generates still use the **Claude session
  scratchpad** per the harness. This rule governs **Uniface-produced** artifacts and any
  workspace staging Claude directs the user to create.
- **Promote, don't accumulate.** Move a staged artifact into the tracked tree
  (`workarea/`) by an **explicit, reviewed copy**; don't `/imp` or
  commit straight from `scratch/`. `scratch/` is a holding area, not a deliverable home.
- **Quote spaced paths** ([quote-paths-with-spaces](quote-paths-with-spaces.md)) — the
  `scratch/` path on this machine has none, but the habit holds for client installs.

## Why

The scratchpad mis-targeting already bit us once: an IDE export pointed at the
session scratchpad couldn't land there and silently went to `C:\temp` instead
([worklog/018](../../worklog/018-workarea-first-push-helloworld.md)). The scratchpad is
ephemeral and Claude-internal; the **Uniface IDE/userver is a separate process driven by
the user**, so its artifacts belong in a stable in-workspace location. Keeping them in a
gitignored `scratch/` preserves the **repository-is-source-of-truth** model: `scratch/`
holds, `workarea/` is the VCS serialization, runtime stays
gitignored where it is.

## How to apply

- When you (or a subagent) tell the user where to save an IDE export, name **`scratch/`**
  (absolute, e.g. `C:\Users\Bob\source\uniface\ke-uf104\scratch\`) — unless it is a
  WorkArea object, which goes to `workarea/`.
- Verify the file in `scratch/`, then copy it into the tracked tree; never present a
  scratchpad path for a Uniface export again.
- Related: [uniface-workarea-sync](uniface-workarea-sync.md),
  [uniface-repository-source-of-truth](uniface-repository-source-of-truth.md),
  [uniface-cli-and-build-hygiene](uniface-cli-and-build-hygiene.md),
  [quote-paths-with-spaces](quote-paths-with-spaces.md).
