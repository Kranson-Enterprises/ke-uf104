# 013 Full Library PDF verification — doc claims vs. authoritative source

**Date:** 2026-06-30
**Sequence:** … → 011 (re-baseline) → 012 (WorkArea introduction) →
**013 (Library PDF verification)**.
**Purpose:** The user dropped the **full Rocket Uniface Library 10.4** PDF (44 MB,
`webfetched/rocket_uniface_library_10.4_6-30-2026.pdf`) into the gitignored
`webfetched/` folder and asked for a scan to check the workspace docs for any
needed corrections — ahead of running the public **Hello World** tutorial and
practicing with definitions in the IDE.
Confidence: ✅ confirmed verbatim in the Library · 🔎 nuance/refinement.

> **Provenance note:** the PDF is Rocket proprietary/licensed — it stays in
> `webfetched/` (gitignored) and is **never** committed. Only *findings* are
> recorded here. See [protect-secrets-and-proprietary](../.claude/rules/protect-secrets-and-proprietary.md).

---

## 1. Method

`pdftotext -layout` extracted the PDF to a scratchpad text file (278,804 lines),
then targeted greps verified each material claim our docs make — DSP/web API,
the CLI/export/import facility, and the gated-PAM uncertainty markers.

## 2. Confirmed correct (no change needed) ✅

The docs held up well against the authoritative source:

- **DSP client→server returns Promises.** `createInstance()`, `activate()`, and the
  `uniface.datastore` functions "return JavaScript promise objects"; `uniface.activate(…).then(…)`
  is shown verbatim. `uniface.activate(args)` is documented as a synonym for
  `uniface.getInstance().activate(args)` — so **`activate()` is *not* deprecated**
  (the deprecated one is `createDSPInstance` → use `createInstance()`; our docs
  never recommended `createDSPInstance`, so nothing to fix).
- **`OnChange` is interactive-only — verbatim:** *"The OnChange web trigger responds
  only to user actions, not to data changes made using the JavaScript API."*
- **Field API / access chain:** `getInstance()→getEntity()/getEntities()→
  getOccurrence(s)()→getField(s)()→getValue()/setValue()` all present and used in
  examples; `getFieldValue`/`setFieldValue` do **not** appear (correctly flagged as
  non-existent in our DSP rule).
- **CSS hooks:** both `class:Name` and `html:class` documented (`setProperty("html:class", …)`),
  matching our "dynamic class hook vs. whole-list replace" guidance.
- **ES floor = ES2015 (only level Rocket commits to):** Promises are "compliant with
  the **Promises/A+** specification" and cite the **ECMAScript 2015** Promise Objects
  spec; no higher ES level is promised anywhere — confirms our "ES2015 floor" stance.
- **Supported-browser matrix lives in the gated PAM, not the Library.** The Library
  repeatedly defers to the **Platform Availability Matrix** (even noting a browser was
  dropped) — so our ⚠️ marker on §1.6 is *accurate*, a real gated gap, not an
  oversight.
- **CLI facts:** `/imp` returns exit **1 (EXIT_FAILURE)** on import failure (0 on
  success); compile returns 0/1; **unmigrated/incompatible Repository → "command line
  execution will fail"** (matches §3.5); **`/imp` and `$ude("import")` cannot import
  `/cpy`/`$ude("copy")` (Data Copy) output** — confirms the never-`/cpy`-for-defs rule.
- **No `/exp` repository-export switch** — confirmed against the switch reference
  (consistent with our empirical `/exp /all` → error `0099`); `$ude("export")` with
  its full option set (`model`/`component`/`library;include`/…) is the documented
  export path.

## 3. The one refinement made 🔎 — `/sto` ≠ repository export

The Library **does** document command-line *exports* via the **`/sto`** (store)
switch — `/sto /mwr=ws` (WSDL), `/sto /mwr=com /cfg=…` (self-registering COM
interface DLL), `/sto /lan=jav` (Java call-in wrappers). At a glance this looks
like it contradicts our flat "**there is no command-line export switch**."

It does **not**: `/sto` emits **deployment artifacts** generated from a service
**signature** — service *packaging* for call-in — **not** the repository-definition
XML used for VCS, and its output is **not** `/imp`-importable. So our claim is true
for the **repository round-trip** facility, but the absolute phrasing could mislead
anyone reading the switch reference. Refined two canonical spots to draw the
distinction:

- [docs/uniface-10-onboarding.md](../docs/uniface-10-onboarding.md) §1.4 — added a
  🔎 note explaining `/sto`'s WSDL/COM/Java exports are packaging, not the VCS XML.
- [.claude/rules/uniface-repository-source-of-truth.md](../.claude/rules/uniface-repository-source-of-truth.md)
  — qualified the rule with the same `/sto` parenthetical.

Other locations (worklog 005/010, command/README summaries) are correct in their
VCS context and left as-is.

## 4. Net result

The verified-accuracy claim for **10.4.03 CE on the points covered** holds. No
factual error was found in the workspace docs against the full Library — only the
one precision refinement above. The two narrow ⚠️ items (browser matrix / written
ES baseline) are **confirmed** as genuinely gated to the PAM, not gaps we can close
from open docs.

## References
- **Source (local, not committed):** `webfetched/rocket_uniface_library_10.4_6-30-2026.pdf`
  (Rocket Uniface Library 10.4).
- In-repo: [docs/uniface-10-onboarding.md](../docs/uniface-10-onboarding.md) §1.4/§1.6/§3.5,
  [uniface-repository-source-of-truth](../.claude/rules/uniface-repository-source-of-truth.md),
  [uniface-dsp-web-conventions](../.claude/rules/uniface-dsp-web-conventions.md),
  [009](009-dsp-capabilities-web-research.md), [012](012-workarea-introduction.md).
