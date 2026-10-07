---
description: "WAS plugin: orchestrator/reference for building VersionControl.uar from the sibling WASListener clone (Phases A-D)"
allowed-tools: Read, PowerShell, Bash, Edit
---

**WAS-specific** (not a default). Single source of truth for **building the Work Area
Support IDE plugin** (`VersionControl.uar`) from the sibling clone, so a rebuild (new
WASListener release, repo reset) is repeatable. This orchestrates existing steps — run
them in order, gating on each. Full design:
[docs/uniface-was-plugin-integration.md](../../docs/uniface-was-plugin-integration.md);
history: [worklog/021-023](../../worklog/021-was-plugin-discovery-integration.md).

⚠️ **License:** WAS is **non-commercial** — personal skill-refresh only, **not** client
delivery ([worklog/021 §2](../../worklog/021-was-plugin-discovery-integration.md)).

Fixed paths (this install): exe `C:\ref\common\bin\ide.exe`, adm `C:\ref\uniface\adm`,
clone `C:\Users\Bob\source\uniface\WASListener`, sandbox `…\WASListener\IdePlugin`.
The sandbox is **isolated** from MYPROJECT because `dbms.asn` resolves the repo as the
working-dir-relative `.\dbms\usys.db`.

## Phases (each gated; stop and report on failure)

- **Phase A — create the sandbox repo.** Launch the IDE into the sandbox with
  **[/uniface-launch-ide](uniface-launch-ide.md) `--was`**. On first start it creates
  `IdePlugin\dbms\usys.db`. (Idempotent — if `usys.db` exists, skip to B.)
- **Phase B — import the plugin sources.** Batch-import `IdePlugin\WorkArea\**\*.xml`
  (~178 objects) in dependency order with
  **[/uniface-import-batch](uniface-import-batch.md)** (exit-code gated per class:
  ent → lib* → cpt → aps → prj). Do this with the IDE **closed** (repo lock).
- **Phase C — compile.** Either open the project **`prj:VERSIONCONTROL`** in the IDE and
  **Compile All**, or CLI `/all` from the sandbox workdir. Produces loose
  `IdePlugin\resources\`. (No Projects browser in the burger menu — use the U-Bar `prj:`
  prefix; see [feedback-ide-project-discovery-ux](../../docs/feedback-ide-project-discovery-ux.md).)
- **Package — build the UAR.** Run **[/was-package](was-package.md)** to produce
  `IdePlugin\VersionControl.uar` (compile-to-UAR + auto asn revert + verify).
- **Phase D — clear the "all new" state.** Uncomment `IDE_DEFINE_USERMENUS=VC_UPDATED` in
  the sandbox `ide.asn`, restart the IDE, and use burger menu **WorkArea Export → Export
  All** (per-object Export/Revert buttons dim = no pending delta). **Exclude CPT
  signatures** — they're derived compile output (in the `.uar` `sig/`), not WorkArea source.

## Then: Stage 2 — wire into MYPROJECT (separate task)

Run the **`was-project-setup`** skill
([.claude/skills/was-project-setup/SKILL.md](../skills/was-project-setup/SKILL.md)): it
asks download-vs-build for the UAR, backs up config, and writes the project-local asn
chaining the install's — `[RESOURCES]` = `VersionControl.uar`,
`IDE_DEFINE_USERMENUS=VC_UPDATED`, `WAS_ROOT_FOLDER = …\ke-uf104\workarea`. Then use
**Import WorkArea** / **WorkArea Export** against `workarea/` (the real versions of
[/uniface-workarea-sync](uniface-workarea-sync.md) pull/push).

Related rules: [uniface-workarea-sync](../rules/uniface-workarea-sync.md),
[uniface-uar-packaging-and-hardening](../rules/uniface-uar-packaging-and-hardening.md),
[uniface-cli-and-build-hygiene](../rules/uniface-cli-and-build-hygiene.md).
