# 006 Command-Line Usage & Claude Command Suite

**Date:** 2026-06-27
**Sequence:** 001 (Claude setup) → 002 (CEF IDE) → 003 (spaces-in-paths) →
004 (environment definitions) → 005 (source-of-truth & VSCode) →
**006 (CLI usage + Claude commands)**.
**Purpose:** Consolidate the verified Uniface 10 command-line usage into a usable
reference, and document the `.claude/commands/` suite built on top of it to drive
future development.
**Basis:** Gated Rocket *Command Line Interface* / *Command Line Switches* /
*Export and Import Facilities* docs (saved locally in gitignored `webfetched/`,
2026-06-27) + the live 10.4.03 CE install. Confidence: ✅ verified, 📘 docs,
⚠️ guidance.

---

## 1. Uniface command-line usage (verified)

Syntax: `Executable {Switch {SubSwitches}}… {AppShell} {Parameters}`. Executables:
`ide`, `uniface`, `urouter`, `userver`, `udbg`. Quote spaced paths as **whole
tokens** (see worklog/003). The trailing **`?`** opens the command-line dialog.

### Compile ✅
- `ide.exe /all` — compile **everything** (= `/obj /sig /dsp /usp /frm /rpt /svc
  /esv /ssv /ceo /app /dtd`).
- `ide.exe /cpt` — compile **all components** (= `/dsp /usp /frm /rpt /svc /esv /ssv`).
- Per-type: `/frm` `/rpt` `/svc` `/dsp` `/usp` `/esv` `/ssv` (wildcards allowed,
  e.g. `/svc *VAL`).
- Sub-switches: **`/nodebug`** (production — non-debuggable), `/cmi=0|1` (compiled
  module info; default 1), `/sym=0..3` (symbol table / `UXCROSS` xref),
  `/aft=`/`/bef=DateTime` (changed-since), `/inf`/`/war`/`/lis` (verbosity),
  `/iap`/`/tpl`/`/plt` (purpose).
- **Production build:** `ide.exe /all /nodebug` → output to `$RESOURCES_OUTPUT`,
  packaged as **UAR**.

### Import / Export ✅
- **Import:** `ide.exe /imp FileName` — imports XML Repository definitions; exit
  code **0** success / **1** failure (scriptable). Sub-switches `/nos` `/com=N` `/int=N`.
- **Export:** **no CLI switch** — use the IDE (Main Menu (≡)/Actions → Export with
  a retrieve profile) or `$ude("export")` under `ide.exe` (XML, optionally zipped).
- **Data Copy:** `/cpy` copies entity *occurrences* only. **CAUTION: never use
  `/cpy` for Repository definitions — it can corrupt the Repository.** Files made
  by `/cpy` are rejected by `/imp`.

### Schema / DDL ✅
- `ide.exe /gensql {/meta} createTable|createScript entity.model <db>` — generate
  DBMS-specific DDL (tables, indexes, RI) for a target connector (`ORA`, `MSS`, …).
  Not for SEQ/TXT/ODBC. Enables the **SQLite-dev → enterprise-prod** path.

### Topology ✅
- Server processes are defined in **`urouter.asn` `[SERVERS]`**, e.g.
  `wasv = "…userver.exe" /dir=… /adm=… /asn=wasv.asn`.
- CE default ports (`usys.ini [install]`): Router `13001`, Tomcat `8080`, debug `13002`.

### Operational caveats ⚠️
- CLI execution **fails if the Repository has unmigrated/incompatible data** — open
  an interactive IDE session first to migrate.
- Two corrected hypotheses from earlier (names ≠ meaning): **`/ex`** = exclusive
  server (not export); **`/pkg`** = Java call-in package (not UAR packaging).

---

## 2. Claude command suite (`.claude/commands/`)

Project slash commands that turn the above into repeatable workflows. Each is a
prompt that encodes the verified facts so future runs don't repeat solved
problems. Design principles:
- **Quote spaced paths** as whole tokens (rule + PreToolUse hook).
- **Resolve paths from `usys.ini [install]`** (project dir, ports) instead of
  hardcoding a user directory — keeps them portable/shareable.
- **Check exit codes**, and surface the **unmigrated-repo** and **`/cpy`** footguns.

| Command | Drives |
| --- | --- |
| `/build` | Batch build (`setup-env.bat` + `build.bat`). |
| `/uniface-launch-ide` | Launch the IDE with correct `/adm` quoting + project workdir. |
| `/uniface-compile` | CLI compile (`/all /nodebug` default; targeted via args). |
| `/uniface-import` | Import XML definitions (`/imp`) with exit-code check. |
| `/uniface-export` | Export to XML for VCS (IDE / `$ude`; no CLI switch). |
| `/uniface-gensql` | Generate target-DBMS DDL for deployment. |
| `/uniface-asn-review` | Review an `.asn` against the dev→prod checklist. |
| `/uniface-cli` | Print the verified CLI cheat-sheet (no execution). |
| `/worklog-new` | Create the next sequential `worklog/00X` entry. |

These are **committed/shared** config (see [001](001-claude-integration-setup.md));
personal memories and the proprietary `webfetched/` docs stay gitignored.

---

## 3. How this drives future development

- **Onboarding:** a new developer runs `/uniface-cli` and reads
  [docs/uniface-10-onboarding.md](../docs/uniface-10-onboarding.md) §3.5.
- **Daily loop:** edit in the IDE → `/uniface-export` → commit XML →
  `/uniface-compile` → test; `/uniface-asn-review` before promoting an environment.
- **Deployment/CI:** `/uniface-compile` (`/all /nodebug`) → UAR, `/uniface-gensql`
  for target DDL, `/uniface-import` to seed a repo — all with exit-code gating.

---

## 4. Open items (need the live IDE UI)

1. Precise in-IDE **"Workspace"** definition vs. the project directory.
2. IDE **deploy/export** click-path + **export granularity** (one file per object?).
3. Exact 10.4 **ProcScript status-variable** set (`$status`/`$procerror`…).
4. Where **DSP/SSP web assets** live on disk; whether `#file` disk includes work.

> **Update (2026-06-27):** Items 1–3 and the on-disk-asset part of 4 are resolved
> in [008](008-sample-driven-export-verification.md) and
> [009](009-dsp-capabilities-web-research.md) (Workspace = project context; Export
> granularity selectable; status vars `$status`/`$procerror`/`$procerrorcontext`;
> DSP markup is repository-stored). Only the **`#file` disk-include** question
> remains open. The command suite has since gained
> **[/uniface-dsp-review](../.claude/commands/uniface-dsp-review.md)** (review/scaffold
> DSP client JS + layout) — see [009](009-dsp-capabilities-web-research.md).

---

## References
- In-repo: [docs/uniface-10-onboarding.md](../docs/uniface-10-onboarding.md) (§3.5,
  §2.3), [005-v10-source-of-truth-and-vscode-workflow.md](005-v10-source-of-truth-and-vscode-workflow.md),
  [004-ide-environment-definitions-and-asn-guidance.md](004-ide-environment-definitions-and-asn-guidance.md).
- Command suite: [../.claude/commands/](../.claude/commands/) (+ its `README.md`).
- Saved source docs: gitignored `webfetched/` (Rocket proprietary — not committed).
