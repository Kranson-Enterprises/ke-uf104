# 023 How the deployable UAR is built — packaging methodology, its evolution, and hardening

**Date:** 2026-07-01
**Sequence:** … → 021 (WAS plugin discovery) → 022 (VERSIONCONTROL build, Phases A–C) →
**023 (UAR packaging methodology + hardening — the "how do I get a `.uar`?" answer)**.
**Purpose:** During the WAS plugin build (022) we compiled the `VERSIONCONTROL` project
and got a **loose `resources\` folder, not a `.uar`**. This worklog captures *why* that is,
the **four documented ways** to produce a UAR, **how the packaging approach evolved** away
from the old Uniface deployment model, and the **hardening/tamper-protection** tools that
sit on top — so the reasoning is re-readable later. Verified against the offline Rocket
Uniface Library 10.4 ([webfetched/](../webfetched/), §"Create Uniface Archive Files"
p.1358, §"Certifying Uniface Applications" p.1715).
Confidence: ✅ Library-verified + tool presence checked on this install.

---

## 1. Why "Compile" produced a folder, not a UAR

Compiling writes runtime objects to **`$RESOURCES_OUTPUT`** (set in `ide.asn`). Our
sandbox sets it to a **directory** (`.\resources`), so Compile All produced 70 loose files
in the standardized type-subdirs (`svc/ frm/ sig/ edc`) — see [worklog/022 §3](022-versioncontrol-plugin-build-from-sibling.md).
**A `.uar` is simply a ZIP of that same standardized directory structure** (Library p.1348:
"a zip file with a `.uar` extension that contains the application's runtime objects in a
standardized directory structure"). So a UAR is not a different build — it's the same
compiled objects, packaged. **There is no one-click "Build UAR" button on a project** in
the IDE; you choose one of the methods below.

## 2. The four documented ways to create a UAR (Library p.1358)

| # | Method | Tool | Notes |
| --- | --- | --- | --- |
| **1** | **Compile directly to a UAR** — set `$RESOURCES_OUTPUT = .\path\Name.uar`, restart IDE, recompile | IDE / CLI compile | IDE-native; each UAR holds only what you compiled into it. **Chosen for this build (§4).** |
| **2** | **`urm copy`** the already-compiled `resources\` into a `.uar` | `urm.exe` | No recompile; pack an existing folder. `urm copy resources\*\* Name.uar:/*/*` |
| **3** | **`$ude("archive")` ProcScript** (with `$ude("lookup")`) | ProcScript | Scriptable/CI builds; append lists of objects by type |
| **4** | Third-party ZIP (e.g. WinZip) | any zip | ⚠️ must exactly match the expected dir structure or runtime can't find resources |

For **this plugin specifically**, `IdePlugin\readme.md` notes `[RESOURCES]` accepts **either
the resources folder or a `.uar`** — so a UAR isn't strictly required for Stage-2 wiring,
but building one mirrors real deployment and is the learning goal.

## 3. How the packaging methodology evolved (the "changed for good reasons" part)

Uniface 10 replaced the older deployment model wholesale:

- **Everything ships as `.uar` deployment archives now** — "Uniface itself, and the
  applications you build with Uniface, are now delivered as deployment archives (.uar).
  **`.dol` and `.urr` files can no longer be generated**, and `USYSANA.TEXT` / `ULANA.DICT`
  tables were removed from the Repository" (Library, v10 migration notes). The old
  Dictionary Object Library (`.dol`) / runtime-record (`.urr`) world is gone.
- **The old deployment environment (URMA) is deprecated** — "The Uniface Deployment
  Environment (URMA) is no longer delivered… use the **Uniface Resource Manager (`urm`)**
  to do most of the tasks." Packaging consolidated into one CLI utility (`urm`) plus the
  compile-to-UAR path.
- **Why it's better:** one standardized, zip-based, type-structured archive format;
  fast runtime resolution; easy incremental updates (`urm copy … -after=YYYYMMDD`);
  hot-deployment-friendly; scriptable via `$ude("archive")`. A single, inspectable,
  swappable unit instead of format-specific object libraries.

## 4. Hardening the compiled objects (the "encryption/hardening tools" seen elsewhere)

Two distinct protections sit **on top of** the UAR, both shipped in this install
(`C:\ref\common\bin`, all verified present: `urm.exe`, `cert.exe`, `pathscrambler.exe`,
`openssl.exe`):

- **UAR certification — `cert.exe` (tamper protection).** "Deployed Uniface application
  archives can now be **certified with public/private key pairs, protecting you from
  unauthorized tampering** with your resources" (Library p.1715, "Certifying Uniface
  Applications" / "How to Certify a Uniface Application" / `cert.exe`; errors in Uniface
  Messages 9000–9999). This is the archive-integrity/hardening tool for the *compiled
  objects themselves* — sign the `.uar`, and the runtime rejects a tampered archive.
  OpenSSL is now bundled in `/common/bin` to generate the keys/certs.
- **Pathscrambler — `pathscrambler.exe` (asn secret encryption).** Encrypts path
  definitions and other sensitive strings in assignment files (`[ENCRYPTED_PATHS]`);
  recent versions add a **`-seed`** key and a tamper digest appended to encrypted lines.
  This protects *configuration* (credentials, connection strings), not the objects — it's
  the tool our [protect-secrets-and-proprietary](../.claude/rules/protect-secrets-and-proprietary.md)
  rule already points at. Complementary to `cert.exe`.

**Layering:** compile → package (`.uar`) → **certify (`cert.exe`)** for tamper protection →
scramble asn secrets (`pathscrambler`) → deploy. Non-debuggable production builds
(`/all /nodebug`) are the fourth leg (already in
[uniface-cli-and-build-hygiene](../.claude/rules/uniface-cli-and-build-hygiene.md)).

## 5. Decision for the WAS plugin build

Proceeding with **Method 1 (compile directly to a UAR)** — the IDE-native path, which is
what the operator wanted to see. Set `$RESOURCES_OUTPUT` in the sandbox `ide.asn` to a
`.uar` target, restart the IDE, recompile `VERSIONCONTROL`; verify the result with
`urm` (`urm.exe` info/list). Certification (`cert.exe`) is **out of scope** for a personal
skill-refresh build and is **non-commercial-licensed** WAS anyway
([[reference-uniface-workarea-was]]) — noted here for when a *real client deliverable*
needs tamper protection.

## 6. Follow-ups this raised (tooling)

- A **WAS-specific command group** (namespaced, not defaults) to make the whole plugin
  build repeatable: sandbox launch → import → compile-to-UAR → export-all. Candidates in
  the next worklog / commands review.
- A general **UAR packaging & hardening rule** capturing §2–§4 (compile-to-uar vs `urm`
  vs `$ude`; `cert.exe`/`pathscrambler`; never hand-zip the wrong structure) so future
  deployment work starts from verified facts.

## References
- Library 10.4 (offline): "Create Uniface Archive Files" (p.1358), "Certifying Uniface
  Applications" (p.1715), UAR Files (p.1348), `urm` / `urm copy` / `urm split`.
- This install: `C:\ref\common\bin\{urm,cert,pathscrambler,openssl}.exe` (all present).
- Prior: [worklog/022](022-versioncontrol-plugin-build-from-sibling.md) (build),
  [worklog/021](021-was-plugin-discovery-integration.md) (license),
  [uniface-cli-and-build-hygiene](../.claude/rules/uniface-cli-and-build-hygiene.md),
  [protect-secrets-and-proprietary](../.claude/rules/protect-secrets-and-proprietary.md).
