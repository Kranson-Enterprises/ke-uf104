# Uniface 10 Onboarding

> **Purpose:** Bring a developer who knows classic Uniface (v5–v9) — or a capable
> newcomer — up to speed on the Uniface 10 development environment, deployment
> packaging, and runtime/environment management.
>
> **Status: DRAFT for review.** Items tagged **`[verify]`** are things I (Claude)
> state with lower confidence and that should be confirmed against the official
> Rocket Uniface documentation and your own hands-on experience before this doc
> is treated as authoritative. Veteran corrections are expected and welcome.

Confidence legend used below:
- ✅ **Confident** — stable, long-standing Uniface concept.
- ⚠️ **`[verify]`** — believed correct but confirm exact naming / UI / version behavior in 10.4.

---

## 0. Orientation for v5–v9 veterans

The single biggest change to internalize: **Uniface 10 replaced the classic IDF
(the v9 Integrated Development Framework / "Uniface Development Environment")
with an entirely new IDE.** ✅ If your muscle memory is from v7/v8, the *concepts*
carry forward (application model, components, ProcScript, triggers, assignment
files) but the *tooling and workflow* are new.

What carries forward (you already know this):
- **Model-driven development** — the Application Model (entities, fields, keys,
  relationships) is still the backbone. ✅
- **ProcScript** — the procedural 4GL, still trigger- and operation-based. ✅
- **Components** — Forms, Services, Reports, plus web components. ✅
- **The assignment file (`.asn`)** — still how runtime is configured. ✅

What's genuinely new or reworked:
- A rebuilt IDE with a modern UI and a **Workspace**-centric model. ⚠️ `[verify]`
- A cleaner separation between **development repository** and **deployment**. ✅
- Stronger emphasis on **web components (Dynamic Server Pages / DSP)** with a
  documented JavaScript/browser API. ⚠️ `[verify exact DSP capabilities in 10.4]`
- Editions including **Community Edition** (what this project uses: 10.4.03 CE),
  which is feature/connector-limited vs. the full product. ⚠️ `[verify CE limits]`

---

## 1. Development environment

### 1.1 The IDE and the Workspace
- The Uniface 10 IDE is itself a Uniface application running on the Uniface
  runtime. ✅
- Work is organized in a **Workspace** — your set of development objects and the
  development-time settings/assignment that back them. ⚠️ `[verify the precise
  Workspace definition and how many you typically maintain]`
- Development objects live in a **repository** (a DBMS). For Community Edition the
  repository is backed by a **bundled database** rather than an external RDBMS.
  ⚠️ `[verify which DB ships with 10.4 CE — historically SQLite-class]`

### 1.2 Object types you build
- **Application Model** — entities, fields, keys, relationships, and modeled
  metadata that components inherit from. ✅
- **Components:** ✅ for the categories, ⚠️ `[verify exact 10.4 type list/names]`
  - **Form** — interactive UI component.
  - **Service** — non-UI, operation-based logic (callable; in-process or remote).
  - **Report** — output/printing.
  - **Server Pages / DSP** — web UI (Dynamic Server Pages) served to a browser.
  - **Session / entry** objects for web request handling. ⚠️ `[verify]`
- **ProcScript** in **triggers** and **operations**, with **signatures** defining
  callable interfaces (params: IN/OUT/INOUT). ✅
- **Global objects**: includes, global ProcScript, message library, glyphs. ⚠️

### 1.3 Editors and workflow
- Structure/model editors for entities and components, a script editor for
  ProcScript, and a painter for Form layout. ⚠️ `[verify exact editor names/UX
  in 10.4 — this is where I'm least sure of current naming]`
- **Compile** turns development objects into runtime objects; compiler
  output/messages surface in the IDE. ✅
- Typical loop: model → define component → write ProcScript in triggers/operations
  → compile → test-run from the IDE → iterate. ✅

### 1.4 Source management
- Uniface supports **exporting development objects to text** (importable/exportable
  source) so they can live in version control rather than only inside the
  repository DB. ✅ concept; ⚠️ `[verify the exact 10.4 export format/command and
  whether it's per-object or workspace-level]`
- For this repo, that's the bridge between the Uniface repository and Git:
  export sources into `src/` / `components/` and commit the text artifacts.

---

## 2. Deployment packaging

### 2.1 The mental model
Deployment = assemble everything the Uniface **runtime** needs to execute your
application **without** the development environment:
1. **Compiled runtime objects** (your compiled components/model). ✅
2. **An assignment file (`.asn`)** describing the target environment. ✅
3. **Resources** — message library, glyphs, includes, web resources, etc. ✅
4. **The Uniface runtime distribution** — runtime binaries + connectors +
   license. ✅
5. **Database connectivity** for the target DBMS. ✅

### 2.2 Where compiled objects go
- Compiled objects are stored as records in a **runtime repository (DBMS)** and/or
  exported to **files**, depending on how you assign storage. ⚠️ `[verify the
  default in 10.4 and the recommended packaging path]`
- A deployment typically points its assignment at the **runtime** repository/
  resources, distinct from the development repository. ✅

### 2.3 Producing a package
- The IDE provides a way to **export/deploy** a compiled application set for
  delivery to a target. ⚠️ `[verify the exact 10.4 deploy/export feature name and
  steps — I don't want to invent menu paths]`
- Best practice for "multiple apps at a client site" (this project's goal): treat
  each deployable as **{compiled objects + its own `.asn` + resources + a known
  runtime version}**, versioned and reproducible. ✅ (general principle)

### 2.4 Licensing
- The runtime requires a **valid license** present in the environment. ✅
- ⚠️ `[verify the 10.4 license artifact form (file vs. key) and how CE licensing
  differs from full product]`

---

## 3. Environment & runtime management

This is the part veterans care about most, and it's largely **assignment-file
driven** — conceptually familiar from earlier versions. ✅

### 3.1 The assignment file (`.asn`)
The `.asn` maps **logical** names to **physical** resources and holds runtime
settings. The development environment and each deployed environment each have
their own assignment. ✅

Common sections (names are stable Uniface concepts; ✅ on the model, ⚠️ on
remembering every exact header spelling in 10.4):
- **`[SETTINGS]`** — runtime switches/parameters. ✅
- **`[PATHS]`** — physical path mappings. ✅
- **`[LOGICALS]`** — logical-name → value definitions (`$NAME` logicals). ✅
- **Database/connection mapping** — associates entities/schemas with a DBMS
  connector and connection string. ✅ `[verify the exact 10.4 section header —
  historically the `[ENTITIES]`-style mapping with `tablename DBMS:database`]`
- **Driver / connector settings** — per-connector options. ✅
- **`[SERVICES_EXEC]`** / service routing — where services execute (local vs.
  remote). ⚠️ `[verify header name]`

Promoting dev → test → prod is primarily **swapping the assignment file** (and the
target DB/resources), not recompiling logic. ✅ This is the key operational lever.

### 3.2 Database connectors
- Uniface talks to DBMSs through **connectors/drivers** (short codes, e.g. Oracle,
  MS SQL Server, DB2, ODBC, and a bundled file/SQLite-class DB). ✅ concept;
  ⚠️ `[verify the exact driver code strings available in 10.4 CE — CE is limited]`
- The connector + connection string + credentials live in the assignment, so the
  same compiled app retargets a different database by assignment alone. ✅

### 3.3 N-tier topology (Router / Server)
For client/server and 3-tier deployments, Uniface uses middleware processes: ✅
- **Uniface Router (`urouter`)** — listens on a network port and brokers client
  requests to server processes. ✅
- **Uniface Server (`userver`)** — executes Uniface services/components on the
  server tier. ✅
- Connection topology is configured via assignment + a network configuration
  (historically a `polyserver`/`.tcp`-style config). ⚠️ `[verify exact 10.4
  config filenames]`
- Services can run **in-process** (same runtime) or **remote** (via the Router),
  controlled by assignment/service routing. ✅

### 3.4 Logging, diagnostics, error handling
- Runtime behavior is observable via message frames and ProcScript status
  variables (`$status`, `$procerror`, `$procerrorcontext`). ✅ `[verify exact
  variable set in 10.4]`
- Logging verbosity and output are configurable through assignment settings. ✅
- A practical "is it the code or the environment?" triage: if it compiles and runs
  in dev but fails on a target, suspect **assignment / connector / paths / license**
  before suspecting logic. ✅ (best-practice heuristic)

---

## 4. Productivity tips (AI tooling + human operator)

- **Treat the `.asn` as the environment contract.** Keep one per environment under
  version control (sanitized of secrets) so dev/test/prod differences are
  diff-able. ✅
- **Export Uniface sources to text and commit them** so the repository DB isn't the
  only source of truth and Claude/Git can actually see and review your objects. ✅
- **Name a "known-good runtime version"** per deployable; pin it. Mixed runtime
  versions across client apps is a common support trap. ✅
- **For Claude-assisted workflow:** point me at exported sources (`src/`,
  `components/`) and `.asn` files — I can review ProcScript, diff environment
  configs, and help script packaging/monitoring once the artifacts are in-repo.
- **For the human operator:** build a one-page per-app runbook (assignment
  location, DB target, Router/Server ports, license location, start/stop steps).

---

## 5. What to verify / correct next (handoff to the veteran)

These are the specific points I flagged `[verify]` and would value your
correction on, so this doc can graduate from draft to authoritative:
1. Exact 10.4 IDE object/editor names and the Workspace definition (§1).
2. The current deploy/export feature name and steps (§2.3).
3. Default compiled-object storage and recommended packaging path (§2.2).
4. Exact assignment section headers and DB-mapping syntax in 10.4 (§3.1).
5. Available driver codes and connector limits under Community Edition (§3.2).
6. 10.4 Router/Server network config filenames and license artifact form (§3.3–§2.4).

> Once you mark these up, I'll fold your corrections back in and drop the
> `[verify]` tags on the confirmed items.

---

### Reference
- Official documentation: **Rocket Uniface documentation** (Uniface 10.4
  product docs) — authoritative source for all `[verify]` items above.
- See also: [docs/uniface-links.md](uniface-links.md) (link collection in this repo).
