# Rule: Uniface object naming & reserved-word restrictions

**Scope:** Naming any Uniface development object (model entities/fields, components,
operations, triggers, libraries, variables) and any file/directory name written in
**ProcScript**. Verified against the Rocket Uniface Library 10.4
([offline copy](../../webfetched/), see [worklog/013](../../worklog/013-library-pdf-verification.md)).

## Rule — object names

- **Charset & shape:** up to **60 characters**, `A–Z a–z 0–9 _`, and the name **must
  begin with a letter.** No spaces, no other punctuation.
- **Case is not significant.** Uniface **uppercases** every name, so you **cannot**
  use case to make two names distinct (`Cust` and `cust` are the same object). Don't
  rely on case anywhere — pick a single house convention and keep it.
- **Component namespace is global.** **All** component types share one namespace, so a
  component name must be **unique across the whole application** regardless of type
  (a FRM and a DSP cannot share a name).
- **Tighter limits apply to some object types** — honor the smallest that applies:
  - **Operations:** max **32** characters (`A–Z 0–9 _`, first char a letter). An
    operation added to a component must also be declared in its **Operations trigger**.
  - **Print job models:** max **16** characters (`A–Z 0–9 _`); reserved words barred.

## Rule — reserved words (never use as a name)

A name is reserved — and will be rejected or cause subtle breakage — if it is:
- a **ProcScript statement, function, data type, precompiler directive, or Uniface
  constant**;
- the name of a **Repository (Meta-Dictionary) entity** or of a table/file/overflow
  associated with one;
- a **DBMS / network / OS reserved word** on any target platform;
- one of the **specific reserved tokens** the Library lists (e.g. `HEADER`, `TRAILER`,
  `UNIS`, `DATE`, `TIME`, `LABEL`, `INHERIT`, `NAME16/NAME32`, and the `*.APS / *.DICT
  / *.FRM / *.TEXT / *.USYS` forms).

Double-quoting (`"DATE"`) *can* let a reserved word be used as an entity/field name,
but treat that as a last resort, not a habit — prefer a non-reserved name.

## Rule — platform-independent file/dir names in ProcScript

The target deploys to **non-Windows character terminals** (Unix/Linux) as well as
Windows, so file handling in ProcScript must be portable
([uniface-character-and-web-endpoints.md](uniface-character-and-web-endpoints.md)):
- Use only **alphanumeric + `$`** in file/dir names — **no** spaces, `_`, `@`, `#`.
- **Don't depend on case** (Unix is case-sensitive; Windows isn't). Avoid `SYS1`-style
  reserved names and names starting with **`Q`** (special on iSeries).
- Use **generic separators** (`/` or `[a.b]`), **relative paths**, and keep any path
  **< 255 bytes**. The platform-specific **PathPrefix** belongs in an **`.asn`
  logical**, branched on **`$oprsys`** — never hardcoded.
- Custom physical widget names **must not start with `U`** (reserved for Uniface's own
  widgets).

## Why

These limits are enforced by the engine and the DBMS, not stylistic: an over-length
or reserved name fails to compile or silently collides (global component namespace,
case-folding), and a Windows-only file name breaks on the character-mode Unix/Linux
target. Catching it at naming time avoids a compile/deploy round-trip.

## How to apply

- Validate a proposed name with **[/uniface-name-check](../commands/uniface-name-check.md)**
  before creating the object.
- Related: [uniface-trigger-placement.md](uniface-trigger-placement.md),
  [uniface-character-and-web-endpoints.md](uniface-character-and-web-endpoints.md),
  [quote-paths-with-spaces.md](quote-paths-with-spaces.md),
  [uniface-repository-source-of-truth.md](uniface-repository-source-of-truth.md).
