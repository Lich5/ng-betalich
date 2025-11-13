# Work Unit: Extract and Restore Phase 1-2 Test Suite

**Created:** 2025-11-13
**Estimated Effort:** 3-4 hours
**Branch:** `feat/password-encryption-tests-phase1-2`

---

## Task

Extract 96 passing encryption-relevant tests from `feat/password-encryption-modes-unified`, add Windows keychain and conversion UI tests, restore complete Phase 1-2 test coverage.

---

## Prerequisites

**Base Branch:** `feat/password-encryption-core`

**Branch Creation Instructions:**
```bash
git fetch origin feat/password-encryption-modes-unified
git fetch origin feat/password-encryption-core
git checkout feat/password-encryption-core
git checkout -b feat/password-encryption-tests-phase1-2
```

- [ ] Branch created: `feat/password-encryption-tests-phase1-2` from `feat/password-encryption-core`
- [ ] Context read: `.claude/docs/TRACEABILITY_MATRIX_UNIFIED_SPECS.md` (extraction plan)
- [ ] Source branch available: `feat/password-encryption-modes-unified`

---

## Setup

```bash
git fetch origin feat/password-encryption-modes-unified
git fetch origin feat/password-encryption-core
git checkout feat/password-encryption-core
git checkout -b feat/password-encryption-tests-phase1-2
```

---

## Files

**Extract from feat/password-encryption-modes-unified (ONLY):**
- `spec/password_cipher_spec.rb` (as-is, 18 examples)
- `spec/master_password_manager_spec.rb` (as-is, 16 examples)
- `spec/master_password_prompt_spec.rb` (verify, 47 examples)
- `spec/yaml_state_spec.rb` (verify, ~50 examples)
- `spec/account_manager_spec.rb` (as-is, 43 examples)
- `spec/login_spec_helper.rb` (if required)

**Create NEW:**
- `spec/windows_keychain_spec.rb` (Windows PasswordVault mocking, ~14 examples)
- `spec/conversion_ui_spec.rb` (Mode selection dialog, ~12 examples)

**DO NOT Extract:**
```
infomon_spec.rb, bounty_parser_spec.rb, games_spec.rb, settings_spec.rb,
task_spec.rb, psms_spec.rb, activespell_spec.rb, hmr_spec.rb,
authentication_spec.rb, gui_login_spec.rb
```

---

## Implementation Details

### Step 1: Verify Source Branch (feat/password-encryption-modes-unified)

```bash
git checkout feat/password-encryption-modes-unified
bundle exec rspec spec/password_cipher_spec.rb \
                  spec/master_password_manager_spec.rb \
                  spec/master_password_prompt_spec.rb \
                  spec/yaml_state_spec.rb \
                  spec/account_manager_spec.rb -v
```

Expected: 96 examples, 0 failures, ~1.1 seconds

Verify no SSH Key contamination:
```bash
grep -r "ssh_key\|SSH_KEY\|ssh_mode" spec/password_cipher_spec.rb \
  spec/master_password_manager_spec.rb spec/master_password_prompt_spec.rb \
  spec/yaml_state_spec.rb spec/account_manager_spec.rb
```

Expected: No matches

### Step 2: Switch to Target Branch

```bash
git checkout feat/password-encryption-tests-phase1-2
```

### Step 3: Copy Extraction Files

From checked-out `feat/password-encryption-modes-unified`, copy these files:

```bash
git show origin/feat/password-encryption-modes-unified:spec/password_cipher_spec.rb > spec/password_cipher_spec.rb
git show origin/feat/password-encryption-modes-unified:spec/master_password_manager_spec.rb > spec/master_password_manager_spec.rb
git show origin/feat/password-encryption-modes-unified:spec/master_password_prompt_spec.rb > spec/master_password_prompt_spec.rb
git show origin/feat/password-encryption-modes-unified:spec/yaml_state_spec.rb > spec/yaml_state_spec.rb
git show origin/feat/password-encryption-modes-unified:spec/account_manager_spec.rb > spec/account_manager_spec.rb
git show origin/feat/password-encryption-modes-unified:spec/login_spec_helper.rb > spec/login_spec_helper.rb 2>/dev/null || true
```

### Step 4: Verify Extracted Tests Pass

```bash
bundle exec rspec spec/password_cipher_spec.rb \
                  spec/master_password_manager_spec.rb \
                  spec/master_password_prompt_spec.rb \
                  spec/yaml_state_spec.rb \
                  spec/account_manager_spec.rb -v
```

Expected: 96 examples, 0 failures

### Step 5: Create Windows Keychain Tests (spec/windows_keychain_spec.rb)

Create test file covering:
- Windows 10+ detection via PowerShell
- PasswordVault credential storage
- PasswordVault credential retrieval
- Password deletion
- Fallback when unavailable
- Error handling (permission denied, vault locked)

Reference: `lib/common/gui/master_password_manager.rb` (lines 171-188)

### Step 6: Create Conversion UI Tests (spec/conversion_ui_spec.rb)

Create test file covering:
- Dialog creation with all 4 radio button options
- Default selection (Standard mode)
- Plaintext warning dialog
- Mode availability per platform
- User cancel/close behavior
- Progress indication

Reference: `lib/common/gui/conversion_ui.rb` (lines 33-292)

### Step 7: Run All Tests Together

```bash
bundle exec rspec spec/password_cipher_spec.rb \
                  spec/master_password_manager_spec.rb \
                  spec/master_password_prompt_spec.rb \
                  spec/yaml_state_spec.rb \
                  spec/account_manager_spec.rb \
                  spec/windows_keychain_spec.rb \
                  spec/conversion_ui_spec.rb -v
```

Expected: 122+ examples, 0 failures, <2 seconds

### Step 8: Check Test Coverage

```bash
bundle exec rspec spec/ --format RcovText | grep -E "^(Finished|Coverage:)"
```

Expected: ≥85% coverage for encryption logic

### Step 9: RuboCop Verification

```bash
bundle exec rubocop spec/
```

Expected: 0 offenses

---

## Acceptance Criteria

- [ ] All 96 extracted tests pass individually and together
- [ ] Windows keychain tests (14 examples) created and passing
- [ ] Conversion UI tests (12 examples) created and passing
- [ ] Combined test suite (122+ examples) runs in <2 seconds
- [ ] Zero SSH Key mode contamination verified
- [ ] Test coverage ≥85% for encryption logic
- [ ] RuboCop: 0 offenses
- [ ] Only encryption-related files extracted (6 spec files + helpers)
- [ ] No unrelated specs included (infomon, bounty_parser, games, etc.)
- [ ] All imports/requires properly updated
- [ ] Committed with conventional commit message

---

## Conventional Commit Format (CRITICAL)

**Your commit MUST use this format:**
```
feat(all): extract and restore Phase 1-2 encryption test suite
```

**Details in commit body:**
```
Extract 6 encryption-relevant spec files from feat/password-encryption-modes-unified:
- password_cipher_spec.rb (AES-256-CBC tests)
- master_password_manager_spec.rb (validation test creation)
- master_password_prompt_spec.rb (password dialog)
- yaml_state_spec.rb (encryption and migration)
- account_manager_spec.rb (account CRUD)

Add new test coverage:
- windows_keychain_spec.rb (PowerShell PasswordVault integration)
- conversion_ui_spec.rb (mode selection dialog)

Total: 96 extracted + 26 new = 122 examples
Zero failures, zero SSH Key contamination
```

---

## Context

**Read before starting:**
- `.claude/docs/CLI_PRIMER.md` (ground rules, quality standards)
- `.claude/docs/TRACEABILITY_MATRIX_UNIFIED_SPECS.md` (extraction scope and rationale)
- `.claude/docs/BRD_Password_Encryption.md` (FR-1 through FR-11 requirements)

**Key Context:**
- 96 tests are already written and passing in source branch
- Extraction = copy files, verify they pass
- New tests = Windows keychain + conversion UI (reference existing code)
- Phase 1-2 test suite restores after core + Windows branches deploy

---

## Rollback Plan

**If extraction fails:**

```bash
# Revert extracted files
git reset spec/
git checkout spec/

# Remove any new files created
rm -f spec/windows_keychain_spec.rb spec/conversion_ui_spec.rb

# Verify clean state
git status
```

**If new tests too complex:**
- Defer windows_keychain_spec.rb to separate work unit
- Defer conversion_ui_spec.rb to separate work unit
- Commit 96 extracted tests only

---

## Edge Cases to Handle

1. **master_password_prompt_spec.rb mocks don't match current GTK implementation**
   - Run verification step before extraction
   - If tests fail, update mocks to match current code

2. **yaml_state_spec.rb tests fail on current implementation**
   - Verify decrypt_password/encrypt_password method signatures match
   - Update test expectations if implementation changed

3. **PowerShell not available on test system**
   - Mock system() calls, don't execute actual PowerShell
   - Return false for windows_keychain_available? in tests

4. **Gtk dialog mocking incomplete**
   - Reference existing master_password_prompt_spec.rb mocking approach
   - Use same Gtk::Dialog, Gtk::RadioButton patterns

---

## Questions/Blockers

None anticipated. All tests pre-written and verified in source branch.

**If stuck:**
1. Verify feat/password-encryption-modes-unified branch exists and is accessible
2. Check that extracted tests reference correct lib/ file locations
3. Verify Gtk and OpenSSL gems installed (bundle install)
4. Ask product owner for clarification on test mocking approach

---

**When complete:**
1. Run final verification: `bundle exec rspec spec/ -v`
2. Push branch: `git push -u origin feat/password-encryption-tests-phase1-2`
3. Archive this file to `archive/003-test-extraction-phase1-2.md`
4. Await next work unit
