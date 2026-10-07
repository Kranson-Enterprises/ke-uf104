---
description: Scaffold or extend a ProcScript unit-test module (UTEST pattern) for a model/entity-service operation, then run it in test mode
argument-hint: "[entity/service + operation to test, e.g. 'CUSTOMER::validate']"
allowed-tools: Read, Grep, Glob, Write, Edit, PowerShell
---

Scaffold and run a **Tier-1 ProcScript unit test** for model/entity-service logic — the
preferred, endpoint-independent test layer
([worklog/033](../../worklog/033-uniface-testing-approaches-and-tooling.md)). Follows the
Library's shipped pattern: a ProcScript library entry you `call` (`USTRUCT` ships
`call ustruct::utest()`), extended to your own model operations.

`$ARGUMENTS` = the entity/service + operation under test (e.g. `CUSTOMER::validate`). If
absent, ask which model/entity-service operation to cover, or offer to derive candidates from
[/uniface-test-plan](uniface-test-plan.md).

## Steps

1. **Locate the unit under test.** Confirm the logic lives in the **model / entity service**
   (not a presentation component). If it's in a component, flag it — a model-layer test is
   only meaningful for model-layer logic
   ([uniface-trigger-placement](../rules/uniface-trigger-placement.md)).
2. **Find or create the test library.** Look for a project test ProcScript library (e.g.
   `libprc:TEST_<AREA>` serialized under [workarea/](../../workarea/) `lib*/`). If none, create
   one — a global ProcScript library whose modules are `entry`/`operation` test cases. Names
   must pass [/uniface-name-check](uniface-name-check.md) (≤ 60 chars, `A–Z 0–9 _`, letter-
   first, avoid reserved words).
3. **Write the test module** (UTEST shape). Each case:
   - sets up input (activate/instantiate against the **local SQLite** sandbox),
   - `call`s the model operation under test,
   - **asserts** on the returned value / `$status` / `$procerror`, and
   - reports **PASS/FAIL** via `putmess` (there is no vendor assert library — build a tiny
     `assert_equal`/`assert_status` entry once and reuse it).
   Keep test data disposable; SQLite makes reset cheap.
4. **Serialize the object** — it's a repository object, so round-trip via Export → `workarea/`
   ([uniface-repository-source-of-truth](../rules/uniface-repository-source-of-truth.md)); never
   hand-edit the live object, never `/cpy`.
5. **Run it** via [/uniface-test](uniface-test.md) in **test mode with the debugger**
   (`/tst /deb`) against a thin runner component (or the service directly), with headless
   hardening so an uncaught exception doesn't hang the run:
   `$SUPPRESS_UNCAUGHT_EXCEPTION_DIALOG=1` + `$PUTMESS_LOGFILE=<log>` — then parse the log for
   PASS/FAIL. Check the exit code.

## Notes
- **Compile the library into `usys.uar`** (as the `USTRUCT` docs note for their library) so it
  is callable, then run. Production stays `/all /nodebug`; tests are a **dev/debug** activity.
- Keep tests **fast and isolated** — one behaviour per case; assert on data, not on IDE-shell
  behaviour (test mode runs inside the IDE process, so `$MESSAGE_LINE`/`$MENU_BAR` don't apply).
- For the guided red→green loop, use the **[uniface-tdd-loop](../skills/uniface-tdd-loop/SKILL.md)**
  skill instead of a one-shot.
