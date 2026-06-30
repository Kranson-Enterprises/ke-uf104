# Rule: character-mode & web rendering endpoints (target = non-GUI)

**Scope:** Any component work where the rendering target matters — **character-mode
Form (FRM) delivery to a non-GUI terminal** and **web-rendered server pages
(DSP/USP)**. This is the **primary delivery shape of this application**; rich Windows
GUI is used only for exercises, not as the product. Verified against the Rocket
Uniface Library 10.4 ([worklog/013](../../worklog/013-library-pdf-verification.md)).

## Context — what this application is

- The app uses Uniface's **platform independence** to render the **same server-side
  component** to different front ends. The product endpoints are:
  - **Character-mode Forms** — the server paints **Form (`.frm`) components to a
    non-GUI character terminal** (Unix/Linux, the `[chui]` runtime).
  - **Web endpoints** — **DSP** (Dynamic Server Page, client-side JS) and **USP**
    (Static Server Page) rendered into a browser.
- **GUI Windows forms are practice scaffolding** to reinforce database-entity and
  trigger interactions — *not* the deliverable. **Default to the character/web target**
  when reasoning about a component, and **call out** when advice is GUI-only.

## Rule — keep the operator aware of the real endpoint

When scaffolding, reviewing, or explaining a component, **state which endpoint(s) it
targets** and flag anything that won't survive there:

- **Character mode uses Unifields, not widgets.** GUI widgets are **not supported**; the
  engine renders fields as **Unifields** (EditBox auto-maps to a Unifield). Unifields
  handle all data types and work in GUI too, but support **only basic video attributes —
  bright, underline, inverse, blink** — no proportional fonts, colors, or rich widget
  props.
- **Unrecognized properties are silently ignored, not errors.** At runtime Uniface
  **drops any property the target rendering doesn't understand** and uses GUI defaults.
  So a GUI-only style "compiles fine" yet **does nothing** in character mode — never
  assume a property took effect on the character endpoint; verify on the real target.
- **Text overflows are truncated in character mode.** Fixed-width cells mean text that
  fit in a proportional GUI font **gets cut off**. Be economical with label/field text;
  sanity-check width as if in a monospace (Courier) font.
- **Limited field triggers in character mode.** Only `detail`, `help`, `loseFocus`,
  `startModification`, `valueChanged` fire on Unifields
  ([uniface-trigger-placement.md](uniface-trigger-placement.md)). Some attributes
  (e.g. *highlight-when-active*) are **"not valid in character mode."** Character menus
  are driven by the **`pulldown`** statement.
- **Web (DSP) is a different engine again** — the client is the **end user's browser**
  (not the IDE's CEF), values are **all strings**, `OnChange` is interactive-only, and
  the ES floor is **ES2015** ([uniface-dsp-web-conventions.md](uniface-dsp-web-conventions.md)).
- **Put data/business rules in the model**, not the presentation layer, so they behave
  identically whether the field is painted to a terminal or a browser
  ([uniface-trigger-placement.md](uniface-trigger-placement.md)).

## Why

The whole point of the platform-independent model is that one component serves many
front ends — but the failure mode is silent: GUI styling and GUI-only triggers
**don't error**, they just **no-op** on a character terminal, and text quietly
truncates. Surfacing the real endpoint at design/review time prevents shipping a form
that looks right in the GUI exercise but renders wrong on the character or web target.

## How to apply

- Reach for **[/uniface-endpoint-review](../commands/uniface-endpoint-review.md)** to
  audit a component for character/web portability (GUI-only props & triggers, text
  overflow, model-vs-presentation logic).
- In any component discussion, **name the endpoint** and keep the operator aware of the
  character-mode / web-rendered reality, even when the immediate exercise is a GUI form.
- Related: [uniface-dsp-web-conventions.md](uniface-dsp-web-conventions.md),
  [uniface-trigger-placement.md](uniface-trigger-placement.md),
  [uniface-object-naming.md](uniface-object-naming.md).
