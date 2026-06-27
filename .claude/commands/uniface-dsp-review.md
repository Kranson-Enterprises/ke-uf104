---
description: Review or scaffold DSP client-side JavaScript and page layout against the verified Uniface 10 API and conventions
argument-hint: "[file/component to review, or 'scaffold <Component>' to generate a starter]"
allowed-tools: Read, Grep, Glob, Edit, Write
---

Help author or review **Dynamic Server Page (DSP)** client code so it matches the
verified Uniface 10 API. Grounded in
[docs/uniface-10-onboarding.md](../../docs/uniface-10-onboarding.md) §1.6,
[worklog/009](../../worklog/009-dsp-capabilities-web-research.md), and the rule
[uniface-dsp-web-conventions](../rules/uniface-dsp-web-conventions.md).

## Review mode (default)
Read the target ($ARGUMENTS — a file, a component's exported XML, or embedded
`javascript … endjavascript`) and check, reporting issues with line refs:

1. **Wrong API names** — flag and correct any of these (they are NOT Uniface 10):
   - ❌ `getFieldValue` / `setFieldValue` → ✅ `getField("FLD").getValue()` /
     `.setValue(v)`
   - ❌ `uniface.callServer(...)` → ✅ `uniface.activate(...)` /
     `uniface.createInstance(...)`
   - ❌ a `$w="…"` trigger binding → ✅ declare `webtrigger` / `weboperation` in
     ProcScript, body in `javascript … endjavascript`.
2. **Promise handling** — `activate()` / `createInstance()` are **async**; ensure
   results are `await`ed or `.then()`-chained, not used synchronously.
3. **Data addressing** — path should be
   `uniface.getInstance(...).getEntity(...).getOccurrence(...).getField(...)`; values
   are **strings** in the browser (flag missing parse/format).
4. **`OnChange` misuse** — flag logic that expects `OnChange` to fire after a
   programmatic `setValue` (it only fires on *interactive* change).
5. **Editing generated output** — if the target is `project\resources\*.dsp` or
   `webapps\uniface\dspjs\*.js`, STOP: that's compiler output. Edit the layout in the
   IDE / the component's XML export instead.
6. **CSS hooks** — prefer dynamic `class:Name` (adds/removes one class) over
   `html:class` (replaces the whole class attribute) when toggling state.
7. **ES baseline** — note any post-ES2015 syntax (optional chaining, top-level await,
   modules); it runs on modern engines but Rocket only documents ES2015. For a build
   that must guarantee a browser/ES floor, verify against the gated **PAM**.

## Scaffold mode (`scaffold <Component>`)
Emit a small, convention-correct starter the developer can paste into the component:
- a server `operation` + a client `weboperation` pair,
- a client `webtrigger OnChange` example reading a field with `getValue()`,
- an `await uniface.activate(...)` round-trip,
- a comment pointing layout authoring to the IDE Design Layout worksheet (not a
  hand-edited file).

Keep examples minimal and label client vs server clearly. Quote any spaced paths.

$ARGUMENTS = what to review, or `scaffold <Component>`.
