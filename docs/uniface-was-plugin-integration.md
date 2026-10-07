# Integrating the real WorkArea (WAS) IDE plugin

**Status:** integration guide for replacing our manual WorkArea emulation with the real
Uniface **Work Area Support (WAS)** tooling. Confidence: ✅ verified from the cloned
source · 📘 community/forum · ⚠️ to confirm at execution.
**Primary sources (verified 2026-06-30):**
- Repo: <https://github.com/uniface/WASListener> (branch **`master_10.4`**, latest
  release **10.4.02**). Cloned locally for reference at
  `C:\Users\Bob\source\uniface\WASListener` (sibling of this repo, **not** committed here).
- Prebuilt binary + config: Rocket forum **"Utilities, Addons and Extras"** →
  [Work Area Support Utility](https://community.rocketsoftware.com/viewdocument/work-area-support-utility)
  (community login; route through the operator — Claude can't auth).

This is the productized version of the file↔repository round-trip we currently emulate by
hand in [/uniface-workarea-sync](../.claude/commands/uniface-workarea-sync.md). Design
context: [uniface-workarea.md](uniface-workarea.md).

---

## 0. ⚠️ License — read first

The repo `LICENSE` is **Copyright © 2019 Uniface B.V.**, **not MIT**. It explicitly
**bars commercial use**:

> *"Licensee shall not be entitled to use the Software and the results of use of the
> Software ('Results') for any commercial or illegal purposes."* (as-is, no warranty,
> aggregate liability ≤ €1000.)

- **Personal skill-refresh / learning on this machine** — within terms. ✅
- **Client / commercial delivery** — do **not** rely on this sample. Verify acceptable
  use with Rocket, or use the **commercial UD6** (March Hare) path for client work.

The client you saw using a WorkArea-integrated IDE may be on **UD6** (commercial-licensed)
rather than this sample — worth confirming before assuming the same tool transfers.

## 1. What WAS is (two parts)

| Part | Source | Role |
| --- | --- | --- |
| **IDE plugin** (`VERSIONCONTROL` project → `VersionControl.uar`) | `WASListener/IdePlugin/` | Adds burger-menu actions; imports/deletes one object at a time; tracks per-object change state ("dirty" guard, accept/revert). The `VC_MAIN` component is the engine. |
| **Listener** (`WASListener.exe`) | `WASListener/listener/` | Native Win32 watcher that detects file changes in the WorkArea (e.g. a `git checkout`) and drives the plugin to replay them. **Optional** — the plugin works manually without it. |

**Slow-learning path:** integrate the **plugin first** (manual menu-driven sync against
our `workarea/`), defer the native listener (live watch) to a later stage.

## 2. The three integration knobs (verified from source)

1. **Load the plugin resources** — add the compiled VERSIONCONTROL `resources`/`.uar` to
   the IDE asn **`[RESOURCES]`**. It carries **no dictionary-table descriptors**, so it
   may go **anywhere** in the list (this corrects the earlier "before standard UARs"
   note). ✅ ([IdePlugin/readme.md](C:/Users/Bob/source/uniface/WASListener/IdePlugin/readme.md))
2. **Enable the menu** — set **`IDE_DEFINE_USERMENUS=VC_UPDATED`** in `[LOGICALS]`. That
   surfaces the burger-menu actions **"WorkArea Export/Revert"** and **"Import WorkArea"**
   (verified in [vc_updated.xml:202-203](C:/Users/Bob/source/uniface/WASListener/IdePlugin/WorkArea/cpt/vc_updated.xml#L202)).
3. **Point the WorkArea at *our* tree** — set the logical **`WAS_ROOT_FOLDER`** to this
   repo's `workarea/`. `VC_MAIN.getWASFolder` reads it and defaults to **`.\WorkArea`** if
   unset (verified [vc_main.xml:182](C:/Users/Bob/source/uniface/WASListener/IdePlugin/WorkArea/cpt/vc_main.xml#L182),
   `#define OBJECT_LOCATION_ROOT .\WorkArea` in
   [vc.xml:89](C:/Users/Bob/source/uniface/WASListener/IdePlugin/WorkArea/libinc/vc.xml#L89)).
   Example: `WAS_ROOT_FOLDER = C:\Users\Bob\source\uniface\ke-uf104\workarea`.

Our `workarea/` already uses the plugin's exact class-subfolder layout
(`aps/ cpt/ ent/ prj/ libinc/ libprc/ libsnp/ …`), so no restructuring is needed. ✅

## 3. Getting `VersionControl.uar` — two options

### Option A — Prebuilt (recommended first) 📘
Download the prebuilt `VersionControl.uar` from the forum's **Work Area Support Utility**
attachment (operator does this — login-gated). Drop it somewhere stable (e.g.
`C:\ref\was\VersionControl.uar`), then do §4 wiring. Lowest friction.

### Option B — Build from source in the IDE ✅ (good learning, exercises import/compile)
Per [IdePlugin/readme.md](C:/Users/Bob/source/uniface/WASListener/IdePlugin/readme.md),
in an **isolated sandbox** (its own repository, separate from `MYPROJECT`):
1. Dev shortcut — quote spaced paths:
   `"C:\ref\common\bin\ide.exe" /dir="C:\Users\Bob\source\uniface\WASListener\IdePlugin" "/adm=C:\ref\uniface\adm" ?`
   (The plugin folder ships its own `ide.asn` that chains the install's via
   `#file usysadm:ide.asn`, and its own `dbms/` so the build repository is separate.)
2. **Import all sources** under `IdePlugin\WorkArea\` (≈160 objects: `VC_MAIN`, `VC_UDO`,
   `VC_UPDATED`, the `vc_*` components and the `*.dict`/`*.model` meta-entities).
3. Open the **`VERSIONCONTROL`** project → **Compile** → produces `IdePlugin\resources`.
4. To clear the "all new" state: uncomment `IDE_DEFINE_USERMENUS=VC_UPDATED` in the
   plugin's `ide.asn`, start the IDE, burger menu → **"WorkArea Export/Revert"** →
   **"Export All"**.

> Verified `WorkArea` source layout, `getWASFolder`, and menu wiring from the clone.

## 4. Wiring it into *your* app IDE session (after §3)

Prefer an **isolated, project-local asn that chains the install's** (don't pollute the
shared `C:\ref\uniface\adm\ide.asn` that every project uses). Shape — mirrors the plugin's
own asn:

```
[RESOURCES]
C:\ref\was\resources            ; or the path to VersionControl.uar / its resources

#file usysadm:ide.asn           ; chain the standard IDE resources + settings

[LOGICALS]
IDE_DEFINE_USERMENUS = VC_UPDATED
WAS_ROOT_FOLDER      = C:\Users\Bob\source\uniface\ke-uf104\workarea
```

Launch the IDE with that asn (extend [/uniface-launch-ide](../.claude/commands/uniface-launch-ide.md)
with a `--was` variant once chosen). ⚠️ Confirm the exact asn-selection mechanism for this
install at execution (working-dir `ide.asn` vs `/adm` precedence).

Then the manual flow is: **Import WorkArea** (replay files → repository) and **WorkArea
Export/Revert** (your IDE change → file, or revert to file) — the real versions of our
`/uniface-workarea-sync` `pull`/`push`.

## 5. Stage 2 (deferred) — the native listener

For live folder-watching (auto-replay on `git checkout`): build `WASListener.exe` from
`WASListener/listener/` — **CMake + vcpkg + Visual Studio**, linking the Uniface 3GL C
API. For **this** install set `UNIFACE_3GL_FOLDER="C:\ref\uniface\3gl"` (the readme's
default `C:\Program Files\Uniface\…` does **not** apply here). ✅ Heavy toolchain — defer
until the manual plugin flow is comfortable. Run-time args (`-a adm -i ini -f asn -p
project`) and the `.WASListener.lock` single-instance behavior: ⚠️ confirm from the forum
config doc / listener source before first run.

## 6. How this supersedes our emulation

| Our emulation (increments 1) | Real WAS (this guide) |
| --- | --- |
| `/uniface-workarea-sync push` (manual IDE export → `workarea/`) | **WorkArea Export/Revert → Export All** |
| `/uniface-workarea-sync pull` (manual `/imp`) | **Import WorkArea** (per-object replay + dirty guard) |
| Dry-run/status only; no live watch | Plugin tracks per-object state; listener adds live watch (Stage 2) |
| `workarea/` layout (WAS-compatible) | **unchanged** — `WAS_ROOT_FOLDER` points here |

Keep the [uniface-workarea-sync](../.claude/rules/uniface-workarea-sync.md) hygiene
(repository is master of record; never `/cpy`; dry-run mindset) — the plugin enforces the
dirty/orphan guard for real.

## References
- Cloned source: `C:\Users\Bob\source\uniface\WASListener\` (IdePlugin, listener, readmes).
- [uniface-workarea.md](uniface-workarea.md) (design), [worklog/021](../worklog/021-was-plugin-discovery-integration.md)
  (discovery), [worklog/018](../worklog/018-workarea-first-push-helloworld.md) (first push).
- Related rules: [uniface-workarea-sync](../.claude/rules/uniface-workarea-sync.md),
  [uniface-repository-source-of-truth](../.claude/rules/uniface-repository-source-of-truth.md),
  [protect-secrets-and-proprietary](../.claude/rules/protect-secrets-and-proprietary.md)
  (license/proprietary), [quote-paths-with-spaces](../.claude/rules/quote-paths-with-spaces.md).
