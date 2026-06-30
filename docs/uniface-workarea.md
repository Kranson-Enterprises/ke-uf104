# Uniface WorkArea — file ↔ repository sync (design)

**Status:** design doc for the WorkArea tooling increment. Confidence: ✅ documented
(README/source) · 📘 community-stated · ⚠️ inferred / not documented.
**Primary sources:**
- Work Area Support Utility (Rocket community):
  <https://community.rocketsoftware.com/uniface-samples-111/work-area-support-utility-27362>
- WASListener (GitHub, MIT, branch `master_10.4`): <https://github.com/uniface/WASListener>
- IDE plugin model: <https://github.com/uniface/plugin-samples>

This doc explains what the real Uniface **WorkArea** workflow is, then defines how
this repo **emulates it now** with the export/import facility it already has —
structured so the real WAS tooling can drop in later. It is the architecture behind
the [/uniface-workarea-sync](../.claude/commands/uniface-workarea-sync.md) command and
the [uniface-workarea-sync](../.claude/rules/uniface-workarea-sync.md) rule.

---

## 1. The mental model

The **repository database is the master of record** for development objects (the
existing rule: [uniface-repository-source-of-truth](../.claude/rules/uniface-repository-source-of-truth.md)).
The **WorkArea** is a directory of **one XML export per object**, kept under Git, that
serves as the *shared, diffable* serialization. Each developer has their **own local
IDE + local repository**; teams integrate **only through the Git WorkArea**:

```
   IDE repository (local, per-dev)  ⇄  WorkArea/ (XML files, in Git)  ⇄  remote Git ⇄ teammates
        master of record                serialization / exchange
```

- **push (export):** your repository objects → WorkArea XML → commit.
- **pull (import / replay):** teammate's committed XML → `git pull` → replay into your
  repository (add / modify / delete per file).

This is the **sandbox-per-developer** model that mirrors the **target client's
infra**: the repo DB is a personal cache; the **XML WorkArea is the shared truth**. 📘

## 2. What WAS actually is (so we emulate the right thing)

> **UD6 ≠ WAS.** **UD6** is a **third-party commercial** repository *driver* from
> **March Hare Software** that stores objects as text files at the driver layer; it is
> **not** a Rocket product and is **not** bundled with Community Edition. ⚠️ **WAS**
> (Work Area Support) is **Uniface B.V.'s sample** (`github.com/uniface/WASListener`)
> and the tool we model. They solve the same problem two ways; we emulate **WAS**.
>
> **⚠️ License correction (2026-06-30, verified from the repo `LICENSE`).** Earlier notes
> here and in [worklog/012](../worklog/012-workarea-introduction.md) called WAS
> "MIT-licensed." **That is wrong.** The actual license is **Copyright © 2019 Uniface
> B.V.**, and it **bars commercial use**: *"Licensee shall not be entitled to use the
> Software and the results of use of the Software ('Results') for any commercial or
> illegal purposes."* (as-is, liability capped at €1000). For **personal skill-refresh /
> learning** this sample is fine; for **client/commercial delivery**, do **not** rely on
> it — verify terms with Rocket or use the commercial **UD6** path. Full discovery +
> integration: [worklog/021](../worklog/021-was-plugin-discovery-integration.md) and
> [uniface-was-plugin-integration.md](uniface-was-plugin-integration.md).

**WAS has two parts:** ✅
1. **`VersionControl.uar`** — an **IDE plugin** (Uniface app, project `VERSIONCONTROL`,
   main component `VC_MAIN`) loaded into the IDE; it does the actual repository
   import/delete and tracks per-object change state.
2. **`WASListener.exe`** — a native Win32 **tray watcher** (separate long-running
   process) that watches the WorkArea folder and drives the plugin.

**The sync loop** (verified from `WASListener.cpp` / `Uniface.cpp`): ✅
1. Listener boots a Uniface runtime and instantiates `VC_MAIN` via the 3GL C API.
2. It asks the plugin for the WorkArea path via operation **`GETWASFOLDER`** (so the
   Uniface side owns the location, resolved from a `WAS_ROOT_FOLDER` logical / asn).
3. A `CFolderWatcher` thread uses the Windows directory-change API to watch that
   folder; events are queued as **ADDED / REMOVED / MODIFIED**.
4. Each event maps to `(bDelete, bImport)` — ADDED→import, REMOVED→delete,
   MODIFIED→delete+import — and calls the plugin's **`VC(filePath, bDelete, bImport)`**
   operation, which imports/deletes that one object in the repository.
5. **Orphan / conflict guard:** if `VC` returns **`oprStatus == 2` ("dirty")** — the
   developer has uncommitted IDE changes to that object — the file change is **not**
   force-replayed; the listener raises a tray notification for the developer to
   resolve. ✅
- Single instance enforced by a `.WASListener.lock`; the **WorkArea must be a local
  folder** (network paths aren't monitored). ✅

**Accept / revert** (IDE plugin burger menu, gated by `IDE_DEFINE_USERMENUS=VC_UPDATED`): ✅
- **WorkArea Export/Revert** — per tracked object, **export** your IDE change to the
  WorkArea file, or **revert** to the file's version.
- **Import WorkArea** — bulk-import all files.
- **Mark all as ready for export / Export All** — first-time full dump of the
  repository to the WorkArea (fresh imports are otherwise all flagged "new").

**Setup (real WAS, for reference):** add `VersionControl.uar` **before** standard UARs
in `ide.asn [RESOURCES]`; compile the `VERSIONCONTROL` project; enable
`IDE_DEFINE_USERMENUS=VC_UPDATED`; first-time **Export All**. The listener is built
with CMake/vcpkg, links the Uniface **3GL API**, and runs with `-a <adm> -i <ini>
-f <asn> -p <project>`. Made available **as-is**, not part of the supported product. ✅

## 3. WorkArea file layout (this repo)

WAS lays the WorkArea out as **one subfolder per object class** (3-letter class codes),
**one `.xml` Uniface export per object**. We mirror that so the layout is
**WAS-compatible** — a real WASListener could later watch this same tree. ✅ (layout
verified from the plugin's own sample WorkArea)

```
workarea/
  aps/     application shells          (uapc/uapm/uaps/uapu *.xml)
  cpt/     components (frm/dsp/usp/svc/rpt …)  one *.xml per component
  ent/     model entities / dictionary
  prj/     project objects
  libinc/  include libraries
  libprc/  global ProcScript libraries
  libsnp/  snippet libraries
  …        further lib* classes as needed
```

- Files are **plain Uniface XML exports** — diffable, git-friendly, **one object per
  file** (so SCM history/permissions are per object).
- This **supersedes** the older flat `components/` + `src/` convention from
  [§1.5 onboarding](uniface-10-onboarding.md). Those folders stay as-is for now;
  **folding them into `workarea/` is a tracked follow-up migration**, not done this
  pass.
- See [workarea/README.md](../workarea/README.md) for the on-disk contract.

## 4. How we emulate it now (WAS-ready)

We reproduce the **WAS shape** with the export/import facility already wrapped by
[/uniface-export](../.claude/commands/uniface-export.md) and
[/uniface-import](../.claude/commands/uniface-import.md):

| WAS concept | Our emulation (increment 1) |
| --- | --- |
| WorkArea folder | committed `workarea/` tree (per-object XML, class subfolders) |
| `WASListener.exe` watch loop | **manual / explicit** `/uniface-workarea-sync` invocation (no live watcher yet) ⚠️ |
| ADDED/MODIFIED → import | `pull`: `$ude("import")` / `ide.exe /imp <file>` per changed file |
| REMOVED → delete | flagged in `status`; **deletion is deferred** (not auto-done this pass) |
| push (Export All / per-object) | `push`: export repo objects → `workarea/` (IDE / `$ude("export")` — **no CLI export switch**) |
| `oprStatus==2` "dirty" guard | `status` warns before any import; **dry-run by default**, explicit confirm to write |
| Accept / revert | **deferred** — designed here, built next pass |

**Key constraints carried from the existing rules:**
- Everything round-trips through **Export/Import XML** — **never `/cpy`** for
  definitions (corruption risk). ✅
- There is **no command-line export** — `push` uses the IDE or a `$ude("export")`
  snippet; only **import** has a CLI switch (`/imp`, exit 0/1). ✅
- Resolve all paths from **`usys.ini [install]`**; quote spaced tokens.

### What changes when real WAS is installed later
Drop in `VersionControl.uar` + `WASListener.exe`, point `WAS_ROOT_FOLDER` at
`workarea/`, and the live watcher + plugin take over the replay/dirty-guard/accept-
revert that we currently do explicitly. Because our layout is WAS-shaped, the WorkArea
files don't change. ⚠️ (CE bundling of WAS unconfirmed — likely self-build/download.)

## 5. Designed-but-deferred (next approved pass)
- **Live sync** (a watcher, or a `pull`/`push` that actually performs per-file
  import/delete end-to-end) — this increment ships a **dry-run-by-default skeleton**.
- **Dirty/orphan guard + accept/revert** beyond a `status` warning.
- A **safety hook** (block `/cpy` on definitions; warn before destructive replay)
  alongside [check-quoted-paths.ps1](../.claude/hooks/check-quoted-paths.ps1).
- A **`uniface-workarea` subagent** for multi-step sync/review.
- **Migration** of `components/` + `src/` into `workarea/`.
- **Open questions** to resolve from gated docs / local install: WAS in CE?; the full
  `VC`/`GETWASFOLDER` `oprStatus` contract; whether the plugin calls `$ude` vs a
  lower-level API; branch/merge/conflict policy; exact `WAS_ROOT_FOLDER` asn wiring.

## References
- See **§3 / §4 / §5** above for sources; full mechanics in
  [worklog/012](../worklog/012-workarea-introduction.md).
- Related rules: [uniface-repository-source-of-truth](../.claude/rules/uniface-repository-source-of-truth.md),
  [uniface-cli-and-build-hygiene](../.claude/rules/uniface-cli-and-build-hygiene.md),
  [quote-paths-with-spaces](../.claude/rules/quote-paths-with-spaces.md).
