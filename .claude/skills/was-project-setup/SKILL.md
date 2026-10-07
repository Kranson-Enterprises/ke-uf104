---
name: was-project-setup
description: >-
  One-time setup to enable the WAS WorkArea IDE plugin against MYPROJECT (this
  ke-uf104 repo). Use when the operator wants "WorkArea integration in my project
  IDE", to "wire in VersionControl.uar", or to "turn on the WorkArea Export/Import
  menu" for this repo's workarea/ tree. It asks how to acquire the plugin UAR
  (download the prebuilt GitHub artifact OR build+compile locally), backs up the
  config it touches, then writes the project-local asn settings (RESOURCES +
  IDE_DEFINE_USERMENUS=VC_UPDATED + WAS_ROOT_FOLDER) and verifies the menu loads.
  Non-commercial / skill-refresh only — never a client deliverable.
allowed-tools: Read, Edit, Write, PowerShell, Bash, AskUserQuestion
---

# WAS-project setup (enable the WorkArea plugin on MYPROJECT)

**Goal.** Turn the built **VersionControl** plugin (`VersionControl.uar`) into a live
feature of **MYPROJECT's** IDE, pointed at this repo's tracked
[workarea/](../../../workarea/) tree — so **Import WorkArea** / **WorkArea Export**
replace the manual [/uniface-workarea-sync](../../commands/uniface-workarea-sync.md)
emulation. This is a **one-time** wiring step (Stage 2 of the WAS integration; Stage 1 =
building the UAR, see [/was-build](../../commands/was-build.md)).

> ⚠️ **License gate — read first.** WAS is **non-commercial** (Copyright © 2019 Uniface
> B.V., furnished under license). This setup is for **personal skill-refresh only** and
> must **never** be applied to a client/commercial deliverable. If the target repo is a
> client project, **stop and say so.** See
> [worklog/021](../../../worklog/021-was-plugin-discovery-integration.md) §2 and
> [protect-secrets-and-proprietary](../../rules/protect-secrets-and-proprietary.md).

## Fixed facts for this install (verify, don't assume on another machine)

- exe `C:\ref\common\bin\ide.exe` · adm `C:\ref\uniface\adm` · install root `C:\ref`.
- **MYPROJECT working dir** = `usys.ini [install] project=` — on this machine
  `C:\Users\Bob\source\uniface\ke-uf104\uniface\project` (runtime, gitignored).
- **WorkArea tree** = `C:\Users\Bob\source\uniface\ke-uf104\workarea` (tracked; this is
  what `WAS_ROOT_FOLDER` points at).
- **Sibling plugin build** = `C:\Users\Bob\source\uniface\WASListener\IdePlugin\VersionControl.uar`.
- Always resolve these from `usys.ini [install]` rather than hardcoding; **quote spaced
  paths** as whole tokens ([quote-paths-with-spaces](../../rules/quote-paths-with-spaces.md)).

## Step 0 — preflight & idempotency

1. Confirm the target is **this skill-refresh repo**, not a client project (license gate).
2. Read `C:\ref\uniface\adm\usys.ini` `[install]` → resolve `project=` (MYPROJECT workdir)
   and note ports. Confirm exe + adm exist.
3. **Already wired?** If the MYPROJECT workdir already has a project asn containing
   `IDE_DEFINE_USERMENUS=VC_UPDATED` and a `WAS_ROOT_FOLDER`, report it and **skip to
   Step 4 (verify)** — don't double-apply.

## Step 1 — ask how to acquire the plugin UAR

Use **AskUserQuestion** (header "Plugin UAR"):

- **Download prebuilt (GitHub)** — fetch the released `VersionControl.uar` from the
  `uniface/WASListener` repo. *Fast; no local compile.*
- **Build locally** — run the full Stage-1 flow ([/was-build](../../commands/was-build.md)
  → [/was-package](../../commands/was-package.md)) to compile a fresh UAR from source.
  *Most learning; already done once on this machine.*
- **Use existing local build** — reuse
  `WASListener\IdePlugin\VersionControl.uar` if it's present and current. *Offer this as
  the default when that file already exists.*

### If "Download prebuilt (GitHub)"
- Locate the artifact honestly — **do not invent a pinned URL.** Check, in order:
  ```powershell
  gh release list  --repo uniface/WASListener   # released assets?
  gh api repos/uniface/WASListener/contents --jq '.[].name'  # in-tree UAR?
  ```
- If a `VersionControl.uar` asset/blob exists, download it to the gitignored project
  **`scratch/`** (never the Claude scratchpad, never `C:\temp` —
  [uniface-export-staging](../../rules/uniface-export-staging.md)):
  `gh release download <tag> --repo uniface/WASListener --pattern "*.uar" --dir scratch`.
- **If no prebuilt asset exists**, tell the operator and fall back to **Build locally**.
  (The plugin ships as source; a prebuilt UAR is not guaranteed to be published.)

### If "Build locally"
- Delegate to **[/was-build](../../commands/was-build.md)** (Phases A–C) then
  **[/was-package](../../commands/was-package.md)** (Method A compile-to-UAR, auto asn
  revert). Result: `WASListener\IdePlugin\VersionControl.uar`.

### Resolve `$UAR` (all paths)
Set `$UAR` to the chosen file's **absolute** path and verify it's a real archive with the
type-subdirs before wiring (zip-listing snippet in
[/uniface-package-uar](../../commands/uniface-package-uar.md)): expect `svc/ frm/ sig/
edc/` and a non-trivial entry count. **Do not copy the UAR into the tracked tree** — it's
a derived, non-commercial artifact; reference it by absolute path (or stage in gitignored
`scratch/`).

## Step 2 — back up the config you're about to change

The only file this setup writes is a **project-local asn** in the MYPROJECT workdir.
Before touching it:

```powershell
$proj = '<resolved MYPROJECT workdir>'
$asn  = Join-Path $proj 'ide.asn'
if (Test-Path $asn) { Copy-Item $asn "$asn.bak" -Force }   # timestamp/keep the .bak
```
- If **no** `ide.asn` exists in the workdir, you'll create one that **chains** the
  install's via `#file usysadm:ide.asn` (so nothing already configured is lost).
- Never edit `usys.ini` or the install's shared asn under `C:\ref` — keep changes
  **project-local and reversible**.

## Step 3 — apply the WorkArea settings (asn gotchas apply)

Write/patch the MYPROJECT workdir `ide.asn` to add exactly three things. **Comments on
their own line only** — `[SETTINGS]`/`[RESOURCES]` do **not** strip trailing `;` inline
comments (they get swallowed into the value → "Cannot create directory"; see
[uniface-uar-packaging-and-hardening](../../rules/uniface-uar-packaging-and-hardening.md)).
Keep values clean ASCII; quote nothing that has no space, quote whole tokens that do.

```asn
#file usysadm:ide.asn

[RESOURCES]
C:\Users\Bob\source\uniface\WASListener\IdePlugin\VersionControl.uar

[LOGICALS]
IDE_DEFINE_USERMENUS=VC_UPDATED
WAS_ROOT_FOLDER=C:\Users\Bob\source\uniface\ke-uf104\workarea
```
- `[RESOURCES]` → `$UAR` makes the compiled plugin objects available to MYPROJECT's IDE.
- `IDE_DEFINE_USERMENUS=VC_UPDATED` adds the **WorkArea Export** burger-menu item (single
  item, not an "Export/Revert" submenu — verified in Phase D).
- `WAS_ROOT_FOLDER` points the plugin at **this repo's tracked `workarea/`**, so Export
  writes there and Import reads from there.
- Preserve any existing `[RESOURCES]`/`[LOGICALS]` lines — **append**, don't overwrite.

## Step 4 — launch, verify, hand off

1. Ensure no IDE holds the repo lock (`Get-Process ide,cefrender` → stop if needed).
   `ide.exe` is **GUI-subsystem** — to gate on it use `Start-Process -Wait -PassThru` +
   `.ExitCode`; a bare `&` leaves `$LASTEXITCODE` blank ([/uniface-compile](../../commands/uniface-compile.md)).
2. Launch MYPROJECT with its workdir asn active
   (default mode of [/uniface-launch-ide](../../commands/uniface-launch-ide.md);
   `-WorkingDirectory <MYPROJECT workdir>` so the local `ide.asn` resolves).
3. **Operator-verified GUI step** (CEF isn't UIA-scriptable): open the burger menu ☰ and
   confirm **WorkArea Export** appears. If it's missing, the `VC_UPDATED` menu def didn't
   resolve — recheck `[RESOURCES]` points at a valid UAR and the asn parsed (message log
   under `usyslog:`).
4. First real use: **dry-run mindset** — WorkArea sync must **preview before writing** and
   never `/cpy`; deletions are flagged, not auto-applied
   ([uniface-workarea-sync](../../rules/uniface-workarea-sync.md)). The repository stays
   the master of record; `workarea/` is its serialization
   ([uniface-repository-source-of-truth](../../rules/uniface-repository-source-of-truth.md)).

## Revert (undo the one-time setup)

- Restore the workdir `ide.asn` from `ide.asn.bak` (or delete the asn if this setup
  created it), remove the `.bak`, and remove any UAR staged in `scratch/`. MYPROJECT then
  launches exactly as before — the plugin is opt-in via this asn only.

## Related

- Rules: [uniface-workarea-sync](../../rules/uniface-workarea-sync.md),
  [uniface-uar-packaging-and-hardening](../../rules/uniface-uar-packaging-and-hardening.md),
  [uniface-repository-source-of-truth](../../rules/uniface-repository-source-of-truth.md),
  [uniface-cli-and-build-hygiene](../../rules/uniface-cli-and-build-hygiene.md),
  [protect-secrets-and-proprietary](../../rules/protect-secrets-and-proprietary.md),
  [quote-paths-with-spaces](../../rules/quote-paths-with-spaces.md).
- Commands: [/was-build](../../commands/was-build.md),
  [/was-package](../../commands/was-package.md),
  [/uniface-launch-ide](../../commands/uniface-launch-ide.md),
  [/uniface-workarea-sync](../../commands/uniface-workarea-sync.md).
- Design: [docs/uniface-was-plugin-integration.md](../../../docs/uniface-was-plugin-integration.md);
  history: [worklog/021](../../../worklog/021-was-plugin-discovery-integration.md)–024.
