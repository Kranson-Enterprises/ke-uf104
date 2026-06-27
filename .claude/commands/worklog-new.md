---
description: Create the next sequential worklog/00X entry in the project's established format
argument-hint: "<short title>"
allowed-tools: Glob, Read, Write
---

Create the next worklog entry.

1. Glob `worklog/*.md`; find the highest `NNN` prefix. The new file is `NNN+1`,
   zero-padded to 3 digits: `worklog/<NNN+1>-<kebab-title>.md`.
2. Follow the established format (see worklog/004, worklog/005):
   - `# NNN <Title>`
   - **Date:** (absolute — convert any relative dates)
   - **Sequence:** one line linking the prior entries
   - **Basis:** what the entry is grounded in
   - confidence legend where relevant (✅ verified / 📘 docs / ⚠️ guidance)
   - body sections, an **Open items** section, and **References**
3. Title from $ARGUMENTS. Write the entry, then summarize what you created and
   offer to commit.
