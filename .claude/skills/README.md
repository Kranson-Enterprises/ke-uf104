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
