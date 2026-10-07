# PreToolUse hook: block Write/Edit to GENERATED Uniface output.
#
# Reads the PreToolUse JSON payload from stdin. If a Write/Edit/NotebookEdit targets a
# file that is compiler-generated output (a DSP runtime page, generated DSP client JS,
# or anything under a project resources/ output tree), the hook exits 2 to block the
# call and writes guidance to stderr (shown to Claude). These artifacts are overwritten
# on every compile, so hand-edits are silently lost — the source of truth is the
# repository object (edit in the IDE / via the component's XML export).
#
# Design mirrors check-quoted-paths.ps1: heuristic, FAILS OPEN — any error or
# unparseable input results in exit 0 (allow), so a bug here never blocks real work.
# See .claude/rules/uniface-dsp-web-conventions.md and uniface-repository-source-of-truth.md.

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
    if ($tool -ne 'Write' -and $tool -ne 'Edit' -and $tool -ne 'NotebookEdit') { exit 0 }

    # file_path (Write/Edit) or notebook_path (NotebookEdit)
    $path = [string]$payload.tool_input.file_path
    if ([string]::IsNullOrWhiteSpace($path)) { $path = [string]$payload.tool_input.notebook_path }
    if ([string]::IsNullOrWhiteSpace($path)) { exit 0 }

    # Normalize separators for matching.
    $p = $path.Replace('\', '/')

    # Patterns that identify compiler-generated output (regex, case-insensitive).
    $patterns = @(
        '/dspjs/[^/]+\.js$',        # generated DSP client JavaScript
        '\.dsp$',                   # generated DSP runtime page
        '/webapps/uniface/.+\.(js|html)$',  # deployed web output
        '/project/resources/',      # compiled component output tree
        '\.(frm|rpt|svc|cpt)$'      # compiled runtime objects (binary)
    )

    $hit = $null
    foreach ($rx in $patterns) {
        if ([regex]::IsMatch($p, $rx, 'IgnoreCase')) { $hit = $rx; break }
    }

    if ($hit) {
        $reason = @"
BLOCKED by .claude/hooks/protect-generated-output.ps1: '$path' looks like
COMPILER-GENERATED Uniface output, which is overwritten on every compile — hand-edits
are silently lost.

The source of truth is the repository object. Instead:
  - Edit the page layout in the IDE Component Editor (Design Layout worksheet), or
  - Edit the component's XML export and re-import via /imp, then recompile.

See .claude/rules/uniface-dsp-web-conventions.md and
.claude/rules/uniface-repository-source-of-truth.md. If this file is genuinely a
hand-maintained source (e.g. an /ext external .hts layout you own), proceed via a
direct shell write rather than this tool.
"@
        [Console]::Error.WriteLine($reason)
        exit 2   # block the tool call
    }

    exit 0
} catch {
    exit 0   # fail open on any unexpected error
}
