---
description: Review a component for character-mode + web (DSP/USP) rendering portability — flag GUI-only props/triggers, text overflow, and misplaced logic
argument-hint: "[component / exported XML / script to review]"
allowed-tools: Read, Grep, Glob
---

Audit a Uniface component against the **real delivery endpoints** of this application —
**character-mode Form delivery to a non-GUI terminal** and **web-rendered server pages
(DSP/USP)** — so a component that looks right in a GUI exercise doesn't silently break
on the character or web target. Grounded in
[.claude/rules/uniface-character-and-web-endpoints.md](../rules/uniface-character-and-web-endpoints.md),
[uniface-trigger-placement.md](../rules/uniface-trigger-placement.md), and
[uniface-dsp-web-conventions.md](../rules/uniface-dsp-web-conventions.md)
(Library 10.4, [worklog/013](../../worklog/013-library-pdf-verification.md)).

`$ARGUMENTS` = the component name, its exported XML, or a script file. If the target
endpoint isn't obvious, **state your assumption** (default: character + web, not GUI).

## What to check (report per finding, with endpoint + fix)

1. **Name the endpoint(s)** the component targets up front (FRM-character, DSP-web,
   USP-web, GUI-exercise). Frame every finding against those.
2. **GUI-only properties that no-op in character mode** — colors, proportional fonts,
   rich widget props, *highlight-when-active*. These are **silently ignored** on a
   character terminal (not errors), so flag any reliance on them and note the field
   renders as a **Unifield** (basic video attrs only: bright/underline/inverse/blink).
3. **Text-overflow risk** — labels/fields whose text is long enough to **truncate** in
   fixed-width character cells. Suggest shorter text / monospace width check.
4. **Endpoint-invalid triggers** — for character (Unifield) fields, only `detail`,
   `help`, `loseFocus`, `startModification`, `valueChanged` fire; flag logic on
   GUI-only events. For DSP, flag `OnChange`-after-`setValue` assumptions and
   non-Uniface JS API names (defer deep DSP checks to `/uniface-dsp-review`).
5. **Misplaced logic** — business rules / database I/O sitting in the presentation
   component instead of the **model / entity service**; flag local triggers that
   **override inherited modeled code** (silent divergence).
6. **Portability of file handling** — ProcScript file/dir names that aren't portable to
   the Unix/Linux character target (see
   [uniface-object-naming.md](../rules/uniface-object-naming.md)).

## Output
A concise, endpoint-tagged findings list (most-impactful first) and, at the end, a
one-line **"keep-aware" note** restating which endpoints this component must satisfy.
Review only — propose fixes, don't apply them.
