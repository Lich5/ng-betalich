# BRD Functional Requirements Traceability Matrix

**Project:** Lich 5 Password Encryption
**Branch:** feat/password_encrypts (PR #38)
**Date:** 2025-11-08
**Audit Method:** Full code review with execution flow tracing

---

## Executive Summary

| Metric | Value | Notes |
|:-------|:------|:------|
| **Overall BRD Compliance** | 40-45% | Core encryption complete, management UI missing |
| **Production-Ready Features** | 3 of 8 FRs | FR-1 (partial), FR-2, FR-3 |
| **Platform Coverage** | Mixed | macOS/Linux complete, Windows limited |
| **Test Coverage** | 378/380 passing | 2 environmental failures (test pollution) |

---

## 📊 Requirements Status Overview

### ✅ Complete
- **FR-2:** Conversion Flow (entry.dat → entry.yaml)
- **FR-3:** Password Encryption (for implemented modes)
- **FR-5:** Change Account Password

### ⚠️ Partial
- **FR-1:** Four Encryption Modes (2 of 4 complete, 1 partial)

### ❌ Not Implemented
- **FR-4:** Change Encryption Mode
- **FR-6:** Change Master Password
- **FR-7:** Change SSH Key
- **FR-8:** Password Recovery

---

## FR-1: Four Encryption Modes

### Mode Status

<details>
<summary><strong>✅ Plaintext Mode - COMPLETE</strong></summary>

**Implementation:** Passthrough in YamlState
**Evidence:** `lib/common/gui/yaml_state.rb:157, 174`
**Platforms:** All (Windows, macOS, Linux)
**Tests:** ✅ Passing

**What Works:**
- No encryption/decryption overhead
- Direct password storage in YAML
- Warning dialog shown to user on selection
- Full password change support

</details>

<details>
<summary><strong>✅ Standard Mode - COMPLETE</strong></summary>

**Implementation:** PasswordCipher with `:standard` mode
**Evidence:** `lib/common/gui/password_cipher.rb:106, 129-130`
**Platforms:** All (Windows, macOS, Linux)
**Tests:** ✅ Comprehensive coverage

**Technical Specs:**
- Algorithm: AES-256-CBC ✅
- Key Derivation: PBKDF2-HMAC-SHA256, 10K iterations
- Salt: `"lich5-password-encryption-standard"`
- Key Source: Account name
- IV: Random 16 bytes per encryption
- Output: Base64-encoded

**What Works:**
- Encrypt/decrypt with account name as key
- Cross-device sync (deterministic key)
- Password change support
- Zero keychain dependency

</details>

<details>
<summary><strong>⚠️ Enhanced Mode - PARTIAL (macOS/Linux only)</strong></summary>

**Implementation:** PasswordCipher with `:master_password` mode
**Evidence:** `lib/common/gui/password_cipher.rb:106, 132`
**Platforms:** ✅ macOS, ✅ Linux, ❌ Windows (stub only)
**Tests:** ✅ Comprehensive coverage

**Technical Specs:**
- Algorithm: AES-256-CBC ✅
- Key Derivation: PBKDF2-HMAC-SHA256, 10K iterations (runtime)
- Validation: PBKDF2 100K iterations (one-time security check)
- Salt: `"lich5-password-encryption-enhanced"`
- Key Source: Master password from OS keychain
- Keychain: macOS (security), Linux (secret-tool), Windows (stub)

**What Works:**
- Master password stored in OS keychain
- One-time password entry per device
- High-security validation test (100K iterations)
- Password change support

**Gap - Windows (~80% of users):**
- `store_windows_keychain()` returns `false` (stub)
- `retrieve_windows_keychain()` returns `nil` (stub)
- Conversion dialog disables Master Password option on Windows
- **Impact:** Majority of users cannot use this mode

**Evidence of Windows Stub:**
```ruby
# lib/common/gui/master_password_manager.rb:175-180
def self.store_windows_keychain(_password)
  # Windows credential manager doesn't support piping passwords safely
  # Return false - Windows support would need different approach
  Lich.log "warning: Master password storage not fully implemented for Windows"
  false
end
```

</details>

<details>
<summary><strong>❌ SSH Key Mode - NOT IMPLEMENTED</strong></summary>

**Status:** No code found
**BRD Requirement:** AES-256-CBC with SSH key signature as encryption key

**Missing:**
- SSH key signature generation
- Key file selection UI
- PasswordCipher mode implementation
- SSH agent integration
- Cross-platform SSH key handling

**Impact:** Developer persona (power users) unsupported

</details>

---

## FR-2: Conversion Flow (entry.dat → entry.yaml)

### ✅ COMPLETE (95% - SSH picker missing)

<details>
<summary><strong>Implementation Details</strong></summary>

**Evidence:** `lib/common/gui/conversion_ui.rb:33-292`

#### Startup Detection
- **File:** `lib/common/gui-login.rb:496-505`
- **Logic:** Checks if `entry.dat` exists AND `entry.yaml` missing
- **Action:** Shows conversion dialog before main window

#### Dialog Features

| BRD Requirement | Implementation | Status | Line # |
|:----------------|:---------------|:------:|:-------|
| Modal dialog | `Gtk::Dialog` with `:modal` flag | ✅ | 35-42 |
| 4 radio button options | All 4 modes shown | ✅ | 94-98 |
| Mode descriptions | Descriptive labels | ✅ | 94-97 |
| Default selection | Standard mode pre-selected | ✅ | 100 |
| Plaintext warning | Confirmation dialog | ✅ | 189-214 |
| Master password prompt | Triggered during migration | ✅ | yaml_state.rb:115-116 |
| Progress indication | Progress bar + status label | ✅ | 145-169, 220-246 |
| Convert button | "Convert Data" button | ✅ | 40 |
| Cancel button | Exits application | ✅ | 282-290 |
| SSH Key picker | Not implemented | ❌ | N/A |

#### Radio Button Options
```ruby
# Lines 94-98
plaintext_radio = "Plaintext (no encryption - least secure)"
standard_radio = "Standard Encryption (basic encryption)"  # DEFAULT
master_radio = "Master Password Encryption (recommended)"
enhanced_radio = "Enhanced Encryption (future - not yet available)"  # DISABLED
```

#### Platform-Specific Behavior
- **Windows:** Master Password option disabled (keychain unavailable)
- **macOS/Linux:** All options except "Enhanced" available
- **All platforms:** SSH option shown as "Enhanced (future)" placeholder

</details>

**Gap:** SSH Key file picker not implemented (mode doesn't exist)

---

## FR-3: Password Encryption

### ✅ COMPLETE for Plaintext + Standard + Master Password

<details>
<summary><strong>Core Encryption Engine</strong></summary>

**File:** `lib/common/gui/password_cipher.rb`

#### BRD Compliance Table

| Specification | BRD Requirement | Implementation | Status |
|:--------------|:----------------|:---------------|:------:|
| **Algorithm** | AES-256-CBC | AES-256-CBC | ✅ |
| **Key Derivation** | PBKDF2-HMAC-SHA256 | PBKDF2-HMAC-SHA256 | ✅ |
| **Iterations** | 100,000 | 10,000 (runtime) + 100,000 (validation) | ⚠️ |
| **Key Length** | 32 bytes (256 bits) | 32 bytes | ✅ |
| **IV** | Random 16 bytes | Random per operation | ✅ |
| **Output Format** | Base64 `{iv, ciphertext}` | Base64(iv + ciphertext) | ✅ |

#### Iteration Strategy (Hybrid Approach)

**Runtime Encryption/Decryption:** 10,000 iterations
- Used by `PasswordCipher.encrypt()` and `decrypt()`
- Performance-optimized for frequent operations
- File: `password_cipher.rb:29`

**Validation Test:** 100,000 iterations
- Used by `MasterPasswordManager.create_validation_test()`
- One-time security check during master password creation
- File: `master_password_manager.rb:18, 73, 96`

**Architecture Rationale:**
```ruby
# master_password_manager.rb:14-15 comment
# CRITICAL: Validation test uses 100k iterations (one-time)
#           Runtime decryption uses 10k iterations (via PasswordCipher)
```

This balances security (strong validation) with performance (fast runtime).

</details>

<details>
<summary><strong>Salt Specification Analysis</strong></summary>

#### BRD vs Implementation

| Mode | BRD Salt | Implementation Salt | Cryptographic Impact |
|:-----|:---------|:-------------------|:---------------------|
| Standard | `'lich5-login-salt-v1'` | `"lich5-password-encryption-standard"` | **Better:** Mode separation |
| Enhanced | `'lich5-login-salt-v1'` | `"lich5-password-encryption-master_password"` | **Better:** Mode separation |

**Current Approach Benefits:**
- Cryptographic separation between encryption modes
- Prevents cross-mode key derivation attacks
- Each mode has its own salt namespace

**Assessment:** Implementation is arguably **more secure** than BRD spec

</details>

<details>
<summary><strong>Test Coverage</strong></summary>

**File:** `spec/password_cipher_spec.rb` (150 lines)

**Test Categories:**
- ✅ Standard mode: encrypt/decrypt, IV randomness, wrong key detection
- ✅ Master password mode: encrypt/decrypt, wrong password detection
- ✅ Error handling: invalid modes, missing params, corrupted data
- ✅ Edge cases: empty passwords, special characters, unicode, 1000+ char passwords
- ✅ Security properties: Base64 encoding, length verification, different ciphertexts

**Result:** Comprehensive coverage for all implemented modes

</details>

---

## FR-4: Change Encryption Mode

### ❌ NOT IMPLEMENTED

**BRD Requirement:** User can switch encryption modes post-setup via Account Management UI

**Evidence of Absence:**
- ❌ No "Change Encryption Mode" button in `account_manager_ui.rb`
- ❌ No mode selection dialog
- ❌ No re-encryption workflow
- ❌ Conversion dialog only shown at first run

**User Statement:** *"I need to modify the actual BRD requirements for this"*

**Recommendation:** Defer or remove from BRD scope pending product decision

---

## FR-5: Change Account Password

### ✅ COMPLETE

<details>
<summary><strong>Implementation Details</strong></summary>

**File:** `lib/common/gui/password_change.rb:18-191`

#### UI Integration
- **Button:** "Change Password" in Account Manager (`account_manager_ui.rb:176`)
- **Dialog:** Modal with current/new/confirm password fields
- **Validation:** Password matching, empty checks, current password verification

#### Workflow

```
1. User selects account → clicks "Change Password"
2. Dialog prompts for:
   - Current password (to verify identity)
   - New password
   - Confirm new password
3. System validates current password by:
   - Detecting encryption mode from YAML
   - Retrieving master password from keychain (if needed)
   - Decrypting stored password
   - Comparing with entered password
4. If valid:
   - Encrypt new password with SAME mode
   - Update YAML via AccountManager
   - Show success dialog
```

#### Mode Support

| Mode | Implementation | Evidence |
|:-----|:---------------|:---------|
| Plaintext | Direct comparison + update | Lines 240-241 |
| Standard | Decrypt with account name → re-encrypt | Lines 243-249 |
| Master Password | Keychain retrieval → decrypt → re-encrypt | Lines 237, 274 |
| SSH Key | N/A | Mode not implemented |

**Platform Compatibility:**
- ✅ Windows: Plaintext + Standard modes work
- ✅ macOS/Linux: All implemented modes work

</details>

---

## FR-6: Change Master Password

### ❌ NOT IMPLEMENTED

**BRD Requirement:** User can change their master password and re-encrypt all passwords

**Evidence of Absence:**
- ❌ No "Change Master Password" button
- ❌ No re-encryption workflow
- ❌ No keychain update process

**Available Primitives (not wired to UI):**
- ✅ `MasterPasswordManager.create_validation_test()`
- ✅ `MasterPasswordManager.validate_master_password()`
- ✅ `MasterPasswordManager.store_master_password()`
- ✅ Password encryption/decryption with different keys

**Gap:** UI + orchestration layer missing

---

## FR-7: Change SSH Key

### ❌ NOT IMPLEMENTED

**Reason:** SSH Key mode itself not implemented (FR-1)

---

## FR-8: Password Recovery

### ❌ NOT IMPLEMENTED

**BRD Requirement:** Recovery workflow when passwords cannot be decrypted

**Missing:**
- ❌ Detection of decryption failures
- ❌ Recovery dialog
- ❌ Account password re-entry workflow
- ❌ Mode switching option during recovery

**Current Behavior:** Decryption failures likely result in errors/crashes

---

## Platform Support Matrix

### OS Keychain Implementation

| Platform | Users % | BRD Requirement | Implementation | Status |
|:---------|:--------|:----------------|:---------------|:------:|
| **Windows** | ~80% | Windows Credential Manager | **Stub only** | ❌ |
| **macOS** | ~15% | Keychain.app via `security` | Complete | ✅ |
| **Linux** | ~5% | libsecret via `secret-tool` | Complete | ✅ |

#### Windows Gap Details

**File:** `lib/common/gui/master_password_manager.rb:171-188`

**What Exists:**
- ✅ `windows_keychain_available?` - Checks for `cmdkey` command (line 172)
- ✅ `delete_windows_keychain` - Calls `cmdkey /delete` (line 187)

**What's Stubbed:**
- ❌ `store_windows_keychain()` - Returns `false` with warning log (lines 175-180)
- ❌ `retrieve_windows_keychain()` - Returns `nil` (lines 182-184)

**Code Comment:**
```ruby
# Windows credential manager doesn't support piping passwords safely
# Return false - Windows support would need different approach
```

**Impact:** 80% of user base cannot use Master Password mode

### Mode Availability by Platform

| Mode | Windows | macOS | Linux |
|:-----|:-------:|:-----:|:-----:|
| Plaintext | ✅ | ✅ | ✅ |
| Standard | ✅ | ✅ | ✅ |
| Master Password | ❌ | ✅ | ✅ |
| SSH Key | ❌ | ❌ | ❌ |

---

## Test Coverage Summary

### Overall Status
- **Total Tests:** 380 examples
- **Passing:** 378 (99.5%)
- **Failing:** 2 (environmental - test pollution)
- **RuboCop:** 185 files, 0 offenses

### Encryption-Specific Test Files

<details>
<summary><strong>password_cipher_spec.rb</strong> (150 lines)</summary>

**Coverage:**
- Standard mode encryption/decryption
- Master password mode encryption/decryption
- IV randomness verification
- Wrong key/password detection
- Error handling (invalid modes, missing params, corrupted data)
- Edge cases (empty, special chars, unicode, 1000+ chars)
- Security properties (Base64, length, uniqueness)

**Result:** ✅ Comprehensive

</details>

<details>
<summary><strong>master_password_manager_spec.rb</strong> (117 lines)</summary>

**Coverage:**
- Keychain availability check
- Validation test creation (PBKDF2 100K)
- Password validation (correct/incorrect/edge cases)
- Special characters, unicode, very long passwords
- Keychain integration (skips if unavailable)

**Known Issue:** 2/16 tests fail when run after `infomon_spec.rb` due to NilClass pollution

**Result:** ✅ Comprehensive (with environmental issue)

</details>

### Test Gaps

**No tests for:**
- ❌ Windows keychain (stubbed)
- ❌ SSH Key mode (not implemented)
- ❌ Encryption mode switching (not implemented)
- ❌ Password recovery (not implemented)

---

## Critical Gaps Summary

### High Priority (Blocks Features)

**1. Windows Keychain Support**
- **Impact:** 80% of users cannot use Master Password mode
- **Effort:** 4-8 hours
- **Files:** `master_password_manager.rb:175-184`
- **Approach:** PowerShell + Windows Credential Manager API

### Medium Priority (BRD Compliance)

**2. SSH Key Mode**
- **Impact:** Developer persona unsupported
- **Effort:** 8-12 hours
- **Scope:** Full mode implementation + UI

**3. Password Recovery Workflow**
- **Impact:** Users stuck if master password forgotten
- **Effort:** 4-8 hours
- **Scope:** Recovery dialog + account re-entry

### Low Priority (Nice to Have)

**4. Change Master Password UI**
- **Effort:** 2-4 hours
- **Note:** Primitives exist, needs UI wiring

**5. Change Encryption Mode UI**
- **Effort:** 6-10 hours
- **Note:** May be removed from BRD per user

---

## Recommendations

### For Beta Release

**✅ Include:**
- Plaintext mode (all platforms)
- Standard mode (all platforms)
- Conversion dialog (with Windows limitation noted)
- Password change UI (for working modes)

**⚠️ Conditional:**
- Master Password mode: macOS/Linux only (document limitation)

**❌ Exclude:**
- SSH Key mode (not implemented)
- Windows Master Password (stub only)
- Mode switching UI (not implemented)
- Recovery workflow (not implemented)

### Post-Beta Priorities

**Phase 1:** Windows Parity
1. Implement Windows keychain support
2. Enable Master Password for Windows users
3. Cross-platform testing

**Phase 2:** Management UI
1. Change encryption mode dialog
2. Change master password workflow
3. Password recovery workflow

**Phase 3:** SSH Key Mode
1. Full SSH mode implementation
2. Key selection UI
3. Developer documentation

---

## Decision Points

### 1. PBKDF2 Iteration Count
- **Current:** 100K (validation), 10K (runtime)
- **BRD:** 100K (all)
- **Recommendation:** ✅ Accept hybrid (sound architecture)

### 2. Salt Specification
- **Current:** Dynamic per-mode
- **BRD:** Fixed `'lich5-login-salt-v1'`
- **Recommendation:** ✅ Keep current (better security)

### 3. Windows Support for Beta
- **Option A:** Block beta until Windows implemented
- **Option B:** Beta with "macOS/Linux only" documentation
- **Option C:** Remove Master Password from beta entirely
- **Recommendation:** Option B (quick beta, prioritize Windows post-beta)

### 4. BRD Updates
- FR-4 (Change Encryption Mode): Defer or remove pending product decision
- Salt specification: Document intentional deviation
- Iteration count: Document hybrid approach rationale

---

**Last Updated:** 2025-11-08
**Audit Method:** Full code review with execution flow tracing
**Auditor:** Web Claude
