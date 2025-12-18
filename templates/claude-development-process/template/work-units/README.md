# Work Units Directory

This directory contains work unit specifications - the handoff protocol between planning and implementation.

---

## Structure

```
work-units/
├── CURRENT.md    # The active work unit (create this when you have work)
└── archive/      # Completed work units
```

---

## CURRENT.md

**Purpose:** Single source of truth for "what I'm working on right now"

**Created by:** Architecture mode (`/arch`) or Product Owner

**Executed by:** Implementation mode (`/code`)

**Contains:**
- Feature/task description
- Acceptance criteria
- Context and constraints
- Technical notes
- References

---

## Workflow

### 1. Planning Phase (`/arch` mode)

Create `CURRENT.md` with specifications:

```markdown
# Work Unit: [Feature Name]

## Description
[What needs to be built]

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

## Context
[Why this matters, how it fits in the system]

## Technical Constraints
- [Constraint 1]
- [Constraint 2]

## References
- [Link to design doc]
- [Link to issue]
```

### 2. Implementation Phase (`/code` mode)

1. Read CURRENT.md
2. Implement according to acceptance criteria
3. Check off criteria as completed
4. When all criteria met, work unit is complete

### 3. Completion

**CRITICAL:** Archive CURRENT.md before creating new work unit

**Why:** Keeps CURRENT.md accurate, prevents GitHub search pollution, maintains history

**How:** See `docs/DEVELOPMENT_WORKFLOW.md` for your project's archive approach

---

## Archive Directory

Store completed work units here using your preferred organization:

**Date-based:**
```
archive/
├── 2025-01-15-user-authentication.md
├── 2025-01-16-password-reset.md
└── 2025-01-20-profile-settings.md
```

**Feature-based:**
```
archive/
├── user-management/
│   ├── authentication.md
│   ├── password-reset.md
│   └── profile-settings.md
└── reporting/
    ├── dashboard.md
    └── export.md
```

**Or:** Don't keep files, rely on git history (commit CURRENT.md before deleting)

---

## When to Use Work Units

**Use for:**
- Complex features with multiple components
- Changes requiring architectural decisions
- Tasks with unclear requirements (force clarification)
- Anything that needs handoff between planning and implementation

**Optional for:**
- Simple bug fixes
- Documentation updates
- Style/lint fixes
- Single-file trivial changes

**Customize:** Define your criteria in `DEVELOPMENT_WORKFLOW.md`

---

## Tips

**Good work units:**
- Clear, specific acceptance criteria
- Provide context (why, not just what)
- Include constraints and edge cases
- Reference relevant docs/issues
- Testable criteria (you know when you're done)

**Bad work units:**
- Vague requirements ("make it better")
- No acceptance criteria
- Assume knowledge not captured
- Missing constraints
- Unclear completion state

---

**Remember:** The work unit is a contract. Make it clear enough that implementation mode (or another person) can execute it without guessing.
