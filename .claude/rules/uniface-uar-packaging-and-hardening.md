# Rule: Uniface UAR packaging & hardening

**Scope:** Producing a deployable **Uniface Archive (`.uar`)** from compiled objects, and
hardening it for release. Applies to any packaging/deploy step and to editing the `.asn`
settings that drive it. Verified against the Rocket Uniface Library 10.4
([webfetched/](../../webfetched/), "Create Uniface Archive Files" / "Certifying Uniface
Applications") and executed in [worklog/023](../../worklog/023-uar-packaging-methodology-and-hardening.md).

## What a UAR is

A `.uar` is a **ZIP of the compiled runtime objects in Uniface's standardized type-subdir
structure** (`svc/ frm/ sig/ edc/ …`). Compiling writes objects to `$RESOURCES_OUTPUT`;
if that's a **directory** you get a loose folder, if it's a **`.uar`** you get an archive.
Same objects, just packaged. **There is no one-click "Build UAR" button on a project** in
the IDE — pick a method below.

## Rule — how to build the UAR (pick one)

1. **Compile directly to a UAR** (IDE-native) — set `$RESOURCES_OUTPUT = .\path\Name.uar`
   in the `.asn`, (re)start, and compile (`/all` or targeted). Each UAR holds exactly what
   you compiled into it. Prefer this for a clean, from-source artifact.
2. **`urm copy`** — pack an already-compiled `resources\` folder without recompiling:
   `urm copy resources\*\* Name.uar:/*/*` (preserves the type subdirs). `urm.exe` lives in
   `<install>\common\bin`. Also `urm split` / `-after=YYYYMMDD` for incremental sets.
3. **`$ude("archive")`** (+ `$ude("lookup")`) — scriptable/CI builds; append object lists
   by type.
4. **Third-party ZIP** — ⚠️ last resort; you must reproduce the exact type-subdir
   structure or the runtime can't find resources.

## Rule — asn editing gotchas (cost a compile cycle if missed)

- **`[SETTINGS]` does NOT strip trailing `;` inline comments.** A comment after a value is
  swallowed into the value (e.g. `$resources_output .\X.uar   ; note` → Uniface tries to
  create a directory literally named `X.uar   ; note` and fails with *"Cannot create
  directory"*). Put comments on **their own line**; keep the value clean and ASCII.
- **Restart to apply** — `$RESOURCES_OUTPUT` is read at startup; a running IDE won't pick
  up an edit. When automating, edit → compile via CLI (IDE closed for the repo lock) →
  **revert the asn** so the sandbox/config stays pristine.
- **Quote spaced paths** as whole tokens ([quote-paths-with-spaces](quote-paths-with-spaces.md)).

## Rule — production build & hardening (release only)

- **Non-debuggable:** production compiles use **`/all /nodebug`**
  ([uniface-cli-and-build-hygiene](uniface-cli-and-build-hygiene.md)); never ship a
  debuggable/test-mode build.
- **Certify the archive against tampering — `cert.exe`.** Deployed UARs can be **certified
  with public/private key pairs**; the runtime then rejects a tampered archive (Library,
  "Certifying Uniface Applications"; errors in Uniface Messages 9000–9999). OpenSSL ships
  in `<install>\common\bin` for key/cert generation. This protects the **compiled
  objects**.
- **Encrypt asn secrets — `pathscrambler.exe`.** Scramble path definitions / logon strings
  in `[ENCRYPTED_PATHS]` (supports a `-seed` key + tamper digest). This protects
  **configuration**, not objects — pairs with
  [protect-secrets-and-proprietary](protect-secrets-and-proprietary.md).
- **Layering:** compile `/nodebug` → package `.uar` → **certify (`cert.exe`)** →
  scramble asn secrets → deploy.

## Why

The compile-vs-package split confuses newcomers (compile yields a folder, not a `.uar`);
the asn inline-comment behavior silently corrupts the output path; and shipping a
debuggable, uncertified archive with plaintext secrets is a real security regression.
These are all verified, avoidable footguns.

## How to apply

- Reach for **[/uniface-package-uar](../commands/uniface-package-uar.md)** (general) or,
  for the WAS plugin sandbox, **[/was-package](../commands/was-package.md)**.
- Certification/pathscrambler are **release-time** concerns — out of scope for the
  non-commercial WAS skill-refresh build, in scope for any client deliverable.
- Related: [uniface-cli-and-build-hygiene](uniface-cli-and-build-hygiene.md),
  [protect-secrets-and-proprietary](protect-secrets-and-proprietary.md),
  [uniface-repository-source-of-truth](uniface-repository-source-of-truth.md),
  [quote-paths-with-spaces](quote-paths-with-spaces.md).
