# 009 DSP capabilities — web research

**Date:** 2026-06-27
**Sequence:** 001 (Claude setup) → 002 (CEF IDE) → 003 (spaces-in-paths) →
004 (environment definitions) → 005 (source-of-truth & VSCode) →
006 (CLI usage + commands) → 007 (productivity rules) →
008 (sample-driven export verification) → **009 (DSP capabilities web research)**.
**Purpose:** Resolve the onboarding doc's last *product-capability* `[verify]` tag —
"⚠️ verify exact DSP capabilities in 10.4" (§0) — by deep web research against
Rocket's own documentation, scoped to **HTML5 + CEF features and the ECMAScript
version/support limits**. Result folded into onboarding **§1.6**.

---

## 1. Why this pass

The file-/CLI-/behavioral items were already closed (worklog/008). What remained
were two *product-capability* caveats that no local install settles. The user asked
to research DSP capabilities specifically as they relate to **HTML5**, **CEF**, and
**ECMAScript version/support**. Three parallel research agents covered: (A) DSP
definition/architecture + JS API, (B) HTML5 authoring + supported-browser matrix +
the CEF-vs-deployment distinction, (C) ECMAScript/CEF version limits.

## 2. Sourcing caveat (important)

Rocket moved the docs to a **JavaScript-rendered Zoomin portal**
(`docs.rocketsoftware.com/bundle/uniface_104/…`) whose page *body* a plain fetcher
can't read, and the legacy static hosts (`www3.rocketsoftware.com/rocketd3/…`,
`documentation.uniface.com`) now **301-redirect to a search/login wall**;
`web.archive.org` was blocked. So most official wording below is **page-attested via
the search index** (real pages, indexed text) rather than re-rendered live. CEF
facts are **live-confirmed** from a readable Rocket community post. The definitive
**supported-browser matrix / ES floor lives in the login-gated Platform
Availability Matrix (PAM)** and could **not** be read — that is the one open gap.

Confidence markers used in §1.6 and here: **✅ documented** (Rocket page) ·
**🔸 inferred** (logical, not stated verbatim) · **⚠️ unverified** (gated PAM).

## 3. Findings

### 3.1 Architecture — split component ✅
DSP = **two halves**: a non-persistent **server** part (Uniface Server,
re-instantiated per request) + a persistent **client** part in the browser, talking
**async HTTP / JSON**, mapped by a **client-side JS runtime engine**. Contrast
USP/Static Server Page = whole-page regeneration each round-trip. Server logic =
ProcScript; client logic = JavaScript in `webtrigger`/`weboperation`
(`javascript … endjavascript`).

### 3.2 Client-side JavaScript API ✅
Global **`uniface`** → `getInstance()` → `getEntity()` → `getOccurrence(s)()` →
`getField(s)()`; on a field **`getValue()`/`setValue()`** +
`getProperty()/setProperty()/setProperties()`. Boundary crossing: client→server =
**`uniface.activate()` / `createInstance()`** (async, **Promises** since 9.7);
server→client = ProcScript **`webactivate`**. Field values are **strings** in the
browser regardless of modeled type.
- **Corrected hypotheses:** `getFieldValue`/`setFieldValue`, `uniface.callServer`,
  and a `$w="…"` trigger syntax are **not** Uniface 10 names (other-framework
  confusion). The real names are as above.

### 3.3 HTML5 authoring ✅
- **Default field mapping is to native HTML5 elements** ("you can switch this to use
  JavaScript-based web widgets"). DSP emits **standards XHTML** (bound elements get
  `id="ufld:FLD.ENTITY.COMP"`); USP emits proprietary `<x-entity>`/`<x-occurrence>`.
- Authored in the Component Editor **Design Layout** worksheet (repository-stored,
  compiled — see worklog/008/§1.5). You can **embed your own HTML5/CSS/`<script>`**,
  control JS/CSS load order, add pass-through `html:` attributes, use static
  (`html:class`) / dynamic (`class:Name`) CSS hooks, and emit an **external `.hts`
  layout** with the `/ext` compile sub-switch. Default stylesheet `uniface.css`.
- **Widgets:** physical (generate the HTML control) + logical (map onto them):
  EditBox, TextArea, CommandButton(+`_updatable`), CheckBox, DropDownList, ListBox,
  DatePicker, RadioGroup, Picture, **DspContainer** (nested DSP), RawHTML, etc.;
  in 10.4 several are HTML5 controls replacing older Dojo widgets.
- **Responsive/mobile:** "responsive web app first" + a **Mobile App Layout**
  framework; official `sample-web` uses Bootstrap. No auto-emitted media queries 🔸.

### 3.4 Event / update model ✅
Web triggers **`OnChange`** (interactive change only — *not* JS-API sets),
**`OnFocus`**, **`OnClick`**. AJAX updates are **scope-driven**: the browser sends
only the in-scope entity/occurrence/field JSON and blocks the target elements being
refreshed — the "only changed data is sent" behaviour. **JS must be enabled.**

### 3.5 ECMAScript baseline & CEF-vs-deployment ✅/🔸/⚠️
- **Two engines, never conflate:** the **IDE shell** (+ desktop `uhtml` widget)
  embeds **CEF/Chromium** — verified locally **CEF 141.0.5 / Chromium
  141.0.7390.55** (worklog/002, §1.1); Rocket patch notes show CEF 81 → 123 → **141**
  (patch 10.4.03-028) → 148 (10.4.03-044). **Dev-time only.** A **deployed DSP runs
  in the end user's standard browser** (Tomcat → Web Request Dispatcher → urouter →
  userver), **never in CEF**.
- **Documented ES is thin:** the *only* explicit ECMAScript version in the docs is
  **ES2015 (ES6)**, cited solely as the spec basis for **Promises** — not a required
  level or cap. No polyfill/transpile guidance; `sample-web` ships none.
- **🔸 De-facto floor = ES2015** (the JS API returns native `Promise`, which IE
  lacks). IE 8/9/10 publicly removed from DSP support ("below 0.1% of traffic");
  effective target = **evergreen Chrome/Edge/Firefox/Safari** (Chromium 141 ⇒ full
  ES2015–ES2022+; that Chromium→ES mapping is a general web-platform fact).
- **⚠️ Open gap:** the authoritative **supported-browser matrix + any written ES
  floor / transpilation rule** for DSP are in the **login-gated PAM**
  (`my.rocketsoftware.com`; community-referenced as PAM 10.4.03-028, 2025-11-05).
  Rocket publishes **no** open page stating a required ES level for DSP code.

## 4. Documentation outcome

[docs/uniface-10-onboarding.md](../docs/uniface-10-onboarding.md):
- **§0** — DSP `[verify]` tag replaced with a pointer to §1.6; status block narrowed
  to the two remaining PAM-gated ⚠️ items.
- **§1.6 (new)** — "DSP web components — architecture & capabilities": A
  architecture, B JS API, C HTML5 authoring, D event/update model, E ECMAScript +
  CEF-vs-deployment, with ✅/🔸/⚠️ markers throughout.
- **§5** — verification summary updated; DSP added to the resolved list with the
  one PAM-gated ⚠️ carried forward.

## 5. Next step to fully close

Download the current Uniface 10.4 **PAM** from `my.rocketsoftware.com` and read the
**Web Browsers** rows under the DSP/USP deployment columns; check `readme.html` /
the live `webTechnologies/JavaScript.htm` for any written ES level. That is the only
remaining way to turn the §1.6 ⚠️ into ✅. (Keep any saved PAM/Rocket PDFs in the
gitignored `webfetched/` — proprietary, do not commit.)

## References
- Onboarding: [docs/uniface-10-onboarding.md](../docs/uniface-10-onboarding.md)
  §0/§1.1/§1.6/§5.
- Key Rocket pages (page-attested unless noted): DSP overview
  `…/webApps/components/DSPs/DynamicServerPages.htm`; DSP Component Instances
  (split architecture) `…/webApps/components/DSPs/dspComponentInstances.htm`;
  Promises→ES2015 `…/webApps/scripting/promisesInJS.htm`; JS API hierarchy
  `…/webApps/webTechnologies/JavaScript.htm`; `getValue`/`setValue`/`activate`/
  `createInstance` under `…/_reference/javaScriptApi/…`; HTML5 mapping + binding
  `…/webApps/layout/BindingWebLayoutToComponentStructure.htm`; `class:` hooks
  `…/development/reference/devObjProperties/widgetsDsp/dsp_class.htm`; external
  layouts `…/webApps/layout/ExternalWebLayouts.htm` + `/ext` sub-switch.
- CEF (live): Rocket community "Under the Hood: …Chromium Framework…" (CEF 123→141,
  patch 10.4.03-028); "…10.4.03-044 released" (CEF 148). Chromium→ES mapping:
  caniuse.com/es6, v8.dev/blog/modern-javascript, developer.chrome.com release notes.
- System requirements defer to the **PAM** (gated): install guide / System
  Requirements page; PAM info `uniface.info/display/TI/Uniface+product+availability+information`.
- Related: [008](008-sample-driven-export-verification.md),
  [005](005-v10-source-of-truth-and-vscode-workflow.md),
  [002](002-ide-architecture-analysis.md).
