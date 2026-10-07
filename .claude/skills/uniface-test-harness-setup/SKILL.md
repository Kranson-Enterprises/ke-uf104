---
name: uniface-test-harness-setup
description: >-
  One-time setup of the testing scaffolding for this Uniface repo. Use when the
  operator wants to "set up testing", "add a test harness", "scaffold unit/e2e
  tests", or enable Uniface's built-in test mode + browser E2E for MYPROJECT. It
  scaffolds a ProcScript unit-test library (Tier 1) and a tests/e2e/ browser folder
  (Tier 2), and wires the DEV-ONLY ide.asn test knobs (TEST_COMMAND_CPT …/deb,
  TEST_COMMAND_CPT_WEB, Accessibility=TestMode + DebugPort, suppress-dialog + log
  file) — backed up and reversible. Non-destructive: previews before writing.
allowed-tools: Read, Grep, Glob, Write, Edit, PowerShell, AskUserQuestion
---

# Uniface test-harness setup (one-time, reversible)

**Goal.** Stand up the two-tier test scaffolding described in
[worklog/033](../../../worklog/033-uniface-testing-approaches-and-tooling.md) so the
`/uniface-*test*` commands have a home: a **ProcScript unit-test library** (Tier 1, the
preferred endpoint-independent core) and a **`tests/e2e/` browser folder** (Tier 2), plus the
**dev-only** `ide.asn` knobs that make test mode/debug/browser attach work. Everything is
**previewed, backed up, and reversible** — this touches config, not the repository objects.

> This mirrors the shape of [was-project-setup](../was-project-setup/SKILL.md): resolve paths
> from `usys.ini [install]`, back up before writing, keep changes **project-local**, never edit
> the shared install under `C:\ref`.

## Fixed facts for this install (verify, don't assume elsewhere)
- exe `C:\ref\common\bin\ide.exe` · adm `C:\ref\uniface\adm` · install root `C:\ref`.
- **MYPROJECT workdir** = `usys.ini [install] project=` (runtime, gitignored). Resolve it.
- `tomcat_port` / ports live in `usys.ini [install]`.
- **Quote spaced paths** as whole tokens ([quote-paths-with-spaces](../../rules/quote-paths-with-spaces.md)).

## Step 0 — preflight & idempotency
1. Read `C:\ref\uniface\adm\usys.ini` `[install]` → resolve `project=` and `tomcat_port`;
   confirm exe + adm exist.
2. **Already set up?** If the workdir `ide.asn` already has `TEST_COMMAND_CPT` overrides and a
   `tests/` folder exists, report it and **skip to Step 4 (verify)** — don't double-apply.

## Step 1 — choose scope
Use **AskUserQuestion** (header "Test scope"):
- **Both tiers (recommended)** — unit-test library + `tests/e2e/` browser folder + asn knobs.
- **Tier 1 only** — ProcScript unit-test library + test-mode/debug asn knobs (no browser).
- **Tier 2 only** — `tests/e2e/` browser harness + web/DebugPort asn knobs (no unit library).

## Step 2 — scaffold the test assets (preview first)

### Tier 1 — ProcScript unit-test library (repository object → `workarea/`)
- Propose a global ProcScript library, e.g. **`TEST_MYPROJECT`** (validate with
  [/uniface-name-check](../../commands/uniface-name-check.md)), holding:
  - a tiny reusable **assert helper** (`assert_equal`, `assert_status`) that `putmess`es
    PASS/FAIL — there is no vendor assert library (worklog 033);
  - one starter test case that `call`s a real model/entity-service operation.
- It's a **repository object** → author in the IDE and round-trip via Export →
  [workarea/](../../../workarea/) `lib*/`
  ([uniface-repository-source-of-truth](../../rules/uniface-repository-source-of-truth.md));
  never hand-edit the live object, never `/cpy`. Note it must be compiled into `usys.uar` to be
  callable (as `USTRUCT` documents for its `utest`).
- Add a thin **runner** (a small form/service, e.g. `TEST_RUNNER`) whose `exec` calls each test
  case, so `/tst TEST_RUNNER` executes the suite.

### Tier 2 — browser E2E folder (plain files)
- Create tracked **`tests/e2e/`** with a Playwright (default) or Selenium scaffold and a README;
  gitignore `node_modules/`. Add the `tests/e2e/` layout to `.gitattributes`/`.gitignore` as
  needed. Do **not** put secrets or real creds in specs.

## Step 3 — wire the DEV-ONLY asn knobs (backup, then append)
Back up first: `Copy-Item <workdir>\ide.asn <workdir>\ide.asn.bak -Force` (create-with-`#file
usysadm:ide.asn` chain if none). **Comments on their own line only** — `[SETTINGS]`/
`[RESOURCES]` don't strip trailing `;` inline comments
([uniface-uar-packaging-and-hardening](../../rules/uniface-uar-packaging-and-hardening.md)).
Append (adapt to scope):

```asn
[LOGICALS]
; attach the debugger to component test mode
TEST_COMMAND_CPT = %ExeFile /adm=%AdmDir /dir=%WorkDir /asn=%AsnFile /ini=%IniFile /deb /tst %CptName
; (optional) point web test mode at a specific browser/port
; TEST_COMMAND_CPT_WEB = cmd /c start http://localhost:%TomcatPort/uniface/wrd/%CptName

[SETTINGS]
; headless: don't let an uncaught exception hang an automated run — log it instead
$SUPPRESS_UNCAUGHT_EXCEPTION_DIALOG = 1
; relative to the IDE workdir (<repo>\uniface\project), i.e. the repo's gitignored scratch/
$PUTMESS_LOGFILE = ..\..\scratch\test-run.log
```
For **rich-web CEF attach** (Tier 2), also add to the **ini** (`usys.ini`/component ini),
**dev build only**:
```ini
[settings]
Accessibility = TestMode
[widgets]
HTML = uhtml(debugport=8081)
```
⚠️ `DebugPort`/`EnableDevTools` are **disabled under `/nodebug`** — these knobs are for
**debuggable dev/test builds**; production stays `/all /nodebug`
([uniface-cli-and-build-hygiene](../../rules/uniface-cli-and-build-hygiene.md)). Keep secrets
out of the asn ([protect-secrets-and-proprietary](../../rules/protect-secrets-and-proprietary.md)).

## Step 4 — verify & hand off
1. Restart the IDE (no other IDE holding the repo lock) so the logicals apply.
2. Smoke-test Tier 1: [/uniface-test](../../commands/uniface-test.md) `TEST_RUNNER` → confirm
   PASS/FAIL lands in the `$PUTMESS_LOGFILE`.
3. Smoke-test Tier 2 (if scoped): run the Playwright/Selenium starter spec against a DSP/USP.
4. Hand off to the daily loop: **[uniface-tdd-loop](../uniface-tdd-loop/SKILL.md)** for the
   red→green workflow; [/uniface-test-plan](../../commands/uniface-test-plan.md) to plan
   coverage.

## Revert (undo the setup)
Restore `ide.asn` from `.bak` (or delete if created here), remove the ini `[widgets]`/
`Accessibility` additions, and remove `tests/e2e/` + the test library/runner objects if the
operator wants a clean slate. The repository objects are round-tripped like any other — delete
via the IDE, re-export.

## Related
- Commands: [/uniface-test](../../commands/uniface-test.md),
  [/uniface-unit-test](../../commands/uniface-unit-test.md),
  [/uniface-webtest](../../commands/uniface-webtest.md),
  [/uniface-test-plan](../../commands/uniface-test-plan.md).
- Skill: [uniface-tdd-loop](../uniface-tdd-loop/SKILL.md).
- Rules: [uniface-repository-source-of-truth](../../rules/uniface-repository-source-of-truth.md),
  [uniface-cli-and-build-hygiene](../../rules/uniface-cli-and-build-hygiene.md),
  [uniface-dsp-web-conventions](../../rules/uniface-dsp-web-conventions.md),
  [protect-secrets-and-proprietary](../../rules/protect-secrets-and-proprietary.md),
  [quote-paths-with-spaces](../../rules/quote-paths-with-spaces.md).
- Background: [worklog/033](../../../worklog/033-uniface-testing-approaches-and-tooling.md).
