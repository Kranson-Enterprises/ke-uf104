---
description: Ordered, exit-code-gated batch /imp of a WorkArea-shaped XML tree (class subfolders) into a target repository
argument-hint: "<WorkArea root> [<working-dir/repo, defaults to root's parent>]"
allowed-tools: Read, PowerShell, Bash
---

Batch-import every `*.xml` under a **WAS/WorkArea-shaped tree** (one subfolder per object
class) into a Uniface repository, **in dependency order**, gated on each class's exit code.
Mirrors [/uniface-import](uniface-import.md) but automates the whole tree — built for the
WAS plugin Phase B (`IdePlugin\WorkArea\`) and reusable for any WorkArea sync.

**Preconditions (verify, don't assume):**
- The target repository must be **migrated/current** and **not open in another process** —
  the SLE (SQLite) repo takes an exclusive write lock, so **close any GUI IDE** holding it
  first (`Get-Process ide` → confirm gone). CLI `/imp` fails on an unmigrated repo.
- Resolve `/dir` = the working dir whose `dbms.asn` resolves `.\dbms\usys.db` to the target
  repo. For the WAS sandbox that's `…\WASListener\IdePlugin`.
- Quote spaced paths as whole tokens ([quote-paths-with-spaces](../rules/quote-paths-with-spaces.md)).

**Import order (dependencies first — projects reference everything, so last):**

```
ent  →  libinc libprc libsnp libein libfla libfsy  →  cpt  →  aps  →  prj
```

**Steps:**
1. Enumerate class subfolders actually present under the root; warn on any `*.xml` in a
   class **not** in the order list (don't silently skip it — add it in the right tier).
2. For each class in order, run one gated `/imp` with the class wildcard, from the sandbox
   working dir so the repo resolves correctly. **`ide.exe` is a GUI-subsystem exe — a bare
   `&` call does NOT wait and leaves `$LASTEXITCODE` blank, so you MUST use
   `Start-Process -Wait -PassThru` and read `.ExitCode`** (this is the trap that made the
   first Phase-B run report a false failure). Pass the `/imp` path **relative to the
   working dir including the `WorkArea\` segment** (`WorkArea\<class>\*.xml`), not
   `<class>\*.xml`:
   ```powershell
   $exe='C:\ref\common\bin\ide.exe'; $adm='C:\ref\uniface\adm'
   $dir='C:\Users\Bob\source\uniface\WASListener\IdePlugin'
   $root="$dir\WorkArea"
   $order='ent','libinc','libprc','libsnp','libein','libfla','libfsy','cpt','aps','prj'
   $fail=$null
   foreach ($c in $order) {
     $files = Get-ChildItem (Join-Path $root "$c\*.xml") -EA SilentlyContinue
     if (-not $files) { "SKIP $c"; continue }
     $o="$env:TEMP\imp_$c.out"; $e="$env:TEMP\imp_$c.err"
     $p = Start-Process $exe -ArgumentList "/dir=$dir","/adm=$adm","/imp","WorkArea\$c\*.xml","/nos" `
           -WorkingDirectory $dir -Wait -PassThru -NoNewWindow -RedirectStandardOutput $o -RedirectStandardError $e
     if ($p.ExitCode -ne 0) { Write-Error "IMPORT FAILED at '$c' (exit $($p.ExitCode))"; $fail=$c; break }
     "OK $c ($($files.Count) files)"
   }
   ```
   `/nos` allows supersede so forward references across classes resolve; import is
   idempotent (safe to re-run). Adjust with `/com=N` / `/int=N` for large sets if needed.
3. **Gate on `$p.ExitCode` per class** (0 = success, 1 = failure). Stop on first failure
   and report which class/file; the Uniface message log lands under `usyslog:` (from
   `usys.ini`, e.g. `…\uniface\log\ide_<pid>.log`) — read it for detail, not the console.
4. Report a per-class OK/FAIL summary and the total object count imported.

**After Phase B (WAS plugin):** operator reopens the IDE (`/uniface-launch-ide --was`),
opens project **`VERSIONCONTROL`** → **Compile** (Phase C), then Export All (Phase D).

Related: [uniface-import](uniface-import.md), [uniface-cli-and-build-hygiene](../rules/uniface-cli-and-build-hygiene.md),
[uniface-workarea-sync](../rules/uniface-workarea-sync.md), [docs/uniface-was-plugin-integration.md](../../docs/uniface-was-plugin-integration.md).
