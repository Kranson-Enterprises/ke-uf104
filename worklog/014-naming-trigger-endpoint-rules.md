# 014 Naming / trigger / endpoint rules + commands + hook

**Date:** 2026-06-30
**Sequence:** … → 012 (WorkArea) → 013 (Library PDF verification) →
**014 (naming/trigger/endpoint rules)**.
**Purpose:** Mine the verified Library 10.4 extract ([013](013-library-pdf-verification.md),
offline PDF in gitignored `webfetched/`) for **object-name/restriction** and **trigger
code-placement** facts, turn them into defensive [.claude/rules/](../.claude/rules/),
and add commands + a hook for development productivity — **blended throughout with the
target's real shape: character-mode Form delivery to a non-GUI terminal + web (DSP/USP)
endpoints**, GUI being exercise-only.
Confidence: ✅ all rule facts confirmed verbatim in the Library 10.4.

---

## 1. Facts mined from the Library (✅ verified)

**Object names** — ≤ **60** chars, `A–Z a–z 0–9 _`, **must begin with a letter**;
Uniface **uppercases** names so case can't distinguish them; **component namespace is
global** (unique across all component types). Tighter limits: **operations 32**,
**print-job models 16**. **Reserved words** = ProcScript statements/functions/data
types/directives/constants, Repository (Meta-Dict) entity names, DBMS/OS reserved
words, plus a specific token list (`HEADER`/`TRAILER`/`UNIS`/`DATE`/`*.FRM`/…). Custom
physical widget names must not start with **`U`**. **Cross-platform ProcScript file
names**: alphanumeric+`$` only, no spaces/`_`/`@`/`#`, no `Q`-prefix, generic
separators, `<255` bytes, prefix via `.asn` logical on `$oprsys`.

**Trigger / ProcScript placement** — Uniface 10 = **single Script container, module-
overlay inheritance**; every module (`trigger`/`operation`/`function`/`entry`)
explicitly declared. Inherited modeled code is **not shown** in the component, and a
local **same-type-same-name** module **silently overrides** it (footgun). Fallback
chain **field → entity → component → application**. Recommendation grounded in the
Library's **Entity Services** model: keep business rules + DB I/O in the **model /
entity service**, presentation components thin.

**Character-mode + web endpoints** — character mode renders **Unifields, not widgets**
(EditBox auto-maps); Unifields support **only basic video attrs (bright/underline/
inverse/blink)**. The engine **silently ignores any property the rendering doesn't
recognize** (GUI styling = no-op, not error, on a terminal); character cells **truncate**
overflowing text. Unifield fields fire only **`detail`/`help`/`loseFocus`/
`startModification`/`valueChanged`**. Web (DSP) is the browser engine, ES2015 floor,
`OnChange` interactive-only.

## 2. Authored this pass

**Rules** ([.claude/rules/](../.claude/rules/), wired into [CLAUDE.md](../CLAUDE.md)):
- **[uniface-object-naming.md](../.claude/rules/uniface-object-naming.md)** — name shape/
  length/case, global namespace, reserved words, portable ProcScript file names.
- **[uniface-trigger-placement.md](../.claude/rules/uniface-trigger-placement.md)** —
  module-overlay inheritance, silent-override footgun, model-vs-presentation placement,
  endpoint-dependent triggers.
- **[uniface-character-and-web-endpoints.md](../.claude/rules/uniface-character-and-web-endpoints.md)**
  — the "keep me aware" rule: target = character Forms + web; GUI is exercise-only;
  silent no-op / truncation failure modes.

**Commands** ([.claude/commands/](../.claude/commands/), in the [README](../.claude/commands/README.md)):
- **[/uniface-name-check](../.claude/commands/uniface-name-check.md)** — validate a
  proposed name against the rules before creating the object (no execution).
- **[/uniface-endpoint-review](../.claude/commands/uniface-endpoint-review.md)** — audit a
  component for character/web portability (GUI-only props/triggers, text overflow,
  misplaced logic); names the endpoint(s) and ends with a keep-aware note.

**Hook** ([.claude/hooks/](../.claude/hooks/), wired in `settings.json`):
- **[protect-generated-output.ps1](../.claude/hooks/protect-generated-output.ps1)** —
  PreToolUse `Write|Edit|NotebookEdit` guard blocking edits to generated output
  (`dspjs/*.js`, `*.dsp`, `webapps/uniface/*`, `project/resources/`, compiled
  `*.frm/.rpt/.svc/.cpt`). Fail-open, mirrors `check-quoted-paths.ps1`; tested
  block/allow/fail-open/non-edit paths.

**Memory** — `project-target-character-and-web-delivery` (the non-GUI target shape) +
INDEX line.

## 3. Notes
- The hook only blocks the **Edit/Write tools**; a deliberate shell write to a
  hand-maintained `/ext` `.hts` layout you own is still possible (documented in the
  hook + hooks README).
- All three rules cross-link each other and the existing DSP / source-of-truth / CLI
  rules.

## References
- **Source (local, not committed):** Library 10.4 PDF in `webfetched/` (see
  [013](013-library-pdf-verification.md)).
- In-repo: [CLAUDE.md](../CLAUDE.md) Rules section, the three new rules + two new
  commands + the hook, [009](009-dsp-capabilities-web-research.md) (DSP),
  [008](008-sample-driven-export-verification.md) (export mechanics).
