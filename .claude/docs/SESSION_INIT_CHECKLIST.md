# Session Initialization Checklist for Claude

**READ THIS AT THE START OF EVERY SESSION**

This checklist ensures critical project knowledge is maintained across session boundaries and context compaction.

## Immediate Actions (Every Session)

If you see "This session is being continued from a previous conversation" or if context was compacted:

### 1. Core Philosophy (Read First)
- [ ] Re-read: `.claude/docs/CLI_PRIMER.md` - Development philosophy and testing requirements
- [ ] Re-read: `.claude/docs/SOCIAL_CONTRACT.md` - Team agreements and collaboration rules
- [ ] Re-read: `.claude/docs/DEVELOPMENT_WORKFLOW.md` - Workflow procedures (this repo's practices)

### 2. Current Context
- [ ] Check git status and current branch
- [ ] Review recent commits to understand current work
- [ ] Identify which improvement branches are in progress

### 3. Knowledge Anchors

**NEVER FORGET:**
- Specs are ALWAYS required with code changes
- Branch layering is critical - don't merge unnecessary files
- Validate before pushing: specs pass + rubocop clean
- Session compaction happens - re-read core docs when it does

**RED FLAGS (you've lost context if you do these):**
- Writing code without specs
- Skipping rubocop/spec validation before pushing
- Merging files that aren't direct dependencies
- Not consulting CLI_PRIMER/SOCIAL_CONTRACT

## If You Detect Context Loss Mid-Session

Signs you've lost critical knowledge:
1. You're about to skip specs for a code change
2. You're merging unnecessary files into a branch
3. You're pushing without full validation
4. You can't remember key project requirements

**Recovery**: Stop, re-read the three core documents above, resume work.

## Documents in This Directory

- **CLI_PRIMER.md** - Test-before-develop philosophy, testing requirements
- **SOCIAL_CONTRACT.md** - Team agreements, collaboration principles
- **DEVELOPMENT_WORKFLOW.md** - Specific procedures for this repository
- **SESSION_INIT_CHECKLIST.md** - This document

## Notes for Future Sessions

Key facts about ng-betalich:
- Uses RSpec for testing (test-before-develop)
- Uses Rubocop for style compliance
- PRs are layered: PR81 → PR82 → improvements
- Specs and code must be validated together
- Documentation is referenced in decisions, not optional

If you're uncertain about any practice, check these documents first.

---

**Signed**: The Team (via Claude Code)
**Purpose**: Maintain development standards across session boundaries
**Last Updated**: [When this file was created]
