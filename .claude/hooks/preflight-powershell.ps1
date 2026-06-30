# Preflight: PowerShell version & update advisory for this workspace's hooks/scripts.
#
# WHY: as PowerShell tooling grows in this repo, we want to stay on a supported,
# patched runtime. This is ADVISORY ONLY — it never blocks a tool call (always
# returns; never calls exit). It is dot-sourced by the other PreToolUse hooks and
# also wired as a SessionStart hook (run directly => -Announce).
#
# SECURITY POSTURE (deliberate, see worklog/015):
#   - SECURE BY DEFAULT = OFFLINE. It compares the running version against a
#     hard-coded $LatestKnownVersion. An auto-run hook making surprise outbound
#     network calls is itself a risk (exfil channel, external dependency), so the
#     online "latest release" refresh is OPT-IN via env UNIFACE_PREFLIGHT_ONLINE=1.
#   - When opted in, the network check is: pinned HTTPS URL (no user input => no
#     SSRF), 3s timeout, throttled to once / 24h via a temp state file, fail-SILENT
#     on any error (offline must never break a hook), and only a version string is
#     parsed from the response (nothing is executed).
#   - Set UNIFACE_PREFLIGHT_SILENT=1 to suppress all advisory output.
#
# Bump $LatestKnownVersion when a new PowerShell ships (or enable the online refresh).

$script:MinimumVersion     = [version]'7.4.0'   # supported LTS floor for our tooling
$script:LatestKnownVersion = [version]'7.6.3'   # current as of 2026-06-30 (user-confirmed)

function Invoke-PowerShellPreflight {
    [CmdletBinding()]
    param([switch]$Announce)

    try {
        if ($env:UNIFACE_PREFLIGHT_SILENT -eq '1') { return }

        $cur     = $PSVersionTable.PSVersion
        $edition = [string]$PSVersionTable.PSEdition   # 'Core' (pwsh 7+) or 'Desktop' (Windows PowerShell 5.1)

        # --- throttled, opt-in online refresh of the "latest" figure ---------------
        $latest    = $script:LatestKnownVersion
        $stateDir  = Join-Path $env:TEMP 'uniface-claude-preflight'
        $stateFile = Join-Path $stateDir 'ps-version-state.json'
        $state     = $null
        try { if (Test-Path $stateFile) { $state = Get-Content -Raw $stateFile | ConvertFrom-Json } } catch { $state = $null }

        if ($state -and $state.latestVersion) {
            try { $cached = [version]$state.latestVersion; if ($cached -gt $latest) { $latest = $cached } } catch { }
        }

        if ($env:UNIFACE_PREFLIGHT_ONLINE -eq '1') {
            $due = $true
            if ($state -and $state.lastCheckUtc) {
                try { $due = ((Get-Date).ToUniversalTime() - [datetime]$state.lastCheckUtc).TotalHours -ge 24 } catch { $due = $true }
            }
            if ($due) {
                try {
                    # Pinned, hard-coded HTTPS endpoint. No user input is interpolated.
                    $resp = Invoke-RestMethod -Uri 'https://api.github.com/repos/PowerShell/PowerShell/releases/latest' `
                                              -TimeoutSec 3 -Headers @{ 'User-Agent' = 'uniface-claude-preflight' } -ErrorAction Stop
                    if ($resp.tag_name -match '^v?(\d+\.\d+\.\d+)') {
                        $online = [version]$Matches[1]
                        if ($online -gt $latest) { $latest = $online }
                    }
                } catch { }   # fail SILENT: offline / rate-limited / DNS => keep the known value
                try {
                    if (-not (Test-Path $stateDir)) { New-Item -ItemType Directory -Path $stateDir -Force | Out-Null }
                    [pscustomobject]@{ lastCheckUtc = (Get-Date).ToUniversalTime().ToString('o'); latestVersion = $latest.ToString() } |
                        ConvertTo-Json | Set-Content -Path $stateFile -Encoding utf8
                } catch { }
            }
        }

        # --- evaluate & advise (stderr; throttled so it isn't spammy) --------------
        $msg = $null
        if ($edition -eq 'Desktop' -or $cur.Major -lt 7) {
            $msg = "SECURITY/COMPAT: hooks run on Windows PowerShell $cur (Desktop). Our hooks require PowerShell 7+ (pwsh). Install/upgrade: winget upgrade Microsoft.PowerShell"
        } elseif ($cur -lt $script:MinimumVersion) {
            $msg = "SECURITY: PowerShell $cur is below the supported LTS floor $($script:MinimumVersion). Upgrade: winget upgrade Microsoft.PowerShell  (latest known $latest)"
        } elseif ($cur -lt $latest) {
            $msg = "UPDATE: PowerShell $cur is behind $latest. Consider: winget upgrade Microsoft.PowerShell"
        } elseif ($Announce) {
            $msg = "PowerShell $cur OK (>= LTS $($script:MinimumVersion); latest known $latest)."
        }

        if (-not $msg) { return }

        # Throttle advisory output to at most once / 6h (skip throttle when -Announce).
        $advFile = Join-Path $stateDir 'ps-advisory-stamp'
        if (-not $Announce) {
            try {
                if (Test-Path $advFile) {
                    $age = (Get-Date) - (Get-Item $advFile).LastWriteTime
                    if ($age.TotalHours -lt 6) { return }
                }
            } catch { }
        }
        try {
            if (-not (Test-Path $stateDir)) { New-Item -ItemType Directory -Path $stateDir -Force | Out-Null }
            Set-Content -Path $advFile -Value (Get-Date).ToString('o') -Encoding utf8
        } catch { }

        [Console]::Error.WriteLine("[preflight-powershell] $msg")
    } catch {
        return   # advisory must never throw into a host hook
    }
}

# Direct execution (e.g. SessionStart hook: pwsh -File preflight-powershell.ps1) =>
# announce. When dot-sourced (. preflight-powershell.ps1) this guard is skipped and
# the caller invokes Invoke-PowerShellPreflight itself.
if ($MyInvocation.InvocationName -ne '.') {
    Invoke-PowerShellPreflight -Announce
}
