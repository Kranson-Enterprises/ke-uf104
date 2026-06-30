# Rule: Uniface trigger & ProcScript placement (module inheritance)

**Scope:** Where ProcScript modules — **triggers, operations, functions, entries** —
are declared across the **model → component → entity → field** hierarchy, and how
inheritance resolves them. Verified against the Rocket Uniface Library 10.4
([worklog/013](../../worklog/013-library-pdf-verification.md)).

## Rule — how placement resolves (Uniface 10)

- **One script container, explicit modules.** Uniface 10 has **no separate trigger
  containers**. Each object has a single **Declarations + Script** container, and every
  module is **explicitly declared** — `trigger Name … end`, `operation Name … end`,
  `function`/`entry`. (This replaced Uniface 9's container model.)
- **Module-based *overlay* inheritance.** Components, entities, and fields inherit each
  module declared on the objects they're based on (modeled entity, subtype, modeled
  component). At compile time, local definitions are **added to** inherited ones, and a
  **same-type-same-name** local module **overlays (replaces)** the inherited one.
- **Fallback hierarchy** for an undefined trigger is **field → entity → component →
  application**. `callfieldtrigger` falls back up this chain.
- **⚠️ Silent override footgun.** Modeled entity/field code **is inherited but is *not*
  displayed** in the component editor. **Writing any script in a same-named trigger in
  the component overrides the modeled code** — including a trigger that holds only a
  comment. If you mean to *extend* model logic, call it explicitly; don't shadow it by
  accident.

## Rule — where logic *should* live

The target reinforces **database-entity and trigger interactions**, so keep logic at
the layer that owns it:
- **Shared business rules + database I/O → the model** (modeled entity/field triggers)
  or a dedicated **Entity Service** (single-entity business logic + DB access, reused by
  many components). This centralizes data access and keeps it identical across every
  presentation endpoint.
- **Presentation components (FRM / DSP / USP) stay thin** — UI wiring and endpoint-
  specific behavior only; inherit the model's data logic rather than re-implementing it
  per form. Overriding a modeled trigger in one component silently diverges that
  component from the model.
- **Operations** are declared in the **Operations trigger**; entity-level operations go
  in the entity's **Collection Operations** / **Occurrence Operations** triggers.

## Rule — endpoint-aware triggers

A field's available triggers depend on **how it is rendered**
([uniface-character-and-web-endpoints.md](uniface-character-and-web-endpoints.md)):
- **Character mode (Unifields):** only **`detail`, `help`, `loseFocus`,
  `startModification`, `valueChanged`** fire. GUI-only events (mouse, getFocus on a
  widget, etc.) **do not exist** there — don't hang required logic on them if the
  endpoint is a character terminal.
- **DSP (web):** client logic uses `webtrigger`/`weboperation`; **`OnChange` fires on
  interactive change only**, never on a JS `setValue`
  ([uniface-dsp-web-conventions.md](uniface-dsp-web-conventions.md)).
- Put cross-endpoint data rules in the **model** so they fire regardless of rendering.

## Why

Module-overlay inheritance is predictable but easy to defeat by accident: a stray
local trigger silently replaces tested model logic, and logic placed in a presentation
component doesn't reach other endpoints. Centralizing data/business rules in the model
or entity services — and knowing which triggers a given rendering even fires — is what
keeps a character-form + web-endpoint application consistent.

## How to apply

- When asked to "add a trigger/operation," first ask **which layer owns the behavior**
  (model vs component) and **which endpoint(s)** render the field; place it accordingly
  and flag any override of inherited model code.
- Review a component's placement/portability with
  **[/uniface-endpoint-review](../commands/uniface-endpoint-review.md)**.
- Related: [uniface-repository-source-of-truth.md](uniface-repository-source-of-truth.md),
  [uniface-object-naming.md](uniface-object-naming.md),
  [uniface-character-and-web-endpoints.md](uniface-character-and-web-endpoints.md).
