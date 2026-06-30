# Rule: always quote paths that contain spaces

**Scope:** All shell commands (PowerShell and Bash), command-line arguments,
scripts (`.bat`/`.ps1`/`.sh`), config values, and documentation examples in this
workspace.

## Rule

Any filesystem path that contains a space **must** be quoted so it is passed as a
single argument. This applies to executables, switch values, working directories,
and environment values alike.

Paths **may** contain spaces — and a client's Uniface install often lives under
`C:\Program Files\Rocket Uniface 10 Community Edition\...` (two spaced segments),
so this comes up constantly. This machine's install was deliberately placed at the
space-free `C:\ref` to defuse the problem at the source (see worklog/011), but the
rule still holds defensively: any spaced path — project dirs, user profiles, client
installs — must be quoted as a whole token.

## Why

An unquoted spaced path is split on the first space and the program receives a
truncated value. This is exactly what broke the IDE launch on 2026-06-27: an
unquoted `/adm=...` value made Uniface look for `usys.ini` in the wrong place and
`ide.exe` exited immediately. See
[docs/uniface-10-onboarding.md](../../docs/uniface-10-onboarding.md) §1.1 and
[worklog/002-ide-architecture-analysis.md](../../worklog/002-ide-architecture-analysis.md).

## How to apply

- **Quote the whole switch token** when a switch value contains spaces — quotes
  go around the entire `name=value`, not just the path:
  - ✅ `"/adm=C:\Program Files\Rocket Uniface 10 Community Edition\uniface\adm"`
  - ❌ `/adm="C:\Program Files\...\adm"`  (some tools mis-parse this)
  - ❌ `/adm=C:\Program Files\...\adm`    (splits on the first space)
- **Executable paths:** invoke with quotes, and in PowerShell use the call
  operator: `& "C:\Program Files\...\app.exe" ...`.
- **PowerShell `Start-Process`:** put the spaced value inside the argument string
  with embedded quotes, e.g.
  `Start-Process $exe -ArgumentList '"/adm=C:\Program Files\...\adm" ?' -WorkingDirectory $wd`.
- **Bash tool on Windows paths:** quote the path — `ls "C:/Program Files/..."` —
  or prefer forward slashes; still quote when spaces are present.
- **Working directories and env values:** quote them too
  (`-WorkingDirectory "C:\Users\...\project\"`).
- **Prefer absolute, quoted paths** over relying on the current directory.
- **In docs and scripts:** show the quoted form in every example so the pattern
  is copy-paste safe.

## Verification habit

Before running a command that includes a path, scan it for spaces; if any path
segment has a space and is not inside quotes, fix it before executing.
