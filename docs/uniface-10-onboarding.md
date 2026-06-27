# Uniface 10 Onboarding

> **Purpose:** Bring a developer who knows classic Uniface (v5–v9) — or a capable
> newcomer — up to speed on the Uniface 10 development environment, deployment
> packaging, and runtime/environment management.
>
> **Status: VERIFIED.** Confirmed on 2026-06-27 against a live Uniface 10.4.03 CE
> install — assignment files, `usys.ini`, `common\bin`, gated Rocket docs, and the
> **MusicCart sample** loaded in the IDE (export files, on-disk artifacts, real
> ProcScript). Every original *file-/CLI-/behavioral* `[verify]` item is resolved
> (§5). Two ⚠️ tags remain by nature — **DSP feature depth** and **CE edition
> limits** — product-capability questions answered by Rocket's docs, not by this
> install. Corrections welcome.

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
- A rebuilt IDE whose **"modern UI" is an embedded Chromium browser (CEF)** — the
  UI is HTML/CSS/JavaScript rendered by Chromium Embedded Framework and driven by
  the native Uniface runtime, which is what makes it platform-portable. ✅
  *Verified locally on 10.4.03 042 — see §1.1 Architecture.* Dev work is
  organized around a **repository-backed project**: you develop the model and
  components **in the IDE**, while web presentation assets and other file-based
  artifacts are developed **as files** (e.g. in VSCode). See §1.5. ✅
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

#### Architecture (verified locally on 10.4.03 042, 2026-06-27)
Inspecting the running `ide.exe` (its loaded modules and child processes) shows
the IDE is a **Chromium Embedded Framework (CEF) shell rendering an HTML/JS UI**,
driven by the native Uniface runtime engine. Evidence:
- `libcef.dll` = **CEF 141.0.5 / Chromium 141.0.7390.55**; `chrome_elf.dll` matches.
- **8 × `cefrender.exe`** subprocesses — the classic Chromium multi-process model.
- Native Uniface runtime layer present: `yrtl.dll` (10.4.03 042), plus `uob*`,
  `lsapiw64` (licensing), `xerces-c` (XML), `libcryptou` (OpenSSL 3.5.6).

Takeaway: the "modern UI" is **web technology in a browser shell**, not native
Win32/WPF widgets — hence the platform-portability and Fluent-like styling. The
embedded Chromium is kept close to upstream (141 is recent), a positive security
signal.

#### Launching the IDE from the command line (gotcha)
The install paths contain spaces, so the `/adm` switch **must quote the entire
token** (Rocket's own Start-Menu shortcut does exactly this), and the IDE expects
to start in the project working directory:

```
"C:\Program Files\Rocket Uniface 10 Community Edition\common\bin\ide.exe" "/adm=C:\Program Files\Rocket Uniface 10 Community Edition\uniface\adm" ?
```
- Quote `"/adm=...path..."` as one argument — quoting only the path (or not at
  all) makes Uniface look for `usys.ini` in the wrong place and the IDE exits
  immediately. `usys.ini` lives at `uniface\adm\usys.ini` (where `/adm` points).
- Working directory: `C:\Users\<user>\Rocket Uniface 10 Community Edition\project\`.
- The trailing `?` is a real argument from Rocket's shortcut (not a typo).

- Work is organized in a **project directory** (CE default
  `C:\Users\<user>\Rocket Uniface 10 Community Edition\project\`, recorded as
  `project=` in `usys.ini [install]`). It holds the dev assignment, the `.\dbms\`
  repository databases, and the `.\resources` compile output. ✅ In practice the
  IDE's "Workspace" **is** this project context — the repository (the loaded set of
  projects/components, e.g. the MusicCart `prj: MUSICSHOP`) plus its project
  directory. Organization of what lives where is detailed in §1.5. ✅
- Development objects live in a **repository** (a DBMS). For Community Edition the
  repository is a **bundled SQLite database** — `.\dbms\usys.db` via the `SLE`
  driver (user data in `.\dbms\userdata.db`). ✅ *Verified in `common\adm\dbms.asn`.*

### 1.2 Object types you build
- **Application Model** — entities, fields, keys, relationships, and modeled
  metadata that components inherit from. ✅
- **Components** (type abbreviations confirmed from the IDE's palette config in
  `ide.asn`): ✅
  - **FRM** — Form (interactive UI).
  - **RPT** — Report (output/printing).
  - **SVC** — Service (non-UI, operation-based; in-process or remote).
  - **DSP** — Dynamic Server Page (web UI served to a browser). ✅
  - **USP** — (Uniface) **Static Server Page** — the other web component family
    (the Reference lists "Widget Reference: Static Server Pages" + "XHTML Elements
    for Static Server Pages"). ✅
  - **ESV** — Entity Service; **SSV** — Session Service. ✅ *Confirmed via the
    `/esv` / `/ssv` compile switches.*
  - **CPT** — generic "all components" (compiling `/cpt` = DSP+USP+FRM+RPT+SVC+ESV+SSV). ✅
- **ProcScript** in **triggers** and **operations**, with **signatures** defining
  callable interfaces (params: IN/OUT/INOUT). ✅
- **Global / library objects** (each has its own editor — see §1.3): Include
  Script libraries (LIBINC), Snippet libraries (LIBSNP), Global ProcScript
  libraries (LIBPRC), Projects (PRJ), and Application/Startup Shells (APS). ✅

### 1.3 Editors and workflow
- The IDE ships dedicated editors, confirmed from `ide.asn`: **Component Editor**
  (with Define Structure / Define Frames / Write Script / Design Layout
  worksheets), **Entity Editor**, **Project Editor**, **Startup Shell Editor**,
  **Snippet Library Editor**, **Include Library Editor**, and **Global ProcScript
  Library Editor**. ✅ Navigation uses the **U-Bar** and **Smart Resource
  Browsers**. ✅
- **Compile** turns development objects into runtime objects written to
  `$RESOURCES_OUTPUT` (`.\resources`); compiler output/messages surface in the
  IDE. ✅
- Typical loop: model → define component → write ProcScript in triggers/operations
  → compile → test-run from the IDE → iterate. ✅ Web components (DSP/USP) are
  tested via a bundled **Tomcat** (CE default port 8080). ✅
- **Migrating from Uniface 9?** The IDE has explicit v9→v10 migration logicals
  (trigger/operation migration, inheritance handling). ✅ *Seen in `ide.asn`
  `[LOGICALS]`.* (Note: relevant for v5–8 veterans only after a v9 step.)

### 1.4 Source management — the repository is the source of truth
- **Development objects live in the repository DB, not in files.** A single
  object's definition may be spread over several repository entities, so you can't
  hand-edit it — Uniface provides an **Export/Import facility** (with corruption
  safeguards) as the bridge to the filesystem and version control. ✅ 📘
- **Export/import is to XML** (well-formed, RI-aware, nested by aggregation; schema
  = "Uniface XML Constructs"). Three access methods: ✅ 📘
  - IDE **Main Menu (≡) / Actions** → Export/Import, selecting objects with a
    **retrieve profile**;
  - ProcScript **`$ude("export")` / `$ude("import")`** (XML, optionally zipped);
  - command line **`/imp`** (import). *No documented command-line export switch —
    script export via `$ude("export")` or the IDE.*
- **Import auto-migrates** compatible data and rejects incompatible/copy-created
  data. Note: the separate **Data Copy** facility (`/cpy`, `$ude("copy")`) is
  **not** import-compatible — use export/import for VCS, not copy. ✅ 📘
- For this repo, that's the Uniface↔Git bridge: export objects as XML into
  `components/` / `src/` and commit them as the VCS-visible serialization. See the
  full IDE-vs-VSCode analysis in
  [worklog/005](../worklog/005-v10-source-of-truth-and-vscode-workflow.md).

**Export — verified mechanics (MusicCart sample, 2026-06-27):** ✅
- **Click-path:** select the object in the IDE and use the **Export** menu action.
  Exporting at the **Project** level (`prj: MUSICSHOP` → **Export**) writes the
  whole project; exporting a single component writes just that component.
- **Granularity is selectable.** A single-component export
  (`cpt_musiccart.xml`) contains only **3** repository tables — `UFORM` +
  `UXGROUP` + `UXFIELD` (definition + UX page layout). A full project export
  (`export-all-sample`, 1.8 MB) contains **all 31** object classes (`UAPPL`,
  `UPROJECT`, `UFORM`, `UC*` component tables, `UX*` layout, `US*` service
  specs/signatures/operations, `U*LIB*`/`UINC`/`UPRC`/`USNP` libraries, `UREF*`
  cross-refs). All share the header `<UNIFACE release="10.4" repversion="8">`.
- **There is NO command-line export switch.** Empirically confirmed: running
  `ide.exe … /exp /all` is rejected by Uniface with
  `0099 - Command line string not acceptable` (and exit code 1). The switch
  reference has no `/exp`. Use the IDE **Export** action or ProcScript
  `$ude("export")`; only **`/imp`** exists for the command line (import).

### 1.5 What you develop where — "Workspace" organization
This resolves the "Workspace-centric" question for IDF veterans: dev work splits
into two layers by **where the artifact lives**.

**A. The model & components — develop in the IDE (repository-backed).** ✅
- The **Application Model** (entities, fields, keys, relationships, inheritance)
  and **components** (FRM/RPT/SVC/DSP/USP/ESV/SSV) and their **ProcScript** are
  stored in the repository and edited through the IDE's structured editors
  (Component, Entity, Project, Library editors; U-Bar; Smart Resource Browsers).
- The repository is the **source of truth**; for version control these objects
  **round-trip to XML** via Export/Import (§1.4). You don't edit the live object
  as a file — you export it, optionally edit the XML, and import it back.

**B. Web presentation & additional files — the file-based layer (e.g. VSCode).**
- **Important nuance (verified on the MusicCart sample, 2026-06-27):** a DSP/USP's
  **page markup (XHTML) lives in the repository** and is *embedded into the compiled
  object* at compile time — it is **not** a standalone editable `.html` on disk.
  What you find on disk is **generated/compiled output**, not source you author. So
  the per-component page layout is an **IDE** artifact (Layer A), authored in the
  Component Editor's *Design Layout* worksheet, not a file you hand-edit. ✅
- **What *is* genuinely file-authorable** for the web tier: the **shared** static
  assets under the web app — `webapps\uniface\{css, common, templates, webserver}`
  — plus any custom CSS/JS/widgets and static resources you add. These are real
  files you can own in VSCode. ✅
- **Configuration** — `.asn` / `.ini` are plain text: edit directly in VSCode
  (keep secrets out; see the secrets rule). ✅
- **Automation & build** — `scripts/`, CI, and the `/uniface-*` commands. ✅

**Where artifacts actually land on disk** (verified, MusicCart on 10.4.03 CE):

| Artifact | On-disk location | Nature |
| --- | --- | --- |
| Compiled runtime object | `project\resources\<type>\<name>.<type>` (`dsp` `usp` `frm` `svc` `aps` `edc` `sig`) | Binary-headered; **embeds** the XHTML/template. Not hand-editable. |
| Generated DSP client JS | `…\webapps\uniface\dspjs\<name>.js` | Header: *"This source is generated by UNIFACE"* — **output**, not input. |
| Compiler / debug meta | `project\<name>.cmi` | JSON mapping runtime ↔ source positions (debugger). |
| **XML export (the VCS bridge)** | `project\<class>_<name>.xml` (e.g. `cpt_musiccart.xml`) | Repository serialization (`<DSC>/<FLD>/<DAT>`, `release="10.4" repversion="8"`). **One file per component.** |
| Framework static web assets | `…\webapps\uniface\{css, common, templates, webserver, WEB-INF}` | Shared, file-based. |

**Rule of thumb:** if it's a *modeled* object — including a DSP/USP's page layout —
it belongs to the IDE/repository (round-trip via XML, one `<class>_<name>.xml` per
component); only *shared web assets, config, and scripts* are files you own
directly in VSCode. Full analysis:
[worklog/005](../worklog/005-v10-source-of-truth-and-vscode-workflow.md).

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
- Compilation writes runtime objects to the **`$RESOURCES_OUTPUT` directory**
  (`.\resources` by default in the dev `ide.asn`). ✅ *Verified in `ide.asn`.*
- For packaging, resources are distributed as **UAR files** (Uniface ARchive) —
  the runtime's `[RESOURCES]` section lists either UAR files or resource
  directories (e.g. Uniface's own `usys:ide.uar`). ✅ *Verified in `userver.asn`
  `[RESOURCES]` ("Specify your UAR resource files or resource directories").*
- A deployment points its assignment's `[RESOURCES]` at the packaged
  resources/UARs, distinct from the development project. ✅

### 2.3 Producing a package
- **Compile for production** from the command line: `ide.exe /all /nodebug`
  (`/nodebug` makes shells/components/global ProcScript non-debuggable — the
  production setting). Output lands in `$RESOURCES_OUTPUT`, packaged as **UAR**. ✅
- **Generate the target-DBMS schema** with `/genSql` — e.g. develop on SQLite,
  deploy on Oracle/SQL Server: `ide.exe /gensql createTable *.MYMODEL ora`. It
  emits DBMS-specific DDL (tables, indexes, RI) for the DBA to run. ✅ 📘 (Does
  **not** support SEQ/TXT/ODBC.)
- The IDE **Export** action (select object → **Export**; at project level
  `prj: MUSICSHOP` → Export) produces the XML serialization for VCS — see §1.4 for
  verified granularity. Note this is *source* export, not a deploy-to-target
  wizard; the CLI compile + resources + assignment is the reproducible deploy path
  and is fully sufficient for scripted/CI delivery. ✅
- Best practice for "multiple apps at a client site" (this project's goal): treat
  each deployable as **{compiled objects + its own `.asn` + resources + a known
  runtime version}**, versioned and reproducible. ✅ (general principle)

### 2.4 Licensing
- The runtime requires a **valid license**. Two forms exist in 10.4: ✅
  - **Cloud licensing** — `ulic.exe` registers/activates/returns against a Rocket
    cloud license server (Start-Menu shortcuts: *Cloud LM Registration*, *License
    Activation/Return (Cloud Standalone)*; `ULIC_TIMEOUT` in `ulic.asn`). **This CE
    install uses cloud licensing** — no local license file is present. ✅ *Verified.*
  - **File-based (FlexLM)** — a `lservrc` license file referenced via
    `$license_options LM_LICENSE_FILE=USYSLIC:lservrc` (seen in `userver.asn`),
    used in server/enterprise setups. ✅

---

## 3. Environment & runtime management

This is the part veterans care about most, and it's largely **assignment-file
driven** — conceptually familiar from earlier versions. ✅

### 3.1 The assignment file (`.asn`)
The `.asn` maps **logical** names to **physical** resources and holds runtime
settings. The development environment and each deployed environment each have
their own assignment. ✅

Section headers confirmed from the shipped `ide.asn` / `dbms.asn` / `userver.asn`:
- **`[SETTINGS]`** — runtime switches/parameters (`$NAME` settings). ✅
- **`[LOGICALS]`** — logical-name → value definitions. ✅
- **`[DRIVER_SETTINGS]`** — declares DBMS drivers and versions (e.g. `SLE U2.0`)
  plus their `USYS$<drv>_PARAMS`. ✅
- **`[PATHS]`** — physical path mappings **and DBMS connections**, via
  `$logical DRIVER:connection`. ✅
- **`[ENTITIES]`** — per-entity/schema overrides (present, often empty). ✅
- **`[RESOURCES]`** — UAR files / resource directories. ✅
- **`[FILES]`** — file redirections. ✅
- **`[NET_SETTINGS]`** — network/TLS (e.g. `CERT_PROFILE`). ✅
- **`[USER_3GL]`**, **`[FORMATTING]`** — 3GL registration, code-format rules. ✅
- **`#file <logical>:adm\dbms.asn`** at the top **includes** another assignment —
  this is how DB config is shared across assignments. ✅

**DB-mapping syntax (verified, `dbms.asn`):**
```
[DRIVER_SETTINGS]
SLE     U2.0
USYS$SLE_PARAMS create db = on, identifiers = quoted
[PATHS]
$DBMS        SLE:.\dbms\usys.db                       ; SQLite file
; $DBMS      PGS:PostgreSQL35W:ufdb|postgres|uniface  ; DRIVER:datasource:db|user|pwd
$SYS  $DBMS
$DEF  $DBMS_DEF
```
So the mapping is `$schemaLogical DRIVER:connection`, not the older
`tablename DBMS:database` form I'd guessed.

Promoting dev → test → prod is primarily **swapping the assignment file** (and the
target DB/resources), not recompiling logic. ✅ This is the key operational lever.

### 3.2 Database connectors
- Uniface talks to DBMSs through **connectors/drivers** named by short codes. In
  this **Community Edition** install, the only DBMS connector shipped is **`SLE`
  (SQLite)** — DLLs `usle10.dll` / `usle20.dll` — alongside the built-in file
  drivers `SEQ`/`TXT`. ✅ *Verified: no Oracle/MSSQL/DB2 driver DLLs are present.*
- **`PGS` (PostgreSQL)** appears only as a **commented example** in `dbms.asn`;
  enterprise DBMS connectors are a full-product feature, not bundled with CE. ✅
- The connector + connection string + credentials live in the assignment, so the
  same compiled app retargets a different database by assignment alone. ✅

### 3.3 N-tier topology (Router / Server)
For client/server and 3-tier deployments, Uniface uses middleware processes
(executables in `common\bin`): ✅
- **Uniface Router — `urouter.exe`** — listens on a TCP port and brokers client
  requests to server processes. CE default **`localhost:13001`**. ✅
- **Uniface Server — `userver.exe`** — executes services/components on the server
  tier (its assignment is `userver.asn`). ✅
- **Router Monitor — `urmon.exe`** — the *Router Monitor* admin tool. ✅
- **Debug Server — `udbg.exe`** — CE default **`localhost:13002`**. ✅
- Topology/ports live in `usys.ini [install]` (`urouter_port`, `udbg_port`,
  `tomcat_port`) and connection/TLS in the assignment's **`[NET_SETTINGS]`**. ✅
  *Verified — no separate `polyserver.tcp` file in 10.4 CE.*
- Services can run **in-process** (same runtime) or **remote** (via the Router),
  controlled by assignment/service routing. ✅

### 3.4 Logging, diagnostics, error handling
- Runtime behavior is observable via message frames and ProcScript status
  variables — **`$status`, `$procerror`, `$procerrorcontext` confirmed in 10.4**
  (found in the MusicCart sample's exported ProcScript). ✅ The idiomatic pattern,
  taken verbatim from that sample, is:
  ```
  if ($status = 0)
    if ($procerror < 0)
      procerror = $procerror              ; capture into an OUT param
      procerrorcontext = $procerrorcontext
      return (0)
  ```
  Services propagate the error outward via signature params
  (`numeric procerror : OUT`, `string procerrorcontext : OUT`). `$status` is the
  call/operation status; `$procerror` is the ProcScript error code (**negative =
  error**); `$procerrorcontext` is its string context. (Other status variables
  exist in the full ProcScript reference; these three are the verified, in-use core.)
- Logging verbosity and output are configurable through assignment settings. ✅
- A practical "is it the code or the environment?" triage: if it compiles and runs
  in dev but fails on a target, suspect **assignment / connector / paths / license**
  before suspecting logic. ✅ (best-practice heuristic)

### 3.5 Command-line interface (compile / import / DDL) — verified
Run a Uniface executable (`ide`, `uniface`, `urouter`, `userver`, `udbg`) with
switches: `Executable {Switch {SubSwitches}}… {AppShell} {Parameters}`. ✅ 📘
This is the basis for CI/CD. Key switches (all "Use with `ide.exe`"):

| Switch | Purpose |
| --- | --- |
| `/all [Profile]` | Compile **all** main objects (= `/obj /sig /dsp /usp /frm /rpt /svc /esv /ssv /ceo /app /dtd`). |
| `/cpt` | Compile all **components** (= `/dsp /usp /frm /rpt /svc /esv /ssv`). |
| `/frm` `/rpt` `/svc` `/dsp` `/usp` `/esv` `/ssv` | Compile that one component type (wildcards allowed, e.g. `/svc *VAL`). |
| `/imp FileName` | **Import** XML Repository definitions. Exit code **0** success / **1** failure (scriptable). |
| `/cpy Source Target` | **Data Copy** of entity *occurrences* — **NOT** for Repository definitions (corrupts the Repository; use `/imp` + export instead). |
| `/genSql {/meta} createTable\|createScript entity.model DB [file]` | Generate **DBMS-specific DDL** (tables / RI) for a target connector (e.g. `mss`, `ora`). |

Common compile sub-switches: `/cmi=0|1` (compiled-module info; default 1 in v10),
`/sym=0..3` (symbol table / `UXCROSS` xref), **`/nodebug`** (non-debuggable —
**use for production builds**), `/aft=`/`/bef=DateTime` (changed-since), `/inf`/`/war`/`/lis`
(message verbosity), `/iap`/`/tpl`/`/plt` (purpose: include-all/templates/palettes).

Notes (verified):
- **No command-line *export* switch exists** — export Repository definitions via
  the IDE or `$ude("export")`. (`/ex` is unrelated — "exclusive Uniface Server".)
- **`ide.exe /all`** compiles everything; the trailing **`?`** opens the
  command-line dialog box.
- CLI execution **fails if the Repository has unmigrated/incompatible data** — run
  an interactive IDE session first to migrate (important for CI). ⚠️ operational
- Uniface Server processes are defined in **`urouter.asn` `[SERVERS]`**
  (e.g. `wasv = "…userver.exe" /dir=… /adm=… /asn=wasv.asn`). ✅

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

## 5. Verification status

Resolved by inspecting the live 10.4.03 CE install on 2026-06-27 (assignment
files in `uniface\adm` / `common\adm`, `usys.ini`, and `common\bin`):

- ✅ **§1** IDE object types & editors — confirmed from `ide.asn` palette config.
- ✅ **§2.2** Compiled-object storage & packaging — `$RESOURCES_OUTPUT` + **UAR** files.
- ✅ **§2.4** License form — CE uses **cloud licensing** (`ulic.exe`, Sentinel);
  a `lservrc` file is the file-based alternative.
- ✅ **§3.1** Assignment section headers & **DB-mapping syntax** — from `dbms.asn`.
- ✅ **§3.2** Connectors / CE limits — **SQLite (`SLE`) only**; no enterprise DBMS.
- ✅ **§3.3** Router/Server — `urouter.exe`@13001, `userver.exe`, `urmon.exe`,
  `udbg.exe`@13002; ports in `usys.ini [install]`.

Also resolved from the gated Rocket docs (saved locally 2026-06-27):
- ✅ **§1.4** Source management — XML **Export/Import** facility (IDE Main Menu/
  Actions, `$ude("export"/"import")`, command-line `/imp`); repository is the
  source of truth; Data Copy (`/cpy`) is separate and **must not** be used for
  definitions. **No command-line export switch exists.**
- ✅ **§1.2** Component types — DSP (Dynamic SP), USP (Static SP), **ESV = Entity
  Service**, **SSV = Session Service**, FRM/RPT/SVC, CPT = all components.
- ✅ **§3.5** Command-line interface — compile (`/all`, `/cpt`, per-type, `/nodebug`,
  `/cmi`, `/sym`), import (`/imp`, exit 0/1), DDL (`/genSql`), `?` dialog, repo-
  migration caveat, `urouter.asn [SERVERS]`.
- ✅ **§2.3** Production build — `ide.exe /all /nodebug` → UAR; `/genSql` for target DDL.
- ✅ **§1.5** "Workspace" organization — model & components in the IDE (repository,
  round-trip via XML); web assets / config / scripts as files (VSCode).

Also resolved by inspecting the **MusicCart sample** loaded in the live IDE (2026-06-27):
- ✅ **§1.5** **On-disk artifact map** — compiled objects in `project\resources\<type>\`;
  generated DSP JS in `webapps\uniface\dspjs\`; `.cmi` debug meta in the project root;
  XML export = `<class>_<name>.xml` (e.g. `cpt_musiccart.xml`). Key finding: **DSP/USP
  page markup is repository-stored and embedded into the compiled object** — not a
  standalone editable file on disk.
- ✅ **§1.4 / §2.3** **Export** — click-path = select object → **Export** (project
  level `prj: MUSICSHOP` → Export). Granularity selectable: single component =
  3 tables (`UFORM`+`UXGROUP`+`UXFIELD`); full project = all 31 object classes.
  **No CLI export switch** — `/exp /all` rejected with Uniface error `0099`.
- ✅ **§3.4** **ProcScript status variables** — `$status`, `$procerror`,
  `$procerrorcontext` confirmed in the sample's exported ProcScript, with the
  error-propagation idiom.

**Every file-/CLI-/behavioral `[verify]` item from the original draft is now
resolved.** The document is authoritative for 10.4.03 CE on the points covered. The
only two ⚠️ tags left — **DSP feature depth** (§0) and **CE edition limits** (§0) —
are product-capability questions for Rocket's docs, not things a single install
settles.

---

### Reference
- Official documentation: **Rocket Uniface documentation** (Uniface 10.4
  product docs) — authoritative source for all `[verify]` items above.
- See also: [docs/uniface-links.md](uniface-links.md) (link collection in this repo).
