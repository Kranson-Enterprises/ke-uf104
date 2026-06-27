# 004 IDE Environment — Verified Definitions, Licensing & Driver References, and .asn Guidance

**Date:** 2026-06-27
**Sequence:** Continues the analysis thread — 001 (Claude setup) → 002 (IDE is a
CEF/Chromium shell) → 003 (spaces-in-paths) → **004 (environment definitions +
references)**. This entry consolidates the file-inspection verification pass into
durable, teachable definitions and adds the requested extended references on
licensing, database-driver availability, and development-vs-production `.asn`
usage.
**Basis:** Live Uniface **10.4.03 CE** install — `uniface\adm\*.asn`,
`common\adm\dbms.asn`, `usys.ini`, `common\bin`. Upstream facts cross-checked
against Rocket documentation (see References). Confidence: ✅ verified locally,
📘 from Rocket docs, ⚠️ best-practice guidance.

---

## 1. The "new UI" environment — where we are

The Uniface 10 IDE is **not** a native Win32/WPF app. It is a **Chromium Embedded
Framework (CEF) shell** rendering an HTML/CSS/JS front-end, driven by the native
Uniface runtime (`yrtl.dll`, `uobsrv.dll`, …). ✅ (detail in
[002-ide-architecture-analysis.md](002-ide-architecture-analysis.md)). The IDE is
itself a Uniface application; it talks to a **repository database** and compiles
to **resource files** that the runtime executes.

This matters for "understanding the new UI": the editors, palettes, U-Bar, and
Smart Resource Browsers are web components, which is why the experience feels
"modern/Fluent" and is platform-portable.

---

## 2. Expanded definitions (glossary)

| Term | Definition | Source |
| --- | --- | --- |
| **Project directory** | Working dir holding the dev assignment, `.\dbms\` repository DBs, and `.\resources` compile output. CE default `C:\Users\<user>\Rocket Uniface 10 Community Edition\project\` (`usys.ini [install] project=`). | ✅ |
| **Repository** | The DBMS storing development objects (model, components, ProcScript). In CE it is a bundled **SQLite** file `.\dbms\usys.db` via the `SLE` driver. | ✅ |
| **Assignment file (`.asn`)** | Text config mapping logical names → physical resources and holding runtime settings. One per environment. Supports `#file` includes. | ✅ |
| **`usys.ini`** | Master initialization file (`/adm` points to its folder). Holds `[install]` topology (ports), `[edition]`, widget/UI registration. | ✅ |
| **UAR** | **U**niface **AR**chive — packaged compiled resources. Runtime `[RESOURCES]` lists UAR files or resource directories. | ✅ |
| **`$RESOURCES_OUTPUT`** | Assignment setting for the directory compiled objects are written to / read from (`.\resources`). | ✅ |
| **Component types** | **FRM** Form, **RPT** Report, **SVC** Service, **DSP** Dynamic Server Page (web), **USP** Uniface Server Page (web); ESV/SSV also present. | ✅ (ESV/SSV meaning ⚠️) |
| **Editors** | Component, Entity, Project, Startup-Shell, Snippet-Library, Include-Library, Global-ProcScript-Library; Component Editor has Define-Structure / Define-Frames / Write-Script / Design-Layout worksheets. | ✅ |
| **U-Bar / Smart Resource Browsers** | The IDE's command/search bar and context-aware object pickers (`UBAR_RESULTS_MAXHITS`). | ✅ |
| **Uniface Router (`urouter.exe`)** | TCP broker between clients and server processes. CE default `localhost:13001`. | ✅ |
| **Uniface Server (`userver.exe`)** | Executes services/components on the server tier (assignment `userver.asn`). | ✅ |
| **Router Monitor (`urmon.exe`)** | Admin/monitoring tool for the Router. | ✅ |
| **Debug Server (`udbg.exe`)** | Remote ProcScript debugging. CE default `localhost:13002`. | ✅ |
| **Tomcat** | Servlet container serving web components (DSP/USP). CE default port `8080`. | ✅ |

---

## 3. Extended reference — Licensing

| Aspect | Community Edition | Enterprise Edition |
| --- | --- | --- |
| Model | **Cloud-served standalone** only, via the **Sentinel Cloud Server** | Standalone (file) **and** central license server | 📘 |
| Activation | On first IDE start, the **License Management utility** (`ulic.exe`) activates using an **Entitlement ID**; internet required to activate, renew the lease, and return | File or server-based provisioning | 📘 |
| Artifact (this install) | **No local license file** — cloud activation (`ulic.exe /reg /act /ret`; `ULIC_TIMEOUT` in `ulic.asn`) | File-based uses a **`lservrc`** Sentinel license file, referenced via `$license_options LM_LICENSE_FILE=USYSLIC:lservrc` (seen in `userver.asn`) | ✅ / 📘 |
| Use restriction | **Non-commercial use** only | Commercial | 📘 |
| IDE/features | Same IDE and major features as Enterprise | Full | 📘 |

**Operational implications**
- A CE workstation **must reach the internet** periodically or the lease lapses
  and the runtime/IDE stops. ⚠️ Plan for this on locked-down client machines.
- For production at a client site (the project goal), Enterprise file/central
  licensing avoids per-machine cloud dependency. ⚠️

---

## 4. Extended reference — Database driver availability

Uniface connectors are referenced by short codes in `[DRIVER_SETTINGS]` and bound
in `[PATHS]`.

| Connector | Code | Full product | This CE install |
| --- | --- | --- | --- |
| SQLite | `SLE` | ✅ (SLE **2.0** new in 10.4) | ✅ **shipped** (`usle10/usle20.dll`) |
| Oracle | (ORA) | ✅ | ❌ not present |
| Microsoft SQL Server | (MSS) | ✅ | ❌ not present |
| IBM Db2 | (DB2) | ✅ | ❌ not present |
| MySQL | (MYS) | ✅ | ❌ not present |
| PostgreSQL | `PGS` | ✅ | ❌ (commented example only in `dbms.asn`) |
| ODBC / generic | (ODB) | ✅ | ❌ not present |
| Built-in file drivers | `SEQ`, `TXT` | ✅ | ✅ present |

Notes:
- ✅ Verified locally: **CE bundles only SQLite (SLE)** as a DBMS connector, plus
  the built-in file drivers. Enterprise DBMS connectors are not in the CE `bin`.
- 📘 Per Rocket docs, the full product integrates with Oracle, SQL Server, MySQL,
  Db2, PostgreSQL, and ODBC. (Exact 2/3-letter codes for non-shipped connectors
  marked in parentheses are conventional; ⚠️ confirm against the docs.)
- 📘 **SQLite is single-user** and *not recommended for a shared repository* —
  fine for learning/dev, not for a multi-developer or production repository.

**DB-mapping syntax (verified, `dbms.asn`):**
```
[DRIVER_SETTINGS]
SLE     U2.0
USYS$SLE_PARAMS create db = on, identifiers = quoted
[PATHS]
$DBMS        SLE:.\dbms\usys.db                        ; SQLite: DRIVER:filepath
; $DBMS      PGS:PostgreSQL35W:ufdb|postgres|uniface   ; networked: DRIVER:datasource:db|user|pwd
$SYS  $DBMS
$DEF  $DBMS_DEF
```

---

## 5. `.asn` recommendations — development vs. production

The assignment is the environment contract; the same compiled objects move
between environments by **swapping the `.asn`** (and the target DB/resources).
Verified dev defaults are marked ✅; production guidance is ⚠️ best practice.

| Concern | Development (verified defaults) | Production / deployed (recommended) |
| --- | --- | --- |
| Repository / data DB | SQLite `SLE:.\dbms\usys.db` ✅ | Real DBMS connector (ORA/MSS/PGS/…) with credentials **externalized**, not inline ⚠️ |
| Debuggable compiles | `$NO_DEBUG = 0` ✅ | `$NO_DEBUG = 1` (ship non-debuggable) ⚠️ |
| Test mode | `$test_mode_components` on (reloads defs each request) ✅ | **Remove it** — it's a perf killer ⚠️ |
| Resources | `$RESOURCES_OUTPUT = .\resources` (compile output) ✅ | `[RESOURCES]` → packaged **UAR** files, read-only ⚠️ |
| Compiler messages | `$MESSAGE_LEVEL`, `$LISTING_LEVEL`, `$GENERATE_CMI` for dev feedback ✅ | Tighten/disable verbose listings ⚠️ |
| Network / TLS | plain TCP, local Router `localhost:13001` ✅ | `[NET_SETTINGS] CERT_PROFILE` → **TLS**; real Router host/port ⚠️ 📘 |
| Logging | `$PUTMESS_LOGFILE = usyslog:ide_%p.log` ✅ | Managed log path with rotation; avoid logging secrets ⚠️ |
| Licensing | CE cloud (Sentinel) ✅ | Enterprise file/central license (no per-box cloud dependency) ⚠️ 📘 |
| Documentation logical | `DOCUMENTATION_LOCATION = https://docs.rocketsoftware.com` ✅ | n/a (dev-only) |
| Secrets | — | Keep DB passwords / certs **out of version-controlled `.asn`**; inject at deploy ⚠️ |

**Pattern for "multiple apps at a client site":** one assignment per
{app × environment}, version-controlled **without secrets**, each pinned to a
known runtime version and its own packaged UAR set. ⚠️ (project goal — see
[001-claude-integration-setup.md](001-claude-integration-setup.md)).

---

## 6. Open items (UI/behavioral — not file-derivable)

Carried in the onboarding doc §5 and the project memory:
1. Precise in-IDE **"Workspace"** definition vs. the project directory.
2. The **deploy/export** feature name and click-path in the IDE.
3. Exact meaning of **ESV/SSV** component types.
4. Exact 10.4 source **export format/command** for version control.
5. Exact 10.4 **ProcScript status-variable** set (`$status`/`$procerror`…).

Next probe: explore these in the running IDE (PID from session) or the Rocket docs.

> **Update (2026-06-27):** All six open items are resolved, and the §2 glossary's
> `ESV/SSV meaning ⚠️` is now confirmed: **ESV = Entity Service, SSV = Session
> Service** ([006](006-cli-usage-and-claude-command-suite.md)). Workspace
> definition, the IDE **Export** action + export format/granularity, and the
> ProcScript status variables (`$status`/`$procerror`/`$procerrorcontext`) are in
> [008](008-sample-driven-export-verification.md). DSP capabilities — including
> where web assets actually live — are in
> [009](009-dsp-capabilities-web-research.md) / onboarding §1.6.

---

## References

> Some Rocket documentation URLs may require a (free) Rocket Software login. See
> also [../docs/uniface-links.md](../docs/uniface-links.md).

- DBMS Support (intro): <https://www3.rocketsoftware.com/rocketd3/support/documentation/Uniface/104/uniface/dbmsSupport/dbmsSupport_Intro.htm>
- DBMS Connectors (list): <https://www3.rocketsoftware.com/rocketd3/support/documentation/Uniface/10/uniface/dbmsSupport/dbmsDrivers/DBMSConnectors.htm>
- Configuring the Database Connector: <https://www3.rocketsoftware.com/rocketd3/support/documentation/Uniface/104/uniface/dbmsSupport/dbmsDrivers/configure_database_connector.htm>
- SQLite (SLE) connector: <https://www3.rocketsoftware.com/rocketd3/support/documentation/Uniface/10/uniface/dbmsSupport/dbmsDrivers/SQLite/SLE.htm>
- Licensing overview: <https://www3.rocketsoftware.com/rocketd3/support/documentation/Uniface/10/uniface/installation/Licensing/Concepts/licensingOverview.htm>
- What's New in Uniface 10.4.01 (incl. SLE 2.0): <https://www3.rocketsoftware.com/rocketd3/support/documentation/Uniface/104/uniface/migration/whatsNew/10.04/u100401_whatsNew.htm>
- Uniface 10.4.03-000 released (forum): <https://community.rocketsoftware.com/uniface-product-updates-108/rocket-uniface-10-4-03-000-released-9584>
- Related in-repo: [../docs/uniface-10-onboarding.md](../docs/uniface-10-onboarding.md), [002-ide-architecture-analysis.md](002-ide-architecture-analysis.md)
