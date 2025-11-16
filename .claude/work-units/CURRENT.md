# Work Unit: Change Master Password (Enhanced Encryption)

**Created:** 2025-11-16
**Updated:** 2025-11-16
**Estimated Effort:** 3-4 hours
**Branch:** `feat/change-master-password`
**Priority:** CRITICAL (next day delivery)

---

## Context

**Base Branch:** `feat/windows-credential-manager`
**BRD Reference:** FR-6 (Change Master Password)
**Status:** Phase 2 - Enhanced Security features

**What exists:**
- ✅ Enhanced encryption mode with master password
- ✅ Master password stored in OS keychain (macOS/Linux/Windows)
- ✅ PBKDF2 validation test (100k iterations)
- ✅ Account password change UI (change individual account passwords)
- ✅ All keychain operations (store, retrieve, delete, validate)

**What's missing:**
- ❌ UI to change the master password itself
- ❌ Re-encryption workflow when master password changes
- ❌ Master password change button in Account Manager

---

## Objective

Allow users to **change their master password** with automatic re-encryption of all accounts.

**User Flow:**
1. User clicks "Change Master Password" button
2. Dialog prompts for current master password
3. System validates current password (keychain + PBKDF2 test)
4. Dialog prompts for new master password (enter twice)
5. System re-encrypts all Enhanced mode accounts with new password
6. System updates PBKDF2 validation test
7. System updates keychain with new password
8. System saves updated entry.yaml

---

## Branch Setup

```bash
git fetch origin feat/windows-credential-manager
git checkout feat/windows-credential-manager
git pull origin feat/windows-credential-manager
git checkout -b feat/change-master-password
```

---

## Implementation

### File 1: master_password_change.rb (NEW - ~250 lines)

**Location:** `lib/common/gui/master_password_change.rb`

**Structure:**
```ruby
# frozen_string_literal: true

require 'gtk3'
require_relative 'master_password_manager'
require_relative 'password_cipher'
require_relative 'yaml_state'
require_relative 'accessibility'

module Lich
  module Common
    module GUI
      module MasterPasswordChange
        # Show change master password dialog
        # @param parent [Gtk::Window] Parent window
        # @param data_dir [String] Directory containing account data
        # @return [Boolean] true if password changed, false if cancelled
        def self.show_change_master_password_dialog(parent, data_dir)
          # Create dialog
          # Validate current password
          # Prompt for new password
          # Re-encrypt all accounts
          # Update validation test
          # Update keychain
          # Save YAML
        end
      end
    end
  end
end
```

**Key Methods:**
- `show_change_master_password_dialog(parent, data_dir)` - Main entry point
- `validate_current_password(current_password, yaml_state)` - Validate against PBKDF2 test
- `validate_new_password(new_password, confirm_password)` - Check strength and match
- `re_encrypt_all_accounts(yaml_state, old_password, new_password)` - Core workflow
- `update_keychain_and_validation(new_password)` - Update keychain and PBKDF2 test

**Pattern Reference:** Follow `password_change.rb` dialog structure

---

### File 2: account_manager_ui.rb (MODIFY)

**Location:** `lib/common/gui/account_manager_ui.rb`

**Add Button:**
```ruby
# After existing password change button (~line 400)
@change_master_password_button = Gtk::Button.new(label: "Change Master Password")
@change_master_password_button.signal_connect('clicked') do
  on_change_master_password_clicked
end

# Add to button box
button_box.pack_start(@change_master_password_button, expand: false, fill: false, padding: 5)

# Update button state based on encryption mode
update_change_master_password_button_state
```

**Signal Handler:**
```ruby
def on_change_master_password_clicked
  success = MasterPasswordChange.show_change_master_password_dialog(self, @data_dir)
  refresh_account_list if success
end
```

**State Management:**
```ruby
def update_change_master_password_button_state
  # Hide button if OS keychain not available (feature unavailable)
  # Disable button if keychain available but:
  #   - No Enhanced accounts exist, OR
  #   - No master password in keychain

  has_keychain = MasterPasswordManager.keychain_available?

  # Hide if feature not available on this OS
  @change_master_password_button.visible = has_keychain

  # Disable if feature available but not currently usable
  if has_keychain
    yaml_file = YamlState.yaml_file_path(@data_dir)
    if File.exist?(yaml_file)
      yaml_data = YAML.load_file(yaml_file)
      has_enhanced = (yaml_data['encryption_mode'] == 'enhanced')
      has_password = MasterPasswordManager.retrieve_master_password

      @change_master_password_button.sensitive = has_enhanced && has_password
    else
      @change_master_password_button.sensitive = false
    end
  end
end
```

**Call on Refresh:**
```ruby
# In refresh_account_list method
update_change_master_password_button_state
```

---

### File 3: master_password_change_spec.rb (NEW - ~150 lines)

**Location:** `spec/master_password_change_spec.rb`

**Test Coverage:**
- Dialog creation and structure
- Current password validation (correct/incorrect)
- New password validation (strength, match, mismatch)
- Re-encryption workflow (all Enhanced accounts)
- Keychain update
- PBKDF2 validation test update
- Error handling (validation failure, re-encryption failure)
- Cancel behavior

**Pattern Reference:** Follow `password_change_spec.rb` test structure

---

## Re-Encryption Workflow

**Core Logic:**
```ruby
def self.re_encrypt_all_accounts(yaml_state, old_password, new_password)
  # Create backup first
  yaml_state.create_backup

  # Get all Enhanced mode accounts
  enhanced_accounts = yaml_state.accounts.select do |account|
    account['encryption_mode'] == 'enhanced'
  end

  # Re-encrypt each account
  enhanced_accounts.each do |account|
    # Decrypt with old password
    encrypted_data = account['password_encrypted']
    plaintext = PasswordCipher.decrypt(
      encrypted_data,
      account['username'],
      mode: :enhanced,
      master_password: old_password
    )

    # Encrypt with new password
    new_encrypted = PasswordCipher.encrypt(
      plaintext,
      account['username'],
      mode: :enhanced,
      master_password: new_password
    )

    # Update account
    account['password_encrypted'] = new_encrypted
  end

  # Create new validation test
  new_validation = MasterPasswordManager.create_validation_test(new_password)
  yaml_state.set_master_password_validation(new_validation)

  # Save YAML
  yaml_state.save

  # Update keychain
  MasterPasswordManager.store_master_password(new_password)

  true
rescue StandardError => e
  Lich.log "error: Failed to change master password: #{e.message}"
  yaml_state.restore_backup if yaml_state.backup_exists?
  false
end
```

---

## Acceptance Criteria

### UI Implementation
- [ ] "Change Master Password" button added to Account Manager
- [ ] Button hidden when OS keychain not available
- [ ] Button visible but disabled when no Enhanced accounts exist
- [ ] Button visible but disabled when no master password in keychain
- [ ] Button visible and enabled when Enhanced accounts exist with master password
- [ ] Dialog with 3 password fields (current, new, confirm)
- [ ] Dialog has Cancel and Change Password buttons
- [ ] Dialog follows existing accessibility patterns

### Functionality
- [ ] Current password validated against PBKDF2 test
- [ ] Current password validated against keychain
- [ ] New password strength validated (8+ chars minimum)
- [ ] Password confirmation matching works
- [ ] All Enhanced accounts re-encrypted with new password
- [ ] PBKDF2 validation test updated with new password
- [ ] Keychain updated with new password
- [ ] YAML saved with new encrypted passwords and validation test
- [ ] Backup created before changes

### Security
- [ ] Current password required (prevents unauthorized change)
- [ ] Password strength enforced (minimum 8 characters)
- [ ] Old password not logged
- [ ] New password stored securely in keychain
- [ ] Constant-time comparison used for validation

### Error Handling
- [ ] Wrong current password → clear error message, retry allowed
- [ ] Weak new password → error with requirements shown
- [ ] Password mismatch → error message, retry allowed
- [ ] Re-encryption failure → rollback to backup, error shown
- [ ] Keychain update failure → error message

### Tests
- [ ] All new tests pass (~15-20 examples)
- [ ] All existing tests still pass
- [ ] Dialog creation tested
- [ ] Validation logic tested
- [ ] Re-encryption workflow tested
- [ ] Error cases covered
- [ ] Edge cases handled (no Enhanced accounts, keychain unavailable)

### Code Quality
- [ ] SOLID + DRY principles followed
- [ ] YARD documentation on all public methods
- [ ] Follows existing UI patterns (password_change.rb)
- [ ] RuboCop clean: 0 offenses
- [ ] No code duplication

### Git
- [ ] Conventional commit: `feat(all): add change master password workflow`
- [ ] Branch: `feat/change-master-password`
- [ ] Clean commit history
- [ ] No merge conflicts with base branch

---

## Verification Commands

```bash
# File existence
ls lib/common/gui/master_password_change.rb
grep -n "Change Master Password" lib/common/gui/account_manager_ui.rb

# Tests
bundle exec rspec spec/master_password_change_spec.rb -v
bundle exec rspec  # All tests

# Code quality
bundle exec rubocop lib/common/gui/master_password_change.rb
bundle exec rubocop spec/master_password_change_spec.rb

# Git
git log --oneline -1
git diff origin/feat/windows-credential-manager --stat
```

---

## Edge Cases

### 1. No Enhanced Mode Accounts
- Button visible but disabled (grayed out)
- If somehow activated, show error: "No Enhanced encryption accounts found"

### 2. Keychain Unavailable
- Button hidden (not visible at all)
- Enhanced mode requires keychain - feature completely unavailable

### 3. Re-encryption Fails Mid-Process
- Rollback to backup immediately
- Don't update keychain
- Show specific error

### 4. Keychain Update Fails After Re-encryption
- Log error
- Warn user: "Passwords updated but keychain update failed"
- Don't rollback (passwords already changed)

### 5. User Cancels Mid-Dialog
- No changes made
- No partial updates
- Atomic operation

### 6. Multiple Enhanced Accounts (20+)
- Show progress indication during re-encryption
- Don't block UI completely
- Handle gracefully if one account fails

---

## Testing Notes

**Manual Testing Checklist:**
1. Create account with Enhanced mode
2. Click "Change Master Password"
3. Enter incorrect current password → see error
4. Enter correct current password
5. Enter weak new password (< 8 chars) → see error
6. Enter strong new password, mismatched confirm → see error
7. Enter strong new password, matched confirm → success
8. Close app, reopen
9. Verify account still decrypts with new password
10. Verify keychain has new password

**Test Data:**
- Current password: `TestPassword123`
- New password: `NewSecurePassword456`
- Weak password: `weak`

---

## Commit Message Template

```
feat(all): add change master password workflow

Implements FR-6 (Change Master Password) from BRD:
- "Change Master Password" button in Account Manager UI
- Dialog for current/new/confirm password entry
- Current password validation (keychain + PBKDF2 test)
- New password strength validation (8+ characters)
- Automatic re-encryption of all Enhanced mode accounts
- PBKDF2 validation test update (100k iterations)
- Keychain update with new password
- Backup/rollback on failure

Users can now change their master password without data loss.

Related: BRD Password Encryption FR-6
```

---

## Rollback Plan

**If implementation fails:**
```bash
git reset --hard origin/feat/windows-credential-manager
git branch -D feat/change-master-password
```

**If tests too complex:**
- Defer progress indication (manual testing only)
- Defer edge case handling (multiple accounts)
- Deliver core workflow first

---

## Dependencies

**Base Branch:** `feat/windows-credential-manager`

**Required Files (must exist in base):**
- ✅ `lib/common/gui/master_password_manager.rb`
- ✅ `lib/common/gui/password_cipher.rb`
- ✅ `lib/common/gui/yaml_state.rb`
- ✅ `lib/common/gui/account_manager_ui.rb`

**Methods Required:**
- ✅ `MasterPasswordManager.validate_master_password`
- ✅ `MasterPasswordManager.create_validation_test`
- ✅ `MasterPasswordManager.store_master_password`
- ✅ `PasswordCipher.encrypt`
- ✅ `PasswordCipher.decrypt`

---

## Next Steps After Completion

1. Push branch: `git push -u origin feat/change-master-password`
2. Manual testing on all platforms (macOS, Linux, Windows)
3. Create PR for review
4. Archive work unit to `.claude/work-units/archive/`
5. Move to CLI variant work unit

---

**Status:** Ready for CLI Claude execution
**Estimated Completion:** 3-4 hours
**Blocker:** None (all dependencies in base branch)
