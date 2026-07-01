# Product Feedback — WorkArea Export has no filter to exclude Uniface system objects

**To:** Rocket Uniface product team (and the WAS / WorkArea Support maintainers)
**From:** Uniface 10 workspace evaluation (`ke-uf104`)
**Date:** 2026-07-01
**Component:** WAS WorkArea IDE plugin (`VersionControl.uar`, from `github.com/uniface/WASListener`), Uniface 10.4.03 CE IDE
**Category:** WorkArea/VCS usability — export scoping / noise reduction

## Summary

The WAS **WorkArea Export** form lists **every** development object in the repository as
"new" on first use — including **Uniface's own delivered `USYS*` / `U*` system objects**
alongside the developer's project objects. There is **no checkbox, retrieve profile, or
name filter** to exclude the delivered system objects, so the only ways to avoid dragging
them into version control are to **hand-pick each of your own objects** or to press
**Export All** and then manually prune. For a VCS-first workflow this is error-prone and
noisy, and it invites a **dangerous "cleanup" reflex** (see Impact).

## Context (how we hit it)

We wired `VersionControl.uar` into a project IDE with `IDE_DEFINE_USERMENUS=VC_UPDATED`
and `WAS_ROOT_FOLDER` pointed at a Git-tracked `workarea/` tree, then opened **WorkArea
Export** to establish the baseline. The repository is a small project (**2** authored
objects: a `prj` and a `cpt`), yet the form also listed Uniface-delivered objects —
confirmed present in the repository db: `USYSUPALETTE_FRM`, `USYSUPALETTE_RPT`,
`USYSSTAT`, and others in the reserved `U*` namespace.

## Observed

1. **No exclude/scoping control on the Export form.** No "exclude Uniface system objects"
   checkbox, no retrieve profile, no name-pattern/source filter. The list is all-or-pick.
2. **`Export All` exports the delivered system objects too**, writing them into the
   `WAS_ROOT_FOLDER` tree — i.e. into version control, where Rocket-delivered content is
   both **noise** (identical across every install) and arguably **out of place**.
3. **The only precise path is manual per-object selection** of your own objects — which
   does not scale as a project grows and is easy to get wrong.

## Steps to reproduce

1. Point the WorkArea plugin at any repository (even a fresh one with 1–2 authored
   objects) via `IDE_DEFINE_USERMENUS=VC_UPDATED` + `WAS_ROOT_FOLDER`.
2. Open the burger (≡) menu → **WorkArea Export**.
3. Observe the object list includes Uniface `USYS*` / `U*` system objects with active
   Export/Revert, and that **there is no control to filter or exclude them**.

## Impact

- **VCS pollution.** `Export All` puts Uniface-delivered system objects into the Git tree
  — bloat and churn that isn't the team's source, and licensed/delivered content in a
  repo it doesn't belong in.
- **Dangerous cleanup reflex.** Because the system objects clutter the list, a developer's
  natural instinct is to **delete them to tidy up** — but the WorkArea Revert/Remove path
  deletes **repository definitions**, and the `U*` namespace is Uniface's own (reserved).
  Removing e.g. `USYSUPALETTE_*` can break IDE features or repository integrity. The UI
  currently makes the wrong action (delete) look as available as the right one (exclude).
- **Toil at scale.** Hand-selecting project objects every baseline does not scale.

## Suggested improvements (low effort, high clarity)

1. **Add an "Exclude Uniface system objects" checkbox** (default **on**) that hides/omits
   the delivered `USYS*` / `U*` reserved-namespace objects from export. This alone solves
   the common case.
2. **Support a retrieve profile / filter** on the Export form — by **object-name pattern**
   (include/exclude, e.g. exclude `U*`), by **source/collection**, or by **project
   membership** — so a team can scope the WorkArea to exactly its own objects.
3. **Guard the delete/Revert path** for reserved-namespace objects (confirm-with-warning,
   or disable) so "tidying the list" can't silently remove delivered system definitions.
4. Optionally, **scope Export to the active project's membership** by default, since the
   plugin already knows the project context.

## Environment

| Item | Value |
| --- | --- |
| Product | Uniface 10.4.03 Community Edition |
| IDE | `C:\ref\common\bin\ide.exe` (build 2026-05-13) |
| Plugin | WAS `VersionControl.uar` (compiled from `github.com/uniface/WASListener`), **non-commercial license** |
| Repository | SQLite (SLE), small project — 2 authored objects + delivered `USYS*` objects |
| System objects seen | `USYSUPALETTE_FRM`, `USYSUPALETTE_RPT`, `USYSSTAT`, … (`U*` reserved namespace) |

## Related

- Workspace hygiene rule this drove: [.claude/rules/uniface-workarea-sync.md](../.claude/rules/uniface-workarea-sync.md) ("export project objects only").
- WorkArea tree contract: [workarea/README.md](../workarea/README.md).
- Reserved-namespace basis: [.claude/rules/uniface-object-naming.md](../.claude/rules/uniface-object-naming.md) (`U` prefix is Uniface's).
- Prior IDE feedback: [feedback-ide-project-discovery-ux.md](feedback-ide-project-discovery-ux.md).
- Integration history: [worklog/024](../worklog/024-was-phase-d-and-project-setup-skill.md).
