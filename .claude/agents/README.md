# Project subagents

Each `*.md` file defines a custom subagent scoped to this project, available to
the Agent tool by its `name`. Format:

```markdown
---
name: my-agent
description: When this agent should be used (be specific — this drives routing).
tools: Read, Grep, Glob   # optional; omit to inherit all tools
model: sonnet             # optional
---

System prompt for the agent goes here.
```

No agents are defined yet — add one per file as the project needs them.
