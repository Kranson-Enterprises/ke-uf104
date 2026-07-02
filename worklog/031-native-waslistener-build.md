# 031 Native `WASListener.exe` built — toolchain installed, x64 Release green

**Date:** 2026-07-02
**Sequence:** … → 029 (change round-trip) → 030 (legacy-folder fold) →
**031 (built the deferred native `WASListener.exe` live watcher)**.
**Purpose:** Close the last deferred item of the WAS WorkArea plan — install the missing
C++ toolchain and build the native watcher from the sibling `WASListener` clone. This is the
live file-watcher that automates the WorkArea import/export the manual round-trip (027/029)
stood in for.
Confidence: ✅ Executed and verified on this install (build exit 0; exe links + starts).

⚠️ **License gate (unchanged):** WAS is **non-commercial** (© 2019 Uniface B.V.) — personal
skill-refresh only, never a client deliverable. The build lives in the sibling clone
`C:\Users\Bob\source\uniface\WASListener`, **not** in this repo.

---

## 1. Toolchain installed (was absent)

| Tool | Action | Result |
| --- | --- | --- |
| **CMake** | `winget install Kitware.CMake` | **4.3.4** on PATH (≥ 3.15 floor) |
| **VS 2022 Build Tools** | `winget install Microsoft.VisualStudio.2022.BuildTools` + `--override "--add Microsoft.VisualStudio.Workload.VCTools --includeRecommended"` | **MSVC 14.44.35207** + Win SDK; `VC.Tools.x86.x64` confirmed via `vswhere` |
| **vcpkg** | `git submodule update --init --recursive` → `bootstrap-vcpkg.bat` | vcpkg 2025-09-03; submodule `listener/vcpkg` @ `29ff5b8` |

winget was already present (v1.29); git 2.54. VS Build Tools installed non-interactively
(`--passive`, machine scope).

## 2. Build (x64 Release)

From `C:\Users\Bob\source\uniface\WASListener\listener` per `listener\readme.md`, with the
machine's **space-free** `UNIFACE_3GL_FOLDER=C:\ref\uniface\3gl` (not the readme's spaced
default):

```
cmake -DCMAKE_TOOLCHAIN_FILE="…\vcpkg\scripts\buildsystems\vcpkg.cmake" \
      -DVCPKG_TARGET_TRIPLET="x64-windows-static" \
      -DUNIFACE_3GL_FOLDER="C:\ref\uniface\3gl" -A x64 -B "build\x64"
cmake --build build\x64 --config Release
```

- **Configure** (exit 0, ~236 s): vcpkg built **Boost 1.85.0** (`program_options` + `thread`
  and their deps) for `x64-windows-static`; generator **Visual Studio 17 2022**; solution
  `WASListener.sln` generated.
- **Build** (exit 0): compiled `CommandLine / FileAction / FolderWatcher / Notifications /
  Uniface / WASListener` → **`build\x64\WASListener\Release\WASListener.exe`** (607 KB,
  2026-07-02 11:25).

## 3. Verification

- `dumpbin /dependents` → **`UCALL.dll`**, KERNEL32, USER32, SHELL32, COMCTL32. `UCALL.dll`
  is the Uniface 3GL call interface — proof it linked the Uniface 3gl correctly.
- Bare run first failed `0xC0000135` (DLL_NOT_FOUND) — **expected**: needs the Uniface runtime
  on PATH. With **`C:\ref\common\bin`** (home of `ucall.dll`) on PATH, it **starts and exits
  0**. So the watcher is runnable inside a Uniface environment.
- `--help` prints nothing here because `CCommandLine::_initConsole()` calls `AllocConsole()`
  (a no-op when already attached to a console); the option set was read from the source
  instead (§4).

## 4. How to run it (from `WASListener\CommandLine.cpp`)

boost-program-options flags:
- `-a, --uniface-adm-folder` — Uniface ADM folder (else auto-detected as `..\..\uniface\adm`
  **relative to the exe**, i.e. it expects to sit in a Uniface `bin`).
- `-i, --uniface-ini-file` — Uniface ini.
- `-f, --uniface-asn-file` — asn; **else it looks for `waslistener.asn`** in the project
  folder, then the adm folder. **This is where `WAS_ROOT_FOLDER` → `workarea/` gets wired**
  (same knob the plugin uses).
- `-p, --project-folder` — "Start In" working folder.
- `-h, --help`.

So a live run = place the exe where it can find the Uniface runtime + adm, give it a
`waslistener.asn` whose `WAS_ROOT_FOLDER` points at this repo's `workarea/`, and start it; it
uses `FolderWatcher` to watch that tree and drive import/export via the Uniface engine.

## 5. Not done here — the live run is a deliberate, guarded step

⚠️ The plugin/watcher **Import is destructive** — `Delete <object>` then `Import <object>`
for everything under `WAS_ROOT_FOLDER`, no preview (worklog 027). The native watcher automates
that path, so pointing it at the real `workarea/` + repository can **overwrite/delete
uncommitted repository work**. Per [uniface-workarea-sync](../.claude/rules/uniface-workarea-sync.md),
a live run is done **deliberately, with the repo committed/backed up first** — not as an
unattended step. Deferred as its own exercise (candidate: run against a throwaway repo copy or
with the tree known-good, then edit a file and observe the file→repository sync).

## 6. Outcome — WAS WorkArea plan complete

- Stage 1 (build `VersionControl.uar`), Stage 2 (wire into MYPROJECT + round-trip), the
  change round-trip (029), the legacy fold (030), and now the **native watcher build (031)**
  are all done. The only remaining WAS activity is the **guarded live-watcher run** (§5),
  which is optional and deliberately separate.

## Related

- [worklog/030](030-fold-legacy-components-src-into-workarea.md),
  [worklog/029](029-workarea-change-roundtrip-delta.md),
  [worklog/027](027-workarea-first-roundtrip-helloworld.md) (destructive Import),
  [worklog/028](028-was-integration-day-summary.md) (integration day).
- Build doc: `WASListener\listener\readme.md`; memory
  [project-was-native-listener-build-prereqs](../.claude/memory/project-was-native-listener-build-prereqs.md),
  [project-was-plugin-integration-status](../.claude/memory/project-was-plugin-integration-status.md).
- Rule: [uniface-workarea-sync](../.claude/rules/uniface-workarea-sync.md).
