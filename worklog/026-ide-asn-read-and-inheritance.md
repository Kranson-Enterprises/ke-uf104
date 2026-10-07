# 026 How Uniface reads `ide.asn` — the `#FILE` include & its inheritance model

**Date:** 2026-07-01
**Sequence:** … → 024 (WAS Phase D + project-setup skill) → 025 (export/import exceptions) →
**026 (assignment-file read order + `#FILE` inheritance — the config counterpart to 025)**.
**Purpose:** Document how Uniface **assembles its internal assignment file** (global →
local), what the **`#FILE` include directive** does and its **scope/precedence**, and the
**cautions for shared / multi-project / client-hosted dev environments and WorkArea
integrations** — where a mis-scoped include cross-wires environments. Prompted by wiring
`#file usysadm:ide.asn` into both the sandbox and the MYPROJECT `ide.asn` (worklog 024).
Verified against the offline Rocket Uniface Library 10.4 ([webfetched/](../webfetched/),
§"Global Assignment File" / "Local Assignment Files" ~p.1368–1369, §"Including Assignment
Files" (`#FILE`) ~p.1371, §"Using Expressions in Assignment Files" ~p.1372–1373).
Confidence: ✅ Library-verified for behavior/semantics; ⚠️ the "new since version X"
question is answered honestly — the Library states **no** version-introduced for `#FILE`.

---

## 1. How Uniface builds its **internal** assignment file

Uniface does not read one asn — it **assembles** an internal one (Library ~p.1368):

> "When you start an application, Uniface builds an internal assignment file from a
> **global** assignment file (`usys.asn`) **followed by** a **local** assignment file (for
> example, `myapp.asn`). **Settings in the local assignment file take precedence over
> those in the global assignment file.**"

- **Global** `usys.asn` lives in the install dir; holds settings for *all* applications.
  "The global assignments from this file **can be overruled by local assignments**."
- **Local** asn is application-specific — resolved by e.g. **same name as the application
  shell, `.asn`, in the start directory** (several resolution methods exist).
- So the base model is **global (base) → local (override/augment)**. This *is* the
  inheritance mechanism the `#FILE` directive lets you compose and extend.

## 2. The `#FILE` directive — what it actually does

From §"Including Assignment Files" (Library ~p.1371):

- **Syntax:** `#FILE FileName`.
- The named file is **NOT copied in**. It is **handled as a separate assignment file** and
  **must have a section header on its first non-comment line**. After the `#FILE` line,
  processing in the **parent continues in the current section**.
- **Multiple `#FILE` directives are allowed** — you can chain/compose many.
- Canonical example: `#FILE USYSADM:usyschr.asn` (pulls the delivered **character-mode**
  widget-mapping defaults).

This is exactly our pattern: our local `ide.asn` opens with `#file usysadm:ide.asn` to pull
the **install baseline** first, then appends our own sections.

## 3. Scope & precedence nuances (the sharp edges)

From §"Using Expressions in Assignment Files" → "Scope" (Library ~p.1372–1373):

- **`[logicals]` is processed first**, so logicals are usable in **all** sections even if
  defined later — **but inside `[logicals]` order matters** (only previously-declared
  logicals are usable in an expression).
- **`#file` must precede a `[logicals]` section that uses the included file's logicals** in
  an expression. Include-before-use.
- **One-way visibility:** logicals defined in **`usys.asn` can be used** in expressions in
  other application asn files, **but not the other way around**. Global is visible to
  local; local is not visible to global.
- **Wildcard assemble caution:** "The method that Uniface uses for assembling its internal
  assignment file has implications when assignments involving wildcards are used"
  (Library ~p.1369) — merged `[FILES]`/`[RESOURCES]` wildcards can interact.
- **Section behavior differs:** list-style sections (`[RESOURCES]`, `[FILES]`) **accumulate**
  entries across the global+local+included files; single-value settings
  (`[SETTINGS]`, `[LOGICALS]`) resolve to the **local/last** value. Know which you're
  editing so an include doesn't silently **drop** (override) or **duplicate** (accumulate).

## 4. "Since what version?" — the honest answer

The operator recalls `#FILE` as **new since a certain version**. The offline Library 10.4:
- documents `#FILE` as a **current, standard directive** with **no "introduced in version
  N" note** anywhere I could find (searched the full 278k-line extract);
- shows it used across contexts (character-mode include, **encryption**: "you can use the
  `#FILE` command to include an old assignment file in a newly encrypted one"), i.e. it is
  **long-standing**, present through v9→v10.

What *is* comparatively **new** in asn files is the **`%%( … )` expression** feature
(inline arithmetic/substring/env-var evaluation, Library ~p.1372) — a likely source of the
"new since" impression. **Conclusion:** treat `#FILE` as **long-standing, not version-
gated**; treat asn **expressions** as the newer capability. If a hard version floor ever
matters for a deliverable, confirm against Rocket's **release notes / PAM**, not an open
doc page (same discipline as [uniface-dsp-web-conventions](../.claude/rules/uniface-dsp-web-conventions.md)).

## 5. How we actually rely on it (this project)

- **Sandbox** `IdePlugin\ide.asn`: `#file usysadm:ide.asn` (baseline) → `[RESOURCES] .\resources`
  (+ Phase D `[LOGICALS] IDE_DEFINE_USERMENUS=VC_UPDATED`).
- **MYPROJECT** `uniface\project\ide.asn` (created by the `was-project-setup` skill, worklog
  024): `#file usysadm:ide.asn` (baseline) → `[RESOURCES]`→`VersionControl.uar` →
  `[LOGICALS] IDE_DEFINE_USERMENUS=VC_UPDATED` + `WAS_ROOT_FOLDER=…\ke-uf104\workarea`.
  Verified from the startup log: `Asn File : ide.asn` read from the project workdir.

Both rely on: **include the install baseline first, then let local sections
override/append.** Order is deliberate — see §6.

## 6. Cautions for shared / multi-project / client-hosted environments (the crux)

`#FILE` is powerful precisely because it composes environments — which is also how it
**cross-wires** them if mis-scoped:

1. **Include order = precedence.** Put `#file usysadm:ide.asn` **first** so the baseline is
   the *base* and your local settings win. Put it *after* your sections and it can **clobber
   your own settings**; also it must **precede** any `[logicals]` that use its logicals (§3).
2. **Absolute paths in an included/shared asn bind to one machine.** A committed asn that
   hardcodes `C:\ref` or a client path **breaks on another host**. Use **logicals /
   `%%($ENV)` expressions / relative paths**, and keep machine-specific asn **local &
   gitignored** — exactly why `uniface/project/ide.asn` is gitignored (worklog 024).
3. **`WAS_ROOT_FOLDER` is per-developer / per-project — never global.** It points a
   WorkArea integration at a specific repo path. Baking it into a **shared/global**
   `usys.asn` would point *every* project at one WorkArea tree and **cross-contaminate**
   sandboxes. It belongs only in a **local include** so each sandbox/client dir hosts its
   own WorkArea root. Same for `[RESOURCES]`→a plugin `.uar` and `IDE_DEFINE_USERMENUS`.
4. **Client-hosting / multi-tenant dirs:** if one machine hosts several project directories
   (client sandboxes), each must resolve its **own local asn** (start dir / its own `#file`
   chain). A global `usys.asn` that leaks one client's paths/resources into another is a
   confidentiality and correctness hazard
   ([protect-secrets-and-proprietary](../.claude/rules/protect-secrets-and-proprietary.md)).
5. **Encryption interplay (hardened client asn):** you **can't mix** old and new lines in an
   encrypted asn, **but `#FILE` can include an old asn into a newly encrypted one** (Library).
   Useful when `pathscrambler`-hardening a client asn
   ([uniface-uar-packaging-and-hardening](../.claude/rules/uniface-uar-packaging-and-hardening.md)).
6. **Keep asn ASCII / own-line comments.** Non-ASCII needs a UTF BOM (Library p.1368); and
   `[SETTINGS]`/`[RESOURCES]` don't strip trailing `;` inline comments (worklog 023). An
   include won't rescue a value corrupted by an inline comment.
7. **Quote spaced paths** as whole tokens in every asn value
   ([quote-paths-with-spaces](../.claude/rules/quote-paths-with-spaces.md)).

## 7. Takeaways

- Uniface **assembles** its config: **global `usys.asn` → local**, local overriding global;
  `#FILE` composes that chain (separate file, own section header, multiple allowed,
  include-before-use for logicals).
- `#FILE` is **long-standing, not version-gated** (per the offline Library); asn `%%()`
  **expressions** are the newer feature.
- In shared / multi-project / client / WorkArea setups, **scope machine- and project-
  specific settings to a *local* include and keep it gitignored** — a mis-placed global
  `#FILE` or absolute path cross-wires environments.

## Related

- Rules: [quote-paths-with-spaces](../.claude/rules/quote-paths-with-spaces.md),
  [uniface-uar-packaging-and-hardening](../.claude/rules/uniface-uar-packaging-and-hardening.md),
  [protect-secrets-and-proprietary](../.claude/rules/protect-secrets-and-proprietary.md),
  [uniface-workarea-sync](../.claude/rules/uniface-workarea-sync.md).
- Skill/commands: [.claude/skills/was-project-setup/SKILL.md](../.claude/skills/was-project-setup/SKILL.md),
  [/uniface-launch-ide](../.claude/commands/uniface-launch-ide.md),
  [/uniface-asn-review](../.claude/commands/uniface-asn-review.md).
- Companion: [worklog/025](025-export-import-reasons-and-exceptions.md) (object round-trip —
  the *object* counterpart to this *config* read model); [worklog/024](024-was-phase-d-and-project-setup-skill.md)
  (where these includes were wired).
