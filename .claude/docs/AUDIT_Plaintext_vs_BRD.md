# Audit Report: Existing Plaintext Implementation vs BRD Requirements

**Date:** November 1, 2025  
**Auditor:** Claude (Sonnet 4.5)  
**Scope:** Compare existing lich-5 plaintext implementation against BRD functional requirements  
**Repository:** https://github.com/elanthia-online/lich-5

---

## EXECUTIVE SUMMARY

**Overall Assessment:** Existing plaintext implementation covers ~60% of BRD requirements.

**Key Findings:**
- ✅ Core conversion flow (entry.dat → entry.yaml) exists
- ✅ Password change functionality exists
- ✅ Account management exists
- ❌ Missing: Encryption mode selection UI
- ❌ Missing: "Encryption" tab entirely
- ❌ Missing: Mode change capability
- ❌ Missing: Enhanced/SSH key mode prompts
- ⚠️ Partial: Corruption handling exists but incomplete per BRD

**Recommendation:** Phase 1 must include gap-filling for plaintext mode + Standard Encryption.

---

## DETAILED GAP ANALYSIS

### FR-1: Four Encryption Modes

**BRD Requirement:** System shall support four encryption modes selectable by user.

**Current State:**
- ✅ Plaintext mode fully implemented (ENC-1)
- ❌ Standard mode not implemented (ENC-2)
- ❌ Enhanced mode not implemented (ENC-3)
- ❌ SSH Key mode not implemented (ENC-4)

**Gap:** 3 of 4 modes missing (expected - this is Phase 1 goal)

**Files Affected:**
- Need: `lib/common/gui/password_cipher.rb` (new)
- Need: Modifications to `lib/common/gui/yaml_state.rb`

---

### FR-2: Conversion Flow (entry.dat → entry.yaml)

**BRD Requirement:** Modal dialog with four encryption mode choices during conversion.

**Current State (lib/common/gui/conversion_ui.rb):**

**✅ EXISTS:**
- Modal dialog on first launch
- Conversion from entry.dat to entry.yaml
- "Convert Data" button
- Cancel exits application
- entry.dat left unmodified after conversion

**❌ MISSING:**
- Four radio button options (only has single "Convert" button)
- Mode descriptions for each option
- Plaintext warning/confirmation dialog
- Enhanced mode master password prompt
- SSH Key mode file picker
- Mode selection stored in YAML (`security_mode` field)

**Evidence from conversion_ui.rb (lines 32-36):**
```ruby
dialog = Gtk::Dialog.new(
  title: "Data Conversion Required",
  buttons: [
    ["Convert Data", Gtk::ResponseType::APPLY]  # Single button, no mode choice
  ]
)
```

**Gap:** Conversion UI needs complete redesign to support mode selection.

**Files Requiring Changes:**
- `lib/common/gui/conversion_ui.rb` - Add radio buttons, conditional prompts
- `lib/common/gui/yaml_state.rb` - Accept security_mode parameter during conversion

---

### FR-3: Password Encryption/Decryption

**BRD Requirement:** Encrypt passwords on save, decrypt on load based on active encryption mode.

**Current State:**
- ✅ Plaintext save/load works (no encryption)
- ❌ No encryption layer exists
- ❌ No mode-based encrypt/decrypt logic

**Evidence from yaml_state.rb (line 79):**
```ruby
file.puts "# WARNING: Passwords are stored in plain text"  # Acknowledges plaintext
```

**Gap:** Entire encryption layer missing (password_cipher.rb needed).

**Files Requiring Changes:**
- Need: `lib/common/gui/password_cipher.rb` (new file)
- `lib/common/gui/yaml_state.rb` - Add encrypt/decrypt calls in save_entries/load_saved_entries

---

### FR-4: Change Encryption Mode

**BRD Requirement:** User can change encryption mode at any time via Account Management UI.

**Current State:**
- ❌ No "Change Encryption Mode" UI exists
- ❌ No mode change logic exists
- ❌ No validation for exiting Enhanced mode

**Gap:** Entire feature missing (expected for Phase 3, but UI prep needed in Phase 1).

**Files Requiring Changes:**
- Need: `lib/common/gui/security_mode_manager.rb` (new file - Phase 3)
- Need: UI in Encryption tab (Phase 5)

**Status:** OUT OF SCOPE for Phase 1 (will address in Phase 3)

---

### FR-5: Change Account Password

**BRD Requirement:** User can change password for any account in any encryption mode.

**Current State:**

**⚠️ PARTIAL IMPLEMENTATION:**

**Evidence from account_manager_ui.rb (line 390):**
```ruby
def on_password_change_clicked
  # Prompts for new password
  # Updates password in account data
  # Saves to YAML
end
```

**✅ EXISTS:**
- Password change UI in Account Management
- Password prompt dialog
- Save updated password to YAML

**❌ MISSING:**
- Mode-aware password change (currently only handles plaintext)
- Decrypt → update → re-encrypt flow for encrypted modes
- Backup before password change

**Gap:** Password change exists but not mode-aware. Needs modification for encrypted modes.

**Files Requiring Changes:**
- `lib/common/gui/account_manager_ui.rb` - Add mode-aware password change logic
- OR: Create `lib/common/gui/password_manager.rb` (new file) with mode-aware logic

---

### FR-6: Change Master Password (Enhanced Mode)

**BRD Requirement:** In Enhanced mode, user can change master password.

**Current State:**
- ❌ No master password concept exists
- ❌ No "Change Master Password" UI

**Gap:** Entire feature missing (expected - Phase 2 scope).

**Status:** OUT OF SCOPE for Phase 1

---

### FR-7: Change SSH Key (SSH Key Mode)

**BRD Requirement:** In SSH Key mode, user can change SSH key.

**Current State:**
- ❌ No SSH key concept exists
- ❌ No "Change SSH Key" UI

**Gap:** Entire feature missing (expected - Phase 4 scope).

**Status:** OUT OF SCOPE for Phase 1

---

### FR-8: Password Recovery (Cannot Decrypt)

**BRD Requirement:** Recovery workflow when decryption fails.

**Current State:**
- ❌ No recovery workflow exists
- ❌ Cannot fail to decrypt (plaintext only)

**Gap:** Entire feature missing (expected - Phase 3 scope).

**Status:** OUT OF SCOPE for Phase 1

---

### FR-9: Corruption Detection & Recovery

**BRD Requirement:** Detect file corruption, offer backup restoration.

**Current State:**

**⚠️ PARTIAL IMPLEMENTATION:**

**Evidence from yaml_state.rb (lines 30-47):**
```ruby
if File.exist?(yaml_file)
  begin
    yaml_data = YAML.load_file(yaml_file)
    # ... process data ...
  rescue StandardError => e
    Lich.log "error: Error loading YAML entry file: #{e.message}"
    []  # Returns empty array on error
  end
```

**✅ EXISTS:**
- YAML parse error handling (returns empty array)
- Backup file creation (line 68: `FileUtils.cp(yaml_file, backup_file)`)

**❌ MISSING per BRD:**
- No prompt to restore from backup (silent failure)
- No distinction between corruption types
- No "both files corrupt" handling
- No user-facing restoration dialog
- Backup restoration is automatic, not permission-based

**Gap:** Basic error handling exists, but BRD requires user-facing dialogs and permission-based restoration.

**Files Requiring Changes:**
- `lib/common/gui/yaml_state.rb` - Enhanced corruption detection
- Need: Restoration dialog UI (can be in conversion_ui.rb or new file)

**Priority:** MEDIUM - Current behavior is acceptable for Phase 1, improve in Phase 3

---

### FR-10: Master Password Validation (Enhanced Mode)

**BRD Requirement:** PBKDF2 validation test in YAML for Enhanced mode.

**Current State:**
- ❌ No master password concept exists
- ❌ No validation test

**Gap:** Entire feature missing (expected - Phase 2 scope).

**Status:** OUT OF SCOPE for Phase 1

---

### FR-11: File Management

**BRD Requirement:** Backup on every save, file permissions 0600, timestamped backups.

**Current State:**

**✅ EXISTS:**
- Backup created on save (yaml_state.rb line 68)
- Single backup file (entry.yaml.bak)

**❌ MISSING:**
- File permissions not set to 0600
- No timestamped backups for recovery scenarios
- No "unrecoverable" backup naming

**Evidence from yaml_state.rb (lines 73-80):**
```ruby
File.open(yaml_file, 'w') do |file|  # No mode/permissions specified
  file.puts "# Lich 5 Login Entries - YAML Format"
  file.puts "# Generated: #{Time.now}"
  file.puts "# WARNING: Passwords are stored in plain text"
  file.write(YAML.dump(yaml_data))
end
```

**Gap:** File permissions not enforced.

**Files Requiring Changes:**
- `lib/common/gui/yaml_state.rb` - Add file mode 0600 to File.open
- `lib/common/gui/utilities.rb` - Modify safe_file_operation to enforce permissions

**Priority:** HIGH - Should be in Phase 1 (simple fix)

---

### FR-12: Multi-Installation Support

**BRD Requirement:** Multiple installations don't conflict, keychain only used if enhanced mode.

**Current State:**
- ✅ No keychain usage currently (plaintext mode)
- ✅ Multiple installations work fine

**Gap:** None for plaintext. Will need attention in Phase 2 (Enhanced mode).

**Status:** OUT OF SCOPE for Phase 1

---

## UI REQUIREMENTS GAP ANALYSIS

### UI-1: New "Encryption" Tab

**BRD Requirement:** New tab in main notebook with encryption controls.

**Current State:**
- ❌ No "Encryption" tab exists

**Evidence from gui-login.rb (lines 447-460):**
```ruby
@notebook.append_page(@quick_game_entry_tab, Gtk::Label.new('Saved Entry'))
@notebook.append_page(@game_entry_tab, Gtk::Label.new('Manual Entry'))
@notebook.append_page(@account_mgmt_tab, Gtk::Label.new('Account Management'))
# No "Encryption" tab
```

**Gap:** Entire tab missing.

**Priority:** MEDIUM - Can defer to Phase 5, but placeholder useful

**Files Requiring Changes:**
- `lib/common/gui-login.rb` - Add Encryption tab to notebook
- Need: `lib/common/gui/encryption_tab.rb` (new file)

---

### UI-2: Conversion Dialog

**BRD Requirement:** Four radio buttons for mode selection during conversion.

**Current State:**
- ❌ Single "Convert Data" button only
- ❌ No mode selection

**Gap:** Already documented in FR-2 above.

**Priority:** HIGH - Must fix in Phase 1

---

### UI-3: Change Encryption Mode Dialog

**BRD Requirement:** Dialog for changing encryption mode.

**Current State:**
- ❌ Does not exist

**Gap:** Expected - Phase 3 scope.

**Status:** OUT OF SCOPE for Phase 1

---

### UI-4: Change Account Password Dialog

**BRD Requirement:** Dialog for changing account password (mode-aware).

**Current State:**
- ⚠️ EXISTS but not mode-aware

**Evidence from account_manager_ui.rb (lines 390-425):**
```ruby
def on_password_change_clicked
  # Dialog exists
  # Password entry fields exist
  # But no encryption logic
end
```

**Gap:** Needs mode-aware enhancement.

**Priority:** HIGH - Must fix in Phase 1

---

### UI-5: Password Recovery Dialog

**BRD Requirement:** Recovery dialog when decryption fails.

**Current State:**
- ❌ Does not exist

**Gap:** Expected - Phase 3 scope.

**Status:** OUT OF SCOPE for Phase 1

---

### UI-6: Backup Restoration Dialog

**BRD Requirement:** User-facing dialog to restore from backup.

**Current State:**
- ❌ Does not exist (silent error handling)

**Gap:** Needs user-facing dialog.

**Priority:** MEDIUM - Can defer to Phase 3, current behavior acceptable

---

## ARCHITECTURE GAP ANALYSIS

### Missing Files (Per BRD)

| File | Purpose | Phase | Priority |
|------|---------|-------|----------|
| `password_cipher.rb` | Encryption utilities | 1 | HIGH |
| `master_password_validator.rb` | PBKDF2 validation | 2 | - |
| `os_keychain.rb` | Keychain integration | 2 | - |
| `security_mode_manager.rb` | Mode change logic | 3 | - |
| `password_manager.rb` | Mode-aware password changes | 1 | HIGH |
| `password_recovery.rb` | Recovery workflow | 3 | - |
| `ssh_key_manager.rb` | SSH key integration | 4 | - |
| `encryption_tab.rb` | Encryption tab UI | 5 | MEDIUM |

**Phase 1 Needs:** `password_cipher.rb`, `password_manager.rb`

---

### Files Requiring Modification (Phase 1)

| File | Current State | Needed Changes |
|------|---------------|----------------|
| `yaml_state.rb` | Plaintext save/load | Add encrypt/decrypt layer, mode awareness |
| `conversion_ui.rb` | Single button conversion | Add radio buttons, mode selection, conditional prompts |
| `account_manager_ui.rb` | Plaintext password change | Make mode-aware OR delegate to password_manager.rb |
| `utilities.rb` | No permission enforcement | Add mode 0600 to file operations |
| `gui-login.rb` | Three tabs | Optional: Add Encryption tab placeholder |

---

## YAML FORMAT GAP ANALYSIS

### Current YAML Structure (Plaintext)

**From repository yaml_state.rb:**
```yaml
accounts:
  ACCOUNTNAME:
    password: PlaintextPassword
    characters:
      - char_name: Charname
        game_code: GS3
        # ... other fields
```

### BRD Required Structure (with mode support)

**Plaintext:**
```yaml
security_mode: plaintext  # MISSING in current implementation
accounts:
  ACCOUNTNAME:
    password: PlaintextPassword  # Same as current
    characters: [...]
```

**Standard:**
```yaml
security_mode: standard  # MISSING
accounts:
  ACCOUNTNAME:
    password_encrypted:  # NEW field
      iv: "base64"
      ciphertext: "base64"
      version: 1
    characters: [...]
```

**Gap:** Current YAML format lacks `security_mode` field entirely.

**Impact:** Must add `security_mode` to YAML even for plaintext to enable future mode detection.

**Files Requiring Changes:**
- `yaml_state.rb` - Add `security_mode` to YAML structure
- Migration: Auto-add `security_mode: plaintext` to existing YAML files without it

---

## CRITICAL FINDINGS

### 1. ⚠️ Conversion UI is Incomplete for BRD

**Current:** Single "Convert Data" button
**BRD:** Four radio buttons with mode selection

**Impact:** Cannot meet FR-2 without significant conversion_ui.rb rewrite.

**Recommendation:** Phase 1 must include conversion UI redesign.

---

### 2. ⚠️ No security_mode Field in YAML

**Current:** YAML has no mode indicator
**BRD:** Requires `security_mode` field

**Impact:** Cannot distinguish between modes without this field.

**Recommendation:** Add `security_mode: plaintext` to current implementation immediately (backward compatible).

---

### 3. ⚠️ Password Change Not Mode-Aware

**Current:** Direct password update (plaintext only)
**BRD:** Mode-aware with encrypt/decrypt

**Impact:** Password changes will break encrypted passwords.

**Recommendation:** Create `password_manager.rb` with mode-aware logic, or enhance account_manager_ui.rb.

---

### 4. ⚠️ File Permissions Not Enforced

**Current:** Default umask (often 644)
**BRD:** Requires 0600 on Unix/macOS

**Impact:** Passwords readable by other users on system.

**Recommendation:** Simple fix - add mode parameter to File.open calls.

---

### 5. ✅ Backup Strategy Exists

**Current:** Creates entry.yaml.bak on save
**BRD:** Same requirement

**Impact:** None - existing behavior matches BRD.

---

## PHASE 1 REVISED SCOPE

### Original Phase 1 Plan:
- Add `password_cipher.rb`
- Modify `yaml_state.rb` for encryption
- Add Standard mode to conversion

### Revised Phase 1 Scope (Gap-Filling + Standard):

**Must Include:**
1. ✅ Add `password_cipher.rb` (encryption utilities)
2. ✅ Modify `yaml_state.rb`:
   - Add `security_mode` field to YAML (plaintext + standard)
   - Add encrypt/decrypt layer
   - Add migration for existing YAML without security_mode
3. ✅ Rewrite `conversion_ui.rb`:
   - Replace single button with radio buttons
   - Add plaintext warning dialog
   - Store chosen mode in YAML
4. ✅ Create `password_manager.rb`:
   - Mode-aware password changes
   - Called from account_manager_ui.rb
5. ✅ Modify `utilities.rb`:
   - Enforce file mode 0600 on save

**Optional (Nice to Have):**
6. ⚠️ Add Encryption tab placeholder (can defer to Phase 5)
7. ⚠️ Enhance corruption handling dialogs (can defer to Phase 3)

**Estimated Effort (Revised):** 16-20 hours (was 12-16)

---

## RECOMMENDATIONS

### For Phase 1 Approval:

**1. Accept Revised Scope:**
- Includes gap-filling for plaintext BRD compliance
- Adds Standard Encryption
- Estimated 16-20 hours (4 hour increase)

**2. Defer to Later Phases:**
- Encryption tab UI (Phase 5)
- Enhanced corruption dialogs (Phase 3)
- Password recovery (Phase 3)

**3. Critical Path:**
- Fix conversion UI (blocking for any mode selection)
- Add security_mode field (required for mode detection)
- Make password change mode-aware (will break without this)

---

## TESTING IMPACT

### Additional Tests Needed (Due to Gaps):

**Unit Tests:**
- security_mode field handling
- Migration of old YAML to new format (with security_mode)
- Mode-aware password change logic
- File permission verification

**Integration Tests:**
- Conversion with mode selection (plaintext vs standard)
- Existing YAML without security_mode loads correctly
- Password change works in both modes

**Regression Tests:**
- Existing plaintext workflows unchanged
- Old YAML files load and auto-migrate

**Estimate:** +2-3 hours testing effort

---

## SUMMARY TABLE: BRD vs Current State

| FR | Requirement | Current State | Gap | Phase 1 Priority |
|----|-------------|---------------|-----|------------------|
| FR-1 | Four modes | Plaintext only | 3 modes missing | HIGH (add Standard) |
| FR-2 | Conversion UI | Single button | Mode selection missing | HIGH (rewrite) |
| FR-3 | Encrypt/decrypt | None | Full encryption layer | HIGH (new file) |
| FR-4 | Change mode | None | Entire feature | OUT OF SCOPE |
| FR-5 | Change password | Exists (plaintext) | Not mode-aware | HIGH (fix) |
| FR-6 | Change master pass | None | Entire feature | OUT OF SCOPE |
| FR-7 | Change SSH key | None | Entire feature | OUT OF SCOPE |
| FR-8 | Recovery | None | Entire feature | OUT OF SCOPE |
| FR-9 | Corruption handling | Partial | User dialogs missing | MEDIUM (defer) |
| FR-10 | Master pass validation | None | Entire feature | OUT OF SCOPE |
| FR-11 | File management | Partial | Permissions missing | HIGH (simple fix) |
| FR-12 | Multi-install | Works | None | N/A |

**Phase 1 Must-Fix:** FR-1, FR-2, FR-3, FR-5, FR-11

---

## APPENDIX: Code Evidence

### Conversion UI Current State
**File:** lib/common/gui/conversion_ui.rb  
**Lines:** 32-60

```ruby
dialog = Gtk::Dialog.new(
  title: "Data Conversion Required",
  parent: parent,
  flags: :modal,
  buttons: [
    ["Convert Data", Gtk::ResponseType::APPLY]  # Single button
  ]
)

# ... content area with explanation text ...

# No mode selection UI
```

---

### YAML Save Current State
**File:** lib/common/gui/yaml_state.rb  
**Lines:** 60-89

```ruby
def self.save_entries(data_dir, entry_data)
  yaml_file = yaml_file_path(data_dir)
  yaml_data = convert_legacy_to_yaml_format(entry_data)
  
  if File.exist?(yaml_file)
    backup_file = "#{yaml_file}.bak"
    FileUtils.cp(yaml_file, backup_file)
  end
  
  # No security_mode field added
  # No encryption applied
  
  File.open(yaml_file, 'w') do |file|  # No mode 0600
    file.puts "# Lich 5 Login Entries - YAML Format"
    file.puts "# Generated: #{Time.now}"
    file.puts "# WARNING: Passwords are stored in plain text"
    file.write(YAML.dump(yaml_data))
  end
end
```

---

### Password Change Current State
**File:** lib/common/gui/account_manager_ui.rb  
**Lines:** 390-425

```ruby
def on_password_change_clicked
  # Prompts for new password
  # Updates directly without mode awareness
  
  account_data['password'] = new_password  # Plaintext only
  
  # No encryption
  # No mode checking
end
```

---

**END OF AUDIT REPORT**
