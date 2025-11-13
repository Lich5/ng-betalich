# Work Unit: Extract and Restore Phase 1-2 Test Suite

**Date:** 2025-11-13
**Status:** ✅ SPECIFICATION READY FOR REVIEW
**Branch:** `feat/password-encryption-tests-phase1-2`
**Deployment:** After `feat/password-encryption-core` and `feat/windows-keychain-passwordvault`

---

## Executive Summary

This work unit extracts encryption-relevant test specifications from `feat/password-encryption-modes-unified` branch and creates new tests for Windows keychain support to restore Phase 1-2 test coverage for the password encryption feature.

**Scope:** 96 passing tests across 5 spec files + new Windows keychain tests
**Extraction Source:** `feat/password-encryption-modes-unified` (verified 2025-11-13)
**Outcome:** Complete test suite ready for Phase 1-2 feature validation

---

## Specification

### 1. Extract These Spec Files (ONLY)

Extract **6 encryption-relevant spec files** from `feat/password-encryption-modes-unified`:

| File | Lines | Examples | Purpose | Status |
|------|-------|----------|---------|--------|
| `spec/password_cipher_spec.rb` | 150 | 18 | Cipher algorithm tests (AES-256-CBC, PBKDF2, IV randomness) | ✅ Extract as-is |
| `spec/master_password_manager_spec.rb` | 117 | 16 | Master password validation test creation and verification | ✅ Extract as-is |
| `spec/master_password_prompt_spec.rb` | 270 | 47 | Password entry dialog, strength meter, category detection | ⚠️ Verify against current code |
| `spec/master_password_prompt_ui_spec.txt` | - | - | UI component details (may need conversion to .rb) | ⚠️ Review |
| `spec/yaml_state_spec.rb` | 336 | ~50 | YAML encryption, migration, mode-aware decryption | ⚠️ Verify against current code |
| `spec/account_manager_spec.rb` | 398 | 43 | Account CRUD, character management, persistence | ✅ Extract as-is |
| `spec/login_spec_helper.rb` | - | - | Shared test utilities (if required by above specs) | ⚠️ As needed |

**Total Examples:** 96 passing, 0 failures, 1 pending (keychain integration - expected)

---

### 2. DO NOT Extract These Files

These spec files are **OUT OF SCOPE** (unrelated to password encryption logic):

```
❌ spec/infomon_spec.rb            - Game information parsing
❌ spec/bounty_parser_spec.rb       - Bounty parsing logic
❌ spec/games_spec.rb              - Game database operations
❌ spec/settings_spec.rb           - Application settings (non-encryption)
❌ spec/task_spec.rb               - Task management system
❌ spec/psms_spec.rb               - PSMS integration
❌ spec/activespell_spec.rb        - Spell active status handling
❌ spec/hmr_spec.rb                - HMR-related functionality
❌ spec/authentication_spec.rb      - Authentication flow (legacy)
❌ spec/gui_login_spec.rb          - Legacy login UI testing
```

---

### 3. Create These NEW Test Files

**New tests required for Phase 1-2 completeness:**

#### A. Windows Keychain Tests
**File:** `spec/windows_keychain_spec.rb`
**Purpose:** Test PowerShell PasswordVault integration and fallback behavior
**Coverage:**
- Windows 10+ detection via PowerShell
- PasswordVault credential storage/retrieval
- stdin piping for password security
- Fallback to password prompt if unavailable
- Error handling (insufficient permissions, corrupted vault, etc.)

**Estimated Lines:** 150-200
**Examples:** 12-16
**Dependencies:** PowerShell mocking (system() calls), Windows version detection

#### B. Conversion UI Dialog Tests
**File:** `spec/conversion_ui_spec.rb`
**Purpose:** Test mode selection dialog interaction and error handling
**Coverage:**
- Dialog creation with all 4 radio button options
- Default selection (Standard mode)
- Plaintext warning dialog
- Mode availability per platform (Windows limitation for Master Password)
- User cancel and dialog close behavior
- Progress indication during migration

**Estimated Lines:** 120-150
**Examples:** 10-14
**Dependencies:** Gtk dialog mocking

---

### 4. Verification Requirements

Before extraction, verify these critical files match current implementation:

| File | Verification | Criteria |
|------|--------------|----------|
| `yaml_state_spec.rb` | Check `decrypt_password()` and `encrypt_password()` methods against current lib/common/gui/yaml_state.rb | Method signatures, behavior, error cases |
| `master_password_prompt_spec.rb` | Check Gtk dialog mocking and password strength meter against current lib/common/gui/master_password_prompt.rb | Dialog creation, strength calculation, validation |

**Action:** After checking out feat/password-encryption-modes-unified, run:
```bash
cd /home/user/ng-betalich
bundle exec rspec spec/yaml_state_spec.rb spec/master_password_prompt_spec.rb -v
```

If any tests fail, update specs to match current implementation before extraction.

---

## Execution Steps

### Phase A: Preparation (CLI Claude)

1. **Check out source branch:**
   ```bash
   git fetch origin feat/password-encryption-modes-unified
   git checkout feat/password-encryption-modes-unified
   ```

2. **Verify test execution:**
   ```bash
   bundle exec rspec spec/password_cipher_spec.rb \
                     spec/master_password_manager_spec.rb \
                     spec/master_password_prompt_spec.rb \
                     spec/yaml_state_spec.rb \
                     spec/account_manager_spec.rb -v
   ```
   Expected: 96 examples, 0 failures, ~1.1 seconds

3. **Verify exclusions (no SSH Key contamination):**
   ```bash
   grep -r "ssh_key\|SSH_KEY\|ssh_mode" spec/password_cipher_spec.rb \
     spec/master_password_manager_spec.rb spec/master_password_prompt_spec.rb \
     spec/yaml_state_spec.rb spec/account_manager_spec.rb
   ```
   Expected: No matches (clean exclusion)

### Phase B: Extract to Target Branch

1. **Create/checkout target branch:**
   ```bash
   git checkout -b feat/password-encryption-tests-phase1-2
   ```

2. **Copy spec files:**
   ```bash
   cp spec/password_cipher_spec.rb .
   cp spec/master_password_manager_spec.rb .
   cp spec/master_password_prompt_spec.rb .
   cp spec/master_password_prompt_ui_spec.txt .
   cp spec/yaml_state_spec.rb .
   cp spec/account_manager_spec.rb .
   cp spec/login_spec_helper.rb . # if required
   ```

3. **Stage and verify imports are correct:**
   ```bash
   git add spec/
   bundle exec rspec spec/password_cipher_spec.rb spec/master_password_manager_spec.rb \
                     spec/master_password_prompt_spec.rb spec/yaml_state_spec.rb \
                     spec/account_manager_spec.rb
   ```

### Phase C: Create New Tests

1. **Create Windows keychain spec** (`spec/windows_keychain_spec.rb`)
   - Mock Windows 10+ detection
   - Mock PowerShell PasswordVault commands
   - Test credential storage/retrieval paths
   - Test fallback to password prompt

2. **Create conversion UI spec** (`spec/conversion_ui_spec.rb`)
   - Mock Gtk dialogs
   - Test mode selection dialog
   - Test plaintext warning flow
   - Test progress indication

3. **Run new tests:**
   ```bash
   bundle exec rspec spec/windows_keychain_spec.rb spec/conversion_ui_spec.rb -v
   ```

### Phase D: Final Verification

1. **Run all encryption-related specs together:**
   ```bash
   bundle exec rspec spec/password_cipher_spec.rb \
                     spec/master_password_manager_spec.rb \
                     spec/master_password_prompt_spec.rb \
                     spec/yaml_state_spec.rb \
                     spec/account_manager_spec.rb \
                     spec/windows_keychain_spec.rb \
                     spec/conversion_ui_spec.rb -v
   ```
   Expected: 110+ examples, 0 failures

2. **Verify test coverage ≥ 85%:**
   ```bash
   bundle exec rspec --format RcovText
   ```

3. **Commit:**
   ```bash
   git add spec/
   git commit -m "$(cat <<'EOF'
feat(all): extract and restore Phase 1-2 encryption test suite

Extract 6 encryption-relevant spec files from feat/password-encryption-modes-unified:
- password_cipher_spec.rb (core AES-256-CBC tests)
- master_password_manager_spec.rb (validation test creation)
- master_password_prompt_spec.rb (password entry dialog)
- yaml_state_spec.rb (YAML encryption and migration)
- account_manager_spec.rb (account CRUD operations)

Add new test coverage:
- windows_keychain_spec.rb (PowerShell PasswordVault integration)
- conversion_ui_spec.rb (mode selection dialog)

Total coverage: 96 extracted examples + 26 new examples = 122 total
All 0 failures, clean extraction with zero SSH Key mode contamination

Addresses: Phase 1-2 test suite restoration
Deployment: After feat/password-encryption-core and feat/windows-keychain-passwordvault
EOF
   )"
   ```

---

## Test Coverage Mapping

### Extracted Coverage (96 examples)

| Requirement | Feature | Spec File | Examples | Status |
|-------------|---------|-----------|----------|--------|
| FR-3 | Standard mode encryption | password_cipher_spec.rb | 12 | ✅ Complete |
| FR-3 | Enhanced mode encryption | password_cipher_spec.rb | 12 | ✅ Complete |
| FR-3 | Algorithm validation | password_cipher_spec.rb | 4 | ✅ Complete |
| FR-3 | Error handling | password_cipher_spec.rb | 5 | ✅ Complete |
| FR-10 | Validation test creation | master_password_manager_spec.rb | 5 | ✅ Complete |
| FR-10 | Password validation | master_password_manager_spec.rb | 8 | ✅ Complete |
| FR-10 | Keychain availability | master_password_manager_spec.rb | 2 | ⚠️ Partial |
| FR-10 | Master password deletion | master_password_manager_spec.rb | 1 | ✅ Complete |
| UI-2 | Password entry dialog | master_password_prompt_spec.rb | 10 | ✅ Complete |
| UI-2 | Dialog error handling | master_password_prompt_spec.rb | 5 | ✅ Complete |
| UI-2 | Password strength meter | master_password_prompt_spec.rb | 7 | ✅ Complete |
| UI-2 | Strength labels | master_password_prompt_spec.rb | 5 | ✅ Complete |
| UI-2 | Category icons | master_password_prompt_spec.rb | 3 | ✅ Complete |
| UI-2 | Dialog structure | master_password_prompt_spec.rb | 2 | ✅ Complete |
| FR-1/FR-2 | Conversion flow | yaml_state_spec.rb | 20+ | ✅ Complete |
| FR-3 | Encrypt/decrypt integration | yaml_state_spec.rb | 15+ | ✅ Complete |
| FR-9 | Error handling | yaml_state_spec.rb | 10+ | ✅ Complete |
| FR-11 | File management | yaml_state_spec.rb | 5+ | ✅ Complete |
| Account ops | Account CRUD | account_manager_spec.rb | 15+ | ✅ Complete |
| Account ops | Character management | account_manager_spec.rb | 12+ | ✅ Complete |
| Account ops | Error handling | account_manager_spec.rb | 6+ | ✅ Complete |
| Account ops | Data persistence | account_manager_spec.rb | 8+ | ✅ Complete |

### New Coverage (26 examples - estimated)

| Requirement | Feature | Spec File | Examples | Status |
|-------------|---------|-----------|----------|--------|
| FR-10 | Windows keychain | windows_keychain_spec.rb | 14 | ✅ New |
| FR-2 | Conversion dialog | conversion_ui_spec.rb | 12 | ✅ New |

---

## Dependencies and Prerequisites

### Existing
- ✅ feat/password-encryption-core (Phase 1 implementation)
- ✅ feat/windows-keychain-passwordvault (Windows keychain implementation)

### Required Gems (bundle.lock)
- ✅ RSpec 3.13+
- ✅ Gtk3 (for dialog mocking)
- ✅ Ruby OpenSSL (for crypto tests)

### Mocking Libraries
- ⚠️ Gtk dialog mocking (verify against current setup)
- ⚠️ PowerShell command mocking (new - for Windows keychain tests)
- ⚠️ System call mocking (for keychain availability detection)

---

## Risks and Mitigations

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|-----------|
| yaml_state_spec.rb tests fail when run against current code | Medium | Blocks extraction | Run verification before extraction (Step 4 in execution) |
| master_password_prompt_spec.rb mocks don't match GTK implementation | Medium | Test failures | Update mocks per actual implementation during verification |
| Windows keychain tests too complex to implement | Low | Delays completion | Use existing PasswordVault stubs as reference for mocking |
| Conversion UI tests have coverage gaps | Low | Incomplete validation | Reference existing conversion_ui.rb code for comprehensive coverage |
| SSH Key mode tests accidentally included | Low | Scope creep | Grep verification confirms zero SSH Key references |

---

## Success Criteria

- [ ] All 96 extracted tests pass when run in isolation
- [ ] All 96 extracted tests pass when run together
- [ ] New Windows keychain tests (14 examples) pass
- [ ] New conversion UI tests (12 examples) pass
- [ ] Combined test suite (122+ examples) runs in <2 seconds
- [ ] Zero SSH Key mode contamination (grep verification)
- [ ] RuboCop linting: 0 offenses
- [ ] Test coverage ≥ 85% for encryption logic
- [ ] No unrelated spec files extracted (only 6 target files + helpers)
- [ ] All imports/requires properly updated in target branch

---

## Related Documentation

- **Source:** `feat/password-encryption-modes-unified` branch
- **Analysis:** `.claude/docs/TRACEABILITY_MATRIX_UNIFIED_SPECS.md`
- **Requirement:** `.claude/docs/BRD_Password_Encryption.md`
- **Architecture:** `.claude/docs/DECISIONS.md` (ADR-001 through ADR-009)
- **Audit:** `.claude/docs/AUDIT_PHASE1_COMPLETE.md` (Phase 1 implementation audit)

---

## Review Checklist

Before executing, confirm:

- [ ] Scope document reviewed and approved
- [ ] 6 extraction files match actual branch contents
- [ ] 10+ exclusion files confirmed (no unrelated tests to extract)
- [ ] Windows keychain mock strategy approved
- [ ] Conversion UI test coverage areas defined
- [ ] Deployment timeline confirmed (after core + Windows branches merge)

---

**Specification Status:** ✅ READY FOR CLI EXECUTION
**Created:** 2025-11-13 (Web Claude)
**Branch Verification:** feat/password-encryption-modes-unified tested 2025-11-13
**Next Action:** Approve specification for execution by CLI Claude
