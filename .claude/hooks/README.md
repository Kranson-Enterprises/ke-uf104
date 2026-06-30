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

### `protect-generated-output.ps1` — block edits to generated output (PreToolUse)

Blocks `Write`/`Edit`/`NotebookEdit` to **compiler-generated** Uniface artifacts —
generated DSP client JS (`**/dspjs/*.js`), DSP runtime pages (`*.dsp`), deployed
`webapps/uniface/` web output, the `project/resources/` compiled tree, and compiled
runtime objects (`*.frm/.rpt/.svc/.cpt`). These are overwritten on every compile, so
hand-edits are silently lost; the source of truth is the repository object. Wired in
`settings.json` under the `Write|Edit|NotebookEdit` matcher. Enforces
[../rules/uniface-dsp-web-conventions.md](../rules/uniface-dsp-web-conventions.md) and
[../rules/uniface-repository-source-of-truth.md](../rules/uniface-repository-source-of-truth.md).
Same fail-open design as above (any parse error / non-matching path → exit 0). For a
genuinely hand-maintained `/ext` `.hts` layout you own, write it via a shell command
rather than the Edit tool. Test:

```powershell
'{"tool_name":"Edit","tool_input":{"file_path":"x/webapps/uniface/dspjs/a.js"}}' |
  pwsh -NoProfile -File .claude/hooks/protect-generated-output.ps1; $LASTEXITCODE  # 2 = blocked
```

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

### `preflight-powershell.ps1` — PowerShell version/update advisory (SessionStart + dot-sourced)

Keeps the workspace on a supported, patched PowerShell as our `.ps1` tooling grows.
**Advisory only — it never blocks** (always returns; never `exit`s). Wired two ways:

- **SessionStart** in `settings.json` — runs `-Announce` once per session and reports
  the version status.
- **Dot-sourced** at the top of the other two PreToolUse hooks
  (`. "$PSScriptRoot/preflight-powershell.ps1"; Invoke-PowerShellPreflight`) inside a
  `try/catch`, so it also checks during normal work but can never affect the host hook's
  stdin handling or exit code. Advisory output is throttled to once / 6h.

Compares `$PSVersionTable.PSVersion` against `$MinimumVersion` (7.4 LTS floor) and
`$LatestKnownVersion` (7.6.3, bump as new releases ship) and warns via stderr if on
Windows PowerShell 5.1, below the LTS floor, or behind the latest.

**Security posture (deliberate — see [worklog/015](../../worklog/015-powershell-security-and-preflight.md)):**

- **Secure by default = offline.** The update check compares against the hard-coded
  `$LatestKnownVersion`; an auto-run hook making surprise outbound calls is itself a
  risk, so the live "latest release" lookup is **opt-in** via `UNIFACE_PREFLIGHT_ONLINE=1`.
- When opted in, the network call is **pinned HTTPS** (no user input → no SSRF), **3s
  timeout**, **throttled to once / 24h** via a temp state file
  (`$env:TEMP\uniface-claude-preflight\`), **fail-silent** on any error (offline must
  never break a hook), and only a **version string** is parsed (nothing executed).
- `UNIFACE_PREFLIGHT_SILENT=1` suppresses all advisory output.

Test:

```powershell
pwsh -NoProfile -File .claude/hooks/preflight-powershell.ps1   # announce; exit 0
# simulate "behind": dot-source, raise the target, force a message
pwsh -NoProfile -Command ". .\.claude\hooks\preflight-powershell.ps1; `$script:LatestKnownVersion=[version]'9.9.9'; Invoke-PowerShellPreflight -Announce"
```

To test the path hooks manually, pipe a sample payload to the script and check the exit code:

```powershell
'{"tool_name":"PowerShell","tool_input":{"command":"& C:\\Program Files\\x.exe"}}' |
  pwsh -NoProfile -File .claude/hooks/check-quoted-paths.ps1; $LASTEXITCODE  # 2 = blocked
```
