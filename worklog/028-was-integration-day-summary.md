# 028 WAS WorkArea integration — day summary (Stage 1 close-out → Stage 2 verified)

**Date:** 2026-07-01
**Sequence:** roundup of **021–027** — the day that took the WAS WorkArea plugin from
"built" to "wired into MYPROJECT and round-tripped."
**Purpose:** One place to re-read what was found, improved, and shipped today, and where
the effort stands. Detail lives in the per-topic worklogs (024–027) and the commits below.
Confidence: ✅ All claims executed/log-verified on this install.

---

## 1. Where we ended the day

- **Stage 1 (build the plugin) — COMPLETE.** `VersionControl.uar` built from the sibling
  `WASListener` clone (Phases A–C + Method-A UAR), and Phase D cleared the WorkArea
  baseline.
- **Stage 2 (wire into MYPROJECT) — COMPLETE & VERIFIED.** The plugin is live in the
  MYPROJECT IDE against this repo's `workarea/`, and a first Export→Import round-trip of
  `HELLO_WORLD` + `MYPROJECT` is green.
- **Deferred:** the native `WASListener.exe` live watcher (toolchain build) — prerequisites
  captured in project memory for a clean resume.

## 2. What we found (verified learnings)

1. **Phase D menu reality:** the burger-menu item is a single **WorkArea Export** (not the
   "Export/Revert" submenu the docs had guessed); **Export All** dims per-object buttons
   when there's no pending delta. (worklog 024)
2. **CPT signatures are derived, not source** — excluded from WorkArea sync; they live in
   the `.uar` `sig/`, regenerated each `/all`. (worklog 024)
3. **Export/Import exceptions** — the enduring restriction is the **copy-vs-export
   boundary**: `/cpy`/`$ude("copy")` output can't be `/imp`-imported, can't be appended to
   export files, reads as incompatible; import is a compatible-or-migratable gate. The
   "exception from years ago" stays flagged as recollection where the Library doesn't
   confirm a removed case. (worklog 025)
4. **`ide.asn` is assembled, not read flat** — global `usys.asn` → local, local overriding
   global; `#FILE` composes that chain (separate file, own section header, include-before-
   use for logicals, one-way global→local logical visibility). `#FILE` is long-standing (no
   version-introduced in the Library); the newer asn feature is `%%()` expressions.
   (worklog 026)
5. **WorkArea Export is intentionally leaner than IDE Export** — the plugin drops the
   `system="S"` `UPROJECT`/`UREFCPT` meta-dictionary tables + `varinfo` the IDE export
   bundles into a component file (those belong to the *project*, proven by the import
   mapping). IDE Export = portable self-contained dump; WorkArea Export = minimal per-object
   VCS delta. (worklog 027)
6. **The real plugin's Import is destructive** — `Delete <object>` then `Import <object>`
   for everything under `WAS_ROOT_FOLDER`, with no preview/selection/scope; it can silently
   overwrite uncommitted repository work. Our emulation's dry-run/preview-first model is the
   safer one. (worklog 027)
7. **System-object bleed is real** — a repository ships Uniface-delivered `USYS*`/`U*`
   objects (`USYSUPALETTE_FRM/RPT`, `USYSSTAT`, …); the Export form lists them with no
   filter. Never `Export All`; never *delete* them to tidy (reserved namespace, breaks the
   IDE). (worklog 024/027)

## 3. What we improved (tooling, rules, hygiene)

**New capability**
- **`was-project-setup` skill** — the repo's first `.claude/skills/` entry: a one-time
  Stage-2 wizard (download vs build vs reuse the UAR → back up config → write the
  project-local asn → verify the menu). Introduced `.claude/skills/README.md` (skills =
  multi-step procedures vs commands = one-shot vs agents = delegated).

**Rules**
- `uniface-workarea-sync` — added **"export project objects only, never `USYS*`/`U*`"** and
  the **"real Import is destructive; keep our pull dry-run/preview-first"** cautions.

**Feedback to Rocket** (self-contained, no repo links, for external submission)
- `feedback-workarea-plugin-export-import.md` — Export has no system-object filter **and**
  Import is a destructive no-preview/no-scope replace, with reproduced log evidence and
  concrete fixes.

**Safety/tidy**
- Gitignored the runtime `uniface/project/ide.asn` (machine-specific paths; enables a
  non-commercial plugin; recreate via the skill).
- Adopted the WAS-format `HELLO_WORLD.xml` as the canonical serialization.

## 4. Commits (2026-07-01)

| Hash | Summary |
| --- | --- |
| `86b73f8` | fix(commands): reliable exit codes for GUI-subsystem `ide.exe` in PowerShell |
| `35c5c90` | feat(commands): batch WorkArea import + UAR packaging rule and command |
| `6093c66` | feat(was): WorkArea (WAS) plugin build tooling group |
| `2a5bc85` | docs: worklogs 022–023 and IDE project-discovery feedback |
| `1be943f` | docs(was): correct Phase D menu name + note signature exclusion |
| `11af673` | feat(skills): `was-project-setup` one-time WAS wiring skill + worklog 024 |
| `c957e08` | docs(worklog): export/import exceptions (025) + `ide.asn` `#FILE` inheritance (026) |
| `ed7572a` | docs(workarea): system-object export hygiene rule + plugin filter feedback |
| `838e03f` | chore(workarea): adopt WAS-format `HELLO_WORLD` export (drop system-table bleed) |
| `6677bde` | docs(workarea): round-trip worklog 027 + self-contained Export/Import feedback |

## 5. Next

- **Deferred build:** native `WASListener.exe` live watcher — see the project memory
  resume note for prerequisites (toolchain, `UNIFACE_3GL_FOLDER`, license gate).
- **Optional:** exercise a *change*-then-round-trip (edit `HELLO_WORLD`, Export, diff) to
  see a non-idempotent delta; fold the legacy `components/`+`src/` exports into `workarea/`
  (tracked follow-up from the WorkArea README).

## Related

- Topic worklogs: [024](024-was-phase-d-and-project-setup-skill.md),
  [025](025-export-import-reasons-and-exceptions.md),
  [026](026-ide-asn-read-and-inheritance.md),
  [027](027-workarea-first-roundtrip-helloworld.md); build history
  [021](021-was-plugin-discovery-integration.md)–[023](023-uar-packaging-methodology-and-hardening.md).
- Skill: [.claude/skills/was-project-setup/SKILL.md](../.claude/skills/was-project-setup/SKILL.md).
- Feedback: [docs/feedback-workarea-plugin-export-import.md](../docs/feedback-workarea-plugin-export-import.md).
