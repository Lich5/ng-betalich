# Architecture Decision Record: SSH Key Encryption Mode Removal

**Date:** 2025-11-16
**Status:** DECIDED - REMOVED FROM SCOPE
**Decision Maker:** Product Owner (Doug)
**Documented By:** Web Claude

---

## Context

The original BRD (BRD_Password_Encryption.md) specified **four encryption modes**:

1. **ENC-1:** Plaintext (no encryption)
2. **ENC-2:** Standard (AES-256-CBC with account name as key)
3. **ENC-3:** Enhanced (AES-256-CBC with master password)
4. **ENC-4:** SSH Key (AES-256-CBC with SSH key signature)

**BRD Specification for SSH Key Mode (FR-7, FR-10):**

> **FR-7: Change SSH Key (SSH Key Mode)**
> - User can change SSH key used for encryption
> - Re-encrypts all passwords with new SSH key signature
> - Updates `ssh_key_path` and `ssh_key_fingerprint` in YAML
>
> **Priority:** SHOULD HAVE

---

## Decision

**SSH Key encryption mode (ENC-4) has been REMOVED from the project scope.**

**Affected BRD Sections:**
- FR-7: Change SSH Key (REMOVED)
- FR-10: Master Password Validation (no change - only applies to Enhanced mode)
- Phase 4: SSH Key Mode implementation (REMOVED from roadmap)
- Phase 5: Encryption Tab UI (SSH Key button removed)
- Persona 4: Developer use case (SSH Key workflow removed)

---

## Rationale

### Reasons for Removal (Product Owner Decision)

1. **Limited User Base**
   - SSH Key mode primarily benefits developers
   - Developer persona is smallest user segment
   - Most developers comfortable with Enhanced mode

2. **Complexity vs. Value**
   - Requires SSH key management education
   - Adds UI complexity for niche feature
   - Testing complexity (SSH key generation, rotation, etc.)

3. **Security Considerations**
   - Enhanced mode with strong master password provides equivalent security
   - OS keychain integration simplifies cross-device workflow
   - SSH key rotation adds operational complexity

4. **Scope Management**
   - Allows faster delivery of core features (Plaintext, Standard, Enhanced)
   - Reduces beta testing surface area
   - Can be added later if demand emerges

### Product Owner Quote

> "I determined to pull the SSH Key requirement - I think I said this yesterday but am unclear if we made it solid in our documentation, though."

---

## Consequences

### Positive

✅ **Faster Time to Beta**
- Three modes instead of four reduces implementation time
- Fewer test scenarios
- Simpler UI (no SSH key file picker)

✅ **Reduced Complexity**
- No SSH key validation logic
- No SSH key fingerprint management
- No SSH key rotation workflow

✅ **Clearer User Experience**
- Three modes easier to explain (Plaintext, Standard, Enhanced)
- Reduced cognitive load during conversion dialog

### Negative

⚠️ **Developer Workflow**
- Developers must use master password (Enhanced mode)
- No SSH agent integration
- "Yet another password" concern remains

⚠️ **Future Feature Request**
- If users request SSH key mode, must be added post-release
- Would require architecture extension (but design already exists in BRD)

### Neutral

🔵 **BRD Remains Valid**
- SSH Key mode specification preserved in BRD for future reference
- Can be implemented later if needed
- Architecture supports extension

---

## Updated Encryption Modes

### In Scope (Implemented)

| Mode | Description | Key Derivation | Cross-Device |
|------|-------------|----------------|--------------|
| **Plaintext** | No encryption | N/A | ✅ Seamless |
| **Standard** | Account-name key | PBKDF2(account_name, salt) | ✅ Seamless |
| **Enhanced** | Master password | PBKDF2(master_password, salt) | ⚠️ One-time prompt per device |

### Out of Scope (Removed)

| Mode | Description | Status |
|------|-------------|--------|
| **SSH Key** | SSH key signature | ❌ **REMOVED FROM SCOPE** |

---

## Impact on Work Units

### Completed Work Units
- ✅ Phase 1: Standard Encryption (no SSH key dependency)
- ✅ Phase 2: Enhanced Encryption (no SSH key dependency)
- ✅ Change Master Password (FR-6) (no SSH key dependency)

### Removed Work Units
- ❌ Phase 4: SSH Key Mode implementation
- ❌ FR-7: Change SSH Key functionality

### Modified Work Units
- ⚠️ **Encryption Tab UI:** Remove "Change SSH Key" button (if it was added)
- ⚠️ **Conversion Dialog:** Three modes instead of four

---

## Updated Conversion Dialog UI

### Before (BRD Spec)
```
○ Plaintext (No Encryption)
○ Standard Encryption (Account Name)
○ Enhanced Encryption (Master Password)
○ SSH Key Encryption (Advanced)  ← REMOVED
```

### After (Current Spec)
```
○ Plaintext (No Encryption)
○ Standard Encryption (Account Name)
○ Enhanced Encryption (Master Password)
```

---

## CLI Password Manager Impact

**Note:** The CLI password manager (`feat/cli-password-manager` branch) does NOT implement SSH Key mode, so this decision has **no impact** on that feature.

---

## Future Considerations

### If SSH Key Mode is Requested Later

**Implementation Path:**
1. Resurrect FR-7, Phase 4 specs from BRD
2. Implement `SshKeyManager` module (similar to `MasterPasswordManager`)
3. Add SSH key signature generation (`ssh-keygen -Y sign`)
4. Add UI for SSH key selection (file picker)
5. Update conversion dialog to include SSH Key option
6. Add "Change SSH Key" button to Encryption tab

**Estimated Effort:** 8-10 hours (per BRD Phase 4 estimate)

**Architecture:** Already designed in BRD, ready to implement if needed

---

## Documentation Updates Required

### BRD
- [x] Add note: "SSH Key mode (ENC-4) removed from initial release scope"
- [x] Mark FR-7 as "DEFERRED"
- [x] Mark Phase 4 as "DEFERRED"
- [ ] Update "IMPLEMENTATION PHASES" section with removal note

### README / CHANGELOG
- [ ] Document supported encryption modes (3 modes)
- [ ] Note SSH Key mode as potential future enhancement

### Conversion Dialog Help Text
- [ ] Remove SSH Key option
- [ ] Update help text to describe three modes

---

## Approval

**Product Owner (Doug):** ✅ APPROVED
**Web Claude (Architecture):** ✅ ACKNOWLEDGED
**CLI Claude (Implementation):** (to be informed)

---

## References

- **BRD:** `.claude/docs/BRD_Password_Encryption.md`
  - FR-7: Change SSH Key (lines 344-358)
  - Phase 4: SSH Key Mode (lines 974-989)
  - Persona 4: Developer (lines 132-148)
- **Work Units:** No SSH Key work units created (removed before work unit phase)

---

**Last Updated:** 2025-11-16
**Status:** DECIDED - REMOVED FROM SCOPE
