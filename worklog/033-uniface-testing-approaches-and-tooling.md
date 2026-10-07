# 033 Uniface testing approaches + a Claude test-productivity suite

**Date:** 2026-07-02
**Sequence:** … → 031 (native `WASListener.exe`) → 032 (SDLC/Agile delivery model) →
**033 (how to *test* this application, and the Claude commands/skills that drive it)**.
**Purpose:** Answer "what is the preferred testing tool for Uniface, covering Unifield /
character + web first, then rich web, then GUI desktop?" — grounded in the Library 10.4 —
and turn the answer into a **new set of `/uniface-*test*` commands and two skills** so the
approach is repeatable, not a one-off explanation.
**Basis:** Rocket Uniface Library 10.4 (offline copy in gitignored `webfetched/`;
`pdftotext` + grep), cross-checked against this repo's endpoint / trigger-placement /
build-hygiene rules.

**Confidence legend:** ✅ verified in the Library on this install · 📘 documented behaviour ·
⚠️ best-practice recommendation (**not** a Rocket-named product) · 💡 design proposal.

---

## 1. The headline: Uniface ships no single cross-endpoint test tool

There is **no Rocket-branded test product** that spans character, web, rich web and GUI.
Uniface's own strategy is **two tiers**, and the "preferred tool" is different at each. This
maps cleanly onto the app's real shape — character Forms + web DSP/USP are the product, GUI
is exercise-only, and business logic belongs in the **model / entity services**
(*[uniface-trigger-placement], [uniface-character-and-web-endpoints]*). So the single most
valuable test asset is the one tier that is **endpoint-independent**.

## 2. Tier 1 (preferred core) — ProcScript unit tests in the built-in test environment

This is the tier Rocket actually ships, and the only one that covers **every** endpoint at
once: logic in the model behaves identically whether it renders to a Unifield, a browser, a
CEF widget, or a GUI form, so you test it **once**.

- ✅ **Pre-configured test/runtime environment.** Uniface bundles a standalone runtime
  (its own Uniface Router + Uniface Server + Apache Tomcat) "for unit testing", plus the
  **Uniface Debugger**. Driven from the CLI by **`/tst`** (test mode) and **`/deb`** (attach
  debugger).
- ✅ **`/tst ComponentName`** starts the component's `exec` operation via `activate` and runs
  it **inside the IDE process** (so IDE behaviour is maintained; assignment settings like
  `$MESSAGE_LINE`/`$MENU_BAR` don't apply, and RTL/bidirectional forms can't run in test
  mode). DSP/USP open in the **default browser**; other components run in the IDE process.
- ✅ **The shipped unit-test pattern is a ProcScript entry you `call`.** The `USTRUCT` global
  ProcScript library ships a unit test invoked as `call ustruct::utest()`. That is the
  template: put test modules (`entry`/`operation`) in a **test ProcScript library**, have
  each `call` the model/entity-service operation under test and assert on `$status` / the
  returned value, reporting PASS/FAIL via `putmess`. **There is no vendor xUnit/assertion
  harness beyond this** — you build the assert-and-report module yourself (a real, worth-
  stating gap).
- ✅ **Headless hardening for automated runs.** By default an uncaught exception shows a form,
  which **hangs an automated test**. Set **`$SUPPRESS_UNCAUGHT_EXCEPTION_DIALOG = 1`** *and*
  a **`$PUTMESS_LOGFILE`** (or `$TRANSCRIPT_LOGFILE`) so the exception/result text lands in a
  parseable log — on Windows, without a log file the info is **lost**. Use only for automated
  processes, never production (wrap `apstart` in try/catch there instead).
- ✅ **Spawn is configurable.** `ide.asn [LOGICALS]` `TEST_COMMAND_CPT` (form/report/service)
  and `TEST_COMMAND_CPT_WEB` (DSP/USP) customise how test mode launches — e.g. append `/deb`
  to attach the debugger, or point `TEST_COMMAND_CPT_WEB` at a **specific browser
  executable / host / port** (`http://localhost:%TomcatPort/uniface/wrd/%CptName`). Restart
  the IDE to apply. This is the hook a browser-automation runner (Tier 2) plugs into.

## 3. Tier 2 (bring-your-own UI/E2E) — Uniface exposes handles, you supply the tool

For UI-level end-to-end tests Uniface **exposes automation handles** rather than shipping the
tool. In the app's stated priority order:

1. **Character + web (DSP/USP) — top priority.**
   - A deployed **DSP/USP renders to a real browser** (not CEF). ⚠️ Drive it with a
     **browser-automation framework — Playwright (recommended) or Selenium** — targeting the
     generated HTML. *(Not a Rocket-named tool; best practice.)*
   - **Pure character-mode terminal has *no* MSAA/DebugPort hook** — there is no vendor UI-
     automation path for the terminal. ⚠️ Cover it with an expect-style terminal harness *and*
     (better) push the logic to the model so Tier 1 covers it; the terminal is a thin
     renderer.
2. **Rich web (CEF HTML widget) — extends from the same tool.**
   - ✅ The same Selenium/Playwright family attaches to the CEF widget via its remote-debug
     port: set **`Accessibility = TestMode`** in the ini and give the widget a port —
     **`Html = uhtml(debugport=8081)`** — so MSAA/CDP tools can connect; `EnableDevTools =
     true` exposes CEF DevTools. ⚠️ **Both `DebugPort` and `EnableDevTools` are disabled
     under `/nodebug`** — dev/test builds only; production (`/all /nodebug`) has them off by
     design (*[uniface-cli-and-build-hygiene]*).
3. **GUI desktop — extend last, different tool family.**
   - ✅ Uniface exposes desktop widgets via **UI Automation + MSAA**; with `Accessibility =
     TestMode` the widget returns a technical name automation tools can key on. ⚠️ Needs a
     Windows UI-automation tool — **WinAppDriver** (free, Appium family) or commercial
     **Ranorex / TestComplete**. Separate skillset → correctly the bottom tier (and exercise-
     only here anyway).

## 4. Endpoint → tool matrix

| Endpoint (priority) | Tier-1 (model unit) | Tier-2 (UI/E2E) | Uniface handle |
| --- | --- | --- | --- |
| **Character Form (Unifield)** | ✅ ProcScript unit tests (`/tst /deb`) | ⚠️ expect-style terminal harness | none — push logic to model |
| **Web DSP / USP** | ✅ same model tests | ⚠️ Playwright / Selenium (real browser) | `TEST_COMMAND_CPT_WEB` → browser |
| **Rich web (CEF HTML widget)** | ✅ same model tests | ⚠️ Playwright / Selenium via debug port | ✅ `Accessibility=TestMode` + `DebugPort` / `EnableDevTools` |
| **GUI desktop (exercise-only)** | ✅ same model tests | ⚠️ WinAppDriver / Ranorex / TestComplete | ✅ UI Automation + MSAA (`Accessibility=TestMode`) |

**Bottom line:** the preferred core is the **built-in `/tst` + `/deb` environment running
ProcScript unit tests of the model/entity-service layer**; the preferred E2E tool that
satisfies *web/character → rich web* with one skillset is **Playwright (or Selenium)**, with
only the GUI tier needing a second tool.

## 5. What this worklog adds to the Claude tooling

A coherent **test-productivity suite** so the two-tier approach is a set of repeatable
commands, not a re-explained concept each time.

### Commands (`.claude/commands/`)

| Command | Tier | What it does |
| --- | --- | --- |
| `/uniface-test-plan` | plan | Read-only: emit a **layered, endpoint-tagged test plan** for a component/entity — what belongs at the model-unit layer vs per-endpoint E2E, in priority order. |
| `/uniface-unit-test` | 1 | Scaffold/extend a **ProcScript unit-test module** (UTEST pattern) for a model/entity-service operation and run it in test mode. |
| `/uniface-test` | 1 | **Run** a component/service/app-shell in the built-in test environment (`/tst`, `+/deb`), endpoint-aware, with headless hardening (`$SUPPRESS_UNCAUGHT_EXCEPTION_DIALOG` + log file). |
| `/uniface-webtest` | 2 | Scaffold a **browser-automation harness** (Playwright default) for a DSP/USP, incl. CEF rich-web attach via `Accessibility=TestMode` + `DebugPort`, and the DSP string/`OnChange` gotchas. |

### Skills (`.claude/skills/`)

| Skill | What it does |
| --- | --- |
| `uniface-test-harness-setup` | One-time: scaffold the repo `tests/` layout (ProcScript test library + browser E2E folder), wire the **dev-only** `ide.asn` test knobs (`TEST_COMMAND_CPT … /deb`, `TEST_COMMAND_CPT_WEB`, `Accessibility=TestMode`/`DebugPort`, suppress-dialog + log), backed up and reversible. |
| `uniface-tdd-loop` | Guided **model-first red→green→refactor** inner loop against the local SQLite sandbox: pick an entity/service, write a failing unit test, run via `/tst /deb`, iterate to green, then export to `workarea/` to promote (ties into worklog 032's delivery model). |

## 6. Guardrails (verified — carry into every test task)

- ✅ **`/nodebug` disables the UI-automation hooks.** `DebugPort` and `EnableDevTools` are off
  under `/nodebug`; run Tier-2 E2E against a **debuggable dev/test build**, and keep
  production `/all /nodebug` (*[uniface-cli-and-build-hygiene]*).
- ✅ **Character mode has no UI-automation hook** — that is *why* the rules push data/business
  rules into the model; test them at Tier 1, not through the terminal.
- 📘 **DSP browser gotchas when scripting assertions:** all field values are **strings**, and
  **`OnChange` fires on interactive change only** (never on a JS `setValue`)
  (*[uniface-dsp-web-conventions]*).
- ✅ **Test mode ≠ your app.** `/tst` runs inside the IDE process, so `$MESSAGE_LINE`/
  `$MENU_BAR` and similar don't apply, and RTL forms can't run in test mode — don't assert on
  IDE-shell behaviour.
- ⚠️ **Externalise any test DB logon** — `/tst` can't show a logon form; put path-to-connector
  creds in an assignment file, and keep secrets out of git (*[protect-secrets-and-proprietary]*).
- ⚠️ **SQLite is dev-only** — promote schema with `/genSql`; production compiles `/all
  /nodebug`.

## 7. Open items

- 💡 **A `tests/` tracking decision.** ProcScript test libraries are repository objects →
  round-trip through `workarea/` like any object; browser E2E specs are plain files → a new
  tracked `tests/e2e/` folder (with `node_modules/` gitignored). The harness-setup skill
  proposes this; confirm the exact layout on first run.
- 💡 **CI wiring.** A future step: gate `ci.yml` on a headless `/tst` unit-test run (exit-code
  + parse the `$PUTMESS_LOGFILE`) — the Tier-1 half is CI-friendly today; the browser half
  needs a runner on the Windows agent.
- 💡 **Optional testing rule.** If the suite proves useful, promote the two-tier + guardrails
  into a `.claude/rules/uniface-testing.md` and link it from CLAUDE.md (not done here — kept
  to the requested worklog + commands + skills).

## 8. References

- ✅ **External, gated product docs** (licensed — consult under your Rocket entitlement):
  Rocket Uniface Library 10.4 — *Testing and Debugging* (Test a Component / Configure
  Component Testing — `TEST_COMMAND_CPT`, `TEST_COMMAND_CPT_WEB`); *Uniface Debugger*
  (`/tst`, `/deb`); `USTRUCT` helper library (`utest`); `DebugPort`, `EnableDevTools`,
  `Accessibility = TestMode`; `$SUPPRESS_UNCAUGHT_EXCEPTION_DIALOG`, `$PUTMESS_LOGFILE`.
- Project rules: [uniface-character-and-web-endpoints](../.claude/rules/uniface-character-and-web-endpoints.md),
  [uniface-trigger-placement](../.claude/rules/uniface-trigger-placement.md),
  [uniface-dsp-web-conventions](../.claude/rules/uniface-dsp-web-conventions.md),
  [uniface-cli-and-build-hygiene](../.claude/rules/uniface-cli-and-build-hygiene.md),
  [protect-secrets-and-proprietary](../.claude/rules/protect-secrets-and-proprietary.md).
- New tooling: commands `/uniface-test-plan`, `/uniface-unit-test`, `/uniface-test`,
  `/uniface-webtest`; skills `uniface-test-harness-setup`, `uniface-tdd-loop`.
- Prior: [worklog/032](032-sdlc-agile-workarea-waslistener-delivery.md) (delivery model —
  local SQLite → WorkArea promotion, which the TDD loop plugs into).
