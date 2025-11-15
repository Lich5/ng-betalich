# Work Unit: Certificate Encryption - Phase 2 Implementation

**Created:** 2025-11-15 (Ready for Next Session)
**Status:** Specification complete, awaiting Product Owner approval before execution
**Estimated Effort:** 4-6 hours
**Target Branch:** `feat/certificate-encryption-phase2`
**Prerequisite:** `feat/password-encryption-tests-phase1-2` (merged to main)

---

## Task Summary

Implement certificate-based encryption mode as Phase 2 enhancement. This provides asymmetric encryption capability alongside existing plaintext, standard (AES-256-CBC), and master password modes. Certificate encryption enables secure password storage using public key cryptography with private key management.

---

## Phase Context

**Phase 1 (Complete):** Core encryption infrastructure
- ✅ Plaintext mode
- ✅ Standard encryption (AES-256-CBC)
- ✅ Master password (PBKDF2 key derivation)
- ✅ Entry.dat → entry.yaml conversion
- ✅ Account manager integration
- ✅ 96+ tests

**Phase 2 (In Progress):** Enhanced security and platform integration
- ✅ Windows PasswordVault integration (tests extracted)
- ✅ Conversion UI dialog (tests extracted)
- ⏳ **Certificate encryption (this work unit)** ← YOU ARE HERE
- ⏳ Linux secret-tool integration (next)
- ⏳ Full test suite restoration (after)

---

## Requirements Context

**From BRD Requirements:**
- **FR-4** (Windows PasswordVault): Leverage secure storage for certificate management
- **FR-5** (Linux secret-tool): Leverage secure storage for certificate management
- **Phase 2 Scope:** Enable certificate-based encryption alongside Windows/Linux keychains

**Architecture Decision:**
- Certificate mode = asymmetric (public key encryption, private key decryption)
- Separate from master password mode (symmetric PBKDF2 key derivation)
- Integration with OS keychains for private key storage (Phase 2+)

---

## Implementation Scope

### Core Encryption Implementation

**File:** `lib/common/gui/password_cipher.rb`
**Existing Implementation:**
- ✅ `encrypt(password, account_name, mode: :standard, master_password: nil)`
- ✅ `decrypt(encrypted_data, account_name, mode: :standard, master_password: nil)`
- ✅ Modes: `:plaintext`, `:standard`, `:master_password`
- ✅ Tests: 18 examples in password_cipher_spec.rb

**Add Certificate Mode:**
1. Add `:certificate` as valid mode option
2. Implement certificate-based encryption:
   - Public key encryption of password
   - Private key decryption capability
   - Error handling for missing/invalid certificates
3. Add 8-12 new test examples covering:
   - Certificate validation before encrypt
   - Encryption with public key
   - Decryption with private key
   - Error handling (missing cert, invalid format)
   - Edge cases (empty password, long passwords)

### Certificate Management

**File:** `lib/common/gui/certificate_manager.rb` (NEW)
**Scope:**
- Certificate validation (X.509 format)
- Public/private key pair management
- Private key storage location handling
- Fallback to plaintext on validation failure
- Reference existing `master_password_manager.rb` pattern for consistency

**Implementation Details:**
```ruby
module Lich::Common::GUI
  class CertificateManager
    # Validate certificate format and expiry
    def self.validate_certificate(cert_path)
      # Return: true if valid, false if invalid/expired
    end

    # Retrieve public key from certificate
    def self.public_key(cert_path)
      # Return: OpenSSL::PKey::RSA public key
    end

    # Retrieve private key (from keychain or fallback)
    def self.private_key(cert_path, password = nil)
      # Return: OpenSSL::PKey::RSA private key
    end

    # Check if certificate mode is available
    def self.certificate_available?
      # Return: boolean
    end
  end
end
```

**Tests:** 10-15 examples covering:
- Certificate validation
- Public key extraction
- Private key retrieval
- Keychain integration (stub for Phase 2)
- Error handling

### YAML State Management Integration

**File:** `lib/common/gui/yaml_state.rb`
**Update Encryption Handling:**
- ✅ Already supports mode-aware encryption (plaintext, standard, master_password)
- Add `:certificate` mode support:
  - Store encrypted password with certificate reference
  - Store certificate path in entry.yaml
  - Decrypt using appropriate key management
  - Handle migration from other modes

**Tests:** 4-6 new examples in yaml_state_spec.rb:
- Certificate mode encryption/decryption
- Certificate path storage
- Mode-aware decryption logic

### Account Manager Integration

**File:** `lib/common/gui/account_manager.rb`
**Updates:**
- ✅ Already supports mode-aware encryption
- Add certificate validation on account operations
- Error handling for missing certificates
- Fallback behavior (e.g., if certificate unavailable)

**Tests:** 3-5 new examples in account_manager_spec.rb:
- Account CRUD with certificate mode
- Certificate validation on save
- Fallback on invalid certificate

### Conversion UI Enhancement

**File:** `lib/common/gui/conversion_ui.rb`
**Add Certificate Option:**
- ✅ Already supports mode selection dialog (plaintext, standard, master_password, enhanced)
- Add `:certificate` as new mode option
- Require certificate path selection if mode chosen
- Validate certificate before applying conversion
- Show appropriate warning for certificate mode

**Tests:** 4-6 new examples in conversion_ui_spec.rb:
- Certificate option availability
- Certificate path selection dialog
- Validation before mode switch
- Platform-specific behavior

---

## Test-Driven Development Approach

### Test Files (All NEW - No Extraction)

1. **`spec/certificate_manager_spec.rb`** (10-15 examples)
   - Certificate validation and format checking
   - Public key extraction from certificate
   - Private key retrieval and caching
   - Error handling and fallback

2. **`spec/password_cipher_cert_spec.rb`** (8-12 examples)
   - `:certificate` mode encryption/decryption
   - Certificate requirement validation
   - Public key encryption correctness
   - Private key decryption correctness

3. **Updates to Existing Specs:**
   - `password_cipher_spec.rb`: +8-12 examples
   - `yaml_state_spec.rb`: +4-6 examples
   - `account_manager_spec.rb`: +3-5 examples
   - `conversion_ui_spec.rb`: +4-6 examples

**Total New Tests:** 25-40 examples (TBD based on implementation depth)

---

## Acceptance Criteria

### Functional Requirements

- [ ] Certificate mode implemented in password_cipher.rb
- [ ] Encrypts passwords using certificate public key
- [ ] Decrypts passwords using private key
- [ ] Validates certificates before use (format, expiry)
- [ ] Handles missing/invalid certificates gracefully
- [ ] Integrates with YAML state management
- [ ] Integrates with account manager CRUD
- [ ] Certificate option added to conversion UI
- [ ] Prompts for certificate path when mode selected
- [ ] Handles mode conversion from other modes to certificate

### Test Requirements

- [ ] All 25-40 new tests passing
- [ ] 0 RuboCop violations
- [ ] 0 SSH Key contamination (unrelated mode)
- [ ] Combined suite runs in <3 seconds
- [ ] All extracted Phase 1-2 tests still passing
- [ ] Code coverage ≥85% for certificate-related code

### Code Quality

- [ ] RuboCop: 0 offenses
- [ ] YARD documentation on all public methods
- [ ] Clear error messages for common failures
- [ ] Consistent with existing mode implementations
- [ ] No code duplication with master password mode

### Git Requirements

- [ ] Conventional commit: `feat(all): implement certificate-based encryption mode`
- [ ] Detailed commit body describing implementation scope
- [ ] All commits follow project conventions

---

## Architecture Notes

### Design Patterns (From Phase 1)

**Reference Pattern 1: Master Password Mode**
- Located in: `password_cipher.rb` (lines ~150-200)
- Pattern: Mode-specific parameter + dedicated validation
- Use this pattern for certificate mode implementation

**Reference Pattern 2: Mode Integration**
- Located in: `yaml_state.rb` (lines ~60-120)
- Pattern: case statement on mode, mode-specific encryption logic
- Use this pattern for YAML integration

**Reference Pattern 3: Error Handling**
- Located in: `password_cipher.rb` (lines ~80-100)
- Pattern: Explicit error types + clear messages
- Match this style for certificate errors

### Key Differences from Master Password

| Aspect | Master Password | Certificate |
|--------|-----------------|-------------|
| Key Type | Symmetric (PBKDF2 derived) | Asymmetric (RSA pair) |
| Key Storage | User provides at runtime | Certificate + private key |
| Validation | Password strength check | Certificate validity check |
| Error Recovery | Fallback impossible | Fallback to plaintext possible |
| Platform Integration | None (Phase 1) | Keychains (Phase 2+) |

---

## Platform Considerations

### Phase 2 Implementation (This Work Unit)

**Windows Preparation:**
- Tests should mock Windows-specific behavior
- Reference `windows_keychain_spec.rb` for mocking patterns
- Don't implement actual Windows integration yet (Phase 2+)

**Linux Preparation:**
- Tests should mock Linux secret-tool integration
- Reference `master_password_manager_spec.rb` for keychain patterns
- Don't implement actual Linux integration yet (Phase 2+)

**macOS (Phase 1 Desktop Testing):**
- Test certificate loading from file system
- Test basic encrypt/decrypt cycle
- Platform-agnostic until keychain integration

---

## Edge Cases to Handle

1. **Missing Certificate File**
   - Detection: File not found on decrypt
   - Behavior: Clear error, fallback to plaintext (if applicable)
   - Test: 1 example

2. **Invalid Certificate Format**
   - Detection: Non-PEM, corrupted, or wrong type
   - Behavior: Error message + skip mode
   - Test: 1 example

3. **Expired Certificate**
   - Detection: Validity date check on validation
   - Behavior: Warn user, allow override (?) or skip mode
   - Test: 1 example

4. **Very Long Passwords**
   - Edge case: RSA key size limits (2048-bit = ~245 bytes max)
   - Behavior: Explicit error if password too long
   - Test: 1 example

5. **Empty Password**
   - Edge case: Empty string encryption/decryption
   - Behavior: Allow (consistent with other modes)
   - Test: 1 example

6. **Unicode/Special Characters**
   - Edge case: Non-ASCII passwords
   - Behavior: Handle gracefully (consistent with other modes)
   - Test: 1 example

---

## Questions & Blockers

### Before Starting

**Q1: Certificate Source?**
- Will certificates be user-provided or auto-generated?
- Affects: CertificateManager implementation, error handling
- **Status:** Awaiting Product Owner clarification

**Q2: Private Key Storage?**
- Phase 1: File system only (testing)
- Phase 2: Windows PasswordVault + Linux secret-tool
- **Status:** Confirmed - use file system for Phase 1

**Q3: Fallback Behavior?**
- If certificate unavailable: Skip mode? Force plaintext? Error?
- Affects: Error handling, UX flow
- **Status:** Tentative - graceful error + skip mode option

**Q4: Certificate Format?**
- X.509 PEM format assumed, or support others?
- Affects: Validation logic, test certificates
- **Status:** Assumed PEM, confirm before implementation

---

## Implementation Notes

### Reference Code Locations

- **password_cipher.rb:** `lib/common/gui/password_cipher.rb`
  - Study: `:master_password` mode implementation (lines 150-200)
  - Study: Error handling pattern (lines 80-100)
  - Study: Mode parameter structure (lines 1-50)

- **yaml_state.rb:** `lib/common/gui/yaml_state.rb`
  - Study: Mode-aware encryption (lines 60-120)
  - Study: Decryption logic (lines 130-180)
  - Study: Migration handling (if applicable)

- **account_manager.rb:** `lib/common/gui/account_manager.rb`
  - Study: Mode parameter passing (throughout)
  - Study: Error propagation

- **conversion_ui.rb:** `lib/common/gui/conversion_ui.rb`
  - Study: Mode options dialog (lines 100-150)
  - Study: Signal handling (lines 200-250)

- **Test Reference:** `spec/password_cipher_spec.rb`
  - Study: Test mocking patterns (lines 1-100)
  - Study: Example structure for each mode

---

## Rollback Plan

**If Implementation Blocked:**

```bash
# Reset to Phase 1-2 completion
git reset --hard feat/password-encryption-tests-phase1-2
git branch -D feat/certificate-encryption-phase2

# Alternative: Create minimal certificate stub
# - Add :certificate option to password_cipher.rb
# - Raise NotImplementedError for now
# - Tests all skipped (pending implementation)
```

**If Tests Too Complex:**
- Defer error handling edge cases to separate work unit
- Defer platform integration tests (Phase 2)
- Deliver core encrypt/decrypt tests only

---

## Success Criteria

**When Complete:**
1. ✅ All acceptance criteria met
2. ✅ All new tests passing
3. ✅ All Phase 1-2 tests still passing
4. ✅ Code quality verified
5. ✅ Ready for merge to main

**Ready For:** Next work unit on Linux/Windows integration or Phase 2 platform support

---

## Next Work Unit (Phase 2+)

**After This Unit Completes:**
1. Windows PasswordVault certificate integration
2. Linux secret-tool certificate integration
3. Full test restoration (300+ examples)
4. Additional encryption modes (SSH Key? Other?)

---

**Status:** ✅ Ready for Product Owner approval
**Ready to:** Await user confirmation before CLI Claude execution begins
