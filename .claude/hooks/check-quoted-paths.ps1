# PreToolUse hook: block shell commands that reference a known spaced path unquoted.
#
# Reads the PreToolUse JSON payload from stdin. If a Bash/PowerShell command
# contains a known directory fragment that has spaces (e.g. "Program Files") and
# that occurrence is NOT inside a quoted span, the hook exits 2 to block the call
# and writes guidance to stderr (shown to Claude).
#
# Design: heuristic, not a shell parser. It FAILS OPEN — any error or unparseable
# input results in exit 0 (allow), so a bug here never blocks legitimate work.
# See .claude/hooks/README.md for the full list of caveats.

$ErrorActionPreference = 'Stop'

# Advisory PowerShell version/update preflight (never blocks; see preflight-powershell.ps1).
try { . "$PSScriptRoot/preflight-powershell.ps1"; Invoke-PowerShellPreflight } catch { }

try {
    $raw = [Console]::In.ReadToEnd()
    if ([string]::IsNullOrWhiteSpace($raw)) { exit 0 }
    $payload = $raw | ConvertFrom-Json
} catch {
    exit 0   # fail open: can't read/parse -> don't block
}

try {
    $tool = [string]$payload.tool_name
    if ($tool -ne 'Bash' -and $tool -ne 'PowerShell') { exit 0 }

    $cmd = [string]$payload.tool_input.command
    if ([string]::IsNullOrWhiteSpace($cmd)) { exit 0 }

    # Directory fragments that contain spaces and essentially always need quoting.
    # Order matters: list more specific fragments first. Extend this list as new
    # spaced paths enter the project.
    $fragments = @(
        'Program Files (x86)',
        'Program Files',
        'Rocket Uniface 10 Community Edition'
    )

    # Index ranges of quoted spans ("..." and '...') so we can ignore matches
    # that are already quoted.
    $spans = @()
    $rx = [regex]'"[^"]*"|''[^'']*'''
    foreach ($m in $rx.Matches($cmd)) {
        $spans += ,@($m.Index, ($m.Index + $m.Length - 1))
    }

    function Test-InQuotedSpan([int]$idx, $spans) {
        foreach ($sp in $spans) {
            if ($idx -ge $sp[0] -and $idx -le $sp[1]) { return $true }
        }
        return $false
    }

    $violations = @()
    foreach ($frag in $fragments) {
        $start = 0
        while (($i = $cmd.IndexOf($frag, $start)) -ge 0) {
            if (-not (Test-InQuotedSpan $i $spans)) {
                $violations += $frag
                break
            }
            $start = $i + $frag.Length
        }
    }

    if ($violations.Count -gt 0) {
        $reason = @"
BLOCKED by .claude/hooks/check-quoted-paths.ps1: a path containing spaces appears
UNQUOTED in this command. Unquoted spaced fragment(s): $($violations -join ', ').

Fix: quote the ENTIRE token so it is passed as a single argument, e.g.
  "/adm=C:\Program Files\Rocket Uniface 10 Community Edition\uniface\adm"
For an executable in PowerShell, use the call operator with quotes:
  & "C:\Program Files\Rocket Uniface 10 Community Edition\common\bin\ide.exe" ...

See .claude/rules/quote-paths-with-spaces.md for the full rule.
"@
        [Console]::Error.WriteLine($reason)
        exit 2   # block the tool call
    }

    exit 0
} catch {
    exit 0   # fail open on any unexpected error
}
