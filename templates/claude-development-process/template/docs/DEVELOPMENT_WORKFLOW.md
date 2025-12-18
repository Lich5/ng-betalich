# Development Workflow

## Philosophy

This project follows **test-before-develop** methodology with **quality gates at boundaries**.

All work must be:
- Spec-complete before validation
- Validated (tests + [YOUR CHECKS]) before any push
- Documented according to project standards

---

## Branch Strategy

**Customize this section for your branching model:**

[YOUR BRANCHING STRATEGY]

Examples:
- Git Flow (main, develop, feature/, hotfix/, release/)
- GitHub Flow (main, feature branches)
- Trunk-based development
- Custom strategy

**Key Principle:** [YOUR PRINCIPLE - e.g., "Always branch from develop", "Keep branches short-lived", etc.]

---

## Work Units

### CURRENT.md - The Active Work Unit

**Location:** `.claude/work-units/CURRENT.md`

**Purpose:**
- Single source of truth for "what I'm working on right now"
- Handoff protocol between planning and implementation
- Contains: specifications, acceptance criteria, context, constraints

### Archiving Work Units

**CRITICAL:** Archive completed work units before creating new ones.

**Why this matters:**
- Keeps CURRENT.md accurate (always shows active work)
- Prevents GitHub searches from surfacing stale/completed tasks
- Maintains clean project history

**How to archive:** [YOUR APPROACH - examples below]

**Examples:**
```bash
# Option 1: Date-based
mv .claude/work-units/CURRENT.md .claude/work-units/archive/2025-01-15-feature-name.md

# Option 2: Feature-based
mv .claude/work-units/CURRENT.md .claude/work-units/archive/feature-name/work-unit.md

# Option 3: Git-based (commit and delete, rely on git history)
git add .claude/work-units/CURRENT.md
git commit -m "chore: complete work unit for feature X"
rm .claude/work-units/CURRENT.md
```

**Choose the approach that fits your team's organization style.**

---

## Pre-Push Validation Checklist

**BEFORE EVERY PUSH:**

- [ ] Tests written for all code changes
- [ ] Tests pass ([YOUR TEST COMMAND])
- [ ] [YOUR LINTER] clean (no violations)
- [ ] [OTHER CHECKS: e.g., type checking, security scanning]
- [ ] Only necessary files included in commit
- [ ] Commit messages follow [YOUR CONVENTION]
- [ ] [YOUR DOCUMENTATION STANDARD] complete
- [ ] `git status` shows clean working tree (or only intended changes)

---

## Test Requirements

Tests are **ALWAYS** required:
- [Test type 1] per [what warrants this test type]
- [Test type 2] per [what warrants this test type]
- Tests must be committed with code changes

### When Tests Can't Run in Isolation

Some changes can't run tests standalone due to dependencies. This is acceptable IF:
1. You've validated tests would pass with dependencies available
2. You've documented the dependency
3. The dependency will be satisfied in the actual environment

---

## Code Review & Quality Gates

Every change must pass:
1. **[YOUR TEST FRAMEWORK]** - All tests passing
2. **[YOUR LINTER]** - Style compliance
3. **Logical validation** - Code follows project patterns from CLI_PRIMER and SOCIAL_CONTRACT

---

## Session Continuity

This document is your foundation. If you detect session compaction or context loss:
1. Re-read CLI_PRIMER (development philosophy)
2. Re-read SOCIAL_CONTRACT (team agreements)
3. Re-read this document (workflow procedures)
4. Reference them explicitly in decisions

**Signs of session loss:**
- Forgetting to include tests with code changes
- Skipping validation before pushing
- Not consulting known project documentation
- Forgetting to archive CURRENT.md before creating new work unit

---

## Common Patterns

### Creating a Feature Branch

```bash
# Customize for your branching strategy
git checkout -b feature/[name] [base-branch]
# Make changes
# Add tests
git add [files]
git commit -m "[your convention]"
# Validate (tests + linter)
git push -u origin feature/[name]
```

### Commit Message Format

```
[YOUR CONVENTION]
```

**Examples:**
```
# Customize these examples
feat: add user authentication
fix: resolve login timeout
chore: update dependencies

# Or if you use ticket numbers:
PROJ-123: implement user search
PROJ-124: fix pagination bug
```

---

## Mode-Specific Workflows

### Planning Mode (`/arch`)
1. Research existing architecture
2. Design approach
3. Create work unit in `.claude/work-units/CURRENT.md`
4. Define acceptance criteria
5. Hand off to implementation mode

### Investigation Mode (`/analyze`)
1. Reproduce issue or validate hypothesis
2. Experiment locally
3. Document findings
4. Either: create work unit for fix, or provide analysis

### Implementation Mode (`/code`)
1. Read work unit from CURRENT.md
2. Implement according to specifications
3. Write tests
4. Validate (tests + [YOUR CHECKS])
5. Commit and push
6. Archive CURRENT.md

---

## References

- **CLI_PRIMER** - Core development philosophy and testing strategy
- **SOCIAL_CONTRACT** - Team agreements and collaboration principles
- **SESSION_INIT_CHECKLIST** - Context recovery protocol

---

## Customization Notes

**This template should be adapted to your team's workflow.**

Update:
- Branch strategy section with your branching model
- Test requirements with your testing approach
- Pre-push checklist with your quality gates
- Commit format with your convention
- Archive approach with your preferred method

**The principles matter more than the specific format.**
