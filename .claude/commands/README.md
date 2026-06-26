# Project slash commands

Each `*.md` file here becomes a `/command` available in this project. The file
body is the prompt; optional frontmatter sets `description`, `argument-hint`,
and `allowed-tools`. Use `$ARGUMENTS` (or `$1`, `$2`, ...) for args, and prefix
a line with `!` to run a shell command whose output is injected.

See [build.md](build.md) for a working example (`/build`).
