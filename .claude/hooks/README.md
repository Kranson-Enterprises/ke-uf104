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

A hook receives JSON on stdin and can block/allow the action via its exit code:
for a `PreToolUse` hook, **exit 2 blocks** the tool call and feeds the script's
stderr back to Claude; **exit 0 allows**; any other non-zero is a non-blocking
error shown to the user.

## Wired hooks

### `check-quoted-paths.ps1` — enforce quoting of spaced paths (PreToolUse)

Blocks `Bash`/`PowerShell` commands that reference a known spaced directory
fragment (e.g. `Program Files`) **outside** of quotes — the failure mode that
crashed the IDE launch on 2026-06-27. Wired in `settings.json` as:

```json
"PreToolUse": [
  {
    "matcher": "Bash|PowerShell",
    "hooks": [
      { "type": "command",
        "command": "pwsh -NoProfile -ExecutionPolicy Bypass -File \"$CLAUDE_PROJECT_DIR/.claude/hooks/check-quoted-paths.ps1\"" }
    ]
  }
]
```

Enforces the rule in [../rules/quote-paths-with-spaces.md](../rules/quote-paths-with-spaces.md).

#### Caveats (this is the "tricky" part — read before trusting it)

- **Heuristic, not a shell parser.** It cannot, in general, know whether a space
  continues a path or separates two arguments — that ambiguity is the whole
  problem. So it does **not** detect arbitrary spaced paths; it matches a
  **curated list of known fragments** hard-coded in the script
  (`$fragments`). New spaced paths must be **added to that list** or they pass
  unchecked. This keeps false positives near zero at the cost of completeness.
- **Fails open by design.** Any unreadable/unparseable input or unexpected error
  exits 0 (allow). A bug in the hook will never block legitimate work — but it
  also means a malformed payload is not enforced. Safety over strictness.
- **Quote-span detection is naive.** It treats `"..."` and `'...'` as quoted
  spans via regex. It does **not** understand: here-strings (`@"..."@`/`@'...'@`),
  backtick/backslash escaping, nested or escaped quotes, or shell variable
  expansion. A fragment inside a here-string can be a **false positive**; an
  exotic escaping trick could be a **false negative**.
- **"Quoted" ≠ "correctly quoted".** The hook only checks that the fragment sits
  inside *some* quote span. It will allow `/adm="C:\Program Files\...\adm"` even
  though the rule prefers quoting the **whole** token (`"/adm=C:\Program
  Files\...\adm"`). The hook prevents the crash; the rule doc covers the nuance.
- **Substring, not word-boundary, matching.** `Program Files` also matches inside
  `Program Files (x86)` (both are listed, so this is intentional here) — but be
  aware when adding fragments that one can shadow another.
- **Requires `pwsh` on PATH.** PowerShell 7 must be invocable as `pwsh`. On a
  machine with only Windows PowerShell, change the command to `powershell` (note:
  `[Console]::In.ReadToEnd()` and exit codes behave the same).
- **Self-referential gotcha:** `$CLAUDE_PROJECT_DIR` here resolves to a path with
  **no** spaces, so it works — but it is quoted anyway to stay correct if the
  project is ever cloned under `C:\Program Files\...` or similar.

To test it manually, pipe a sample payload to the script and check the exit code:

```powershell
'{"tool_name":"PowerShell","tool_input":{"command":"& C:\\Program Files\\x.exe"}}' |
  pwsh -NoProfile -File .claude/hooks/check-quoted-paths.ps1; $LASTEXITCODE  # 2 = blocked
```
