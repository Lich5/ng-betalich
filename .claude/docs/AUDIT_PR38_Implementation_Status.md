# Audit: PR #38 Implementation Status vs BRD

**Date:** 2025-11-08
**Auditor:** Web Claude
**Branch:** feat/password_encrypts
**BRD Reference:** `.claude/docs/BRD_Password_Encryption.md`

---

## EXECUTIVE SUMMARY

**Overall Status:** Partial implementation - Core encryption infrastructure complete, gaps in BRD requirements.

**Ready for Beta:** Plaintext + Standard modes only (with fixes)
**Not Ready:** Enhanced mode (spec mismatch), SSH Key mode (not implemented), Windows keychain, UI controls

**Blockers:**
1. Pre-existing test pollution (infomon_spec.rb) causing 2 test failures
2. PBKDF2 iterations: 10K (implemented) vs 100K (BRD spec)
3. Salt string mismatch: implementation vs BRD
4. Missing Windows keychain support

---

## AUDIT A: CLI CLAUDE TEST FIXES

### Summary
CLI Claude's work unit 001 correctly identified and resolved RSpec failures. All changes are architecturally sound.

### Validation Results

**✅ PASS - Code Changes:**
- Removed `private_class_method` declarations (correct - enables RSpec stubbing)
- Fixed `.present?` to native Ruby (correct - ActiveSupport not available)
- Restored `require 'os'` in master_password_manager.rb per ADR-008 (correct)

**✅ PASS - Test Infrastructure:**
- Added GTK3 stubs appropriately
- Proper test setup (tmpdir, State alias)
- Removed problematic recursive test (design flaw)

**✅ PASS - Code Quality:**
- RuboCop: 185 files, 0 offenses
- Commits follow conventional format
- Work unit properly archived

**❌ BLOCKER - Test Suite:**
- **Issue:** infomon_spec.rb:17-21 monkey-patches NilClass globally
- **Impact:** When full suite runs, master_password_manager_spec.rb fails (2/16 tests)
- **Evidence:**
  - master_password_manager_spec.rb alone: 16/16 pass
  - After infomon_spec.rb: 14/16 fail
- **Root Cause:** `NilClass#method_missing` returns nil for any method, pollutes `system()` behavior
- **Status:** Pre-existing technical debt (not introduced by CLI Claude)
- **Recommendation:** Fix before beta release

**Verdict:** CLI Claude's work is correct. Test failures are environmental, not implementation errors.

---

## AUDIT B: BRD IMPLEMENTATION STATUS

### Encryption Modes Comparison

| BRD Mode | Implementation | Status | Notes |
|----------|---------------|--------|-------|
| **Plaintext** | `:plaintext` | ✅ Complete | Works correctly |
| **Standard** (AES-256-CBC, account_name key) | `:account_name` mode (called `:standard` in cipher) | ⚠️ Partial | Works but spec violations (see below) |
| **Enhanced** (AES-256-CBC, master_password key) | `:master_password` mode | ⚠️ Partial | Works but spec violations + keychain issues |
| **SSH Key** | Not implemented | ❌ Missing | No code exists |

### Critical Specification Violations

#### 1. PBKDF2 Iterations Mismatch
**BRD Requirement:** 100,000 iterations
**Implementation:** 10,000 iterations (lib/common/gui/password_cipher.rb:29)

```ruby
# Current implementation:
KEY_ITERATIONS = 10_000

# BRD requirement:
# PBKDF2-HMAC-SHA256, 100,000 iterations
```

**Impact:** Passwords 10x more vulnerable to brute force attacks
**Risk:** HIGH - Security reduction
**Fix Required:** Change constant to 100,000 + re-encrypt all test data

---

#### 2. Salt String Mismatch
**BRD Requirement:** `'lich5-login-salt-v1'`
**Implementation:** `"lich5-password-encryption-#{mode}"` (dynamic salt per mode)

**Impact:**
- Passwords encrypted with current implementation cannot be decrypted if salt changes
- Non-compliant with BRD security spec
- If this changes, ALL encrypted passwords become unrecoverable

**Risk:** CRITICAL - Breaking change if corrected
**Decision Needed:** Accept current implementation or migrate (requires decrypt-all + re-encrypt workflow)

---

#### 3. Terminology Inconsistency
**BRD:** Modes are `plaintext`, `standard`, `enhanced`, `ssh_key`
**Code:** Uses `:plaintext`, `:account_name`, `:master_password`, (ssh missing)

**Files with inconsistency:**
- `password_cipher.rb` validates `%i[standard master_password]`
- `yaml_state.rb` uses `:account_name`, `:master_password`
- Comments reference `:account_name` mode

**Impact:** Confusing code + BRD mismatch
**Recommendation:** Align terminology - prefer BRD names

---

### Functional Requirements Coverage

| FR # | Requirement | Status | Evidence |
|------|-------------|--------|----------|
| FR-1 | Plaintext Mode | ✅ | `encryption_mode: :plaintext` works |
| FR-2 | Standard Mode (account-based) | ⚠️ | Works but spec violations |
| FR-3 | Enhanced Mode (master password) | ⚠️ | Works but spec violations + keychain gaps |
| FR-4 | Change Encryption Mode UI | ❌ | No UI control found |
| FR-5 | Change Account Password | ❌ | No UI control found |
| FR-6 | Change Master Password | ❌ | No UI control found |
| FR-7 | Change SSH Key | ❌ | SSH mode not implemented |
| FR-8 | Password Recovery | ❌ | No recovery workflow |

---

### OS Keychain Support

| Platform | BRD Requirement | Implementation | Status |
|----------|----------------|----------------|--------|
| **macOS** | Keychain.app via `security` command | ✅ Implemented | `mac_keychain_available?`, store/retrieve/delete methods exist |
| **Linux** | libsecret via `secret-tool` | ✅ Implemented | `linux_keychain_available?`, store/retrieve/delete methods exist |
| **Windows** | Windows Credential Manager via PowerShell | ❌ Not Implemented | Missing methods: `windows_keychain_available?`, `store_windows_keychain`, etc. |

**Windows Impact:** Enhanced mode cannot use system keychain on Windows - master password must be re-entered every session.

**Risk:** MEDIUM - Usability degradation for Windows users (~30-40% of user base estimated)

---

### Master Password Validation

**BRD Requirement (FR-6):** "Two layers: keychain comparison + PBKDF2 validation test"

**Implementation Check:**
- ✅ `MasterPasswordManager.create_validation_test` exists (lib/common/gui/master_password_manager.rb)
- ✅ `MasterPasswordManager.validate_master_password` exists
- ✅ PBKDF2-based validation hash stored in validation_test
- ⚠️ Keychain integration exists but Windows missing

**Verdict:** Core validation logic complete, Windows support missing

---

### Migration & Conversion

**Status:** ✅ Partial
- `YamlState.migrate_from_legacy` exists
- Handles entry.dat → entry.yaml conversion
- Supports encryption during migration
- Creates backups (`.bak` files)

**Gap:** No UI for triggering migration or selecting encryption mode during first run

---

## FILES CHANGED ANALYSIS

### Production Code Added (New Features)

**Encryption Core:**
- `lib/common/gui/password_cipher.rb` - AES-256-CBC encryption (standard + master_password modes)
- `lib/common/gui/master_password_manager.rb` - Keychain integration + PBKDF2 validation (macOS/Linux only)
- `lib/common/gui/master_password_prompt.rb` - UI prompts for master password
- `lib/common/gui/master_password_prompt_ui.rb` - GTK3 password dialog components

**State Management:**
- `lib/common/gui/yaml_state.rb` - Enhanced with encryption support
- `lib/common/gui/account_manager.rb` - Updated for YAML + encryption (no UI controls for mode changes)

**Total New Files:** 4 major encryption modules + 2 enhanced existing modules

### Test Coverage

**New Test Files:**
- `spec/password_cipher_spec.rb` - Encryption/decryption unit tests
- `spec/master_password_manager_spec.rb` - Keychain + validation tests
- `spec/master_password_prompt_spec.rb` - UI prompt tests
- `spec/yaml_state_spec.rb` - Enhanced with encryption scenarios

**Test Results:**
- When run independently: All pass
- When run in full suite: 2 failures (environmental pollution)

---

## RECOMMENDATIONS

### For Beta Inclusion (Ready Now with Fixes)

**Scope:** Plaintext + Standard modes only

**Required Fixes:**
1. Fix infomon_spec.rb test pollution (isolate NilClass monkey-patch)
2. Decision on PBKDF2 iterations: Keep 10K (with ADR) OR change to 100K (breaking change)
3. Decision on salt: Keep current OR align with BRD (breaking change)
4. Align terminology: `:account_name` → `:standard`, `:master_password` → `:enhanced`

**Estimated Effort:** 2-4 hours (CLI Claude work unit)

---

### Defer to Post-Beta (Not Ready)

**Enhanced Mode:**
- Windows keychain implementation required
- UI controls for "Change Encryption Mode" (FR-4)
- UI controls for "Change Master Password" (FR-6)
- Password recovery workflow (FR-8)

**SSH Key Mode:**
- Complete implementation from scratch (not started)
- UI integration
- FR-7 controls

**Estimated Effort:** 12-20 hours total

---

## PROPOSED DECOMPOSITION STRATEGY

### PR Chunk 1: Core Refactor (Base for All)
**Contents:** PR #7 (`eo-996`) - GUI login YAML refactor
**Status:** Ready to merge (foundation work)
**Encryption:** None (just YAML structure)

### PR Chunk 2: Plaintext + Standard Encryption (Beta-Ready)
**Contents:**
- password_cipher.rb (with spec fixes)
- yaml_state.rb encryption integration
- master_password_manager.rb (macOS/Linux only, clearly marked)
- Test fixes (including infomon pollution fix)
- Specs: 380/380 passing

**Title:** `chore(all): add password encryption foundation (plaintext + standard modes)`
**Justification for `chore`:** Infrastructure work, not user-facing feature (no UI controls yet)

**Deliverables:**
- Encryption works for plaintext + standard modes
- No UI to switch modes (requires manual YAML edit for testing)
- Windows users: Standard mode works (account-name based, no keychain needed)

### PR Chunk 3: Enhanced Mode + UI Controls (Post-Beta)
**Contents:**
- Windows keychain implementation
- Account Manager UI additions (FR-4, FR-5, FR-6)
- Password recovery workflow (FR-8)
- Migration UI

**Title:** `feat(all): add enhanced password encryption with UI controls`

### PR Chunk 4: SSH Key Mode (Post-Beta)
**Contents:**
- SSH key signature-based encryption
- UI integration
- FR-7 controls

**Title:** `feat(all): add SSH key-based password encryption`

---

## GAPS & RISKS SUMMARY

**High Priority (Block Beta):**
1. ❌ Test pollution in infomon_spec.rb
2. ⚠️ PBKDF2 iterations decision (10K vs 100K)
3. ⚠️ Salt string decision (breaking change if corrected)

**Medium Priority (Defer Post-Beta):**
4. ❌ Windows keychain support
5. ❌ UI controls for encryption mode management
6. ❌ Password recovery workflow

**Low Priority (Future):**
7. ❌ SSH Key mode implementation
8. ⚠️ Terminology alignment (confusing but functional)

---

**END OF AUDIT**
