# 011 Environment re-baseline + tutorial review (construct workflow)

**Date:** 2026-06-30
**Sequence:** … → 008 (sample-driven export verification) → 009 (DSP capabilities) →
010 (plan: tutorials + WorkArea) → **011 (re-baseline + tutorial review)**.
**Purpose:** Execute Phase 0 + Phase A of the [010 plan](010-plan-tutorials-and-workarea.md):
(1) re-baseline the moved install so the active tooling resolves the new locations,
and (2) review a few public Uniface 10.4 tutorials and distil the **construct
workflow** into the onboarding doc. Confidence markers: ✅ verified locally /
plainly stated · 📘 Rocket/community · ⚠️ best-practice / implied / unverified.

---

## Part 1 — Environment re-baseline (✅ verified 2026-06-30)

The user **reinstalled** Uniface and **moved folders**; the **MusicShop/MUSICSHOP
sample no longer exists**. New baseline, read from `C:\ref\uniface\adm\usys.ini`
`[install]` and [uniface/log/install_info.txt](../uniface/log/install_info.txt):

| Item | Old | **New** |
| --- | --- | --- |
| Install root | `C:\Program Files\Rocket Uniface 10 Community Edition` (spaced) | **`C:\ref`** (space-free) ✅ |
| `ide.exe` | `…\common\bin\ide.exe` | **`C:\ref\common\bin\ide.exe`** ✅ |
| adm | `…\uniface\adm` | **`C:\ref\uniface\adm`** ✅ |
| Project dir | `%USERPROFILE%\Rocket Uniface 10 Community Edition\project` | **`C:\Users\Bob\source\uniface\ke-uf104\uniface\project`** (inside the repo) ✅ |
| Version | 10.4.03 | **10.4.03.042**, edition **CE** ✅ |
| Ports | — | urouter **13001** · tomcat **8080** · udbg **13002** ✅ |

**Notable:** the new root `C:\ref` is **deliberately space-free** — it defuses the
spaced-path failure mode worklogs [002](002-ide-architecture-analysis.md)/[003](003-spaces-in-paths-guidance.md)
documented (an unquoted `/adm` token broke IDE launch). The project now lives
**inside the repo** at `uniface\project`.

### What changed in the repo
- **[scripts/setup-env.bat](../scripts/setup-env.bat)** — `UNIFACE_HOME` → `C:\ref`;
  `UNIFACE_PROJECT` now **read from `usys.ini [install] project=`** (with a fallback
  to the in-repo `uniface\project`) so a future move self-heals. Verified output:
  `IDE_EXE = C:\ref\common\bin\ide.exe`, `PROJECT = …\ke-uf104\uniface\project`. ✅
- **Active guidance reconciled** to the new paths / "resolve from `usys.ini`":
  onboarding §1.1, [/build](../.claude/commands/build.md),
  [/uniface-launch-ide](../.claude/commands/uniface-launch-ide.md),
  [/uniface-cli](../.claude/commands/uniface-cli.md). The
  [quote-paths rule](../.claude/rules/quote-paths-with-spaces.md) premise was
  **softened** (paths *may* have spaces; this install avoids them — the rule stays as
  defensive hygiene). The spaced path survives only as a **cautionary example** and in
  the detection list of [check-quoted-paths.ps1](../.claude/hooks/check-quoted-paths.ps1).
- **Historical worklogs (002–008) were left unchanged** — they record what was true
  then. This entry is the reconciliation note.
- **Git tracking corrected** (per source-of-truth rule — XML exports are the VCS
  serialization, not the live DB): untracked `uniface/project/dbms/usys.db` (1.4 MB
  live repository DB), `ide_state.zip`, and the `Your Project Folder.txt` marker;
  added them to [.gitignore](../.gitignore) (plus `uniface/project/resources/`
  generated output). **`install_info.txt` kept tracked** as the install baseline.
  Working copies untouched.

## Part 2 — Tutorial review: the construct workflow

Reviewed Rocket's **public 10.4 tutorials** (the `dev.to/petercode` series). Goal:
capture the repeatable build sequence and the verifiable v10 idioms; fold into
onboarding **§1.7**. Distilled findings (✅ stated in the tutorial · ⚠️ implied):

### Construct sequence ✅
**Create → Define structure → Script (ProcScript triggers) → Create layout
(skipped for headless services) → Compile → Test (Actions → Test, tuned via test
logicals in `ide.asn`).** Triggers are `trigger <name>` / `trigger <ENTITY>.<event>`.

### Services (compile to `.svc`, no UI) ✅
4-tier flow: Presentation → **SSV** (business) → **ESV** (data access) → DB.
- **ESV (Entity Service)** — wraps exactly **one** entity/table; CRUD + Data Access
  Logic; validation in `write`/`validate` triggers; watch **"chattiness"**
  (per-call instantiation cost).
- **SSV (Session Service)** — multi-entity business logic, stateless per request,
  **transaction controller** (`commit`/`rollback`). Call an op:
  `activate "SVC_NAME".operation(in_x, out_y)`; bodies `entry <op> … end`. Interactive
  statements (`askmess`/`display`/`print`/`run`) are **forbidden** in services.

### Application Server Shell ✅
A module with **Shell Type `APU`** that controls server start-up and request routing:
`receiveMessage` dispatches requests to components; `preRequest`/`postRequest` wrap
each activation (auth via `$user_id`, logging). Created by dragging the **Windows
Shell** template onto the project, setting Shell Type `APU`, scripting init, compiling.

### Running an app ✅
`uniface.exe <appshell>` runs the runtime against that shell; a copied `myapp.exe`
auto-loads matching `myapp.ini`/`.asn` but is **locked to one app** (only the original
`uniface.exe` is parameter-driven). `.ini` = customization, `.asn` = resource
assignment.

### What the public tutorials DON'T cover (→ seek from gated *Getting Started*)
Definition-side mechanics and runtime plumbing are thin: the **signature/operations
editor** (how service operations + IN/OUT params are formally declared — only the
call-site `activate` is shown), **`newinstance`/instance lifecycle**, **`.asn`
registration** of components/services, **urouter/userver runtime topology**, the
**UAR packaging** + schema-gen steps, and a full **Form/Server-Page layout** walk-through.

## Part 3 — Hand-off: gated *Getting Started* fetch-list

I cannot authenticate to `docs.rocketsoftware.com` / `my.rocketsoftware.com`
([[reference-rocket-docs-login]]). To close the gaps above, please save these gated
pages (or their PDFs) into the **gitignored `webfetched/`** folder and I'll distil
them (Rocket-proprietary — never committed):
1. **Getting Started** tutorial bundle — `…/uniface_104/…/gettingStarted/…`.
2. **Defining a Service / signature & operations editor** reference.
3. **Application shell / `.asn` assignment** reference (logicals, `[application]`).
4. **Runtime topology** (urouter/userver/connectors) overview.
5. The **PAM** (still-open DSP browser/ES rows from worklog/009).

## Documentation outcome
- **onboarding §1.1** — project dir + launch example re-based to `C:\ref` / in-repo
  project; spaced-path gotcha reframed (live command is now space-free, with the
  spaced case kept as the cautionary example).
- **onboarding §1.7 (new)** — "Building a component: the construct workflow."
- **onboarding Contents** — §1.7 added.
- This worklog records the new baseline and the tutorial distillation.

> **Next (Phase B/C → [worklog/012](012-workarea-introduction.md)):** the **WorkArea**
> design doc + a non-destructive WorkArea command/rule skeleton (emulate the WAS
> file↔repository sync with the export/import CLI; UD6/WAS-ready).

## References
- **WorkArea / WAS — primary sources (carried forward for 012):**
  - Work Area Support Utility (Rocket community):
    <https://community.rocketsoftware.com/uniface-samples-111/work-area-support-utility-27362>
  - WASListener (GitHub): <https://github.com/uniface/WASListener>
- **Public 10.4 tutorials (this pass):**
  - Construct a component — <https://dev.to/petercode/how-to-construct-a-component-in-uniface-104-a-step-by-step-guide-32ae>
  - Services overview — <https://dev.to/petercode/understanding-uniface-104-services-a-developers-guide-430o>
  - Entity Services (ESV) — <https://dev.to/petercode/uniface-entity-services-your-database-bodyguard-22b1>
  - Session Services (SSV) — <https://dev.to/petercode/uniface-session-services-the-unsung-heroes-of-business-logic-22fc>
  - Application Server Shell — <https://dev.to/petercode/creating-an-application-server-shell-in-uniface-104-a-step-by-step-guide-acb>
  - Running apps — <https://dev.to/petercode/running-your-uniface-104-applications-a-simple-guide-d4n>
- Baseline source: `C:\ref\uniface\adm\usys.ini [install]`,
  [uniface/log/install_info.txt](../uniface/log/install_info.txt).
- Related: [005](005-v10-source-of-truth-and-vscode-workflow.md),
  [008](008-sample-driven-export-verification.md),
  [010](010-plan-tutorials-and-workarea.md).
