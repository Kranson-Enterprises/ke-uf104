---
description: Scaffold a browser-automation E2E harness (Playwright default) for a DSP/USP, incl. CEF rich-web attach via Accessibility=TestMode + DebugPort
argument-hint: "[DSP/USP component to test; optional 'selenium']"
allowed-tools: Read, Grep, Glob, Write, Edit, PowerShell
---

Scaffold a **Tier-2 UI/E2E harness** for a web endpoint
([worklog/033](../../worklog/033-uniface-testing-approaches-and-tooling.md)). Uniface exposes
the *handles*; the runner is **bring-your-own**. ⚠️ **Playwright/Selenium are best-practice
recommendations, not Rocket-named products** — the Library documents the exposure hooks
(`Accessibility=TestMode`, `DebugPort`, `EnableDevTools`), not a browser framework.

`$ARGUMENTS` = the DSP/USP component to test (default runner **Playwright**; pass `selenium`
to scaffold Selenium instead). If the component isn't a DSP/USP, say so — this is the
web/rich-web tier, not character or GUI.

## Steps

1. **Confirm the endpoint + URL.** A deployed **DSP/USP renders in a real browser** (not CEF).
   Test URL follows the test-mode default: `http://localhost:<tomcat_port>/uniface/wrd/<CptName>`
   (resolve `tomcat_port` from `usys.ini [install]`). For a **CEF rich-web HTML widget** inside
   a component, use the debug-port attach path in step 3.
2. **Scaffold the harness** under a tracked `tests/e2e/` folder (files, not repository objects):
   - Playwright: `npm init playwright@latest` layout — a spec that navigates to the URL,
     locates fields, drives input, and asserts. Gitignore `node_modules/`.
   - Keep selectors resilient to Uniface's generated HTML; prefer stable ids/roles.
3. **Rich-web (CEF) attach — dev build only.** To drive an HTML widget inside a component,
   enable the debug port (verified): in the ini,
   ```ini
   [settings]
   Accessibility = TestMode
   [widgets]
   HTML = uhtml(debugport=8081)     ; add EnableDevTools=true for CEF DevTools
   ```
   then connect the runner to the CEF remote-debug endpoint on that port. ⚠️ **`DebugPort` and
   `EnableDevTools` are disabled under `/nodebug`** — run E2E against a **debuggable** build;
   production `/all /nodebug` has them off ([uniface-cli-and-build-hygiene](../rules/uniface-cli-and-build-hygiene.md)).
4. **Bake in the DSP assertion gotchas** (comment them in the spec):
   - Field **values are strings** in the browser regardless of modeled type — compare as
     strings / convert yourself.
   - **`OnChange` fires on interactive change only** — driving a value via the JS API
     (`setValue`) won't fire it; simulate real user input to trigger triggers
     ([uniface-dsp-web-conventions](../rules/uniface-dsp-web-conventions.md)).
   - Use the **real `uniface` JS API** names if the spec reaches into the client
     (`getValue`/`setValue`, `activate`/`createInstance` return Promises) — not
     `getFieldValue`/`callServer`.
5. **Wire the run.** Start the component in test mode via [/uniface-test](uniface-test.md)
   (`TEST_COMMAND_CPT_WEB` can point at a specific browser/port), then run the E2E spec against
   the URL. Keep the app logic thin — most coverage belongs at the **model** layer
   ([/uniface-unit-test](uniface-unit-test.md)); E2E asserts wiring/presentation only.

## Notes
- **Don't hand-edit generated `.dsp`/`dspjs`** to make a test pass — the layout is a repository
  object; round-trip via Export/Import
  ([uniface-repository-source-of-truth](../rules/uniface-repository-source-of-truth.md)).
- GUI-desktop E2E is a different tool family (WinAppDriver/Ranorex/TestComplete via UI
  Automation/MSAA) and out of scope here — the app's GUI is exercise-only.
- For repeatable setup of the `tests/e2e/` folder + dev-only asn knobs, use the
  **[uniface-test-harness-setup](../skills/uniface-test-harness-setup/SKILL.md)** skill.
