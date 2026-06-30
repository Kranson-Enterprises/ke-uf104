# 021 WorkArea (WAS) IDE plugin — discovery, license correction, integration plan

**Date:** 2026-06-30
**Sequence:** … → 018 (first WorkArea push) → 019 (export staging) → 020 (byte-faithful
XML) → **021 (real WAS plugin discovery + integration plan)**.
**Purpose:** The client's IDE had the WorkArea integrated (the WAS plugin). Discover the
real tooling, document accurate integration steps for **this** install, and surface a
material license finding — so we can move from our manual emulation to the real plugin,
slowly.
Confidence: ✅ verified from the cloned repo source; 📘 forum for prebuilt/config.

---

## 1. What it is (confirmed)

Rocket/Uniface **Work Area Support (WAS)** = `github.com/uniface/WASListener` (branch
`master_10.4`, latest release 10.4.02, July 2022). Two parts:
- **IDE plugin** — `IdePlugin/`, project **`VERSIONCONTROL`** → `VersionControl.uar`;
  engine component **`VC_MAIN`**; ~160 source objects. Adds burger-menu **"WorkArea
  Export/Revert"** + **"Import WorkArea"**, per-object import/delete, dirty/orphan guard.
- **Listener** — `listener/`, native `WASListener.exe` (CMake + vcpkg + VS, links the
  Uniface 3GL C API); watches the WorkArea folder for live replay. Optional.

Cloned for reference at `C:\Users\Bob\source\uniface\WASListener` (sibling, **not** part
of this repo). The unrelated `uniface/plugin-samples` repo (WS_LISTING/CHECKSTYLE/
STATISTICS worksheet plugins) does **not** contain version control — ruled out.

## 2. ⚠️ Material finding — the license is NOT MIT

The repo `LICENSE` is **Copyright © 2019 Uniface B.V.** and **bars commercial use**:
*"Licensee shall not be entitled to use the Software and the results of use of the
Software ('Results') for any commercial or illegal purposes."* (as-is; liability ≤ €1000).

- [worklog/012](012-workarea-introduction.md) and the design doc called WAS
  "**MIT-licensed**." **That was wrong** — corrected in
  [docs/uniface-workarea.md §2](../docs/uniface-workarea.md) (012 left as-is per the
  no-rewrite-history convention; this worklog is the dated correction).
- **Impact:** fine for the operator's **personal skill-refresh**; **not** for
  **client/commercial delivery**. For client work, verify terms with Rocket or use the
  commercial **UD6** (March Hare). The client's integrated WorkArea may well be **UD6**,
  not this sample — confirm before assuming it transfers. Ties to
  [protect-secrets-and-proprietary](../.claude/rules/protect-secrets-and-proprietary.md).

## 3. Integration knobs (verified from source, adapted to this install)

1. **`[RESOURCES]`** — add the compiled VERSIONCONTROL resources; **anywhere** in the
   list (no dictionary descriptors — corrects the earlier "before standard UARs" note).
2. **`[LOGICALS] IDE_DEFINE_USERMENUS=VC_UPDATED`** — surfaces the menu
   ([vc_updated.xml:202](C:/Users/Bob/source/uniface/WASListener/IdePlugin/WorkArea/cpt/vc_updated.xml#L202)).
3. **`[LOGICALS] WAS_ROOT_FOLDER`** → `…\ke-uf104\workarea` — `VC_MAIN.getWASFolder`
   reads it (default `.\WorkArea`), [vc_main.xml:182](C:/Users/Bob/source/uniface/WASListener/IdePlugin/WorkArea/cpt/vc_main.xml#L182).
   Our `workarea/` already matches the plugin's class-subfolder layout. ✅

This-install specifics: ide.exe `C:\ref\common\bin\ide.exe`; adm `C:\ref\uniface\adm`;
3GL `C:\ref\uniface\3gl` (the listener readme's `C:\Program Files\Uniface\…` default does
**not** apply here).

## 4. Plan (slow, staged) — full guide in [docs/uniface-was-plugin-integration.md](../docs/uniface-was-plugin-integration.md)

- **Stage 0 (this worklog):** discover + document + license flag. ✅ no install change.
- **Stage 1 — plugin, manual:** obtain `VersionControl.uar` — **(A) prebuilt** from the
  forum (gated; operator) or **(B) build from source** in an isolated IDE sandbox (import
  `IdePlugin\WorkArea`, compile `VERSIONCONTROL`, Export All). Then wire a **project-local
  asn** that chains the install's, with the three knobs above, and use **Import WorkArea**
  / **Export All** against `workarea/`. Don't edit the shared `C:\ref` ide.asn.
- **Stage 2 — listener (deferred):** build `WASListener.exe` (CMake/vcpkg/VS,
  `UNIFACE_3GL_FOLDER=C:\ref\uniface\3gl`) for live folder-watch.

## 5. Open / to confirm at execution
- Exact asn-selection for this install (working-dir `ide.asn` vs `/adm` precedence).
- Listener run args (`-a -i -f -p`) + `.WASListener.lock` — from forum config / source.
- The commercial-use decision for any client engagement (Stage 1 gate).

## References
- Repo: <https://github.com/uniface/WASListener>; forum **Work Area Support Utility**
  (prebuilt + config). Clone: `C:\Users\Bob\source\uniface\WASListener\`.
- [docs/uniface-was-plugin-integration.md](../docs/uniface-was-plugin-integration.md),
  [docs/uniface-workarea.md](../docs/uniface-workarea.md),
  [worklog/012](012-workarea-introduction.md).
