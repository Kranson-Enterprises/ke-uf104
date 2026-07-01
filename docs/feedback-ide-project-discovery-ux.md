# Product Feedback — Imported projects are not discoverable in the IDE (no Projects browser)

**To:** Rocket Uniface product team
**From:** Uniface 10 workspace evaluation (`ke-uf104`)
**Date:** 2026-07-01
**Component:** Uniface 10.4.03 Community Edition IDE (`common\bin\ide.exe`)
**Category:** IDE usability — project navigation / discoverability

## Summary

After importing a project's objects into a repository via the command line (`/imp`), the
imported **project could not be found by browsing the IDE** — there is **no Projects
list/browser in the burger (≡) menu**, and the project did not surface from a plain U-Bar
search of its name. The only way to open it was to know the **U-Bar class prefix**
convention and type **`prj:VERSIONCONTROL`**. A developer who imports a project (rather
than creating it in-session) has no discoverable path to it.

## Context (how we hit it)

We imported the open-source **WAS "VERSIONCONTROL"** IDE-plugin project
(`github.com/uniface/WASListener`, `IdePlugin\WorkArea\`) into a fresh sandbox repository —
178 objects, all `/imp` exit 0, including the `prj/versioncontrol.xml` project record
(a `UPROJECT` occurrence, verified present). We then needed to open the project to compile
it.

## Observed

1. **No "Projects" entry in the burger (≡) menu.** There is no list of projects and no
   recent-projects list to pick from. Nothing in the menu leads to an imported project.
2. **Plain-name U-Bar search did not resolve the project.** Typing `VERSIONCONTROL` alone
   did not open it in this session.
3. **The class-prefixed U-Bar search worked:** `prj:VERSIONCONTROL` located and opened the
   project. This depends on the developer already knowing the `prj:` prefix convention.

## Steps to reproduce

1. In an empty/fresh repository, `/imp` a project definition (any `prj` XML with its member
   objects) from the command line — do **not** create the project in the IDE.
2. Launch the IDE against that repository.
3. Open the burger (≡) menu and look for a way to browse/open projects → **none is
   offered**.
4. Type the project name in the U-Bar → it does not open the project.
5. Type `prj:<name>` in the U-Bar → the project opens.

## Impact

- **Import-first / VCS-driven workflows are the ones that hit this.** Teams that keep
  object definitions in version control and import them into a clean repository (exactly
  the model the WorkArea/WAS tooling itself promotes) land in a repository whose projects
  are invisible unless the developer knows the `prj:` trick. It reads as "the import
  didn't work" when in fact the object is present.
- Newcomers with no in-session project to anchor on can dead-end here.

## Suggested improvements (low effort, high clarity)

1. **Add a "Projects" browser / recent-projects list to the burger menu** — a discoverable
   entry point that lists projects in the current repository. This is the primary ask.
2. Optionally, have a **plain U-Bar name search** also match objects by name across common
   classes (or hint the `prj:` prefix in results) so discovery doesn't require prior
   knowledge of the class-prefix syntax.
3. Consider surfacing the **U-Bar class-prefix legend** (`prj:`, `cpt:`, `ent:`, …)
   somewhere in the UI for discoverability.

## Environment

| Item | Value |
| --- | --- |
| Product | Uniface 10.4.03 Community Edition |
| IDE | `C:\ref\common\bin\ide.exe` (build 2026-05-18) |
| Repository | SQLite (SLE `U2.0`), fresh sandbox created this session |
| Repro data | WAS `VERSIONCONTROL` project, imported via `/imp` (exit 0) |

## Related

- Workspace worklog: [worklog/022](../worklog/022-versioncontrol-plugin-build-from-sibling.md) (§4 IDE behaviour differences).
- Prior IDE feedback: [feedback-cef-chromium-currency.md](feedback-cef-chromium-currency.md).
