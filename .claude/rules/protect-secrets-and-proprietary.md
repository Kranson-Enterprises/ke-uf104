# Rule: keep secrets and proprietary content out of version control

**Scope:** All commits, `.asn`/config files, saved documentation, and memory.

## Rule

- **Never commit credentials or certificates.** DB passwords, connection secrets,
  and cert files must not appear in `.asn` (or anywhere) in version control.
  Externalize them — inject at deploy — and use **`pathscrambler.exe`** to obscure
  values that must live in an `.asn`.
- **Sanitize `.asn` before committing** — keep one per environment, secret-free, so
  dev/test/prod differences stay diff-able.
- **Keep Rocket proprietary docs local.** Saved Uniface documentation is "Rocket
  proprietary and confidential, furnished under license" — it lives only in the
  gitignored `webfetched/` folder and must never be committed or published.
- **Personal memories stay local** in the gitignored `.claude/memory/`. Never put
  secrets in memory either.

## Why

Licensing (proprietary docs), security (credentials), and privacy (memory). A leak
into Git history is hard to undo, and pushing licensed content is a license breach.

## How to apply

- **Before committing, scan `git status`/`git diff`.** If anything under
  `webfetched/` or `.claude/memory/`, or a credential/secret, is staged, **stop**
  and fix it — don't commit.
- Stage files **explicitly** for scoped commits rather than blanket `git add -A`
  when sensitive or unrelated files are present.
- Related: [quote-paths-with-spaces.md](quote-paths-with-spaces.md),
  [uniface-cli-and-build-hygiene.md](uniface-cli-and-build-hygiene.md).
