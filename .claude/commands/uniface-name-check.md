---
description: Validate a proposed Uniface object name against the naming & reserved-word rules before you create the object
argument-hint: "<proposed-name> [object-type: entity|field|component|operation|printjob]"
allowed-tools: Read, Grep, Glob
---

Check a **proposed Uniface object name** against the verified naming restrictions so a
bad name is caught *before* the create/compile round-trip. Grounded in
[.claude/rules/uniface-object-naming.md](../rules/uniface-object-naming.md)
(Library 10.4, [worklog/013](../../worklog/013-library-pdf-verification.md)).

`$ARGUMENTS`: `$1` = the proposed name, `$2` (optional) = object type for the tighter
length limit.

## Checks (report ✅/❌ per item, with the fix)

1. **Shape** — matches `^[A-Za-z][A-Za-z0-9_]*$` (starts with a letter; only
   letters/digits/underscore). Flag spaces or any other character.
2. **Length** — within the limit for the type:
   - default object: **60**; **operation: 32**; **print-job model: 16**.
3. **Case reliance** — Uniface **uppercases** names. Warn if the intent depends on case
   (e.g. distinguishing `myObj` from `MYOBJ`) — it won't hold.
4. **Reserved word** — reject if the name is a **ProcScript statement/function/data
   type/directive/constant**, a **Repository (Meta-Dictionary) entity** name, a likely
   **DBMS/OS reserved word**, or one of the specific reserved tokens (`HEADER`,
   `TRAILER`, `UNIS`, `DATE`, `TIME`, `LABEL`, `INHERIT`, `NAME16/NAME32`, `*.APS`,
   `*.DICT`, `*.FRM`, `*.TEXT`, `*.USYS`, …). If unsure, say so and point to the
   Library's *Uniface Reserved Words* topic.
5. **Component namespace collision** (components only) — names are unique across **all**
   component types in one global namespace. Grep the `workarea/` exports for an
   existing object of that name and flag a clash.
6. **Custom widget** — if naming a physical widget, reject a leading **`U`** (reserved
   for Uniface's own widgets).
7. **ProcScript file/dir name** (if `$2` says it's a path) — apply the portable-naming
   guidance: alphanumeric + `$` only, no spaces/`_`/`@`/`#`, no `Q`-prefix, generic
   separators, `< 255` bytes (target deploys to Unix/Linux character terminals).

## Output
A short verdict — **OK** or **REJECT/WARN** — listing each failed check and a corrected
suggestion. Do **not** create anything; this is validation only.
