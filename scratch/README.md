# `scratch/` — local staging for Uniface export/engine artifacts

**Gitignored holding area** (contents never committed). This is where Uniface
artifacts that the **IDE / engine** produces on disk are staged **inside the
workspace** — instead of the Claude scratchpad or ad-hoc `C:\temp`.

Use it for: IDE **Export** output, `$ude("export")` dumps, `/genSql` DDL you want to
eyeball, one-off inspection XML, and any pre-WorkArea staging.

**Not** for:
- **WorkArea objects** → those go to the tracked [`workarea/`](../workarea/README.md)
  tree (WAS layout, one XML per object).
- **Runtime / wasv output** (generated `.dsp` / `dspjs`, `project/resources/`,
  `project/dbms/`, logs) → those stay where the install/`.asn` place them and are
  gitignored there; don't move them here.
- **Claude's own tool-internal temp** (helper scripts, intermediate analysis) → that
  still uses the Claude session scratchpad per the harness.

**Promotion:** when a staged artifact is ready for version control, **copy** it into the
tracked tree (`workarea/<class>/`, `components/`, `src/`) by an explicit, reviewed step —
don't leave deliverables in `scratch/`, and don't `/imp` or commit straight from here
blindly.

Rule: [.claude/rules/uniface-export-staging.md](../.claude/rules/uniface-export-staging.md).
