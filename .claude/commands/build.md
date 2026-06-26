---
description: Run the Uniface build scripts and report the result
argument-hint: "[optional: extra build target]"
allowed-tools: Bash(scripts/*.bat), Read
---

Build the Uniface project.

1. Run `scripts/setup-env.bat` to configure the environment.
2. Run `scripts/build.bat` $ARGUMENTS.
3. Summarize success/failure and surface any errors from the output.
