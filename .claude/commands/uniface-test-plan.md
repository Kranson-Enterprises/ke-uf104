---
description: Produce a layered, endpoint-tagged test plan for a component/entity — model-unit (Tier 1) vs per-endpoint E2E (Tier 2), in priority order
argument-hint: "[component / entity / exported XML to plan tests for]"
allowed-tools: Read, Grep, Glob
---

Read-only. Produce a **layered test plan** for a Uniface object against this app's real
delivery endpoints, following the two-tier strategy verified in the Library
([worklog/033](../../worklog/033-uniface-testing-approaches-and-tooling.md)): the endpoint-
independent **model/entity-service unit layer first**, then per-endpoint UI/E2E in the app's
priority order (character + web → rich web → GUI). Grounded in
[uniface-character-and-web-endpoints](../rules/uniface-character-and-web-endpoints.md),
[uniface-trigger-placement](../rules/uniface-trigger-placement.md), and
[uniface-dsp-web-conventions](../rules/uniface-dsp-web-conventions.md).

`$ARGUMENTS` = the component/entity name or its exported XML. If the endpoint isn't obvious,
**state your assumption** (default: character + web, not GUI).

## What to produce

1. **Name the endpoint(s)** and the object's role (model/entity-service vs presentation).
2. **Tier 1 — model/entity-service unit tests (preferred core).** List the business rules /
   DB-I/O operations that should be tested **once at the model layer** with ProcScript unit
   tests (UTEST pattern, run via `/tst /deb`), because they behave identically on every
   endpoint. Flag any logic currently sitting in the presentation component that **should
   move to the model** so it's testable once (silent-override risk).
3. **Tier 2 — per-endpoint E2E**, only for behaviour that is genuinely presentation-level, in
   priority order:
   - **Character (Unifield):** note there is **no UI-automation hook** — recommend covering
     via Tier 1; only truly terminal-specific flows need a terminal harness. Remember only
     `detail`/`help`/`loseFocus`/`startModification`/`valueChanged` fire.
   - **Web DSP/USP:** browser E2E (Playwright/Selenium ⚠️ best-practice, not Rocket-named).
     Flag DSP assertion gotchas: values are **strings**, `OnChange` is interactive-only.
   - **Rich web (CEF HTML widget):** same tool via `Accessibility=TestMode` + `DebugPort`
     (dev build only — off under `/nodebug`).
   - **GUI desktop (if in scope):** UI Automation/MSAA tool (WinAppDriver/Ranorex ⚠️) — flag
     as exercise-only unless stated otherwise.
4. **Data & harness notes:** SQLite dev sandbox for fast reset; externalise any test-DB logon
   (path-to-connector in an asn — `/tst` can't show a logon form); headless hardening
   (`$SUPPRESS_UNCAUGHT_EXCEPTION_DIALOG` + `$PUTMESS_LOGFILE`) if the plan is automated.

## Output
A concise, tier-and-endpoint-tagged plan (most-valuable Tier-1 items first), naming which of
[/uniface-unit-test](uniface-unit-test.md), [/uniface-test](uniface-test.md), and
[/uniface-webtest](uniface-webtest.md) implements each item. **Plan only — scaffold/run
nothing.**
