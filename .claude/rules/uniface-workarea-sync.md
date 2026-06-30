# Rule: Uniface WorkArea sync hygiene

**Scope:** Any work that moves Uniface development objects between the repository and
the Git-tracked **`workarea/`** tree — the [/uniface-workarea-sync](../commands/uniface-workarea-sync.md)
command and any manual export/import done in WorkArea terms. Grounded in
[docs/uniface-workarea.md](../../docs/uniface-workarea.md).

## Rule

- **The repository is the master of record; `workarea/` is the serialization.** Sync
  is **export → WorkArea** (`push`) and **import ← WorkArea** (`pull`/replay). Never
  treat a WorkArea file as the live object — round-trip it. (See
  [uniface-repository-source-of-truth.md](uniface-repository-source-of-truth.md).)
- **Dry-run by default.** A sync operation must **preview** what it would import,
  export, or delete and **require explicit confirmation** before any repository write.
  Never silently replay or overwrite.
- **Honor the "dirty" guard.** Before importing a file over an object, account for
  uncommitted IDE changes (the WAS `oprStatus==2` "dirty"/orphan case). If in doubt,
  stop and surface it — do **not** force-replay. Deletions (REMOVED files) are
  **flagged, not auto-applied**, in this increment.
- **Never use `/cpy`** (Data Copy) for definitions — corruption risk; its files are
  rejected by `/imp`. WorkArea = Export/Import XML only.
- **There is no command-line export.** `push` uses the IDE Export action or a
  `$ude("export")` snippet. Only **import** has a CLI switch: `/imp` (exit **0**
  success / **1** failure — gate on it).
- **WAS-compatible layout:** one subfolder per object class, **one `.xml` per object**
  (`aps/ cpt/ ent/ prj/ lib*/`). Keep it that way so real WASListener could later
  watch the same tree. See [workarea/README.md](../../workarea/README.md).
- **Resolve paths from `usys.ini [install]`** and **quote spaced tokens**
  ([quote-paths-with-spaces.md](quote-paths-with-spaces.md),
  [uniface-cli-and-build-hygiene.md](uniface-cli-and-build-hygiene.md)).

## Why

The WorkArea workflow mirrors the **target client's** file↔repository infrastructure
(sandbox-per-developer, integrate via Git). Getting the hygiene wrong — forcing a
replay over a developer's uncommitted work, using `/cpy`, or expecting a CLI export —
corrupts the repository or loses changes. Dry-run-by-default makes the emulation safe
while the live WAS watcher / accept-revert is still deferred.

## How to apply

- Reach for **[/uniface-workarea-sync](../commands/uniface-workarea-sync.md)** for
  status / pull / push; it previews first and never writes without confirmation.
- When asked to "sync the WorkArea," default to **`status`** (read-only) and report
  before doing anything that writes.
- Related: [uniface-repository-source-of-truth.md](uniface-repository-source-of-truth.md),
  [uniface-cli-and-build-hygiene.md](uniface-cli-and-build-hygiene.md),
  [quote-paths-with-spaces.md](quote-paths-with-spaces.md).
