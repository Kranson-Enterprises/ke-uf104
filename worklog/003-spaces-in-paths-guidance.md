# 003 Spaces in Paths — Guidance & Understanding

**Date:** 2026-06-27
**Purpose:** Explain *why* spaces in filesystem paths break commands, *how*
different shells handle quoting, and *what* this project does about it (a rule +
an enforcement hook). Written to be teachable to another developer.

---

## 1. Why a space breaks a command

A command line is **tokenized into arguments by whitespace** before the target
program ever sees it. The space is the default argument separator. So an
unquoted path that contains a space is split into multiple arguments:

```
ide.exe /adm=C:\Program Files\...\adm
                     ^ split here
```
The program receives `/adm=C:\Program` as one argument and `Files\...\adm` as a
second, unrelated one. It never sees the path you meant.

**This is not a bug in the program — it is how the shell works.** The fix is to
tell the shell "this whole thing is one argument" by **quoting** it.

### The concrete failure that prompted this (Uniface IDE)
On 2026-06-27 the Uniface 10 IDE (`ide.exe`) exited within seconds of launch.
Root cause: the `/adm=` switch pointed at
`C:\Program Files\Rocket Uniface 10 Community Edition\uniface\adm` (two spaced
segments) and was not quoted as a single token. Uniface resolved a truncated
path, failed to find `usys.ini`, and aborted. Quoting the whole token fixed it.
See [002-ide-architecture-analysis.md](002-ide-architecture-analysis.md).

---

## 2. Where to put the quotes

The non-obvious part: for a `name=value` switch whose **value** has spaces, quote
the **entire token**, not just the value.

| Form | Result |
| --- | --- |
| `/adm=C:\Program Files\...\adm` | ❌ splits on first space |
| `/adm="C:\Program Files\...\adm"` | ⚠️ works in many shells, but some tools mis-parse the embedded quote |
| `"/adm=C:\Program Files\...\adm"` | ✅ entire token is one argument — safest |

The third form is what Rocket's own Start-Menu `IDE.lnk` uses, so we standardize
on it.

---

## 3. How each shell/tool wants it

### cmd.exe / `.bat`
- Quote with double quotes: `"C:\Program Files\app.exe"`.
- Quote the whole switch token: `"/adm=C:\Program Files\...\adm"`.
- Inside `.bat`, also beware `%VAR%` expansion containing spaces — quote
  `"%MYPATH%"`.

### PowerShell
- To **run** an executable whose path has spaces, use the **call operator** `&`:
  ```powershell
  & "C:\Program Files\Rocket Uniface 10 Community Edition\common\bin\ide.exe" arg1 arg2
  ```
  Without `&`, PowerShell treats a quoted string as a *string literal*, not a
  command to execute.
- With `Start-Process`, pass the spaced value inside the argument string with
  embedded quotes, and quote the working directory:
  ```powershell
  Start-Process $exe -ArgumentList '"/adm=C:\Program Files\...\adm" ?' -WorkingDirectory "C:\Users\...\project\"
  ```
  (This project hit exactly this: a naive `-ArgumentList` of a spaced value got
  re-split; embedding the quotes in the argument string fixed it.)
- Prefer `Join-Path` to build paths, and keep variables quoted when interpolated:
  `& $exe "$dir\file.txt"`.

### Bash (incl. the Bash tool on Windows)
- Quote the path: `ls "C:/Program Files/..."` — or prefer forward slashes and
  still quote when spaces are present.
- Variables: always `"$path"`, never bare `$path`, when the value may contain
  spaces.

---

## 4. Best-practice habits

1. **Quote by default** any path that *could* contain a space — don't wait to be
   surprised.
2. **Prefer absolute, quoted paths** over depending on the current directory.
3. **Avoid spaced paths you control.** You can't change `C:\Program Files`, but
   you can keep *your* project/output dirs space-free.
4. **Copy the vendor's own launcher.** When in doubt about a third-party tool's
   exact invocation, read its installed shortcut (`.lnk`) — it encodes the
   correct quoting, working directory, and arguments.
5. **Show the quoted form in docs and scripts**, so examples are copy-paste safe.

---

## 5. What this project enforces

Two layers, both committed under `.claude/`:

- **The rule** — [.claude/rules/quote-paths-with-spaces.md](../.claude/rules/quote-paths-with-spaces.md),
  referenced from [CLAUDE.md](../CLAUDE.md) so it loads every session. This is
  *guidance* the AI assistant follows.
- **The enforcement hook** — [.claude/hooks/check-quoted-paths.ps1](../.claude/hooks/check-quoted-paths.ps1),
  a `PreToolUse` hook wired in `.claude/settings.json`. It **blocks** any
  `Bash`/`PowerShell` command that references a known spaced fragment (e.g.
  `Program Files`) outside of quotes, returning guidance instead of running the
  broken command.

### Understand the hook's limits (important)
The hook is a **heuristic, not a shell parser**, and deliberately **fails open**:

- It only catches a **curated list** of known spaced fragments — new spaced paths
  must be added to `$fragments` in the script or they pass unchecked.
- It cannot, in general, tell whether a space continues a path or separates two
  arguments — that ambiguity is the root problem, so perfect detection is
  impossible.
- Its quote detection is naive (here-strings, escaping, nested quotes can fool
  it → occasional false positive/negative).
- It checks only that a fragment is inside *some* quotes, not that the *whole
  token* is quoted correctly.

Full caveat list: [.claude/hooks/README.md](../.claude/hooks/README.md). The hook
prevents the common crash; the rule and this document cover the nuance the hook
cannot.

> **Activation note:** Claude Code loads hooks at session start, so the hook
> takes effect after a session restart (or a `/hooks` review), not mid-session.
