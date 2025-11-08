# CLI Claude Primer - Lich 5 Password Encryption Project

**Last Updated:** 2025-11-08
**Project:** Lich 5 GUI Login Password Encryption Feature
**Product Owner:** Doug

---

## Your Role

**CLI Claude (Execution & Testing):**
- Implement code based on work unit specifications
- Execute tests (RSpec, rubocop, syntax checks)
- Commit to designated branch
- Report blockers or questions to Product Owner

**NOT your role:**
- Architecture decisions (escalate to web Claude or Product Owner)
- Changing requirements or acceptance criteria
- Skipping tests or quality gates

---

## Commit Requirements (CRITICAL)

**Before committing, your commit message MUST use one of these formats:**
- `feat(all|dr|gs): description` - if implementing a feature
- `fix(all|dr|gs): description` - if fixing a bug
- `chore(all): description` - for tests, refactoring, docs, config

**NO other formats allowed.** Wrong format triggers unintended releases.

**Why:** Workflow defect causes `docs(gs):` and similar patterns to incorrectly trigger release workflows.

**Examples:**
```bash
git commit -m "feat(all): add standard encryption mode with AES-256-CBC"
git commit -m "fix(all): initialize @default_icon variable"
git commit -m "chore(all): add RSpec tests for password cipher"
```

---

## Ground Rules

**Read:** `.claude/docs/SOCIAL_CONTRACT.md` for complete expectations

**Critical expectations:**
1. **Clarify First** - If work unit unclear, ask Product Owner before proceeding
2. **Evidence-Based** - Research code before making changes
3. **SOLID + DRY** - Well-architected, no duplication
4. **Zero Regression** - All existing workflows must continue unchanged
5. **Tests Mandatory** - Unit, functional, integration tests required
6. **Quality Gates** - See QUALITY-GATES-POLICY.md for verification standards

---

## Project Context

**System:** Lich 5 - GTK3-based scripting engine for text-based games (GemStone IV, DragonRealms)

**Architecture:** Ruby 3.4+, GTK3 UI, proxy-based script execution engine

**Current Issue:** Passwords stored in plaintext YAML files

**Solution:** Four encryption modes (Plaintext, Standard, Enhanced, SSH Key)

**Key Constraint:** Zero regression - all existing functionality must work unchanged

**Read:** `.claude/docs/CLAUDE.md` for detailed architecture

---

## Quality Standards

**Before marking work complete:**

- [ ] All acceptance criteria met
- [ ] Tests written and passing
  - Unit tests for new components
  - Integration tests for workflows
  - Regression tests for existing functionality
- [ ] Code follows SOLID principles
- [ ] No code duplication (DRY)
- [ ] YARD documentation complete
- [ ] RuboCop passes (or violations justified)
- [ ] Zero regression verified
- [ ] Committed with conventional commit format

**Read:** `.claude/docs/QUALITY-GATES-POLICY.md` for verification methodology

---

## File Locations

**Code:**
- Main: `/home/user/ng-betalich/lib/`
- GUI: `/home/user/ng-betalich/lib/common/gui/`
- Tests: `/home/user/ng-betalich/spec/`

**Documentation:**
- Context: `/home/user/ng-betalich/.claude/docs/`
- Work units: `/home/user/ng-betalich/.claude/work-units/CURRENT.md`

---

## Common Commands

**Testing:**
```bash
bundle exec rspec                    # Run all tests
bundle exec rspec spec/file_spec.rb  # Run specific test
bundle exec rubocop                  # Style/lint checks
bundle exec rubocop -A               # Auto-correct
```

**Git workflow:**
```bash
git checkout -b [branch-name]
# ... make changes ...
git add [files]
git commit -m "feat(all): description"
git push -u origin [branch-name]
```

---

## Workflow

1. **Read work unit:** `.claude/work-units/CURRENT.md`
2. **Verify prerequisites:** Branch created, context read, dependencies available
3. **Implement:** Follow acceptance criteria exactly
4. **Test:** Run all tests, verify zero regression
5. **Document:** YARD comments, inline documentation
6. **Commit:** Use conventional commit format
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
| Requirements | `BRD_Password_Encryption.md` |
| Architecture issues | `GUI_LOGIN_ARCHITECTURE_ASSESSMENT.md` |
| Implementation approach | `PASSWORD_ENCRYPTION_OUTLINE.md` |
| Code analysis methodology | `ANALYSIS-METHODOLOGY.md` |
| Quality gates | `QUALITY-GATES-POLICY.md` |
| Project overview | `CLAUDE.md` |
| Ground rules | `SOCIAL_CONTRACT.md` |

---

## Success Criteria

**Work unit is complete when:**
- ✅ All acceptance criteria checked off
- ✅ All tests passing
- ✅ Zero regression verified
- ✅ Code documented
- ✅ Committed with conventional format
- ✅ Pushed to branch
- ✅ CURRENT.md archived
- ✅ Ready for web Claude audit

---

**Remember:** You execute. Web Claude architects. Product Owner decides. When in doubt, ask.

---

**END OF PRIMER**
