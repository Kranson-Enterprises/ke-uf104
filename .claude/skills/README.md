# Project skills

Each subfolder here is a Claude Code **skill** — a `SKILL.md` (YAML frontmatter
`name` + `description`, then a markdown procedure) that Claude invokes by name via
the Skill tool when the description matches the request. Skills suit **multi-step,
stateful procedures** (a setup wizard, a guided one-time task); one-shot prompts
belong in [../commands/](../commands/), and delegated autonomous work in
[../agents/](../agents/).

```
.claude/skills/<name>/SKILL.md
---
name: <name>                     # kebab-case, matches the folder
description: When to use this skill (specific — this drives routing).
allowed-tools: Read, Edit, PowerShell   # optional; omit to inherit all
---
Procedure body…
```

| Skill | What it does |
| --- | --- |
| `was-project-setup` | One-time setup to enable the WAS WorkArea plugin against MYPROJECT — asks download-vs-build for `VersionControl.uar`, backs up config, writes the project-local asn (`[RESOURCES]` + `IDE_DEFINE_USERMENUS=VC_UPDATED` + `WAS_ROOT_FOLDER`), verifies the menu. **Non-commercial / skill-refresh only.** |
| `uniface-test-harness-setup` | One-time setup of the two-tier test scaffolding — a ProcScript unit-test library + runner (Tier 1), a `tests/e2e/` browser folder (Tier 2), and the **dev-only** `ide.asn` test knobs (`TEST_COMMAND_CPT …/deb`, `TEST_COMMAND_CPT_WEB`, `Accessibility=TestMode`/`DebugPort`, suppress-dialog + log). Backed up, previews before writing, reversible. See [worklog/033](../../worklog/033-uniface-testing-approaches-and-tooling.md). |
| `uniface-tdd-loop` | Guided model-first **red→green→refactor** inner loop against the local SQLite sandbox — pick a unit → failing ProcScript unit test → run `/tst /deb` → pass → refactor → export to `workarea/` to promote (ties into [worklog/032](../../worklog/032-sdlc-agile-workarea-waslistener-delivery.md)). |
