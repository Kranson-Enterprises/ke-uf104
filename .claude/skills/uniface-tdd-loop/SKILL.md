---
name: uniface-tdd-loop
description: >-
  Guided model-first TDD inner loop for Uniface against the local SQLite sandbox.
  Use when the operator wants to "TDD a change", "write a failing test first", "do
  red-green-refactor", or iterate on model/entity-service logic with fast local
  feedback before promoting. Drives: pick the unit → write a failing ProcScript
  unit test → run in test mode (/tst /deb) → make it pass against SQLite →
  refactor → export to workarea/ to promote. Ties into the 032 delivery model.
allowed-tools: Read, Grep, Glob, Write, Edit, PowerShell
---

# Uniface model-first TDD loop (local SQLite → WorkArea promote)

**Goal.** Run the developer **inner loop** — red → green → refactor — on **model/entity-
service** logic with fast local feedback, then promote via the WorkArea. This is the daily
counterpart to the one-time [uniface-test-harness-setup](../uniface-test-harness-setup/SKILL.md),
and it plugs into the delivery model in
[worklog/032](../../../worklog/032-sdlc-agile-workarea-waslistener-delivery.md) (edit against
SQLite → export to `workarea/` → promote by Git).

> **Precondition:** the harness exists (a test ProcScript library + runner, dev-only asn knobs).
> If not, run [uniface-test-harness-setup](../uniface-test-harness-setup/SKILL.md) first.
> **Test the layer that owns the behaviour:** business rules + DB I/O in the **model / entity
> service**, not the presentation component
> ([uniface-trigger-placement](../../rules/uniface-trigger-placement.md)) — that's what makes a
> single test cover every endpoint.

## The loop

1. **Pick the unit.** One behaviour of one model/entity-service operation. If unclear, use
   [/uniface-test-plan](../../commands/uniface-test-plan.md) to choose the highest-value Tier-1
   item. Confirm it's model-layer logic (flag and relocate if it's stuck in a component —
   silent-override risk).
2. **RED — write a failing test first.** Add a test case to the project test library via
   [/uniface-unit-test](../../commands/uniface-unit-test.md): set up disposable input against
   the **local SQLite** repo, `call` the (maybe not-yet-written) operation, assert the intended
   result, `putmess` PASS/FAIL. Run it and **watch it fail** —
   [/uniface-test](../../commands/uniface-test.md) `TEST_RUNNER` with `/tst /deb`; read the
   `$PUTMESS_LOGFILE`. A test that passes before you write the code is a broken test.
3. **GREEN — implement minimally.** Write just enough model/entity-service ProcScript to pass.
   Compile the library into `usys.uar`, re-run, confirm PASS + exit 0. SQLite makes reset/retry
   cheap — iterate here, not against a shared DB.
4. **REFACTOR.** Clean up with the test as a safety net; keep logic in the model so it stays
   endpoint-independent. Re-run to stay green.
5. **Serialize + promote.** Export the changed model object **and** the test library to
   [workarea/](../../../workarea/) `lib*/`/`ent/` (Export → `workarea/`, never `/cpy`;
   [uniface-repository-source-of-truth](../../rules/uniface-repository-source-of-truth.md)),
   commit on your feature branch, and promote per
   [worklog/032](../../../worklog/032-sdlc-agile-workarea-waslistener-delivery.md)
   (PR → merge → environment). ⚠️ Any WorkArea **Import is destructive** (delete-then-import,
   no preview) — commit/back up before promoting
   ([uniface-workarea-sync](../../rules/uniface-workarea-sync.md)).
6. **Repeat** for the next behaviour. Keep cases small and isolated.

## Guardrails
- **Fast + isolated:** one behaviour per case; assert on data/`$status`, not IDE-shell
  behaviour (test mode runs in the IDE process — `$MESSAGE_LINE`/`$MENU_BAR` don't apply, RTL
  can't run in test mode).
- **Headless honesty:** keep `$SUPPRESS_UNCAUGHT_EXCEPTION_DIALOG=1` + `$PUTMESS_LOGFILE` so a
  crash logs instead of hanging; still read the log — a suppressed dialog is not a pass.
- **Dev-only build:** tests run debuggable; production is `/all /nodebug`
  ([uniface-cli-and-build-hygiene](../../rules/uniface-cli-and-build-hygiene.md)).
- **Presentation tests are Tier 2:** if a behaviour is genuinely UI (DSP wiring, character
  layout), route it to [/uniface-webtest](../../commands/uniface-webtest.md) or a terminal
  harness — don't force it into a model unit test.
- **Secrets/data:** test-DB creds via an assignment file, never in git or in a spec
  ([protect-secrets-and-proprietary](../../rules/protect-secrets-and-proprietary.md)).

## Related
- Skill: [uniface-test-harness-setup](../uniface-test-harness-setup/SKILL.md).
- Commands: [/uniface-unit-test](../../commands/uniface-unit-test.md),
  [/uniface-test](../../commands/uniface-test.md),
  [/uniface-test-plan](../../commands/uniface-test-plan.md),
  [/uniface-webtest](../../commands/uniface-webtest.md).
- Background: [worklog/033](../../../worklog/033-uniface-testing-approaches-and-tooling.md),
  [worklog/032](../../../worklog/032-sdlc-agile-workarea-waslistener-delivery.md).
