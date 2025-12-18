# Session Initialization Checklist for Claude

**READ THIS AT THE START OF EVERY SESSION**

This checklist ensures critical project knowledge is maintained across session boundaries and context compaction.

---

## Immediate Actions (Every Session)

If you see "This session is being continued from a previous conversation" or if context was compacted:

### 1. Core Philosophy (Read First)
- [ ] Re-read: `.claude/docs/CLI_PRIMER.md` - Development philosophy and testing requirements
- [ ] Re-read: `.claude/docs/SOCIAL_CONTRACT.md` - Team agreements and collaboration rules
- [ ] Re-read: `.claude/docs/DEVELOPMENT_WORKFLOW.md` - Workflow procedures

### 2. Current Context
- [ ] Check git status and current branch
- [ ] Review recent commits to understand current work
- [ ] Check for active work unit in `.claude/work-units/CURRENT.md`

### 3. Knowledge Anchors

**NEVER FORGET:**
- Tests are ALWAYS required with code changes
- Validate before pushing: tests pass + [YOUR CHECKS] clean
- Archive CURRENT.md before creating new work units
- Session compaction happens - re-read core docs when it does

**RED FLAGS (you've lost context if you do these):**
- Writing code without tests
- Skipping validation before pushing
- Overwriting CURRENT.md without archiving
- Not consulting CLI_PRIMER/SOCIAL_CONTRACT
- Making architectural decisions in implementation mode

---

## If You Detect Context Loss Mid-Session

Signs you've lost critical knowledge:
1. You're about to skip tests for a code change
2. You're about to push without validation
3. You're making architectural decisions in `/code` mode
4. You can't remember key project requirements
5. You're about to overwrite CURRENT.md without archiving

**Recovery:** Stop, re-run `/init`, resume work.

---

## Mode Awareness

**Check which mode you're in:**
- **`/arch` mode:** Planning and design, no code execution
- **`/analyze` mode:** Investigation and troubleshooting, full toolkit
- **`/code` mode:** Implementation and testing, full toolkit

**Mode boundaries exist for a reason.** Use the right mode for the task.

---

## Documents in This Directory

- **CLI_PRIMER.md** - Development philosophy, testing requirements, commit standards
- **SOCIAL_CONTRACT.md** - Team agreements, collaboration principles
- **DEVELOPMENT_WORKFLOW.md** - Branch strategy, validation checklist, work unit protocol
- **SESSION_INIT_CHECKLIST.md** - This document

---

## Notes for Future Sessions

Key facts about [YOUR PROJECT]:
- Uses [YOUR TEST FRAMEWORK] for testing
- Uses [YOUR LINTER] for style compliance
- [YOUR BRANCHING STRATEGY]
- [YOUR KEY CONVENTIONS]
- Documentation is referenced in decisions, not optional

If you're uncertain about any practice, check these documents first.

---

## Quick Reference

**Starting a new feature:**
1. `/arch` - Plan and create work unit
2. `/code` - Implement and test
3. Archive CURRENT.md when complete

**Investigating an issue:**
1. `/analyze` - Troubleshoot and experiment
2. Document findings
3. Either create work unit or provide analysis

**Making a quick fix:**
1. `/code` - Implement and test
2. Validate before push
3. Skip work unit if appropriate for simple changes

---

**Signed**: The Team (via Claude Code)
**Purpose**: Maintain development standards across session boundaries
**Last Updated**: [DATE]
