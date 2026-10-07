# 022 Building the VERSIONCONTROL plugin from the sibling WASListener repo — a build-a-tool-in-a-sandbox workflow

**Date:** 2026-07-01
**Sequence:** … → 020 (byte-faithful XML) → 021 (WAS plugin discovery + integration plan) →
**022 (VERSIONCONTROL plugin build — Phases A–C executed)**.
**Purpose:** Capture the *unique* shape of this task — we are not developing our own app
here; we are **compiling someone else's tool (the WAS IDE plugin) from source in a
throwaway sandbox repository**, to produce an artifact we later install into our app. This
worklog records the mechanics, the things that behaved differently from ordinary
component work, and the IDE UX gaps worth reporting to the product team.
Confidence: ✅ executed and file-verified this session · ⚠️ = open / to confirm.

---

## 1. What makes this build unusual

Normal work in this workspace edits **our** objects in **our** repository and round-trips
them to `workarea/`. This task is different in three ways, and conflating them is exactly
what caused confusion mid-session:

1. **`C:\Users\Bob\source\uniface\WASListener` (sibling clone) is *a tool's source code*,
   not a workspace.** It is never added to the VSCode workspace and never developed in. It
   exists only to be compiled once. (Ties to
   [uniface-repository-source-of-truth](../.claude/rules/uniface-repository-source-of-truth.md):
   the objects are the truth; the clone's XML is just the serialization we import.)
2. **`IdePlugin\` is a throwaway *build sandbox* — its own Uniface repository**, entirely
   separate from MYPROJECT. Isolation is structural: the chained `dbms.asn` resolves the
   repo as the **working-dir-relative** `.\dbms\usys.db`, so launching with
   `/dir=…\IdePlugin` builds into `IdePlugin\dbms\`, never touching `ke-uf104`'s repo.
   The **VERSIONCONTROL** project lives *here*, not in our app.
3. **The deliverable is an artifact (the compiled `resources` / a future `.uar`), not a
   running application.** We build it here, then (Stage 2) load it into *our app's* IDE
   session so its burger menu gains WorkArea Import/Export against our `workarea/`.

Pipeline in one line: **build the plugin in sandbox (#2) from tool source (#1) → install
the artifact into our app (#3).** This worklog covers building #2 through compile.

## 2. What we did (Phases A–C)

Staged plan is in [docs/uniface-was-plugin-integration.md](../docs/uniface-was-plugin-integration.md)
and [worklog/021](021-was-plugin-discovery-integration.md). Executed today:

- **Phase A — create + migrate the sandbox repo.** Launched via the new
  **`/uniface-launch-ide --was`** mode. The IDE created `IdePlugin\dbms\usys.db` (~1.41 MB)
  on first start. No manual migration prompt was needed — a freshly created CE repo is
  already current.
- **Phase B — batch-import the plugin source (178 XML objects).** CLI `/imp`, one gated
  call per class, in dependency order
  **ent → libinc → libprc → libsnp → libein → libfla → libfsy → cpt → aps → prj**. Every
  class returned **exit 0**; repo grew **1.41 MB → 2.46 MB**. Automated with the new
  **`/uniface-import-batch`** command.
- **Phase C — open the project and Compile All.** Opened **VERSIONCONTROL** via the U-Bar
  (see §4), ran Compile All. Output landed in `IdePlugin\resources\` (§3).

## 3. What "Compile All" actually produced (and what it did *not*)

Compile wrote **loose compiled objects into `resources\`** plus a listings/cmi archive —
**it did not produce a `.uar`.** Verified on disk:

| Folder | Count | Contents |
| --- | --- | --- |
| `resources\svc` | 21 | service components `vc_aps`…`vc_sig` (one per object class) |
| `resources\frm` | 3 | forms `vc_main` (engine), `vc_specs`, `vc_updated` (the menu form) |
| `resources\sig` | 25 | component signatures |
| `resources\edc` | 22 | entity descriptors `vc_uappl@vc`…`vc_uproject@vc`, `vc_updated@vc_views` |
| `development.zip` | — | listings + `.cmi` (per the sandbox `ide.asn` `[FILES]` mapping) |

Total 70 files (~350 KB). **No `.uar` in the sandbox** — confirming that *compile* and
*UAR packaging* are distinct steps in Uniface 10. Building the deployable `.uar` from the
`VERSIONCONTROL` project is the **next question to work** (§6). Note the readme's point
that this project compiles **no dictionary-table descriptors**, which is why the resulting
resources/`.uar` may be placed **anywhere** in an `[RESOURCES]` list.

## 4. IDE behaviour differences observed (candidates to report to the product team)

- **No Projects browser in the burger (hamburger) menu.** There was **no project list**
  offered anywhere in the ≡ menu, so a freshly-imported project is not discoverable by
  browsing. The only way in was the **U-Bar with the `prj:` prefix** — typing
  **`prj:VERSIONCONTROL`** located and opened it. (A bare `VERSIONCONTROL` in the U-Bar was
  not sufficient in this session; the class prefix was required.) ⚠️ **Report:** a
  discoverable "Projects" entry / recent-projects list in the burger menu would remove a
  real dead-end for anyone importing a project rather than creating it in-session.
- **IDE window model.** The IDE presents a single top-level window titled *"Uniface 10
  IDE"* (UI-automation enumeration showed one `ControlType.Window` for the process; the CEF
  render children carry no separate window titles). Worksheets/editors are hosted inside
  that one CEF shell rather than as separate OS windows.

## 5. Tooling added / fixed this session

- **`/uniface-launch-ide --was`** (new mode) — launches the IDE into the `IdePlugin\`
  sandbox with correct `/dir` + working dir so `.\dbms` and `.\resources` resolve there.
- **`/uniface-import-batch`** (new) — ordered, exit-code-gated batch `/imp` of a
  WorkArea-shaped class-subfolder tree. Reusable for any WorkArea sync.
- **Two traps found by executing, then fixed in the command suite:**
  1. **`ide.exe` is a GUI-subsystem exe.** PowerShell's `&` **does not wait** for it and
     leaves `$LASTEXITCODE` **blank**, so an exit-code gate silently never fires (this
     produced a *false failure* on the first Phase-B run). Fix: `Start-Process -Wait
     -PassThru` and read `.ExitCode`. cmd/`.bat` *does* block on GUI exes, so
     [build.bat](../scripts/build.bat)'s `%ERRORLEVEL%` gate was already correct — the trap
     is **PowerShell-only**. Corrected [/uniface-import](../.claude/commands/uniface-import.md)
     and [/uniface-compile](../.claude/commands/uniface-compile.md).
  2. **`/imp` path is relative to the working dir and must include the `WorkArea\`
     segment** (`WorkArea\<class>\*.xml`, not `<class>\*.xml`) — the missing prefix matched
     no files and returned exit 1.

## 6. Open items / next

- **⚠️ How the UAR is built from the IDE** — the immediate next question. Compile yields
  loose `resources`; the deployable **`VersionControl.uar`** must come from a separate
  **project package/deploy** step (the `VERSIONCONTROL` project defines `UUARNAME` /
  output fields). Determine whether it's a Project-editor action, a `$ude`/CLI step, or
  IDE-only — and where it writes.
- **Phase D** — uncomment `IDE_DEFINE_USERMENUS=VC_UPDATED` in the sandbox `ide.asn`,
  restart, and **WorkArea Export/Revert → Export All** to clear the "all new" state.
- **Stage 2** — wire the built artifact into MYPROJECT via a project-local asn (a future
  `/uniface-launch-ide --was-project` mode) pointing `WAS_ROOT_FOLDER` at our `workarea/`.
- **License gate stands** — WAS is **non-commercial only**; this whole exercise is personal
  skill-refresh, **not** for client delivery
  ([[reference-uniface-workarea-was]], [worklog/021 §2](021-was-plugin-discovery-integration.md)).

## References
- Plan/guide: [docs/uniface-was-plugin-integration.md](../docs/uniface-was-plugin-integration.md);
  discovery: [worklog/021](021-was-plugin-discovery-integration.md).
- Source clone: `C:\Users\Bob\source\uniface\WASListener\` (sibling, not committed here).
- Commands touched: [/uniface-launch-ide](../.claude/commands/uniface-launch-ide.md),
  [/uniface-import-batch](../.claude/commands/uniface-import-batch.md),
  [/uniface-import](../.claude/commands/uniface-import.md),
  [/uniface-compile](../.claude/commands/uniface-compile.md).
