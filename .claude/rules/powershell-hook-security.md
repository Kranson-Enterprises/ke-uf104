# Rule: PowerShell hook & script security

**Scope:** Every `.ps1` in this repo — Claude Code hooks (`.claude/hooks/`), build/env
scripts (`scripts/`), and any PowerShell we add. As PowerShell tooling grows, keep
security in the design, not bolted on.

## Rule

- **Stay on a supported, patched runtime.** Target **PowerShell 7+ (`pwsh`)**, not
  Windows PowerShell 5.1 (legacy). The
  [preflight-powershell.ps1](../hooks/preflight-powershell.ps1) advisory flags an
  outdated/unsupported runtime; don't ignore it. Uniface itself mandates **no**
  PowerShell version or modules (it only ships `installrms.ps1`), so our floor is
  ours to keep current.
- **No surprise network calls from auto-run code.** Hooks fire automatically, so a hook
  that phones home is an exfil/availability risk. Network access must be **opt-in**,
  to a **pinned HTTPS** URL (no user input in the URL → no SSRF), with a **timeout**,
  **throttled**, and **fail-silent**. Offline must never break a hook.
- **Never put secrets on the command line or in a script.** CLI args leak to process
  listings, shell history, and logs (cf. the documented `installrms.ps1 -prxpwd
  <password>` — avoid that pattern). Externalize credentials; see
  [protect-secrets-and-proprietary.md](protect-secrets-and-proprietary.md).
- **Treat hook stdin as untrusted input.** Parse the PreToolUse JSON defensively; never
  `Invoke-Expression`/`iex` or otherwise execute any value taken from a tool payload or
  a network response. Match/inspect strings only.
- **Fail open for advisories, fail closed only on clear violations.** Mirror the
  existing hooks: any parse error or unexpected exception → `exit 0` (allow). Reserve
  `exit 2` (block) for unambiguous rule breaches (unquoted spaced path, editing
  generated output). A buggy hook must never wedge the workspace.
- **Run hooks hardened:** invoke with **`-NoProfile`** (no profile injection) and from
  the **committed, reviewed** script path. We use `-ExecutionPolicy Bypass` because the
  scripts are in-repo and code-reviewed — that means execution policy provides **no**
  safety here, so **review is the control**: read any `.ps1` change like production code.
- **Quote spaced paths** in every PowerShell invocation
  ([quote-paths-with-spaces.md](quote-paths-with-spaces.md)).

## Why

Auto-run hooks execute on nearly every tool call with the developer's privileges. The
failure modes that matter — outbound exfil, credential leakage, executing untrusted
input, or a crash that blocks all work — are preventable by the defaults above. An
unpatched runtime carries known CVEs; surprise network calls and CLI-passed secrets are
classic leak vectors.

## How to apply

- When adding or editing a `.ps1` hook/script, check it against this rule and keep the
  fail-open + no-network-by-default shape of the existing hooks.
- Bump `$LatestKnownVersion` in the preflight when a new PowerShell ships, or set
  `UNIFACE_PREFLIGHT_ONLINE=1` for a throttled live check.
- Related: [protect-secrets-and-proprietary.md](protect-secrets-and-proprietary.md),
  [quote-paths-with-spaces.md](quote-paths-with-spaces.md); hooks documented in
  [../hooks/README.md](../hooks/README.md).
