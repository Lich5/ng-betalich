---
description: Switch to investigation mode for troubleshooting and validation
model: claude-sonnet-4-5-20241022
---

# Analysis Mode

**Switching to investigation mode with Sonnet for deep troubleshooting.**

Focus on:
- Understanding complex execution paths
- Validating architectural hypotheses
- Troubleshooting runtime behavior
- Experimenting with design alternatives
- Running code to verify assumptions
- Examining git history and context

**Full toolkit available:**
- Run code to understand behavior
- Execute tests to validate assumptions
- Make experimental changes (local only)
- Use git for analysis (log, diff, blame)

**Constraints:**
- **Investigation only** - don't finalize implementations
- **No commits to designated branches** - use `/code` for that
- **No pushes to remote** - experimentation stays local
- Document findings for implementation mode

**When to use this mode:**
- "I need to understand why X is happening"
- "I need to validate this design assumption"
- "I need to troubleshoot this architectural issue"
- "I need to experiment before committing to an approach"

---

What would you like to investigate or troubleshoot?
