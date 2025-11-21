# ADR: Unified Standard+Enhanced PR Instead of Decomposition

**Date:** 2025-11-12
**Status:** Accepted
**Session:** Web Claude - Landscape Re-evaluation
**Decision Makers:** Product Owner (Doug), Web Claude

---

## Context

Previous session (011C) decomposed PR #38 (monolithic password encryption implementation) into 5 sequential PRs:
- PR-Standard (Standard mode extraction)
- PR-Enhanced (Enhanced mode extraction)
- PR-SSH (SSH Key mode)
- Fix-MasterPassword (Password change UI)
- Fix-SSHKey (SSH key change UI)

**Problem discovered:** Extraction approach created gaps. Early PRs (Standard, Enhanced) were missing dependencies when isolated from PR #38. Audits did not catch gaps until after work units were created.

**Root cause:** Standard and Enhanced modes are not cleanly separable in PR #38:
- Both depend on shared `PasswordCipher` module
- Both depend on `MasterPasswordManager` (keychain integration)
- Both are integrated into `YamlState` save/load workflow
- Both share encryption mode selection UI in `ConversionUI`

Attempting to extract incrementally introduced error-prone duplication and missed dependencies.

---

## Decision

**Move from 5-PR decomposition to unified 1-PR approach:**

1. **Phase 1 (Standard + Enhanced combined):** Copy all relevant files from PR #38 into single feature branch
   - Branch name: `feat/password-encryption-standard`
   - Starting point: `eo-996` (PR 7, YAML foundation)
   - Execution: Simple file copy (`git show feat/password_encrypts:FILE > FILE`)
   - Verification: All tests pass, diff validates against PR #38
   - Result: Single, complete, testable PR

2. **Phase 2 (SSH Key mode):** Separate PR (Phase 2) branching from Phase 1 result
3. **Phase 3 (Management UIs):** Fix PRs as needed

---

## Rationale

### Why This Works Better

| Aspect | 5-PR Decomposition | 1-Unified PR |
|--------|-------------------|--------------|
| **Extraction Logic** | Surgical, error-prone | None—copy entire delta |
| **Dependency Management** | Requires careful separation | All dependencies included |
| **Audit Confidence** | Gaps discovered after execution | Verifiable against PR #38 |
| **Feature Completeness** | Partial modes per PR | Complete mode per PR |
| **Review Scope** | Smaller PRs (easier to review) | Larger PR (complete feature) |
| **Testing** | Incremental mode testing | Full encryption testing |

### Why Extraction Failed

- Standard mode alone is incomplete without keychain infrastructure
- Enhanced mode can't be isolated without Standard mode's cipher logic
- Both depend on shared YAML integration
- Monolithic PR #38 doesn't have clean boundaries to extract along

### Why Copy Works

- PR #38 already has working implementation + tests
- No logic complexity—just file duplication
- Verifiable: diffs must match PR #38 source
- GitHub runners will validate all tests pass
- Natural dependencies preserved automatically

---

## Implications

### Adoption

**Phase 1 (Standard + Enhanced):**
- Single 3,500+ line feature PR
- Complete encryption foundation
- Fully testable independently
- Clear before/after state

**Phase 2 (SSH Key):**
- Branches from Phase 1 result
- Adds SSH Key encryption mode
- Adds CLI support
- Separate, focused PR

**Phase 3 (Management UIs):**
- Password change workflows
- Master password change workflow
- SSH key change workflow
- Fix PRs as needed

### Risks Mitigated

| Risk | Mitigation |
|------|-----------|
| Large PR hard to review | Single feature (encryption foundation) is naturally cohesive |
| Feature incomplete across PRs | Phase 1 is complete (both modes work) |
| Extraction gaps | No extraction—file copy is verifiable |
| Test coverage gaps | All 380+ tests run before merge |

### Timing

- **Faster to production:** No intermediate PRs, single review cycle for Phase 1
- **Simpler orchestration:** Three logical phases instead of five sequential PRs
- **Clear dependencies:** Phase 2 depends on Phase 1, Phase 3 on Phase 2

---

## Alternatives Considered

### Alternative 1: Keep 5-PR Decomposition, Fix Gaps
- Pros: Smaller review units
- Cons: Requires rework on already-created work units; still error-prone extraction logic
- **Rejected:** Complexity not justified by smaller review scope

### Alternative 2: Wait for PR #38 to be Reviewed, Then Extract
- Pros: Review feedback would inform extraction
- Cons: Delays Phase 1 execution; still requires extraction logic
- **Rejected:** Adds delay without solving extraction problem

### Alternative 3: Use PR #38 As-Is (No Decomposition)
- Pros: No work needed
- Cons: Monolithic PR too large to review
- **Rejected:** Original requirement was to decompose for review manageability

---

## Status & Next Steps

**Status:** ✅ Accepted - Unified PR approach in effect

**Execution:**
- ✅ Work unit created: STANDARD_AND_ENHANCED_UNIFIED.md (simple file copy approach)
- ⏳ CLI Claude executes Phase 1 (copy files, run tests, push)
- ⏳ GitHub runners validate all tests pass
- ⏳ Product Owner reviews unified PR
- ⏳ Merge and proceed to Phase 2

**Preserved for Future Use:**
- SSH_KEY_CURRENT.md (Phase 2 work unit - to be updated)
- MASTER_PASSWORD_CHANGE_CURRENT.md (Phase 3 work unit - to be updated)
- SSH_KEY_CHANGE_CURRENT.md (Phase 3 work unit - to be updated)

---

## Conclusion

The unified Standard+Enhanced PR is simpler, more verifiable, and less error-prone than extraction-based decomposition. It preserves complete feature functionality while providing a clear, testable unit of work. GitHub runners will validate correctness before any human review is required.

