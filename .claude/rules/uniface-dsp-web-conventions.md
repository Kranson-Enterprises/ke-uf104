# Rule: Uniface DSP web-component conventions

**Scope:** Any work on **Dynamic Server Pages (DSP)** — client-side JavaScript,
the web page layout, web triggers/operations, and the HTML5/CSS authored for them.
Grounded in [docs/uniface-10-onboarding.md](../../docs/uniface-10-onboarding.md) §1.6
and [worklog/009](../../worklog/009-dsp-capabilities-web-research.md).

## Rule

- **The page layout is a repository object, not an on-disk file.** A DSP's XHTML is
  authored in the Component Editor's **Design Layout** worksheet and *compiled into*
  the runtime object. The `*.dsp` under `project\resources\` and the
  `webapps\uniface\dspjs\<name>.js` are **generated output — never hand-edit them**;
  they are overwritten on every compile. Round-trip the component via XML
  Export/Import for VCS (see [uniface-repository-source-of-truth.md](uniface-repository-source-of-truth.md)).
- **Use the real Uniface 10 JavaScript API names.** The client API hangs off the
  global **`uniface`** object:
  `uniface.getInstance()` → `getEntity()` → `getOccurrence(s)()` → `getField(s)()`,
  then **`getValue()` / `setValue()`** and `getProperty()` / `setProperty()` /
  `setProperties()` on the field. These do **not** exist in Uniface — do not invent
  them: ❌ `getFieldValue`/`setFieldValue`, ❌ `uniface.callServer`, ❌ a `$w="…"`
  trigger syntax (those are other frameworks).
- **Cross the client/server boundary the documented way.** Client→server =
  **`uniface.activate()` / `uniface.createInstance()`** (asynchronous — they
  **return Promises**, so `await`/`.then()`); server→client = the ProcScript
  **`webactivate`** statement (queues a client `weboperation`). Declare client logic
  with **`webtrigger` / `weboperation`** (ProcScript wrapper, body in
  `javascript … endjavascript`) so Uniface manages scope and parameters.
- **`OnChange` fires on *interactive* change only** — it does **not** fire when you
  set a value via the JS API (`setValue`). Don't rely on it to react to programmatic
  updates. In the browser, **all field values are strings** regardless of the modeled
  data type; convert/format yourself.
- **Author standards HTML5/CSS, and target evergreen browsers.** You may embed your
  own HTML5, `<style>`/`<link>`, and `<script>` in the layout; prefer **dynamic CSS
  hooks** (`class:Name`, which adds/removes one class) over `html:class` (replaces
  the whole class list); use `/ext` external `.hts` layouts if markup is maintained
  in another tool. **JavaScript must be enabled** or DSPs do not run.
- **Know which engine runs your code.** The **IDE** embeds CEF/Chromium (this install:
  CEF 141), but a **deployed DSP runs in the end user's own browser, not CEF** — test
  in the real target browser, not just the IDE preview. **ECMAScript:** the only level
  Rocket documents is **ES2015** (for Promises); treat **ES2015 as the floor**.
  Anything newer "works on a modern engine but isn't promised by the vendor" — if a
  build must guarantee a browser/ES baseline, confirm it against Rocket's gated
  **Platform Availability Matrix (PAM)**, not an open doc page.

## Why

DSP is the v10 web story, and its footguns are specific: editing generated output
(silently lost on recompile), inventing non-existent API names (from other JS
frameworks), expecting `OnChange` to fire on programmatic sets, and assuming a
modern-JS/browser baseline that Rocket never commits to in writing. Each wastes a
debug cycle; the verified facts above prevent them.

## How to apply

- Reach for **[/uniface-dsp-review](../commands/uniface-dsp-review.md)** to review or
  scaffold DSP client JS + layout against these conventions.
- When asked to "edit a DSP page," edit it in the IDE / via the component's XML
  export — not the on-disk `.dsp`/`dspjs` output.
- When writing or reviewing DSP JavaScript, check the API names against this rule and
  flag `getFieldValue`/`callServer`/`$w=` as wrong.
- Related: [uniface-repository-source-of-truth.md](uniface-repository-source-of-truth.md),
  [uniface-cli-and-build-hygiene.md](uniface-cli-and-build-hygiene.md),
  [quote-paths-with-spaces.md](quote-paths-with-spaces.md).
