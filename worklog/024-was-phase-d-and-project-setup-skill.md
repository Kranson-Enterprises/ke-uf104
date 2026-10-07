# 024 WAS Phase D (baseline cleared) + a one-time project-setup skill

**Date:** 2026-07-01
**Sequence:** … → 021 (WAS plugin discovery) → 022 (VERSIONCONTROL build, Phases A–C) →
023 (UAR packaging methodology + hardening) →
**024 (Phase D done → Stage-1 complete; skill authored for Stage-2 wiring)**.
**Purpose:** Close out **Stage 1** of the WAS WorkArea plugin integration (the plugin is
built *and* its WorkArea baseline is clean), capture one non-obvious decision surfaced by
the operator (whether CPT **signatures** belong in the WorkArea tree), and record why the
Stage-2 wiring was turned into a reusable **`was-project-setup` skill** rather than an
ad-hoc procedure.
Confidence: ✅ Executed on this install; ⚠️ the GitHub-download acquisition path in the
skill is written defensively (asset existence is checked at run time, not assumed).

---

## 1. Phase D — clearing the "all new" state

After Phases A–C (sandbox repo, 178 objects imported, Compile All) and the Method-A UAR
build (worklog 023), the sandbox repo's WorkArea status showed **every object as new** —
expected, because a freshly-imported repo has no WorkArea baseline yet.

Steps taken:
1. Closed the sandbox IDE (releases the repo lock; the asn is read only at startup).
2. Uncommented `IDE_DEFINE_USERMENUS=VC_UPDATED` in the sandbox
   `IdePlugin\ide.asn` `[LOGICALS]`.
3. Relaunched into the sandbox — clean session start (`10.4.03.042`), no asn parse error.
4. **Operator** drove the GUI (CEF is not UIA-scriptable): burger menu → **WorkArea
   Export** → **Export All**.

**Result:** all objects' per-object **Export**/**Revert** buttons **dimmed** — i.e. no
pending WorkArea delta; the "all new" baseline is cleared. The form reports **no count**
(normal for this plugin). The WorkArea tree was rewritten at 12:04:32 (cpt 48, ent 102,
aps 4, prj 7, lib* 21).

### Doc correction
The menu item is a single **"WorkArea Export"**, not the "WorkArea Export/Revert" submenu
our command docs had guessed. Fixed in
[/was-build](../.claude/commands/was-build.md) Phase D (commit `1be943f`).

## 2. Decision: CPT signatures are **excluded** from WorkArea sync

The Export form offered to include **Uniface CPT signatures**; the operator left them out
and asked whether that was right. It was — and the reasoning is worth pinning:

- A component **signature (`.sig`) is *derived* compile output**, regenerated from the
  `.cpt` on every `/all`. It already lives in the compiled resources / the `.uar` `sig/`
  subdir (24 entries in `VersionControl.uar`).
- The WorkArea tree serializes **source development objects only** — its layout is
  `aps/ cpt/ ent/ lib*/ prj/`, with **no `sig/` folder**. Putting signatures there would
  version-control generated output (churn on every recompile, duplication of the `.uar`),
  contradicting *repository-is-source-of-truth*.
- **When you *would* tick it:** cross-repository distribution — handing another team the
  signatures so they can compile a component that *calls* these without having the source.
  That's a packaging/distribution concern, not version control, and N/A here where all 182
  source objects live in the one sandbox.

Recorded in [/was-build](../.claude/commands/was-build.md) Phase D and the project memory.

## 3. Stage-1 status (complete)

| Phase | Result |
| --- | --- |
| A | Sandbox repo created (`IdePlugin\dbms\usys.db`) |
| B | 178 source objects batch-imported, all exit 0 (`/uniface-import-batch`) |
| C | Compile All → 70 loose `resources\` |
| UAR | `VersionControl.uar` (~141 KB, 25/25 components) via compile-to-UAR |
| **D** | **WorkArea baseline cleared** (signatures excluded) |

## 4. Why a skill for Stage 2 (not just a command)

Stage 2 — wiring `VersionControl.uar` into **MYPROJECT** — is a **one-time, stateful,
branching** procedure: choose how to acquire the UAR, back up config, apply reversible
settings, verify a GUI menu. That shape fits a **skill** better than a one-shot slash
command, so this repo gains its first
[.claude/skills/](../.claude/skills/) entry: **`was-project-setup`**.

What it encodes (so the wiring is repeatable and safe on a fresh machine):
- **Acquisition choice** (AskUserQuestion): *download the prebuilt GitHub UAR* vs *build
  locally* ([/was-build](../.claude/commands/was-build.md) → [/was-package](../.claude/commands/was-package.md))
  vs *reuse the existing local build*. The download path **checks that the asset actually
  exists** (`gh release list` / repo contents) and **falls back to a local build** if the
  plugin only ships as source — no invented pinned URL.
- **Backup-before-change**: the only file touched is a **project-local `ide.asn`** in the
  MYPROJECT workdir, chaining the install's via `#file usysadm:ide.asn`; a `.bak` is taken
  and a **revert** section restores the pre-setup state. `usys.ini` and the shared install
  asn under `C:\ref` are never edited.
- **The three settings**: `[RESOURCES]` → the UAR, `[LOGICALS] IDE_DEFINE_USERMENUS=VC_UPDATED`
  (the WorkArea Export menu), `WAS_ROOT_FOLDER = …\ke-uf104\workarea` (this repo's tracked
  tree). Baked-in asn gotcha: **own-line comments only** — `[SETTINGS]`/`[RESOURCES]` don't
  strip trailing `;` comments (worklog 023).
- **Guardrails carried over**: the non-commercial **license gate** (skill-refresh only,
  stop on a client repo), the **GUI-subsystem exit-code trap** for `ide.exe`, don't copy
  the derived/non-commercial UAR into the tracked tree (reference by path or stage in
  gitignored `scratch/`), and the **dry-run/never-`/cpy`** WorkArea hygiene.

New: [.claude/skills/was-project-setup/SKILL.md](../.claude/skills/was-project-setup/SKILL.md),
[.claude/skills/README.md](../.claude/skills/README.md) (documents the skills/ convention:
skills = multi-step procedures; commands = one-shot; agents = delegated work).

## 5. Next

Run **`was-project-setup`** to execute Stage 2 against MYPROJECT, then exercise **Import
WorkArea** / **WorkArea Export** on the real [workarea/](../workarea/) tree — the live
replacement for the [/uniface-workarea-sync](../.claude/commands/uniface-workarea-sync.md)
emulation. Native `WASListener.exe` (live file watcher) remains deferred (needs
CMake/vcpkg/VS + `UNIFACE_3GL_FOLDER=C:\ref\uniface\3gl`).
