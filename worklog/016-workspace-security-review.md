# 016 Workspace security review + Uniface security-review subagent

**Date:** 2026-06-30
**Sequence:** … → 014 (naming/trigger/endpoint) → 015 (PowerShell security) →
**016 (workspace security review)**.
**Purpose:** Run a **full-workspace security review** (the built-in `/security-review`
is diff-based and aborted — no `origin/HEAD` ref) to find leaks/risks to mitigate before
going further, and build a **Uniface-specific security-review subagent** for repeatable
audits. Repo confirmed **private**.
Confidence: ✅ verified by inspection of tracked files + git history.

---

## 1. Scope & method

66 tracked files. Checked: git remote/push state, full-history file scan
(`git log --all --diff-filter=A`), secret-pattern grep across tracked content,
`git check-ignore` on sensitive paths, and manual review of `business/`, the CI
workflow, scripts, the sample component, install/workspace files, and the PowerShell
hooks + Claude config.

## 2. Findings (severity-ranked)

### MEDIUM — Client-confidential content & third-party PII committed (and pushed)
Three `business/` handoff notes (added in commit `badc00d`, **present in `origin/main`**
→ on GitHub) contained client-confidential material: a **named client** and named
individuals, **third-party email addresses (PII)**, internal architecture (DBMS, CI/CD
pipeline, deployment tooling), team / PR-approver process, and a **commercial figure**. A
second note added more client environment/architecture detail; a third was a generic,
low-sensitivity outline. *(The specifics are deliberately omitted here — that confidential
content is exactly what this remediation purges; do not re-introduce it into any tracked
file.)*
- **Repo is private**, which downgrades this from a public leak to *confidential data on
  an access-controlled code host* — but **private ≠ safe**: it can be shared/forked/made
  public, third-party PII still sits on GitHub, and it may breach a client confidentiality
  obligation. Working-tree removal does **not** purge it from history/GitHub.
- **Fix (needs human decision):** decide whether `business/` belongs in this tooling repo
  at all. Options: (a) keep as-is (accept, private + access-controlled); (b) **untrack +
  gitignore** going forward (non-destructive; history retains it); (c) **purge from
  history** (`git filter-repo`) + force-push (destructive, outward-facing — confirm).

### LOW — Inert misnamed `gitignore` file
A tracked lowercase **`gitignore`** (no dot) duplicates only the generic top of
`.gitignore` and does nothing. Harmless but misleading (could imply ignores are active).
**Fix:** remove it (`git rm gitignore`).

### LOW — Runtime artifacts in history
`uniface/project/dbms/usys.db` (SQLite repo DB) and `ide_state.zip` were committed
historically. **Not in `origin/main`** and now gitignored, but they persist in history.
Low sensitivity (no credentials). **Fix:** optional history cleanup; otherwise no action.

### LOW — CI workflow hardening
[.github/workflows/ci.yml](../.github/workflows/ci.yml) has **no least-privilege
`permissions:` block** and pins actions by tag (`actions/checkout@v4`) not SHA. It uses
`pull_request` (not `pull_request_target`) and references no secrets, so untrusted-PR risk
is low. **Fix:** add `permissions: contents: read`; optionally pin to SHA.

### INFO — Local path/identifiers in `install_info.txt`
Exposes a local user path (`C:\Users\Bob\…`) and a Windows uninstall GUID. Intentionally
tracked as an install baseline; negligible risk. No action.

## 3. What's clean (verified)

- **No credentials/keys ever committed** — no `.asn`, `.env`, `.pem/.pfx/.key`, no
  connection strings or tokens in tracked files or history (secret-grep hits were all the
  word "secret" in rule/guidance text).
- **gitignore is effective** — `webfetched/` (Rocket-proprietary), `.claude/memory/`,
  `.claude/settings.local.json`, `dbms/`, `ide_state.zip` all confirmed IGNORED and not
  tracked.
- **Scripts** ([setup-env.bat](../scripts/setup-env.bat), [build.bat](../scripts/build.bat))
  — no secrets, paths quoted as whole tokens, args are operator-supplied (no injection).
- **PowerShell hooks** — read stdin defensively, never `iex`; the preflight's network
  call is opt-in/pinned/timed-out/fail-silent; `-NoProfile`; `-ExecutionPolicy Bypass`
  covered by [powershell-hook-security](../.claude/rules/powershell-hook-security.md)
  (review is the control).
- **Claude config** — `settings.json` allowlist is minimal (Read/Glob/Grep/git
  status·diff·log); `settings.local.json` is gitignored and benign.
- **`sample_component.com`** — placeholder, no secrets.

## 4. Authored this pass

- **[.claude/agents/uniface-security-reviewer.md](../.claude/agents/uniface-security-reviewer.md)**
  — a workspace+Uniface-specific, **read-only** security-review subagent (secrets, client-
  confidential/PII, Rocket-proprietary, runtime artifacts, gitignore integrity, hooks/
  scripts, GitHub remote/CI, Claude config). It proposes fixes and **never** rewrites
  history or pushes.
- **Client-confidential & PII clause** added to
  [protect-secrets-and-proprietary](../.claude/rules/protect-secrets-and-proprietary.md).

## 5. Decision & remediation

**`business/` — decision: purge from history + force-push** (operator-chosen, repo
private). Executed this pass:
1. Full backup bundle (`--all`) + copy of the `business/` files preserved off-repo.
2. `business/` removed from **all** history via `git filter-repo --path business/
   --invert-paths` (rewrites every commit/ref; SHAs change).
3. `business/` files **restored locally as untracked** and added to `.gitignore` (kept on
   disk, never tracked again).
4. `origin` re-added; **`main` force-push prepared but NOT executed here** — this shell has
   no GitHub SSH key (`Permission denied (publickey)`). The operator runs it from an
   authenticated terminal:
   `git push --force-with-lease=main:badc00dd8690295c923f4007813954c288f2188f origin main`
   (the lease aborts if `origin/main` is no longer `badc00d`). After it lands, `origin/main`
   = `09f01df` and `business/` is gone from GitHub. Verified locally: `business/` absent
   from all history, files present + gitignored, no confidential tokens in any tracked file.

> Note: force-push rewrites shared history — any other clone of `main` must reset/re-clone.
> Residual: already-cloned copies and GitHub cached/PR refs may retain `badc00d` until GC;
> private repo + confidential-not-credential content makes this typically acceptable. The
> pre-purge bundle (off-repo) is the recovery point.
>
> **Merge-then-push footgun (operator deferred the push to post-review/merge):** local
> `main` (`09f01df`, purged) and `origin/main` (`badc00d`, still has `business/`) have
> **divergent history**. (1) After merging `feature` into `main`, the push to `origin`
> will be **non-fast-forward → requires `--force-with-lease`** (a plain push is rejected;
> that's expected). (2) **Do NOT `git pull`/merge `origin/main` into local** — it would
> **resurrect `business/`**. Overwrite the remote via force-push; don't pull from it.

### Remaining (lower) actions
- ✅ Removed the inert `gitignore` (commit `5d5cd4a`).
- ✅ Added `permissions: contents: read` to `ci.yml` (commit `5d5cd4a`).
- (Optional) history cleanup of `usys.db`/`ide_state.zip` — low value, deferred.

## References
- In-repo: the new subagent + rule clause; [015](015-powershell-security-and-preflight.md),
  [protect-secrets-and-proprietary](../.claude/rules/protect-secrets-and-proprietary.md).
