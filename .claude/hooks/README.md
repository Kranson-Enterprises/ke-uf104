# Hooks

Scripts the harness runs automatically on events. Hooks are **wired up in
`settings.json`** (the `hooks` key), not by presence in this folder — this is
just where the scripts live.

Common events: `PreToolUse`, `PostToolUse`, `UserPromptSubmit`, `Stop`,
`SessionStart`. Example wiring in `.claude/settings.json`:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          { "type": "command", "command": ".claude/hooks/format.bat" }
        ]
      }
    ]
  }
}
```

A hook receives JSON on stdin and can block/allow the action via its exit code.
No hooks are wired yet — add a script here and reference it from `settings.json`.
