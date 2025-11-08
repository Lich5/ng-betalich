# Business Requirements Document (BRD)
## Lich 5 Password Encryption Feature

**Document Version:** 1.0  
**Date:** November 1, 2025  
**Status:** Ready for Implementation  
**Product Owner:** Doug  
**Development Team:** Claude (Sonnet 4.5)

---

## EXECUTIVE SUMMARY

Lich 5 currently stores game account passwords in plaintext YAML files. This feature adds four encryption modes to balance security, accessibility, and user experience while maintaining zero regression on existing functionality.

**Key Deliverable:** Password encryption with four modes (Plaintext, Standard, Enhanced, SSH Key)

**Primary Driver:** Reduce risk of password compromise while accommodating diverse user needs (accessibility, convenience, security)

**Timeline:** Phased delivery - Standard Encryption first (12-16 hours), then Enhanced + SSH Key modes

**Beta Scope:** All four encryption modes

---

## BACKGROUND & CONTEXT

### Current State

**System:** Lich 5 - Middleware between Simutronics game servers and game frontends  
**Games:** GemStone IV, DragonRealms  
**Clients:** Wrayth, Avalon (macOS only), third-party frontends  
**Storage:** `entry.yaml` file with plaintext passwords  
**User Base:** Non-technical users expecting "light switch" simplicity

### Problem Statement

1. **Password Exposure:** Passwords stored in plaintext YAML files are readable by anyone with file system access
2. **Multi-Device Usage:** Users sync files via cloud services (iCloud, Dropbox, OneDrive), increasing exposure risk
3. **Accessibility Gap:** No accommodation for users requiring screen readers (GTK3 has poor accessibility support)
4. **Developer Workflow:** Power users (developers) want SSH key-based encryption without "another password to remember"

### Business Impact

- **Risk:** Password compromise if files accessed by malicious actors or cloud service breaches
- **User Trust:** Perception that Lich doesn't protect credentials
- **Accessibility Compliance:** Inability to serve visually impaired users
- **Competitive Position:** Other game middleware may offer better credential protection

---

## BUSINESS OBJECTIVES

### Primary Objectives

1. **Reduce Password Compromise Risk** - Encrypt passwords at rest while maintaining usability
2. **Zero Regression** - All existing workflows must continue unchanged
3. **Accessibility Compliance** - Provide plaintext option for screen reader users
4. **Cross-Device Compatibility** - Encryption works seamlessly across user's devices

### Secondary Objectives

1. **Developer Experience** - Accommodate SSH key-based workflows
2. **User Control** - Allow users to change encryption modes at any time
3. **Recovery Paths** - Provide clear recovery when users forget credentials

### Non-Objectives (Out of Scope)

- ❌ Protection against malicious scripts running in Lich environment (future: `script.rb` rewrite)
- ❌ Two-factor authentication or passkeys
- ❌ Encryption of character metadata or favorites (only passwords encrypted)
- ❌ Backward compatibility with entry.dat format (conversion is one-way)

---

## USER PERSONAS & USE CASES

### Persona 1: Casual Gamer (Primary)

**Profile:**
- Non-technical user
- Uses one or two accounts
- Plays on laptop + desktop (cloud sync via iCloud/Dropbox)
- Expects things to "just work"

**Use Cases:**
- UC-1: Choose encryption during initial setup
- UC-2: Click "Play" - automatic password decryption with no prompts (after initial setup)
- UC-3: Change password when required by game server
- UC-4: Sync files to new device - one-time password entry, then seamless

**Preferred Mode:** Enhanced Security (master password)

---

### Persona 2: Accessibility User

**Profile:**
- Visually impaired
- Uses screen reader software
- Cannot navigate GTK3 dialogs effectively
- Needs to read/edit password file directly

**Use Cases:**
- UC-5: Choose plaintext mode for accessibility
- UC-6: Open `entry.yaml` in text editor with screen reader
- UC-7: Read passwords aloud via screen reader
- UC-8: Manually edit passwords in text file

**Preferred Mode:** Plaintext (no encryption)

---

### Persona 3: Multi-Accounter (Power User)

**Profile:**
- Manages 4+ game accounts
- 20+ characters across accounts
- Uses favorites feature extensively
- Syncs across 3+ devices

**Use Cases:**
- UC-9: Choose encryption that doesn't require re-entry on each device
- UC-10: Change account passwords frequently (game security policy)
- UC-11: Recover from forgotten master password without losing character list
- UC-12: Switch encryption modes based on threat assessment

**Preferred Mode:** Standard or Enhanced (depends on security vs convenience preference)

---

### Persona 4: Developer

**Profile:**
- Software developer
- Uses password manager for all credentials (1Password, Bitwarden)
- Uses SSH keys for all authentication
- Philosophically opposed to "yet another password"

**Use Cases:**
- UC-13: Use existing SSH key for encryption
- UC-14: No password prompts - SSH agent handles authentication
- UC-15: Rotate SSH keys without losing passwords
- UC-16: Works in headless/SSH environments

**Preferred Mode:** SSH Key Security

---

## FUNCTIONAL REQUIREMENTS

### FR-1: Four Encryption Modes

**Requirement:** System shall support four encryption modes selectable by user.

| Mode ID | Mode Name | Encryption Method | Key Storage | Cross-Device |
|---------|-----------|-------------------|-------------|--------------|
| ENC-1 | Plaintext | None | N/A | ✅ Yes |
| ENC-2 | Standard | AES-256-CBC with account name as key | Deterministic | ✅ Yes |
| ENC-3 | Enhanced | AES-256-CBC with master password | OS Keychain | ⚠️ One-time prompt per device |
| ENC-4 | SSH Key | AES-256-CBC with SSH key signature | SSH key file | ⚠️ SSH key must be present |

**Business Rule:** User chooses mode once during initial conversion from `entry.dat` to `entry.yaml`

**Priority:** MUST HAVE

---

### FR-2: Conversion Flow (entry.dat → entry.yaml)

**Requirement:** On first launch, if `entry.dat` exists and `entry.yaml` does not exist, system shall present conversion dialog.

**Conversion Dialog Requirements:**

1. **Modal dialog** - User cannot proceed without choice
2. **Four radio button options** - One for each encryption mode
3. **Mode descriptions** - Brief explanation of each mode
4. **Plaintext warning** - Special confirmation for plaintext mode (accessibility justification required)
5. **Enhanced mode prompt** - If chosen, prompt for master password (enter twice for confirmation)
6. **SSH Key mode prompt** - If chosen, file picker to select SSH private key
7. **Convert button** - Executes conversion with chosen mode
8. **Cancel button** - Exits application (no partial conversion)

**Conversion Process:**

1. Read `entry.dat` (MD5-hashed passwords)
2. Convert to YAML structure
3. Encrypt passwords based on chosen mode
4. Save as `entry.yaml` with `security_mode` metadata
5. Leave `entry.dat` unmodified (both files coexist)
6. Future launches: YAML takes precedence

**Business Rule:** Conversion is one-time, irreversible (without manual intervention)

**Priority:** MUST HAVE

---

### FR-3: Password Encryption/Decryption

**Requirement:** System shall encrypt passwords on save and decrypt on load based on active encryption mode.

**Encryption Specifications:**

- **Algorithm:** AES-256-CBC
- **Key Derivation:** PBKDF2-HMAC-SHA256, 100,000 iterations
- **IV:** Random 16 bytes per encryption operation
- **Output Format:** Base64-encoded `{iv, ciphertext}` stored in YAML

**Mode-Specific Key Derivation:**

**ENC-2 (Standard):**
```
Key = PBKDF2(account_name, 'lich5-login-salt-v1', 100000, 32, SHA256)
```

**ENC-3 (Enhanced):**
```
Key = PBKDF2(master_password, 'lich5-login-salt-v1', 100000, 32, SHA256)
```

**ENC-4 (SSH Key):**
```
SSH_signature = ssh-keygen -Y sign -f key_path -n lich5
Key = PBKDF2(SSH_signature, salt, 100000, 32, SHA256)
```

**Business Rule:** Decryption must be transparent - existing code sees plaintext password, encryption handled at storage layer

**Priority:** MUST HAVE

---

### FR-4: Change Encryption Mode

**Requirement:** User shall be able to change encryption mode at any time via Account Management UI.

**Process:**

1. User clicks "Change Encryption Mode" button
2. System displays current mode
3. User selects target mode (radio buttons)
4. If changing FROM Enhanced mode: User must enter master password for validation
5. System creates backup: `entry.yaml.bak`
6. System decrypts all passwords with current method
7. System re-encrypts all passwords with new method
8. System updates `security_mode` metadata
9. If leaving Enhanced mode: System removes master password from OS keychain
10. System saves updated `entry.yaml`

**Business Rules:**
- Backup created before any destructive operation
- Enhanced mode exit requires password validation (two layers: keychain comparison + PBKDF2 validation test)
- Progress indication shown during re-encryption
- Success/failure messaging

**Priority:** MUST HAVE

---

### FR-5: Change Account Password

**Requirement:** User shall be able to change password for any account in any encryption mode.

**Process:**

1. User selects account from list
2. User clicks "Change Account Password"
3. System prompts for new password (enter twice for confirmation)
4. System creates backup: `entry.yaml.bak`
5. System decrypts old password (if encrypted mode)
6. System encrypts new password with current encryption method
7. System saves updated `entry.yaml`

**Mode-Specific Behavior:**

- **Plaintext:** Direct update, no encryption
- **Standard:** Decrypt with account name, update, re-encrypt with account name
- **Enhanced:** Decrypt with master password (from keychain), update, re-encrypt
- **SSH Key:** Decrypt with SSH key signature, update, re-encrypt

**Business Rule:** No additional prompts for Standard/Plaintext modes (seamless)

**Priority:** MUST HAVE

---

### FR-6: Change Master Password (Enhanced Mode)

**Requirement:** In Enhanced mode, user shall be able to change master password.

**Process:**

1. User clicks "Change Master Password"
2. System prompts for current master password
3. System validates current password (two layers: keychain + PBKDF2 test)
4. System prompts for new master password (enter twice)
5. System creates backup: `entry.yaml.bak`
6. System decrypts all passwords with old master password
7. System re-encrypts all passwords with new master password
8. System updates PBKDF2 validation test in YAML
9. System updates master password in OS keychain
10. System saves updated `entry.yaml`

**Business Rule:** Current password must be validated before change is allowed

**Priority:** MUST HAVE

---

### FR-7: Change SSH Key (SSH Key Mode)

**Requirement:** In SSH Key mode, user shall be able to change SSH key.

**Process:**

1. User clicks "Change SSH Key"
2. System presents file picker for new SSH private key
3. System creates backup: `entry.yaml.bak`
4. System decrypts all passwords with old SSH key signature
5. System re-encrypts all passwords with new SSH key signature
6. System updates `ssh_key_path` and `ssh_key_fingerprint` in YAML
7. System saves updated `entry.yaml`

**Business Rule:** Old SSH key must be available for decryption during change

**Priority:** SHOULD HAVE

---

### FR-8: Password Recovery (Cannot Decrypt)

**Requirement:** When system cannot decrypt passwords (forgot master password, lost SSH key, file tampering), system shall provide recovery workflow.

**Trigger Conditions:**

- Enhanced mode: Master password not in keychain AND user doesn't know it
- SSH Key mode: SSH key file missing or changed
- Any encrypted mode: Decryption fails (tampering detected)

**Recovery Process:**

1. System detects decryption failure
2. System displays "Password Recovery" dialog
3. Dialog explains situation (cannot decrypt)
4. Dialog lists accounts requiring password re-entry
5. User selects NEW encryption mode (may be different from current)
6. If Enhanced mode chosen: User enters NEW master password
7. If SSH Key mode chosen: User selects NEW SSH key
8. For each account: System prompts for password (showing character list for context)
9. System creates backup: `entry.yaml.unrecoverable.{timestamp}`
10. System creates new `entry.yaml` with new encryption mode and re-entered passwords
11. Character metadata preserved (favorites, custom launch, etc.)

**Business Rules:**
- Combined workflow: Choose new mode + re-enter passwords in single operation
- Account/character structure preserved
- Unrecoverable file backed up with timestamp
- Cannot proceed without re-entering ALL passwords

**Priority:** MUST HAVE

---

### FR-9: Corruption Detection & Recovery

**Requirement:** System shall detect file corruption and offer recovery options.

**Corruption Types:**

**Type 1: YAML Parse Error (File Corruption)**
- **Detection:** `YAML.load_file` raises `Psych::SyntaxError`
- **Action:** Check if `entry.yaml.bak` exists and is valid
- **Recovery:** Prompt user to restore from backup

**Type 2: Decryption Failure**
- **Detection:** `OpenSSL::Cipher::CipherError` during decryption
- **Action:** Distinguish between wrong password vs tampering
- **Recovery:** Enhanced mode - prompt for password; Others - trigger password recovery

**Type 3: Both Files Corrupt**
- **Detection:** Both `entry.yaml` and `entry.yaml.bak` fail to load
- **Action:** Offer "Re-enter Accounts" option
- **Recovery:** Delete corrupted files, start fresh with manual entry

**Backup Restoration Process:**

1. System detects `entry.yaml` corruption
2. System checks if `entry.yaml.bak` exists and is valid
3. System displays confirmation dialog: "Restore from backup?"
4. User clicks "Restore"
5. System copies `entry.yaml.bak` to `entry.yaml` (NEVER deletes backup)
6. System creates timestamped archive: `entry.yaml.bak.restored.{timestamp}`
7. System reloads data
8. Success message shown

**Business Rules:**
- NEVER delete backup file during recovery
- Always ask permission before restoring from backup (no automatic restoration)
- Preserve backup even after successful restore
- Clear error messages distinguishing corruption types

**Priority:** MUST HAVE

---

### FR-10: Master Password Validation (Enhanced Mode)

**Requirement:** System shall validate master password before storing in OS keychain to prevent wrong password storage.

**Validation Test Structure:**

Stored in `entry.yaml`:
```yaml
master_password_test:
  validation_salt: "base64_encoded_32_byte_salt"
  validation_hash: "base64_encoded_sha256_hash"
  validation_version: 1
```

**Validation Process:**

**Creating Test (during conversion or master password change):**
1. Generate random 32-byte salt
2. Derive validation key: `PBKDF2(master_password, salt, 100000, 32, SHA256)`
3. Hash validation key: `SHA256(validation_key)`
4. Store salt and hash in YAML

**Validating Password (before storing in keychain):**
1. Read salt from YAML
2. Derive validation key from entered password: `PBKDF2(entered_password, salt, 100000, 32, SHA256)`
3. Hash derived key: `SHA256(validation_key)`
4. Compare hashes using constant-time comparison
5. If match: Store password in keychain
6. If mismatch: Reject password, prompt again

**Business Rules:**
- Validation happens BEFORE keychain storage (prevents wrong password in keychain)
- Uses PBKDF2 + SHA256 for cryptographic strength
- Constant-time comparison prevents timing attacks
- Random salt per file (prevents rainbow table attacks)

**Priority:** MUST HAVE

---

### FR-11: File Management

**Requirement:** System shall manage backup files and maintain file security.

**Backup Strategy:**

- **Trigger:** Every save operation (`YamlState.save_entries`)
- **Backup File:** `entry.yaml.bak` (single backup, overwrites previous)
- **Content:** Complete copy of `entry.yaml` including metadata
- **Rotation:** No rotation (only most recent backup kept)

**Special Backups:**

- **Unrecoverable:** `entry.yaml.unrecoverable.{timestamp}` (password recovery scenarios)
- **Restored:** `entry.yaml.bak.restored.{timestamp}` (after backup restoration)

**File Permissions:**

- **Unix/macOS:** Set file mode to 0600 (owner read/write only)
- **Windows:** Skip permission setting (NTFS permissions complex, out of scope)

**Business Rules:**
- Backup created BEFORE any destructive operation
- Never delete backups automatically
- Timestamped backups for audit trail

**Priority:** MUST HAVE

---

### FR-12: Multi-Installation Support

**Requirement:** System shall support multiple Lich installations on same machine without keychain conflicts.

**Implementation:**

- **Keychain Key:** `lich5.master_password` (shared across installations)
- **Retrieval Logic:** Only retrieve from keychain if file's `security_mode = "enhanced"`
- **Behavior:** Standard/Plaintext/SSH Key modes ignore keychain entirely

**Business Rule:** Installation-specific keychains out of scope (adds complexity without clear benefit)

**Priority:** SHOULD HAVE

---

## NON-FUNCTIONAL REQUIREMENTS

### NFR-1: Performance

- **Encryption/Decryption:** < 100ms per password
- **File Load:** < 500ms for 100 accounts
- **Mode Change:** < 5 seconds for re-encrypting 100 passwords

### NFR-2: Security

- **Algorithm:** AES-256-CBC (industry standard)
- **Key Derivation:** PBKDF2-HMAC-SHA256, 100,000 iterations
- **IV:** Random, unique per encryption operation
- **Constant-Time Comparison:** Prevents timing attacks
- **No Plaintext in Logs:** Sanitize passwords from log output

### NFR-3: Compatibility

- **Ruby Version:** Standard library only (no external gems for encryption)
- **OS Support:** macOS, Windows, Linux
- **OS Keychain:** Graceful degradation if keychain unavailable

### NFR-4: Usability

- **Zero Regression:** All existing workflows unchanged
- **One-Click Play:** Maintains current UX (no additional prompts after setup)
- **Clear Errors:** User-friendly messages (avoid technical jargon)
- **Progress Indication:** Show progress for long operations (re-encryption)

### NFR-5: Accessibility

- **Plaintext Mode:** Full screen reader support via direct file access
- **Keyboard Navigation:** All dialogs keyboard-accessible
- **Clear Labels:** All UI elements properly labeled for assistive technology

### NFR-6: Maintainability

- **SOLID Principles:** Follow single responsibility, open/closed, etc.
- **DRY Code:** No duplication, reusable components
- **Documentation:** Inline comments + YARD documentation
- **Testing:** Unit, functional, integration tests for all modes

---

## USER INTERFACE REQUIREMENTS

### UI-1: New "Encryption" Tab

**Location:** Main notebook, alongside "Saved Entry", "Manual Entry", "Account Management"

**Content:**

```
┌─────────────────────────────────────────────┐
│ Encryption                                  │
│                                             │
│ Current Encryption: Enhanced (Master Pass) │
│                                             │
│ Encryption reduces risk of password         │
│ compromise if your files are accessed by    │
│ others.                                     │
│                                             │
│ [Change Encryption Mode]                    │
│                                             │
│ [Change Account Password]                   │
│                                             │
│ [Change Master Password]  ← Enhanced only   │
│                                             │
│ [Change SSH Key]          ← SSH Key only    │
│                                             │
└─────────────────────────────────────────────┘
```

**Terminology Requirements:**
- ❌ Do NOT use: "security", "secure", "protection"
- ✅ DO use: "encryption", "encryption mode", "risk of password compromise"

**Priority:** MUST HAVE

---

### UI-2: Conversion Dialog

**Trigger:** First launch when `entry.dat` exists and `entry.yaml` does not

**Layout:**

```
┌────────────────────────────────────────────────────┐
│ Data Conversion & Encryption Setup                │
│                                                    │
│ Your saved entries will be converted to YAML.     │
│ Choose your encryption level:                     │
│                                                    │
│ ○ Plaintext (No Encryption)                       │
│   For accessibility - screen reader compatible    │
│   ⚠️ Passwords visible in file                    │
│                                                    │
│ ○ Standard Encryption (Account Name)              │
│   Basic encryption, works across devices          │
│   Equivalent to previous Lich encryption          │
│                                                    │
│ ○ Enhanced Encryption (Master Password)           │
│   Strong encryption, one password per device      │
│   Recommended for most users                      │
│                                                    │
│ ○ SSH Key Encryption (Advanced)                   │
│   Uses SSH private key, no password to remember   │
│   For developers familiar with SSH keys           │
│                                                    │
│ [Convert & Apply] [Cancel]                        │
└────────────────────────────────────────────────────┘
```

**Conditional Dialogs:**

**If Plaintext selected:**
```
┌────────────────────────────────────────────────────┐
│ Plaintext Mode Selected                           │
│                                                    │
│ Plaintext mode stores passwords unencrypted.      │
│                                                    │
│ This mode is provided for accessibility purposes  │
│ to allow screen readers to read passwords from    │
│ the entry.yaml file directly.                     │
│                                                    │
│ ⚠️ Risk: Anyone with access to your file system  │
│ can read your passwords.                          │
│                                                    │
│ Continue with Plaintext mode?                     │
│                                                    │
│ [Yes, Use Plaintext] [Choose Different Mode]      │
└────────────────────────────────────────────────────┘
```

**If Enhanced selected:**
```
┌────────────────────────────────────────────────────┐
│ Create Master Password                            │
│                                                    │
│ Enter master password:                            │
│ [____________________]                            │
│                                                    │
│ Confirm master password:                          │
│ [____________________]                            │
│                                                    │
│ This password will be required once on each       │
│ device where you use Lich.                        │
│                                                    │
│ [Continue] [Cancel]                               │
└────────────────────────────────────────────────────┘
```

**If SSH Key selected:**
```
┌────────────────────────────────────────────────────┐
│ Select SSH Private Key                            │
│                                                    │
│ Choose SSH private key for encryption:            │
│                                                    │
│ [~/.ssh/id_ed25519          ] [Browse...]         │
│                                                    │
│ ⚠️ Important:                                     │
│ • If you change/lose this SSH key, you will      │
│   need to re-enter all passwords                 │
│ • Recommended: Use dedicated key for Lich        │
│                                                    │
│ [Continue] [Cancel]                               │
└────────────────────────────────────────────────────┘
```

**Priority:** MUST HAVE

---

### UI-3: Change Encryption Mode Dialog

**Trigger:** User clicks "Change Encryption Mode" in Encryption tab

**Layout:**

```
┌────────────────────────────────────────────────────┐
│ Change Encryption Mode                            │
│                                                    │
│ Current: Enhanced Encryption (Master Password)    │
│                                                    │
│ Select new encryption mode:                       │
│ ○ Plaintext (No Encryption)                       │
│ ○ Standard Encryption (Account Name)              │
│ ○ Enhanced Encryption (Master Password)           │
│ ○ SSH Key Encryption (Advanced)                   │
│                                                    │
│ ⚠️ All passwords will be decrypted and           │
│    re-encrypted with the new method.             │
│                                                    │
│ [Continue] [Cancel]                               │
└────────────────────────────────────────────────────┘
```

**If changing FROM Enhanced mode:**
```
┌────────────────────────────────────────────────────┐
│ Verify Master Password                            │
│                                                    │
│ To change from Enhanced Encryption, please        │
│ enter your master password:                       │
│                                                    │
│ Master Password: [____________________]           │
│                                                    │
│ [Confirm Change] [Cancel]                         │
└────────────────────────────────────────────────────┘
```

**Priority:** MUST HAVE

---

### UI-4: Change Account Password Dialog

**Trigger:** User clicks "Change Account Password" in Encryption tab

**Layout:**

```
┌────────────────────────────────────────────────────┐
│ Change Password - DOUG                            │
│                                                    │
│ Current Encryption: Standard (Account Name)       │
│                                                    │
│ New password for DOUG:                            │
│ [____________________]                            │
│                                                    │
│ Confirm new password:                             │
│ [____________________]                            │
│                                                    │
│ [Change Password] [Cancel]                        │
└────────────────────────────────────────────────────┘
```

**Priority:** MUST HAVE

---

### UI-5: Password Recovery Dialog

**Trigger:** Decryption fails (forgot password, lost key, tampering)

**Layout:**

```
┌────────────────────────────────────────────────────┐
│ Password Recovery Required                        │
│                                                    │
│ Cannot decrypt passwords with current             │
│ credentials. You will need to re-enter all        │
│ account passwords manually.                       │
│                                                    │
│ Accounts requiring password re-entry:             │
│   • DOUG                                          │
│   • EBONDEMON                                     │
│   • MORED                                         │
│                                                    │
│ Choose new encryption mode:                       │
│ ○ Plaintext                                       │
│ ○ Standard Encryption                             │
│ ○ Enhanced Encryption (new master password)      │
│ ○ SSH Key Encryption (select new key)            │
│                                                    │
│ [Begin Recovery] [Cancel]                         │
└────────────────────────────────────────────────────┘
```

**Sequential prompts for each account:**
```
┌────────────────────────────────────────────────────┐
│ Re-enter Password for DOUG                        │
│                                                    │
│ Characters: Dionket, Aglarin, Ghudhxe, ...        │
│                                                    │
│ Password: [____________________]                  │
│                                                    │
│ [Next Account] [Cancel]                           │
└────────────────────────────────────────────────────┘
```

**Priority:** MUST HAVE

---

### UI-6: Backup Restoration Dialog

**Trigger:** File corruption detected, backup available

**Layout:**

```
┌────────────────────────────────────────────────────┐
│ File Corruption Detected                          │
│                                                    │
│ Your login file (entry.yaml) is corrupted and    │
│ cannot be loaded.                                 │
│                                                    │
│ A backup file is available:                       │
│   entry.yaml.bak                                  │
│                                                    │
│ Restore from backup?                              │
│                                                    │
│ Note: Changes since last backup may be lost.     │
│                                                    │
│ [Restore from Backup] [Cancel and Exit]           │
└────────────────────────────────────────────────────┘
```

**If both files corrupt:**
```
┌────────────────────────────────────────────────────┐
│ Cannot Load Saved Accounts                        │
│                                                    │
│ Both login file and backup are corrupted.        │
│                                                    │
│ Please restore from an external backup or         │
│ manually re-enter your account details.           │
│                                                    │
│ [Re-enter Accounts] [Exit]                        │
└────────────────────────────────────────────────────┘
```

**Priority:** MUST HAVE

---

## TECHNICAL CONSTRAINTS

### Platform Constraints

- **Ruby Version:** Must use Ruby standard library (`openssl`, `securerandom`, `digest`)
- **GTK Version:** GTK3 (limited accessibility support)
- **OS Support:** macOS, Windows, Linux (Ubuntu 24+)

### Architecture Constraints

- **Zero Regression:** Cannot break existing workflows
- **Transparent Decryption:** Existing code must see plaintext passwords (encryption at storage layer)
- **Single File Format:** All modes use same YAML structure, only password field differs

### Security Constraints

- **No External Gems:** Encryption must use Ruby standard library only
- **OS Keychain:** Must work if keychain unavailable (graceful degradation)
- **Malicious Scripts:** Out of scope - requires separate `script.rb` architecture rewrite

### Performance Constraints

- **Startup Time:** Encryption must not noticeably delay application startup (< 500ms)
- **File Size:** YAML file with 100 accounts < 100KB
- **Memory:** Plaintext passwords in memory only during active use, cleared after

---

## SUCCESS CRITERIA

### Functional Success

- ✅ All four encryption modes working
- ✅ Conversion from entry.dat completes successfully
- ✅ Zero regression on existing login workflows
- ✅ Password changes work in all modes
- ✅ Encryption mode changes work in all directions
- ✅ Recovery workflows successful (forgot password, file corruption)
- ✅ Backup/restore functionality working

### Non-Functional Success

- ✅ Performance: < 100ms per password operation
- ✅ Security: No plaintext passwords in logs
- ✅ Usability: No user complaints about UX regression
- ✅ Accessibility: Plaintext mode confirmed working with screen readers (user testing)

### Business Success

- ✅ Beta users adopt encryption (> 80% uptake)
- ✅ No security incidents related to password storage
- ✅ Positive user feedback on encryption options
- ✅ Developer community adoption of SSH key mode

---

## IMPLEMENTATION PHASES

### Phase 1: Standard Encryption (Priority 1)

**Deliverables:**
- `password_cipher.rb` - AES-256-CBC encryption with account-name key derivation
- Modified `yaml_state.rb` - Encrypt on save, decrypt on load
- Modified `conversion_ui.rb` - Add Plaintext vs Standard choice
- Unit tests for encryption/decryption
- Integration tests for save/load workflows

**Acceptance Criteria:**
- Standard encryption mode working
- Conversion offers Plaintext or Standard
- Zero regression on existing workflows
- All unit tests passing

**Estimate:** 12-16 hours (human equivalent)

---

### Phase 2: Enhanced Security (Priority 2)

**Deliverables:**
- `master_password_validator.rb` - PBKDF2 validation test
- `os_keychain.rb` - OS keychain integration (macOS/Windows/Linux)
- Modified `password_cipher.rb` - Master password encryption
- Modified `conversion_ui.rb` - Add Enhanced mode option
- "Change Master Password" UI
- Unit + integration tests

**Acceptance Criteria:**
- Enhanced mode working
- Master password stored in OS keychain
- Validation test prevents wrong password storage
- Cross-device workflow tested (enter password once per device)

**Estimate:** 8-10 hours (human equivalent)

---

### Phase 3: Security Mode Changes & Recovery (Priority 3)

**Deliverables:**
- `security_mode_manager.rb` - Mode change logic
- `password_recovery.rb` - Recovery workflow
- "Change Encryption Mode" UI
- "Password Recovery" UI
- Corruption detection & backup restoration
- Integration tests for all transitions

**Acceptance Criteria:**
- All mode changes working (all directions)
- Recovery workflow successful
- Backup restoration working
- Corruption detection accurate

**Estimate:** 10-12 hours (human equivalent)

---

### Phase 4: SSH Key Mode (Priority 4)

**Deliverables:**
- `ssh_key_manager.rb` - SSH key signature integration
- Modified `password_cipher.rb` - SSH key encryption
- Modified `conversion_ui.rb` - Add SSH Key option
- "Change SSH Key" UI
- Unit + integration tests

**Acceptance Criteria:**
- SSH Key mode working
- SSH key selection functional
- Developer workflow validated

**Estimate:** 6-8 hours (human equivalent)

---

### Phase 5: New "Encryption" Tab (Priority 5)

**Deliverables:**
- New tab in main notebook
- "Change Encryption Mode" button
- "Change Account Password" button
- Conditional buttons (master password, SSH key)
- UI integration with existing tabs

**Acceptance Criteria:**
- New tab accessible
- All buttons functional
- Conditional visibility working

**Estimate:** 4-6 hours (human equivalent)

---

### Phase 6: Testing & Documentation (Priority 6)

**Deliverables:**
- Full regression test suite (RSpec)
- Security audit scenarios
- User documentation (USAGE.md)
- Developer documentation (ARCHITECTURE.md)
- Migration guide (MIGRATION.md)

**Acceptance Criteria:**
- All tests passing (100+ test cases)
- Documentation complete and accurate
- Beta ready for distribution

**Estimate:** 8-10 hours (human equivalent)

---

## RISK ASSESSMENT

### High Risks

| Risk | Impact | Mitigation |
|------|--------|-----------|
| **Master password forgotten** | Users lose access to all accounts | Provide recovery workflow with password re-entry |
| **OS keychain unavailable** | Enhanced mode fails | Graceful fallback: prompt for password each launch |
| **File corruption** | Data loss | Automatic backup on every save |
| **Cross-device sync conflicts** | Passwords out of sync | Document cloud sync best practices |

### Medium Risks

| Risk | Impact | Mitigation |
|------|--------|-----------|
| **SSH key lost/rotated** | SSH Key mode users locked out | Recovery workflow + documentation |
| **Performance degradation** | Slow startup | Optimize PBKDF2 iterations, profile code |
| **Malicious script exfiltration** | Passwords stolen by bad scripts | Document limitation, plan script.rb rewrite |
| **Accessibility mode misuse** | Users choose plaintext without understanding risk | Clear warning dialog, require confirmation |

### Low Risks

| Risk | Impact | Mitigation |
|------|--------|-----------|
| **Mode change confusion** | Users accidentally downgrade encryption | Confirmation dialogs, backup before change |
| **Multiple installations conflict** | Keychain collisions | Check security_mode before keychain access |
| **Beta bugs** | Feature instability | Comprehensive testing, phased rollout |

---

## APPENDIX A: YAML FILE FORMAT EXAMPLES

### Plaintext Mode
```yaml
security_mode: plaintext
accounts:
  DOUG:
    password: MyPlaintextPassword123
    characters:
      - char_name: Dionket
        game_code: GS3
        game_name: GemStone IV
        frontend: avalon
        is_favorite: true
        favorite_order: 1
```

### Standard Mode
```yaml
security_mode: standard
accounts:
  DOUG:
    password_encrypted:
      iv: "x8KpP2VGnqI7LM3wQRsT1A=="
      ciphertext: "Ej9kQ2xLPpMzNnRWYXZ1dHl2d3h5ent=="
      version: 1
    characters:
      - char_name: Dionket
        game_code: GS3
        game_name: GemStone IV
        frontend: avalon
```

### Enhanced Mode
```yaml
security_mode: enhanced
master_password_test:
  validation_salt: "randomBase64Salt32bytes=="
  validation_hash: "sha256HashOfPBKDF2Key=="
  validation_version: 1
accounts:
  DOUG:
    password_encrypted:
      iv: "differentIVperAccount=="
      ciphertext: "encryptedWithMasterPassword=="
      version: 1
    characters:
      - char_name: Dionket
        game_code: GS3
```

### SSH Key Mode
```yaml
security_mode: ssh_key
ssh_key_path: /Users/doug/.ssh/id_lich
ssh_key_fingerprint: "SHA256:abc123def456..."
accounts:
  DOUG:
    password_encrypted:
      iv: "uniqueIVforThisPassword=="
      ciphertext: "encryptedWithSSHKeySignature=="
      version: 1
    characters:
      - char_name: Dionket
        game_code: GS3
```

---

## APPENDIX B: GLOSSARY

**AES-256-CBC** - Advanced Encryption Standard with 256-bit key and Cipher Block Chaining mode

**entry.dat** - Legacy password storage file (Marshal format with MD5-hashed passwords)

**entry.yaml** - New password storage file (YAML format with optional encryption)

**Encryption Mode** - User-selected method for password storage (plaintext, standard, enhanced, SSH key)

**PBKDF2** - Password-Based Key Derivation Function 2 (strengthens passwords against brute force)

**Master Password** - Single password that encrypts all account passwords (Enhanced mode only)

**OS Keychain** - Operating system secure credential storage (Keychain on macOS, Credential Manager on Windows)

**Validation Test** - Cryptographic test stored in YAML to verify master password correctness

**Zero Regression** - Requirement that existing functionality continues unchanged

---

## DOCUMENT CONTROL

**Approval:**

| Role | Name | Signature | Date |
|------|------|-----------|------|
| Product Owner | Doug | ________________ | ________ |
| Development Team | Claude (Sonnet 4.5) | ________________ | ________ |

**Change History:**

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-11-01 | Claude | Initial BRD creation |

---

**END OF BUSINESS REQUIREMENTS DOCUMENT**
