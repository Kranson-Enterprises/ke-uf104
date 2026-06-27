# 002 IDE Architecture Analysis

**Date:** 2026-06-27
**Subject:** What makes the Uniface 10.4.03 CE IDE's "modern UI" modern — and the
correct way to launch `ide.exe` from the command line.
**Method:** Empirical inspection of the installed binaries and the live process
(loaded modules + child processes), not documentation alone.

## Objective

Verify the onboarding-doc claim (§1.1) that the Uniface 10 IDE has "a modern UI
and a Workspace-centric model," and understand *how* the UI is built — the docs
describe it as platform-independent / Fluent-like.

## Method

1. Inspected `common\bin\ide.exe` metadata and the `bin` DLL inventory.
2. Launched the IDE and enumerated the running process's loaded modules and
   child processes via PowerShell (`Get-Process`, `.Modules`).

## Key findings

### The "modern UI" is embedded Chromium (CEF)
The IDE is a **Chromium Embedded Framework (CEF) shell rendering an HTML/CSS/JS
UI**, driven by the native Uniface runtime engine. Evidence from the live
`ide.exe` (PID observed at runtime):

| Signal | Value |
| --- | --- |
| `libcef.dll` | **CEF 141.0.5 / Chromium 141.0.7390.55** |
| `chrome_elf.dll` | 141.0.7390.55 (matches) |
| Renderer subprocesses | **8 × `cefrender.exe`** (Chromium multi-process model) |
| `libcef.dll` size on disk | ~236 MB (the bulk of the install's `bin`) |
| Native Uniface runtime | `yrtl.dll` 10.4.03 042 |
| Support libs | `xerces-c` (XML), `libcryptou` (OpenSSL 3.5.6), `lsapiw64` (licensing), ICU |
| Total modules loaded | 164 |

- `ide.exe` itself is a thin ~1 MB launcher; the engine lives in the runtime DLLs.
- Chromium **141** is recent (exe built 2026-05-18) → Rocket tracks upstream
  closely, a positive security signal.
- **Conclusion:** the modern UI is web technology in a browser shell, not native
  Win32/WPF widgets — which is exactly why it is platform-portable and styled
  "Fluent"-like.

### Command-line launch gotcha (paths with spaces)
The IDE exited within seconds on the first launch attempt. Root cause (diagnosed
by the operator): the install paths contain spaces, and the `/adm` switch value
was not quoted as a single token, so Uniface looked for `usys.ini` in the wrong
place and aborted.

- `usys.ini` lives at `uniface\adm\usys.ini` (also a copy in `common\adm\`) — the
  directory `/adm` points to.
- **Fix:** quote the *entire* token and launch from the project working dir,
  matching Rocket's own `IDE.lnk`:

  ```
  "C:\Program Files\Rocket Uniface 10 Community Edition\common\bin\ide.exe" "/adm=C:\Program Files\Rocket Uniface 10 Community Edition\uniface\adm" ?
  ```
  - Working directory: `C:\Users\<user>\Rocket Uniface 10 Community Edition\project\`
  - The trailing `?` is a genuine argument from Rocket's shortcut (not a typo).
- `urouter.exe` (Uniface Router) runs in the background and is used by the IDE for
  the dev/debug tiers — expected.

## Outcome

- Onboarding doc §0 and §1.1 updated: the modern-UI `[verify]` tag is resolved
  with the architecture evidence above, and a "Launching from the command line"
  gotcha section was added. See
  [docs/uniface-10-onboarding.md](../docs/uniface-10-onboarding.md).
- A project rule was added to always quote paths containing spaces (see
  `.claude/rules/`), to prevent a recurrence of the launch failure.

## Follow-ups

- Inspect `ide.asn` to see how the dev environment is wired (next exploration).
- Consider probing the CEF remote-debugging interface, if exposed, to view the
  IDE's DOM/JS layer directly.
- Still open from onboarding §5: exact Workspace definition, deploy/export steps,
  `.asn` section syntax, CE connector limits.
