# Work Unit: SSH Key Change Workflow (Fix #2)

**Created:** 2025-11-09
**Estimated Effort:** 2-3 hours
**Branch:** `fix/change-ssh-key`
**PR Title:** `fix(all): add SSH key change workflow`

---

## Starting Point

**Branch from:** `feat/password-encryption-ssh-key` (PR #3 - completed)
**Source material:** SSH Key Manager, existing password change workflows
**What exists in base:** All 4 encryption modes working, SSH key selection UI
**What you're adding:** UI and workflow to change the SSH key used for encryption
**What you're excluding:** N/A (last Fix PR)

---

## Prerequisites

- [ ] PR #3 complete: `feat/password-encryption-ssh-key` merged or ready
- [ ] Branch created: `fix/change-ssh-key` (you'll do this)
- [ ] Context read: `.claude/docs/BRD_Password_Encryption.md` (FR-7: Change SSH Key)
- [ ] SSH Key Manager understood (`ssh_key_manager.rb`)

---

## Objective

Allow users to **change their SSH key** with automatic re-encryption of all accounts:
- "Change SSH Key" button in Account Manager
- Dialog to select new SSH key file
- Validate new SSH key
- Re-encrypt all SSH Key mode accounts with new key
- Update YAML with new key path

---

## Files to Create

### 1. ssh_key_change.rb (new file ~150 lines)
**Location:** `lib/common/gui/ssh_key_change.rb`

**Purpose:** Dialog and workflow for changing SSH key

**Key functionality:**
```ruby
module SSHKeyChange
  class Dialog < Gtk::Dialog
    def initialize(parent, current_key_path)
      super(title: "Change SSH Key", parent: parent, flags: :modal)

      @current_key_path = current_key_path

      # Show current key info
      @current_key_label = Gtk::Label.new
      @current_key_label.text = "Current key: #{current_key_path}"
      fingerprint = SSHKeyManager.key_fingerprint(current_key_path)
      @current_fingerprint_label = Gtk::Label.new("Fingerprint: #{fingerprint}")

      # New SSH key file selection
      @new_key_entry = Gtk::Entry.new
      @browse_button = Gtk::Button.new(label: "Browse...")
      @browse_button.signal_connect('clicked') do
        on_browse_clicked
      end

      # New key fingerprint (shown after selection)
      @new_fingerprint_label = Gtk::Label.new

      # Buttons
      add_button("Cancel", Gtk::ResponseType::CANCEL)
      add_button("Change Key", Gtk::ResponseType::OK)
    end

    def run_and_destroy
      response = run
      if response == Gtk::ResponseType::OK
        perform_key_change
      end
      destroy
    end

    private

    def on_browse_clicked
      new_key = SSHKeyManager.select_key_file
      if new_key
        @new_key_entry.text = new_key
        update_new_key_fingerprint(new_key)
      end
    end

    def update_new_key_fingerprint(key_path)
      if SSHKeyManager.valid_key?(key_path)
        fingerprint = SSHKeyManager.key_fingerprint(key_path)
        @new_fingerprint_label.text = "Fingerprint: #{fingerprint}"
      else
        @new_fingerprint_label.text = "Invalid SSH key"
      end
    end

    def perform_key_change
      new_key_path = @new_key_entry.text
      # 1. Validate new key
      # 2. Retrieve all accounts using SSH Key mode
      # 3. Decrypt all passwords with old key
      # 4. Encrypt all passwords with new key
      # 5. Update YAML with new key path
    end
  end
end
```

---

### 2. ssh_key_change_spec.rb (new file ~100 lines)
**Location:** `spec/ssh_key_change_spec.rb`

**Test coverage:**
- Dialog initialization
- Key file selection
- New key validation
- Fingerprint display
- Re-encryption workflow
- YAML update with new key path
- Error handling (invalid key, missing file)

---

## Files to Modify

### 1. account_manager_ui.rb - Add Button
**Edit `lib/common/gui/account_manager_ui.rb`:**

Add "Change SSH Key" button:
```ruby
# After "Change Master Password" button:
@change_ssh_key_button = Gtk::Button.new(label: "Change SSH Key")
@change_ssh_key_button.signal_connect('clicked') do
  on_change_ssh_key_clicked
end

# Add to layout
button_box.pack_start(@change_ssh_key_button, expand: false, fill: false, padding: 5)

# Disable if SSH Key mode not in use
update_change_ssh_key_button_state
```

Add state management:
```ruby
def update_change_ssh_key_button_state
  # Enable only if at least one account uses SSH Key mode
  has_ssh_key_accounts = accounts.any? { |acc| acc[:encryption_mode] == :ssh_key }
  @change_ssh_key_button.sensitive = has_ssh_key_accounts
end

def on_change_ssh_key_clicked
  # Get current SSH key path from first SSH Key mode account
  current_key = accounts.find { |acc| acc[:encryption_mode] == :ssh_key }&.dig(:ssh_key_path)

  dialog = SSHKeyChange::Dialog.new(self, current_key)
  dialog.run_and_destroy
  refresh_account_list  # Reload after change
end
```

---

## Implementation Steps

### Step 1: Create Branch from PR #3
```bash
cd /home/user/ng-betalich
git fetch origin
git checkout feat/password-encryption-ssh-key
git pull origin feat/password-encryption-ssh-key
git checkout -b fix/change-ssh-key
```

### Step 2: Create ssh_key_change.rb
```bash
touch lib/common/gui/ssh_key_change.rb
```

Implement the dialog with these key methods:
1. `initialize` - Build GTK dialog with key info and file selection
2. `run_and_destroy` - Show dialog and handle response
3. `perform_key_change` - Main workflow
4. `validate_new_key` - Check key is valid, accessible
5. `re_encrypt_accounts` - Decrypt with old key, encrypt with new key
6. `update_yaml` - Save new key path

**Re-encryption workflow:**
```ruby
def re_encrypt_accounts(old_key_path, new_key_path)
  yaml_state = YamlState.new

  # Get all accounts using SSH Key mode
  ssh_key_accounts = yaml_state.accounts.select { |acc|
    acc[:encryption_mode] == :ssh_key
  }

  # Generate signatures from both keys
  old_signature = SSHKeyManager.generate_signature(old_key_path, 'lich5-password-salt')
  new_signature = SSHKeyManager.generate_signature(new_key_path, 'lich5-password-salt')

  ssh_key_accounts.each do |account|
    # Decrypt with old key signature
    decrypted_password = PasswordCipher.decrypt(
      account[:encrypted_password],
      :ssh_key,
      old_signature
    )

    # Encrypt with new key signature
    new_encrypted = PasswordCipher.encrypt(
      decrypted_password,
      :ssh_key,
      new_signature
    )

    # Update account
    account[:encrypted_password] = new_encrypted
    account[:ssh_key_path] = new_key_path
  end

  # Save YAML
  yaml_state.save
end
```

### Step 3: Add Button to Account Manager UI
Edit `lib/common/gui/account_manager_ui.rb`:
1. Add button declaration
2. Connect signal handler
3. Add state management method
4. Call state management on account list refresh

### Step 4: Write Tests
Create `spec/ssh_key_change_spec.rb`:

```ruby
RSpec.describe SSHKeyChange::Dialog do
  describe '#perform_key_change' do
    it 'validates new SSH key' do
      # Invalid key should fail
    end

    it 're-encrypts all SSH Key mode accounts' do
      # Mock accounts with SSH Key mode
      # Expect re-encryption with new key signature
    end

    it 'updates YAML with new key path' do
      # Expect all accounts updated with new path
    end

    it 'handles missing key file' do
      # Non-existent path should fail
    end

    it 'shows key fingerprints' do
      # Verify fingerprint display for old and new keys
    end
  end
end
```

### Step 5: Run Tests
```bash
bundle exec rspec spec/ssh_key_change_spec.rb
# Expected: All new tests pass

bundle exec rspec
# Expected: All existing tests still pass
```

### Step 6: Run RuboCop
```bash
bundle exec rubocop lib/common/gui/ssh_key_change.rb
bundle exec rubocop spec/ssh_key_change_spec.rb
# Expected: 0 offenses
```

### Step 7: Manual Testing (if possible with SSH key)
1. Start app with SSH Key mode accounts
2. Click "Change SSH Key" button
3. Select new SSH key file
4. Verify fingerprint shown
5. Change key
6. Verify all accounts still decrypt correctly

### Step 8: Commit
```bash
git add .
git commit -m "$(cat <<'EOF'
fix(all): add SSH key change workflow

Adds UI and workflow to change SSH key:
- "Change SSH Key" button in Account Manager
- Dialog for SSH key file selection
- Current and new key fingerprint display
- New key validation
- Re-encryption of all SSH Key mode accounts
- YAML update with new key path
- Comprehensive tests

Users can now change their SSH key without losing encrypted data.

Related: BRD Password Encryption FR-7
EOF
)"
```

### Step 9: Push
```bash
git push -u origin fix/change-ssh-key
```

---

## Acceptance Criteria

### UI Implementation
- [ ] "Change SSH Key" button in Account Manager
- [ ] Button enabled only when SSH Key accounts exist
- [ ] Dialog shows current key path and fingerprint
- [ ] Dialog has file selection for new key
- [ ] Dialog shows new key fingerprint after selection
- [ ] Dialog has Cancel and Change Key buttons

### Functionality
- [ ] New key validation works
- [ ] Key fingerprint display works (old and new)
- [ ] All SSH Key accounts re-encrypted with new key
- [ ] YAML updated with new key path for all accounts
- [ ] File chooser defaults to ~/.ssh/

### Security
- [ ] Old key signature used for decryption
- [ ] New key signature used for encryption
- [ ] Key paths validated before use
- [ ] Permissions checked on key files

### Error Handling
- [ ] Invalid key file → error message
- [ ] Missing key file → error message
- [ ] Re-encryption failure → rollback, error message
- [ ] Same key as current → warning or no-op

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
- [ ] Conventional commit: `fix(all): add SSH key change workflow`
- [ ] Branch pushed: `git push -u origin fix/change-ssh-key`
- [ ] Clean diff
- [ ] No merge conflicts with PR #3 base

### Verification Commands
```bash
# All should pass:
ls lib/common/gui/ssh_key_change.rb                            # Expected: exists
grep -n "Change SSH Key" lib/common/gui/account_manager_ui.rb  # Expected: 1+ matches
bundle exec rspec spec/ssh_key_change_spec.rb                  # Expected: all pass
bundle exec rspec                                               # Expected: all pass
bundle exec rubocop                                             # Expected: 0 offenses
git log --oneline -1                                            # Expected: fix(all): add SSH...
```

---

## Edge Cases to Handle

### 1. No SSH Key Mode Accounts
- Button should be disabled
- If somehow activated, show error

### 2. Same Key Selected
- Detect if new key == current key
- Show warning or treat as no-op

### 3. Re-encryption Fails Mid-Process
- Rollback to previous state
- Don't update YAML if re-encryption fails

### 4. Key File Deleted Between Selection and Change
- Validate key exists at change time
- Show error if missing

### 5. Encrypted Key (Passphrase Protected)
- ssh-keygen will prompt for passphrase (acceptable)
- Document that user must enter passphrase

---

## What Comes Next

**After this Fix PR is complete:**
- ✅ All work units complete
- ✅ Ready for beta testing sequence
- Product Owner orchestrates beta train

**All PRs ready for beta:**
1. PR #1: Standard encryption
2. PR #2: Enhanced encryption (with Windows)
3. PR #3: SSH Key + CLI
4. Fix #1: Master password change
5. Fix #2: SSH key change

---

## Troubleshooting

### "Re-encryption fails"
- Verify old key path is correct
- Check signature generation works for both keys
- Ensure PasswordCipher.decrypt works with old signature

### "Fingerprint not showing"
- Check SSHKeyManager.key_fingerprint implementation
- Verify ssh-keygen available
- Test with known good key file

### "Button not showing"
- Verify account_manager_ui.rb changes applied
- Check button state logic
- Ensure SSH Key accounts exist for testing

---

## Context References

**Read before starting:**
- `.claude/docs/CLI_PRIMER.md` - Ground rules
- `.claude/docs/BRD_Password_Encryption.md` - FR-7 requirements
- `lib/common/gui/ssh_key_manager.rb` - SSH key operations
- `lib/common/gui/master_password_change.rb` - Pattern to follow

---

**END OF WORK UNIT**

When complete, archive this file to `.claude/docs/archive/SSH_KEY_CHANGE_COMPLETED.md`.

**Final PR in sequence** - all work units complete after this.
