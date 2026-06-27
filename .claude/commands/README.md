# Project slash commands

Each `*.md` file here becomes a `/command` available in this project. The file
body is the prompt; optional frontmatter sets `description`, `argument-hint`,
and `allowed-tools`. Use `$ARGUMENTS` (or `$1`, `$2`, ...) for args, and prefix
a line with `!` to run a shell command whose output is injected.

See [build.md](build.md) for a working example (`/build`).

## Available commands

Grounded in the verified analysis in
[docs/uniface-10-onboarding.md](../../docs/uniface-10-onboarding.md) (§3.5) and
worklog 002/004/005. All embed the spaced-path quoting rule and read `usys.ini`
`[install]` for paths rather than hardcoding a user directory.

| Command | What it does |
| --- | --- |
| `/build` | Build via the batch scripts (`ide.exe /all /nodebug` → UAR). |
| `/uniface-launch-ide` | Launch the IDE with correctly quoted `/adm` + project workdir. |
| `/uniface-compile` | CLI compile (`/all /nodebug` by default; targeted via args). |
| `/uniface-import` | Import XML definitions (`/imp`) with exit-code check. |
| `/uniface-export` | Export to XML for VCS (IDE / `$ude` — no CLI export switch). |
| `/uniface-gensql` | Generate target-DBMS DDL (`/genSql`) for deployment. |
| `/uniface-asn-review` | Review an `.asn` against the dev→prod checklist. |
| `/uniface-cli` | Print the verified CLI cheat-sheet (no execution). |
| `/uniface-dsp-review` | Review or scaffold DSP client JS + layout against the verified API. |
| `/worklog-new` | Create the next sequential `worklog/00X` entry. |

**Note:** the compile/import/gensql commands run `ide.exe` against the
Repository; if it has unmigrated/incompatible data, CLI runs fail — open the
interactive IDE once to migrate first.
