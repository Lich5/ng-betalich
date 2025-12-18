# Claude Development Primer

**Last Updated:** [DATE]
**Project:** [YOUR PROJECT NAME]
**Product Owner:** [YOUR NAME/TEAM]

---

## Your Role

**Claude (Execution & Testing):**
- Implement code based on work unit specifications
- Execute tests ([YOUR TEST FRAMEWORK])
- Commit to designated branches
- Report blockers or questions to Product Owner

**NOT your role:**
- Architecture decisions (escalate to Product Owner or use `/arch` mode)
- Changing requirements or acceptance criteria
- Skipping tests or quality gates

---

## Commit Requirements

**Before committing, your commit message MUST follow this format:**

```
[YOUR COMMIT CONVENTION]
```

**Examples:**
```bash
# Customize these examples for your convention
git commit -m "feat: add user authentication"
git commit -m "fix: resolve login timeout issue"
git commit -m "chore: update dependencies"
```

**Why:** [Explain why your convention matters - release automation, changelog generation, etc.]

---

## Ground Rules

**Read:**
- `.claude/docs/SOCIAL_CONTRACT.md` for complete expectations
- `.claude/docs/DEVELOPMENT_WORKFLOW.md` for branch strategy, testing procedures, and pre-push validation

**Critical expectations:**
1. **Clarify First** - If work unit unclear, ask Product Owner before proceeding
2. **Evidence-Based** - Research code before making changes
3. **Well-Architected** - Follow SOLID principles, avoid duplication (DRY)
4. **Zero Regression** - All existing workflows must continue unchanged
5. **Tests Mandatory** - [YOUR TEST TYPES: unit, functional, integration, etc.]
6. **Quality Gates** - See QUALITY-GATES section below

---

## Project Context

**System:** [YOUR PROJECT DESCRIPTION]

**Architecture:** [YOUR TECH STACK AND KEY ARCHITECTURAL PATTERNS]

**Current Focus:** [CURRENT PROJECT PHASE OR PRIORITIES]

**Key Constraint:** [YOUR KEY CONSTRAINTS - e.g., zero regression, backward compatibility, etc.]

---

## Quality Standards

**Before marking work complete:**

- [ ] All acceptance criteria met
- [ ] Tests written and passing
  - [Test type 1: e.g., Unit tests for new components]
  - [Test type 2: e.g., Integration tests for workflows]
  - [Test type 3: e.g., Regression tests for existing functionality]
- [ ] Code follows [YOUR ARCHITECTURE PRINCIPLES]
- [ ] No code duplication (DRY)
- [ ] [YOUR DOCUMENTATION STANDARD: e.g., JSDoc, YARD, docstrings]
- [ ] [YOUR LINTER: e.g., ESLint, RuboCop, Black] passes
- [ ] Zero regression verified
- [ ] Committed with proper format

---

## File Locations

**Customize these paths for your project:**

**Code:**
- Main: `/path/to/your/source/`
- [Component type 1]: `/path/to/component1/`
- Tests: `/path/to/your/tests/`

**Documentation:**
- Context: `/.claude/docs/`
- Work units: `/.claude/work-units/CURRENT.md`

---

## Common Commands

**Testing:**
```bash
# Customize these for your test framework
npm test                    # Run all tests
npm test path/to/test       # Run specific test
npm run lint                # Linting
npm run lint:fix            # Auto-fix linting issues
```

**Git workflow:**
```bash
git checkout -b [branch-name]
# ... make changes ...
git add [files]
git commit -m "[your convention]"
git push -u origin [branch-name]
```

---

## Workflow

1. **Read work unit:** `.claude/work-units/CURRENT.md`
2. **Verify prerequisites:** Branch created, context read, dependencies available
3. **Implement:** Follow acceptance criteria exactly
4. **Test:** Run all tests, verify zero regression
5. **Document:** [Your documentation standard]
6. **Commit:** Use proper commit format
7. **Push:** To designated branch
8. **Report:** Complete or blockers

---

## If You Get Blocked

**Ask Product Owner:**
- Unclear requirements or acceptance criteria
- Ambiguous architectural decisions
- Trade-offs between approaches
- Edge cases not covered in work unit

**Template:**
```
Blocker: [Brief description]
Context: [What you were trying to do]
Options considered: [A, B, C]
Recommendation: [Your suggestion]
Question: [Specific question for Product Owner]
```

---

## Reference Documents

| Topic | Document |
|-------|----------|
| Ground rules | `SOCIAL_CONTRACT.md` |
| Development workflow | `DEVELOPMENT_WORKFLOW.md` |
| Session initialization | `SESSION_INIT_CHECKLIST.md` |

---

## Success Criteria

**Work unit is complete when:**
- ✅ All acceptance criteria checked off
- ✅ All tests passing
- ✅ Zero regression verified
- ✅ Code documented
- ✅ Committed with proper format
- ✅ Pushed to branch
- ✅ CURRENT.md archived (see DEVELOPMENT_WORKFLOW.md)
- ✅ Ready for review

---

**Remember:** Execute carefully. Plan in `/arch` mode. Investigate in `/analyze` mode. When in doubt, ask.

---

**END OF PRIMER**
