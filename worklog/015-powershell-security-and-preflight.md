# 015 PowerShell security & version preflight

**Date:** 2026-06-30
**Sequence:** … → 013 (Library verification) → 014 (naming/trigger/endpoint rules) →
**015 (PowerShell security & preflight)**.
**Purpose:** PowerShell tooling is now part of the workspace (three `.ps1` hooks). Keep
security top of mind as it evolves: add a **version/update preflight** into the hook
`.ps1` files, **review the docs** for any required PowerShell version or modules, and
record the security posture.
Confidence: ✅ verified in the Library 10.4 / tested locally.

---

## 1. Documentation review — does Uniface require a PowerShell version or modules?

Searched the full **Library 10.4** extract and the three smaller webfetched PDFs
(CLI switches, export/import, Uniface reference) for `powershell` / `pwsh` / `.ps1` /
module requirements. Result:

- **PowerShell appears exactly 3 times in the entire Library — all for one feature:**
  **`installrms.ps1`**, the silent installer for the **Sentinel RMS License Manager**
  (alternative to `installrms.bat`).
- **No PowerShell version requirement** is stated anywhere. **No required or recommended
  PowerShell modules** are mentioned. Uniface does not depend on PowerShell.
- Security-relevant notes from that one feature:
  - `installrms.ps1` must run **as Administrator**.
  - It **sets `$LASTEXITCODE`** when run non-interactively (−1 missing arg, −2 bad EID,
    −3 bad friendly name) — gate on it if we ever script it.
  - ⚠️ It accepts a **proxy password on the command line** (`-prxpwd <Password>`). That
    is a **credential-on-CLI leak pattern** (process listing / history / logs) — a
    cautionary example, captured in the new security rule.

**Conclusion:** our PowerShell **minimum is ours to set**, driven by our hook code (which
needs `pwsh` 7+), not by Uniface. Chosen floor: **7.4 LTS**; current/known-latest
**7.6.3** (this machine runs 7.6.3, confirmed).

## 2. Preflight added (advisory, never blocks)

**[.claude/hooks/preflight-powershell.ps1](../.claude/hooks/preflight-powershell.ps1)** —
checks `$PSVersionTable.PSVersion` against `$MinimumVersion` (7.4) and
`$LatestKnownVersion` (7.6.3) and warns (stderr) if on Windows PowerShell 5.1, below the
LTS floor, or behind latest. Wired **two ways**:

- **SessionStart** hook → `-Announce` once per session (reports status).
- **Dot-sourced** at the top of the existing
  [check-quoted-paths.ps1](../.claude/hooks/check-quoted-paths.ps1) and
  [protect-generated-output.ps1](../.claude/hooks/protect-generated-output.ps1) (inside
  `try/catch`) — so it also runs during normal work but **cannot affect the host hook**.
  Advisory output throttled to once / 6h.

## 3. Security posture (deliberate design)

The interesting risk is that the **update check itself** could be a liability — an
auto-run hook making outbound calls on every tool use is an exfil/availability vector.
So:

- **Secure by default = OFFLINE.** Compares against the hard-coded `$LatestKnownVersion`.
  The live "latest release" lookup is **opt-in** via `UNIFACE_PREFLIGHT_ONLINE=1`.
- **When opted in:** pinned **HTTPS** GitHub releases URL (no user input → no SSRF),
  **3s timeout**, **throttled to once / 24h** via a temp state file
  (`$env:TEMP\uniface-claude-preflight\`), **fail-silent** on any error, and only a
  **version string** is parsed from the response (nothing executed).
- `UNIFACE_PREFLIGHT_SILENT=1` suppresses all advisory output.
- The advisory **never blocks** — it always returns / exits 0, preserving the hooks'
  fail-open contract.

## 4. Security rule

**[.claude/rules/powershell-hook-security.md](../.claude/rules/powershell-hook-security.md)**
(wired into [CLAUDE.md](../CLAUDE.md)) institutionalizes the posture for future `.ps1`
work: stay patched (PS 7+); no surprise network from auto-run code; no secrets on the
command line; treat hook stdin as untrusted and never `iex` it; fail open for
advisories, `exit 2` only for clear violations; run `-NoProfile` from committed,
reviewed scripts (so **code review is the control**, since `-ExecutionPolicy Bypass`
provides none).

## 5. Tested

- Direct run on 7.6.3 → `PowerShell 7.6.3 OK` (exit 0).
- Simulated "behind" (`$LatestKnownVersion=9.9.9`) → `UPDATE: … behind 9.9.9`.
- Dot-source when current → silent; host hooks still **block** generated-output edits
  (exit 2) and **allow** clean commands (exit 0) with the preflight integrated.
- Online opt-in with no/blocked network → fail-silent, caches state, exit 0.
- `UNIFACE_PREFLIGHT_SILENT=1` → no output. `settings.json` validates.

## References
- **Source (local, not committed):** Library 10.4 PDF in `webfetched/`
  (installrms.ps1 / Silently Installing the RMS License Manager on Windows).
- In-repo: the preflight + two host hooks + `settings.json` (SessionStart),
  [powershell-hook-security.md](../.claude/rules/powershell-hook-security.md),
  [hooks/README.md](../.claude/hooks/README.md),
  [013](013-library-pdf-verification.md), [014](014-naming-trigger-endpoint-rules.md).
