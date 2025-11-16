# Integration Testing Guide

**Purpose:** Multi-branch integration validation methodology for Lich 5 development
**Audience:** Web Claude, CLI Claude, Product Owner
**Last Updated:** 2025-11-16

---

## Overview

This guide documents the **ephemeral test branch methodology** for validating multi-branch feature integrations before beta/production release.

**Key Principle:** Test the integration of multiple feature branches in a sandboxed environment without affecting branch structure or review workflow.

---

## When to Use Integration Testing

### Required For

✅ **Multi-branch features** (3+ branches that must merge together)
- Example: Password encryption (6 branches)
- Example: UI refactors spanning multiple components

✅ **Pre-beta validation** (before user testing)
- Verify all branches merge cleanly
- Validate end-to-end integration
- Catch dependency issues early

✅ **Complex dependency chains**
- Branch A depends on Branch B depends on Branch C
- Need to verify layered architecture works

✅ **Major architectural changes**
- New module systems
- Refactored core components
- Cross-cutting concerns

### Optional For

⚠️ **Single-branch features** (usually don't need integration testing)
- Unit tests and PR review sufficient

⚠️ **Independent features** (no cross-branch dependencies)
- Can be tested in isolation

---

## The Methodology

### Product Owner's Workflow (Manual Testing)

This is the established process for smoke/integration testing:

```bash
# 1. Fresh clone (or clean workspace)
git fetch origin

# 2. Create ephemeral testing branch (not retained)
git checkout -b test-integration-YYYY-MM-DD origin/main

# 3. Merge PRs in correct sequence
git fetch origin pull/XX/head:refs/heads/pr-XX && git merge pr-XX
# Repeat for each PR in dependency order

# 4. Run specs and validate
bundle exec rspec

# 5. Run smoke tests and integration tests
# Manual testing, playability testing, etc.

# 6. Clean up
git checkout main
git branch -D test-integration-YYYY-MM-DD
```

### Web Claude's Adaptation

Web Claude follows the same process but:
- Uses **branch names** instead of PR numbers (simpler in sandbox)
- Creates **automated integration tests** (in addition to RSpec)
- **Documents results** in standardized report format
- Cannot test GTK UI (no X11), focuses on crypto/logic/API integration

```bash
# 1. Fetch all branches
git fetch origin

# 2. Create ephemeral test branch
git checkout -b test-integration-YYYY-MM-DD origin/main

# 3. Sequential merge (in dependency order)
git merge origin/branch-1 --no-edit
git merge origin/branch-2 --no-edit
git merge origin/branch-3 --no-edit
# ... etc

# 4. Run comprehensive test suite
bundle exec rspec spec/

# 5. Create and run custom integration tests
# (see "Custom Integration Tests" section below)

# 6. Document results
# (see "Test Report Template" section below)

# 7. Clean up
git checkout <working-branch>
git branch -D test-integration-YYYY-MM-DD
```

---

## Determining Merge Order

### Dependency Chain Analysis

**Step 1:** Identify branch lineage
```
main → base-refactor → feature-core → feature-tests → feature-enhancement
```

**Step 2:** Document dependencies
- Which branch was created from which?
- Which modules call which other modules?
- Which features build on other features?

**Step 3:** Merge in dependency order
- Base branches first
- Dependent branches second
- Independent branches last

### Example: Password Encryption (6 Branches)

**Lineage:**
```
main → eo-996 → feat/password-encryption-core →
  feat/password-encryption-tests-phase1-2 →
  feat/windows-credential-manager →
  feat/change-master-password

main → feat/cli-password-manager (independent)
```

**Merge Order:**
1. `eo-996` (base YAML refactor)
2. `feat/password-encryption-core` (crypto modules)
3. `feat/password-encryption-tests-phase1-2` (test suite)
4. `feat/windows-credential-manager` (OS keychain)
5. `feat/change-master-password` (GUI feature)
6. `feat/cli-password-manager` (CLI feature - depends on crypto)

**Rule:** Independent branches go **last** (they depend on earlier branches but nothing depends on them)

---

## Custom Integration Tests

### When to Create Custom Tests

**Create custom integration tests when:**
- Real module integration needs validation (not just mocks)
- API compatibility between modules needs verification
- Crypto/security algorithms need cross-module testing
- Data format compatibility needs validation

**Don't create custom tests when:**
- RSpec suite already covers integration
- Single module being tested
- Pure logic with no cross-module calls

### Example: CLI ↔ GUI Crypto Integration Test

**File:** `test_cli_gui_integration.rb`

**Purpose:** Verify CLI password manager can encrypt/decrypt with real GUI crypto modules (not mocks)

**Tests:**
1. Standard encryption (AES-256-CBC with account-name key)
2. Enhanced encryption (AES-256-CBC with master password)
3. PBKDF2 validation (100k iterations)
4. YAML serialization round-trip

**Structure:**
```ruby
#!/usr/bin/env ruby
require_relative 'lib/common/gui/password_cipher'
require_relative 'lib/common/gui/master_password_manager'

# Test 1: Encrypt with CLI, decrypt with GUI
plaintext = "test"
encrypted = PasswordCipher.encrypt(plaintext, mode: :standard, account_name: "TEST")
decrypted = PasswordCipher.decrypt(encrypted, mode: :standard, account_name: "TEST")

if decrypted == plaintext
  puts "✅ PASS"
else
  puts "❌ FAIL"
  exit 1
end

# Test 2, 3, 4...
```

**Location:** Place in repo root (temporary, not committed unless useful for future)

**Output:** Clear pass/fail results for manual review

---

## Test Report Template

### File Naming Convention

`.claude/docs/INTEGRATION_TEST_REPORT_YYYY_MM_DD.md`

### Report Structure

```markdown
# Integration Test Report: [Feature Name]

**Date:** YYYY-MM-DD
**Tester:** Web Claude / Product Owner / CLI Claude
**Test Branch:** test-integration-YYYY-MM-DD (ephemeral, deleted after testing)
**Method:** Sequential merge testing

---

## Executive Summary

[Overall result: pass/fail, key findings]

---

## Test Methodology

### Sequential Merge Process

[Describe process followed]

### Merge Sequence

[List branches in merge order with dependencies]

---

## Merge Results

### Merge #1: [branch-name]

**Status:** ✅ SUCCESS / ❌ CONFLICT

**Changes:**
- X files changed
- Y insertions, Z deletions
- Key modules added/modified

[Repeat for each merge]

---

## Test Results

### RSpec Test Suite

**Command:** `bundle exec rspec spec/`

**Results:**
- X examples, Y failures
- Breakdown by test file

### Custom Integration Tests

[Document custom tests created and results]

---

## Integration Validation

### What Was Tested

[List integration points validated]

### What Was NOT Tested

[List limitations - e.g., no GTK, mocked keychains, etc.]

---

## Findings

### ✅ Positives

[What worked well]

### ⚠️ Issues Confirmed

[Problems found, severity, recommended fixes]

### 📊 Test Coverage

[What the tests prove vs what they don't]

---

## Recommendations

### For Beta Testing

[Next steps for beta]

### For Production Release

[Additional testing needed]

---

## Appendix: Test Environment

**Platform:** Linux / macOS / Windows
**Ruby Version:** X.X.X
**Bundler:** X.X.X
**RSpec:** X.X.X
**Limitations:** [List what can't be tested in this environment]

---

## Conclusion

[Summary of readiness for merge/beta/production]

---

**Test Completed:** YYYY-MM-DD
**Tester:** [Name]
**Status:** ✅ / ⚠️ / ❌
```

---

## Multi-Vehicle Review Integration

Integration testing is **one vehicle** in the multi-vehicle review strategy:

| Vehicle | Focus | When | Who |
|---------|-------|------|-----|
| **CLI Claude** | Implementation + local testing | During development | CLI Claude on macOS |
| **Web Claude** | Architecture audit + integration testing | Before merge | Web Claude in sandbox |
| **Ellipsis AI** | Automated code review | On PR creation | Ellipsis (GitHub bot) |
| **Human (Product Owner)** | UX validation + acceptance | Before merge | Doug |
| **Alpha Testing** | First integration check | After merge | Internal |
| **Beta Testing** | User acceptance | Before production | External users |

**Integration testing adds value by:**
- ✅ Validating real module integration (not mocks)
- ✅ Catching dependency issues before merge
- ✅ Proving merge sequence works
- ✅ Testing crypto/API compatibility
- ✅ Providing independent validation layer

**Integration testing does NOT replace:**
- ❌ Unit tests (still needed)
- ❌ PR review (still needed)
- ❌ Manual testing (still needed)
- ❌ Beta testing (still needed)

---

## Reference Examples

### Successful Integration Test

**Feature:** Password Encryption (6 branches)
**Report:** `.claude/docs/INTEGRATION_TEST_REPORT_2025_11_16.md`
**Results:** 120 RSpec examples passed, 4 custom tests passed, 0 conflicts
**Value:** Validated CLI ↔ GUI crypto compatibility, proved merge sequence works

---

## Best Practices

### DO

✅ **Create ephemeral branches** (prefix with `test-integration-`)
- Keep them separate from feature branches
- Delete after testing complete

✅ **Document merge sequence** before starting
- Identify dependencies first
- Plan order carefully

✅ **Run comprehensive tests**
- RSpec suite (all relevant specs)
- Custom integration tests (API/crypto/data format)
- Document both

✅ **Report results thoroughly**
- Use standard template
- Include both successes and failures
- Provide actionable recommendations

✅ **Clean up after testing**
- Delete ephemeral branch
- Commit test reports to working branch
- Push documentation

### DON'T

❌ **Don't merge test branch to main**
- Ephemeral branches are for testing only
- Real merges happen on feature branches

❌ **Don't skip conflict resolution**
- If conflicts occur, investigate and document
- May indicate merge order issue or real conflict

❌ **Don't trust mocks alone**
- Integration testing validates real module calls
- Mocks test logic, not integration

❌ **Don't rebase during integration testing**
- Defeats the purpose of testing sequential merge
- Rebase on feature branches if needed, not test branch

---

## Troubleshooting

### Merge Conflicts During Integration Test

**Symptom:** `git merge` fails with conflicts

**Diagnosis:**
1. Check if merge order is correct (dependency chain)
2. Examine conflicting files (related changes?)
3. Determine if conflict is real or ordering issue

**Resolution:**
- If ordering issue: Adjust merge sequence
- If real conflict: Document for Product Owner to resolve on feature branches
- If trivial conflict: Resolve and continue (document in report)

### Tests Fail After Integration

**Symptom:** RSpec or custom tests fail on integrated branch

**Diagnosis:**
1. Do tests pass on individual feature branches? (isolate issue)
2. Is it a real integration bug or test environment issue?
3. Are dependencies missing or API mismatched?

**Resolution:**
- Document findings in integration test report
- Provide specific error messages and reproduction steps
- Recommend fixes for feature branches
- Mark as blocker if critical

### Can't Test Specific Features

**Symptom:** Feature requires GTK, Windows, etc. (not available in sandbox)

**Resolution:**
- Document limitation in "What Was NOT Tested" section
- Test what CAN be tested (business logic, crypto, APIs)
- Recommend manual testing by Product Owner for untestable parts
- Note in recommendations for beta testing

---

## Future Enhancements

### Potential Improvements

**Automated Integration Testing:**
- CI/CD pipeline for automatic integration tests on PR merge
- Nightly integration builds
- Automated test report generation

**Enhanced Test Coverage:**
- Cross-platform testing (Linux + macOS + Windows)
- Performance benchmarking during integration
- Security scanning on integrated codebase

**Process Refinement:**
- Standard merge order templates for common patterns
- Automated conflict detection before merge
- Integration testing checklist

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2025-11-16 | Initial guide created based on password encryption integration testing |

---

**Document Owner:** Web Claude (Architecture & Oversight)
**Review Frequency:** After each multi-branch integration test (refine as needed)
**Status:** ACTIVE
