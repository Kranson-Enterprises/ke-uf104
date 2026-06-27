# Product Feedback — Embedded Chromium (CEF) currency in the Uniface 10 IDE

**To:** Rocket Uniface product team
**From:** Uniface 10 workspace evaluation (`ke-uf104`)
**Date:** 2026-06-27
**Component:** Uniface 10.4.03 Community Edition IDE (`common\bin\ide.exe`)
**Category:** Security / dependency currency — informational feedback, low-effort ask

## Summary

The Uniface 10.4.03 IDE embeds **Chromium 141** via CEF. As of 2026-06-27 that is
roughly **eight major versions behind** the current Chromium Stable channel
(**149**, with **150** due 2026-06-30). Because the IDE's entire UI runs inside
this embedded browser, its Chromium currency is part of the product's security
surface. We'd like to flag the gap and ask about the update cadence.

## Observed (this install)

Verified empirically from the running `ide.exe` process (loaded modules):

| Item | Value |
| --- | --- |
| `libcef.dll` | `141.0.5+gfe26daa+chromium-141.0.7390.55` |
| `chrome_elf.dll` | `141.0.7390.55` |
| IDE build date (`ide.exe`) | 2026-05-18 |
| Product | Uniface 10.4.03 042 (Rocket Software B.V.) |

Chromium **141** reached the Stable channel upstream around **October 2025**, so a
product binary built 2026-05-18 shipped a browser engine ~7 months old at build
time.

## Upstream current state (as of 2026-06-27)

| Channel | Version | Notes |
| --- | --- | --- |
| Chrome/Chromium Stable | **149** (latest patch 149.0.7827.201) | promoted June 2026 |
| Stable (next) | **150** | scheduled 2026-06-30 |
| Dev | 151 (e.g. 151.0.7915.0) | — |

**Gap: ~8 major versions** behind Stable (≈9 behind 150). CEF version numbers
track the Chromium major they are based on, so a CEF **149**-based stable build is
available upstream.

### Even within the 141 branch, this build is behind

The 141 line continued to receive security patches after the version Uniface
ships. The latest 141-branch build we could confirm is **CEF
`141.0.11+g7e73ac4+chromium-141.0.7390.123`** (Chromium **141.0.7390.123**, dated
2025-10-25, per the CefSharp 141.0.110 packaging).

| | Chromium | CEF |
| --- | --- | --- |
| Uniface 10.4.03 ships | 141.0.7390.**55** | 141.0.**5** |
| Latest confirmed 141-branch | 141.0.7390.**123** | 141.0.**11** |

So even without a major-version jump, the embedded engine is ~68 Chromium patch
builds (`.55` → `.123`) behind the final 141-line security baseline — these are
stability/security patches within the *same* major that were available before the
2026-05-18 product build.

## Why this matters

- Each Chromium release cycle (~4 weeks) ships security fixes, periodically
  including **actively-exploited zero-days**. Eight missed major cycles plus their
  patch releases means a meaningful set of known, fixed vulnerabilities are absent
  from the embedded engine.
- The IDE UI is rendered by this engine (HTML/CSS/JS in a CEF shell — confirmed in
  [worklog/002-ide-architecture-analysis.md](../worklog/002-ide-architecture-analysis.md)),
  so the exposure isn't theoretical for the development tool, and the same engine
  likely underpins runtime web components (DSP) shipped to end users.
- **Credit where due:** shipping CEF 141 in a May-2026 build shows the team *does*
  keep CEF reasonably fresh relative to other embedded-browser products — this is
  about closing the remaining gap and clarifying cadence, not a cold start.

## Requests / suggestions (low-effort, prioritized)

1. **Clarify the CEF update cadence** for the 10.4.x line and whether a CEF bump
   ships in maintenance/patch releases or only minor/major releases.
2. **Consider tracking a CEF LTS branch** (CEF designates an LTS every sixth
   branch, e.g. M138) to balance stability with a predictable security baseline.
3. **Publish the embedded Chromium version in release notes** so adopters can map
   it to upstream CVE advisories without process inspection.
4. If feasible, **target a Chromium within ~2–3 majors of Stable** at GA for
   security-sensitive deployments.

## Method / reproducibility

- Inspected loaded modules of the live `ide.exe` via PowerShell
  (`(Get-Process ide).Modules`) — see worklog 002.
- Upstream versions via Chrome Releases blog and Chromium Dash (2026-06-27).

## References

- Chrome Releases — Stable Channel Update for Desktop (June 2026):
  <https://chromereleases.googleblog.com/2026/06/stable-channel-update-for-desktop.html>
- Chromium Dash (release tracker): <https://chromiumdash.appspot.com/releases?platform=Windows>
- CEF branches & versioning: <https://chromiumembedded.github.io/cef/branches_and_building.html>
- CEF automated builds (latest stable / 141.x): <https://cef-builds.spotifycdn.com/index.html>
- Latest confirmed 141-branch build (CEF 141.0.11 / Chromium 141.0.7390.123),
  via CefSharp 141.0.110 (2025-10-25):
  <https://github.com/cefsharp/CefSharp/releases/tag/v141.0.110>

> **Status:** Draft feedback note, recorded locally in this workspace. Not yet
> sent to Rocket. Upstream version facts (current Stable 149/150; latest 141-branch
> CEF 141.0.11 / Chromium 141.0.7390.123) confirmed 2026-06-27.
