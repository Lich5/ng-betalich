# Work Unit: Master Password Change Workflow (Fix #1)

**Created:** 2025-11-09
**Estimated Effort:** 3-4 hours
**Branch:** `fix/change-enhanced-password`
**PR Title:** `fix(all): add master password change workflow`

---

## Starting Point

**Branch from:** `feat/password-encryption-enhanced` (PR #2 - completed)
**Source material:** Account Manager UI patterns, existing password change workflow
**What exists in base:** Enhanced mode with master password, account password change UI
**What you're adding:** UI and workflow to change the master password itself
**What you're excluding:** SSH key change (that's Fix #2)

---

## Prerequisites

- [ ] PR #2 complete: `feat/password-encryption-enhanced` merged or ready
- [ ] Branch created: `fix/change-enhanced-password` (you'll do this)
- [ ] Context read: `.claude/docs/BRD_Password_Encryption.md` (FR-6: Change Master Password)
- [ ] Existing password change UI understood (`password_change.rb`)

---

## Objective

Allow users to **change their master password** with automatic re-encryption of all accounts:
- "Change Master Password" button in Account Manager
- Dialog to enter current + new master password
- Validate current master password
- Re-encrypt all accounts using new master password
- Update keychain with new master password
- Update validation test with new password

---

## Files to Create

### 1. master_password_change.rb (new file ~200 lines)
**Location:** `lib/common/gui/master_password_change.rb`

**Purpose:** Dialog and workflow for changing master password

**Key functionality:**
```ruby
module MasterPasswordChange
  class Dialog < Gtk::Dialog
    def initialize(parent)
      super(title: "Change Master Password", parent: parent, flags: :modal)

      # Current master password entry
      @current_password_entry = Gtk::Entry.new
      @current_password_entry.visibility = false

      # New master password entry
      @new_password_entry = Gtk::Entry.new
      @new_password_entry.visibility = false

      # Confirm new password entry
      @confirm_password_entry = Gtk::Entry.new
      @confirm_password_entry.visibility = false

      # Buttons
      add_button("Cancel", Gtk::ResponseType::CANCEL)
      add_button("Change Password", Gtk::ResponseType::OK)
    end

    def run_and_destroy
      response = run
      if response == Gtk::ResponseType::OK
        perform_password_change
      end
      destroy
    end

    private

    def perform_password_change
      # 1. Validate current master password
      # 2. Validate new password (strength, confirmation match)
      # 3. Retrieve all accounts using Enhanced mode
      # 4. Decrypt all passwords with old master password
      # 5. Encrypt all passwords with new master password
      # 6. Update validation test with new password
      # 7. Store new master password in keychain
      # 8. Save updated YAML
    end
  end
end
```

---

### 2. master_password_change_spec.rb (new file ~120 lines)
**Location:** `spec/master_password_change_spec.rb`

**Test coverage:**
- Dialog initialization
- Current password validation
- New password validation (strength, match)
- Re-encryption workflow
- Keychain update
- Validation test update
- Error handling (wrong current password, weak new password)

---

## Files to Modify

### 1. account_manager_ui.rb - Add Button
**Edit `lib/common/gui/account_manager_ui.rb`:**

Add "Change Master Password" button (near existing "Change Password" button):
```ruby
# Around line 180, after "Change Password" button:
@change_master_password_button = Gtk::Button.new(label: "Change Master Password")
@change_master_password_button.signal_connect('clicked') do
  on_change_master_password_clicked
end

# Add to layout
button_box.pack_start(@change_master_password_button, expand: false, fill: false, padding: 5)

# Disable if Enhanced mode not in use
update_change_master_password_button_state
```

Add state management:
```ruby
def update_change_master_password_button_state
  # Enable only if:
  # 1. At least one account uses Enhanced mode
  # 2. Master password exists in keychain
  has_enhanced_accounts = accounts.any? { |acc| acc[:encryption_mode] == :enhanced }
  has_master_password = MasterPasswordManager.retrieve_master_password

  @change_master_password_button.sensitive = has_enhanced_accounts && has_master_password
end

def on_change_master_password_clicked
  dialog = MasterPasswordChange::Dialog.new(self)
  dialog.run_and_destroy
  refresh_account_list  # Reload after change
end
```

---

### 2. master_password_manager.rb - Add Change Method
**Edit `lib/common/gui/master_password_manager.rb`:**

Add method to change master password:
```ruby
# Change master password and re-encrypt all accounts
def self.change_master_password(old_password, new_password)
  # 1. Validate old password
  return false unless validate_master_password(old_password)

  # 2. Create new validation test
  new_validation = create_validation_test(new_password)

  # 3. Store new password in keychain
  return false unless store_master_password(new_password)

  # 4. Return new validation test for YAML update
  new_validation
end
```

---

## Implementation Steps

### Step 1: Create Branch from PR #2
```bash
cd /home/user/ng-betalich
git fetch origin
git checkout feat/password-encryption-enhanced
git pull origin feat/password-encryption-enhanced
git checkout -b fix/change-enhanced-password
```

### Step 2: Create master_password_change.rb
```bash
touch lib/common/gui/master_password_change.rb
```

Implement the dialog with these key methods:
1. `initialize` - Build GTK dialog with 3 password entries
2. `run_and_destroy` - Show dialog and handle response
3. `perform_password_change` - Main workflow
4. `validate_inputs` - Check password strength, match
5. `re_encrypt_accounts` - Decrypt with old, encrypt with new
6. `update_keychain` - Store new password

**Re-encryption workflow:**
```ruby
def re_encrypt_accounts(old_password, new_password)
  yaml_state = YamlState.new

  # Get all accounts using Enhanced mode
  enhanced_accounts = yaml_state.accounts.select { |acc|
    acc[:encryption_mode] == :enhanced
  }

  enhanced_accounts.each do |account|
    # Decrypt with old master password
    decrypted_password = PasswordCipher.decrypt(
      account[:encrypted_password],
      :enhanced,
      old_password
    )

    # Encrypt with new master password
    new_encrypted = PasswordCipher.encrypt(
      decrypted_password,
      :enhanced,
      new_password
    )

    # Update account
    account[:encrypted_password] = new_encrypted
  end

  # Update validation test
  new_validation = MasterPasswordManager.create_validation_test(new_password)
  yaml_state.set_master_password_validation(new_validation)

  # Save YAML
  yaml_state.save

  # Update keychain
  MasterPasswordManager.store_master_password(new_password)
end
```

### Step 3: Add Button to Account Manager UI
Edit `lib/common/gui/account_manager_ui.rb`:
1. Add button declaration
2. Connect signal handler
3. Add state management method
4. Call state management on account list refresh

### Step 4: Add change_master_password Method
Edit `lib/common/gui/master_password_manager.rb`:
1. Add `change_master_password` method
2. Validate old password
3. Create new validation test
4. Store new password in keychain

### Step 5: Write Tests
Create `spec/master_password_change_spec.rb`:

```ruby
RSpec.describe MasterPasswordChange::Dialog do
  describe '#perform_password_change' do
    it 'validates current master password' do
      # Mock current password validation
      # Expect validation called with current password
    end

    it 'validates new password strength' do
      # Weak password should fail
    end

    it 'validates password confirmation match' do
      # Mismatch should fail
    end

    it 're-encrypts all Enhanced mode accounts' do
      # Mock accounts with Enhanced mode
      # Expect re-encryption with new password
    end

    it 'updates keychain with new password' do
      # Expect store_master_password called
    end

    it 'updates validation test' do
      # Expect new validation test created and saved
    end
  end
end
```

### Step 6: Run Tests
```bash
bundle exec rspec spec/master_password_change_spec.rb
# Expected: All new tests pass

bundle exec rspec
# Expected: All existing tests still pass
```

### Step 7: Run RuboCop
```bash
bundle exec rubocop lib/common/gui/master_password_change.rb
bundle exec rubocop spec/master_password_change_spec.rb
# Expected: 0 offenses
```

### Step 8: Manual Testing (if possible)
1. Start app with Enhanced mode accounts
2. Click "Change Master Password" button
3. Enter current password
4. Enter new password (confirm)
5. Verify all accounts still decrypt correctly
6. Verify keychain updated

### Step 9: Commit
```bash
git add .
git commit -m "$(cat <<'EOF'
fix(all): add master password change workflow

Adds UI and workflow to change master password:
- "Change Master Password" button in Account Manager
- Dialog for current/new/confirm password entry
- Current password validation
- New password strength validation
- Re-encryption of all Enhanced mode accounts
- Keychain update with new password
- Validation test update
- Comprehensive tests

Users can now change their master password without losing encrypted data.

Related: BRD Password Encryption FR-6
EOF
)"
```

### Step 10: Push
```bash
git push -u origin fix/change-enhanced-password
```

---

## Acceptance Criteria

### UI Implementation
- [ ] "Change Master Password" button in Account Manager
- [ ] Button enabled only when Enhanced accounts exist
- [ ] Button disabled when no master password in keychain
- [ ] Dialog with 3 password fields (current, new, confirm)
- [ ] Dialog has Cancel and Change Password buttons

### Functionality
- [ ] Current password validation works
- [ ] New password strength validation works
- [ ] Password confirmation matching works
- [ ] All Enhanced accounts re-encrypted with new password
- [ ] Keychain updated with new password
- [ ] Validation test updated
- [ ] YAML saved with new encrypted passwords

### Security
- [ ] Current password required (prevents unauthorized change)
- [ ] Password strength enforced (minimum length, complexity)
- [ ] Old password not logged or stored
- [ ] New password stored securely in keychain

### Error Handling
- [ ] Wrong current password → error message
- [ ] Weak new password → error message with requirements
- [ ] Password mismatch → error message
- [ ] Re-encryption failure → rollback, error message
- [ ] Keychain update failure → error message

### Tests
- [ ] All new tests pass
- [ ] All existing tests still pass
- [ ] Dialog tests comprehensive
- [ ] Re-encryption workflow tested
- [ ] Error cases covered

### Code Standards
- [ ] SOLID + DRY principles
- [ ] YARD documentation complete
- [ ] RuboCop clean: 0 offenses
- [ ] Follows existing UI patterns

### Git Hygiene
- [ ] Conventional commit: `fix(all): add master password change workflow`
- [ ] Branch pushed: `git push -u origin fix/change-enhanced-password`
- [ ] Clean diff
- [ ] No merge conflicts with PR #2 base

### Verification Commands
```bash
# All should pass:
ls lib/common/gui/master_password_change.rb                    # Expected: exists
grep -n "Change Master Password" lib/common/gui/account_manager_ui.rb  # Expected: 1+ matches
bundle exec rspec spec/master_password_change_spec.rb          # Expected: all pass
bundle exec rspec                                               # Expected: all pass
bundle exec rubocop                                             # Expected: 0 offenses
git log --oneline -1                                            # Expected: fix(all): add master...
```

---

## Edge Cases to Handle

### 1. No Enhanced Mode Accounts
- Button should be disabled
- If somehow activated, show error

### 2. Multiple Failed Attempts
- Consider lockout after N failed current password attempts
- Or rate limiting

### 3. Re-encryption Fails Mid-Process
- Rollback to previous state
- Don't update keychain if re-encryption fails

### 4. Keychain Update Fails
- Rollback re-encryption
- Show error to user

### 5. User Cancels Mid-Process
- Ensure no partial changes saved
- Atomic operation

---

## What Comes Next

**After this Fix PR is complete:**
- ✅ Fix #1 ready for beta testing
- ⏭️ **Next work unit:** SSH_KEY_CHANGE_CURRENT.md (Fix #2)
- Can be developed in parallel with Fix #2

**Dependencies:**
- Can branch from PR #2 (doesn't need PR #3)
- Independent of SSH Key change workflow

---

## Troubleshooting

### "Re-encryption fails"
- Verify old password is correct
- Check all accounts have valid encrypted_password field
- Ensure PasswordCipher.decrypt works with old password

### "Keychain update fails"
- Check keychain availability
- Verify permissions
- Review platform-specific keychain logs

### "Button not showing"
- Verify account_manager_ui.rb changes applied
- Check button state logic
- Ensure Enhanced accounts exist for testing

---

## Context References

**Read before starting:**
- `.claude/docs/CLI_PRIMER.md` - Ground rules
- `.claude/docs/BRD_Password_Encryption.md` - FR-6 requirements
- `lib/common/gui/password_change.rb` - Existing password change pattern

---

**END OF WORK UNIT**

When complete, archive this file to `.claude/docs/archive/MASTER_PASSWORD_CHANGE_COMPLETED.md`.
