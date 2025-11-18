# Work Unit: Change Encryption Mode (Feature - FR-4)

**Created:** 2025-11-18
**Type:** Feature (BRD FR-4)
**Estimated Effort:** 6-8 hours
**Base Branch:** `fix/cli-master-password-defects`
**Target Branch:** `feat/change-encryption-mode`
**Priority:** High
**BRD Reference:** FR-4 (Change Encryption Mode)

---

## Feature Overview

**Feature:** Allow users to change encryption mode at any time.

**Scope:**
- **GUI:** Add UI to Account Management tab
- **CLI:** Add headless parameter for encryption mode changes
- **Modes:** Support all transitions (Plaintext ↔ Standard ↔ Enhanced)

**Use Cases:**
- User wants stronger encryption (Standard → Enhanced)
- User wants accessibility (any mode → Plaintext)
- User wants simplicity (Enhanced → Standard)
- User wants automation/scripting (CLI mode changes)

---

## BRD Requirements (FR-4)

**From BRD_Password_Encryption.md:**

> **FR-4: Change Encryption Mode**
>
> **Requirement:** User shall be able to change encryption mode at any time via Account Management UI.
>
> **Process:**
> 1. User clicks "Change Encryption Mode" button
> 2. System displays current mode
> 3. User selects target mode (radio buttons)
> 4. If changing FROM Enhanced mode: User must enter master password for validation
> 5. System creates backup: `entry.yaml.bak`
> 6. System decrypts all passwords with current method
> 7. System re-encrypts all passwords with new method
> 8. System updates `encryption_mode` metadata
> 9. If leaving Enhanced mode: System removes master password from OS keychain
> 10. System saves updated `entry.yaml`
>
> **Business Rules:**
> - Backup created before any destructive operation
> - Enhanced mode exit requires password validation
> - Progress indication shown during re-encryption
> - Success/failure messaging
>
> **Priority:** MUST HAVE

---

## Design Decisions

### Supported Mode Transitions

**All transitions allowed:**

| From | To | Password Required | Keychain Action | Validation |
|------|----|--------------------|-----------------|------------|
| Plaintext | Standard | No | N/A | None |
| Plaintext | Enhanced | Yes (new master) | Store | Create validation test |
| Standard | Plaintext | No | N/A | None |
| Standard | Enhanced | Yes (new master) | Store | Create validation test |
| Enhanced | Plaintext | Yes (current master) | Delete | Validate before transition |
| Enhanced | Standard | Yes (current master) | Delete | Validate before transition |

### UI Placement

**Account Management Tab:**
- Add "Change Encryption Mode" button
- Position: Below existing "Change Encryption Password" button
- Label: "Change Encryption Mode..."
- Visibility: Always visible (all modes)
- Enabled: Always enabled

### CLI Parameter

**Syntax:**
```bash
ruby lich.rbw --change-encryption-mode MODE [--master-password PASSWORD]

# Short form:
ruby lich.rbw -cem MODE [-mp PASSWORD]
```

**Examples:**
```bash
# Change to Standard (from any mode)
ruby lich.rbw --change-encryption-mode standard

# Change to Enhanced (prompts for new master password)
ruby lich.rbw --change-encryption-mode enhanced

# Change to Enhanced (provides password, avoids prompt)
ruby lich.rbw --change-encryption-mode enhanced --master-password MyPassword123

# Change from Enhanced to Standard (prompts for current master password for validation)
ruby lich.rbw --change-encryption-mode standard

# Change to Plaintext (with warning confirmation)
ruby lich.rbw --change-encryption-mode plaintext
```

---

## Implementation Plan

### Part 1: GUI Implementation

#### File 1: encryption_mode_change.rb (NEW - ~400 lines)

**Location:** `lib/common/gui/encryption_mode_change.rb`

**Structure:**
```ruby
# frozen_string_literal: true

require 'gtk3'
require_relative 'yaml_state'
require_relative 'password_cipher'
require_relative 'master_password_manager'
require_relative 'accessibility'

module Lich
  module Common
    module GUI
      module EncryptionModeChange
        # Show change encryption mode dialog
        # @param parent [Gtk::Window] Parent window
        # @param data_dir [String] Directory containing account data
        # @return [Boolean] true if mode changed, false if cancelled
        def self.show_change_mode_dialog(parent, data_dir)
          # Implementation here
        end

        private

        # Validate current master password if leaving Enhanced mode
        def self.validate_current_password(current_mode, yaml_data)
          # Implementation
        end

        # Prompt for new master password if entering Enhanced mode
        def self.prompt_for_new_master_password
          # Implementation
        end

        # Confirm plaintext mode selection
        def self.confirm_plaintext_mode
          # Implementation
        end

        # Re-encrypt all accounts with new mode
        def self.re_encrypt_all_accounts(yaml_state, old_mode, new_mode, old_password, new_password)
          # Implementation
        end
      end
    end
  end
end
```

**Key Methods:**

1. **show_change_mode_dialog(parent, data_dir)**
   - Main entry point
   - Create dialog with mode selection
   - Handle transitions
   - Return success/failure

2. **validate_current_password(current_mode, yaml_data)**
   - If leaving Enhanced: Validate master password
   - Return validated password or nil

3. **prompt_for_new_master_password**
   - If entering Enhanced: Prompt for new password (twice)
   - Validate strength (8+ chars)
   - Return password or nil if cancelled

4. **confirm_plaintext_mode**
   - If entering Plaintext: Show warning dialog
   - Require explicit confirmation
   - Return true/false

5. **re_encrypt_all_accounts(yaml_state, old_mode, new_mode, old_password, new_password)**
   - Decrypt all with old mode
   - Encrypt all with new mode
   - Update YAML
   - Handle keychain (store/delete)
   - Create backup first

#### File 2: account_manager_ui.rb (MODIFY)

**Add button:**
```ruby
# After "Change Encryption Password" button (~line 195)
@change_encryption_mode_button = Gtk::Button.new(label: "Change Encryption Mode...")
@change_encryption_mode_button.signal_connect('clicked') do
  on_change_encryption_mode_clicked
end

button_box.pack_start(@change_encryption_mode_button, expand: false, fill: false, padding: 5)
```

**Add signal handler:**
```ruby
def on_change_encryption_mode_clicked
  success = EncryptionModeChange.show_change_mode_dialog(self, @data_dir)
  refresh_account_list if success
  update_change_master_password_button_state if success
end
```

#### Dialog Structure

**Mode Selection Dialog:**
```
┌────────────────────────────────────────────────────┐
│ Change Encryption Mode                            │
│                                                    │
│ Current Mode: Enhanced (Master Password)          │
│                                                    │
│ Select new encryption mode:                       │
│ ○ Plaintext (No Encryption)                       │
│   For accessibility - screen reader compatible    │
│   ⚠️ Passwords visible in file                    │
│                                                    │
│ ○ Standard Encryption (Account Name)              │
│   Basic encryption, works across devices          │
│                                                    │
│ ● Enhanced Encryption (Master Password)           │
│   Strong encryption, one password per device      │
│   (Currently selected)                            │
│                                                    │
│ ⚠️ All passwords will be decrypted and           │
│    re-encrypted with the new method.             │
│                                                    │
│ [Change Mode] [Cancel]                            │
└────────────────────────────────────────────────────┘
```

**If changing FROM Enhanced (validation):**
```
┌────────────────────────────────────────────────────┐
│ Verify Master Password                            │
│                                                    │
│ To change from Enhanced encryption, please        │
│ enter your current master password:               │
│                                                    │
│ Master Password: [____________________]           │
│                                                    │
│ [Continue] [Cancel]                               │
└────────────────────────────────────────────────────┘
```

**If changing TO Enhanced (new password):**
```
┌────────────────────────────────────────────────────┐
│ Create Master Password                            │
│                                                    │
│ Enter new master password:                        │
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

**If changing TO Plaintext (confirmation):**
```
┌────────────────────────────────────────────────────┐
│ Plaintext Mode Warning                            │
│                                                    │
│ You are about to disable encryption.              │
│                                                    │
│ Plaintext mode stores passwords unencrypted.      │
│ Anyone with access to your file system can        │
│ read your passwords.                              │
│                                                    │
│ This mode is provided for accessibility purposes. │
│                                                    │
│ Continue with Plaintext mode?                     │
│                                                    │
│ [Yes, Disable Encryption] [Cancel]                │
└────────────────────────────────────────────────────┘
```

---

### Part 2: CLI Implementation

#### File: cli_password_manager.rb (MODIFY)

**Add method:**

```ruby
# Change encryption mode and re-encrypt all accounts
#
# @param new_mode [Symbol] Target encryption mode (:plaintext, :standard, :enhanced)
# @param master_password [String, nil] New master password (for Enhanced mode)
# @return [Integer] Exit code (0=success, 1=error, 2=not found, 3=invalid mode)
def self.change_encryption_mode(new_mode, master_password = nil)
  data_dir = Lich.datadir
  yaml_file = Lich::Common::GUI::YamlState.yaml_file_path(data_dir)

  unless File.exist?(yaml_file)
    puts "error: Login file not found: #{yaml_file}"
    Lich.log "error: CLI change encryption mode failed - file not found"
    return 2
  end

  # Validate new mode
  valid_modes = [:plaintext, :standard, :enhanced]
  unless valid_modes.include?(new_mode)
    puts "error: Invalid encryption mode: #{new_mode}"
    puts "Valid modes: plaintext, standard, enhanced"
    Lich.log "error: CLI change encryption mode failed - invalid mode: #{new_mode}"
    return 3
  end

  begin
    yaml_data = YAML.load_file(yaml_file)
    current_mode = yaml_data['encryption_mode']&.to_sym || :plaintext
    account_count = yaml_data['accounts']&.length || 0

    if current_mode == new_mode
      puts "info: Already using #{new_mode} encryption mode"
      Lich.log "info: CLI change encryption mode - already in target mode"
      return 0
    end

    puts "Changing encryption mode: #{current_mode} → #{new_mode}"
    puts "Accounts to re-encrypt: #{account_count}"
    puts ""

    # Validate leaving Enhanced mode
    old_master_password = nil
    if current_mode == :enhanced
      puts "Current mode is Enhanced encryption."
      print "Enter current master password: "
      input = $stdin.gets
      if input.nil?
        puts "error: Unable to read password from STDIN"
        Lich.log "error: CLI change encryption mode failed - stdin unavailable"
        return 1
      end
      old_master_password = input.strip

      # Validate password
      validation_test = yaml_data['master_password_validation_test']
      unless Lich::Common::GUI::MasterPasswordManager.validate_master_password(old_master_password, validation_test)
        puts "error: Incorrect master password"
        Lich.log "error: CLI change encryption mode failed - password validation failed"
        return 1
      end

      puts "✓ Master password validated"
      puts ""
    end

    # Get new master password if entering Enhanced mode
    new_master_password = nil
    if new_mode == :enhanced
      if master_password
        new_master_password = master_password
      else
        print "Enter new master password: "
        input = $stdin.gets
        if input.nil?
          puts "error: Unable to read password from STDIN"
          Lich.log "error: CLI change encryption mode failed - stdin unavailable"
          return 1
        end
        new_master_password = input.strip

        print "Confirm new master password: "
        input = $stdin.gets
        if input.nil?
          puts "error: Unable to read password from STDIN"
          Lich.log "error: CLI change encryption mode failed - stdin unavailable"
          return 1
        end
        confirm_password = input.strip

        unless new_master_password == confirm_password
          puts "error: Passwords do not match"
          Lich.log "error: CLI change encryption mode failed - confirmation mismatch"
          return 1
        end
      end

      if new_master_password.length < 8
        puts "error: Master password must be at least 8 characters"
        Lich.log "error: CLI change encryption mode failed - password too short"
        return 1
      end

      puts "✓ New master password accepted"
      puts ""
    end

    # Warn about plaintext mode
    if new_mode == :plaintext
      puts "⚠️ WARNING: Plaintext mode disables encryption"
      puts "Passwords will be stored unencrypted and visible in the file."
      puts ""
      print "Continue? (yes/no): "
      input = $stdin.gets
      if input.nil? || input.strip.downcase != 'yes'
        puts "Cancelled"
        Lich.log "info: CLI change encryption mode cancelled by user"
        return 0
      end
      puts ""
    end

    # Create backup
    backup_file = "#{yaml_file}.bak"
    FileUtils.cp(yaml_file, backup_file)
    Lich.log "info: Backup created: #{backup_file}"

    # Re-encrypt all accounts
    puts "Re-encrypting accounts..."
    yaml_data['accounts'].each_with_index do |(account_name, account_data), index|
      print "\r  #{index + 1}/#{account_count} accounts processed"

      # Decrypt with current mode
      plaintext = case current_mode
                  when :plaintext
                    account_data['password']
                  when :standard
                    Lich::Common::GUI::PasswordCipher.decrypt(
                      account_data['password'],
                      mode: :standard,
                      account_name: account_name
                    )
                  when :enhanced
                    Lich::Common::GUI::PasswordCipher.decrypt(
                      account_data['password'],
                      mode: :enhanced,
                      account_name: account_name,
                      master_password: old_master_password
                    )
                  end

      # Encrypt with new mode
      encrypted = case new_mode
                  when :plaintext
                    plaintext
                  when :standard
                    Lich::Common::GUI::PasswordCipher.encrypt(
                      plaintext,
                      mode: :standard,
                      account_name: account_name
                    )
                  when :enhanced
                    Lich::Common::GUI::PasswordCipher.encrypt(
                      plaintext,
                      mode: :enhanced,
                      account_name: account_name,
                      master_password: new_master_password
                    )
                  end

      account_data['password'] = encrypted
    end
    puts ""  # Newline after progress

    # Update encryption mode
    yaml_data['encryption_mode'] = new_mode.to_s

    # Handle Enhanced mode metadata
    if new_mode == :enhanced
      # Create validation test
      validation_test = Lich::Common::GUI::MasterPasswordManager.create_validation_test(new_master_password)
      yaml_data['master_password_validation_test'] = validation_test

      # Store in keychain
      unless Lich::Common::GUI::MasterPasswordManager.store_master_password(new_master_password)
        puts "error: Failed to store master password in keychain"
        Lich.log "error: CLI change encryption mode failed - keychain storage failed"
        # Restore backup
        FileUtils.cp(backup_file, yaml_file)
        return 1
      end
    elsif current_mode == :enhanced
      # Remove validation test
      yaml_data.delete('master_password_validation_test')

      # Remove from keychain
      Lich::Common::GUI::MasterPasswordManager.delete_master_password
    end

    # Save YAML
    File.open(yaml_file, 'w', 0o600) do |file|
      file.write(YAML.dump(yaml_data))
    end

    puts ""
    puts "✓ Encryption mode changed: #{current_mode} → #{new_mode}"
    puts "✓ #{account_count} accounts re-encrypted"
    puts "✓ Backup saved: #{backup_file}"
    Lich.log "info: CLI change encryption mode successful: #{current_mode} → #{new_mode}"
    return 0

  rescue StandardError => e
    puts "error: Failed to change encryption mode: #{e.message}"
    Lich.log "error: CLI change encryption mode failed: #{e.message}"

    # Restore backup if exists
    if File.exist?(backup_file)
      FileUtils.cp(backup_file, yaml_file)
      puts "✓ Backup restored"
    end
    return 1
  end
end
```

#### File: argv_options.rb (MODIFY)

**Add CLI parameter:**

```ruby
# In CliOperations module
elsif arg =~ /^--change-encryption-mode$/ || arg =~ /^-cem$/
  require_relative '../util/cli_password_manager'

  mode_arg = ARGV[ARGV.index(arg) + 1]
  master_password = nil

  if mode_arg.nil?
    puts 'error: Missing encryption mode'
    puts 'Usage: ruby lich.rbw --change-encryption-mode MODE [--master-password PASSWORD]'
    puts '       ruby lich.rbw -cem MODE [-mp PASSWORD]'
    puts 'Modes: plaintext, standard, enhanced'
    exit 1
  end

  mode = mode_arg.to_sym

  # Check for optional master password (for Enhanced mode)
  mp_index = ARGV.index('--master-password') || ARGV.index('-mp')
  if mp_index
    master_password = ARGV[mp_index + 1]
  end

  exit Lich::Util::CLI::PasswordManager.change_encryption_mode(mode, master_password)
```

---

## Testing Strategy

### GUI Test Cases

#### Test Case 1: Standard → Enhanced

**Steps:**
1. Start with Standard mode account
2. Click "Change Encryption Mode..."
3. Select "Enhanced Encryption"
4. Enter new master password (twice)
5. Click "Change Mode"

**Expected:**
- ✅ Prompt for new master password
- ✅ Progress indication during re-encryption
- ✅ Success message
- ✅ Master password stored in keychain
- ✅ Validation test in YAML
- ✅ Accounts encrypted with new mode
- ✅ Backup created

#### Test Case 2: Enhanced → Standard

**Steps:**
1. Start with Enhanced mode account
2. Click "Change Encryption Mode..."
3. Select "Standard Encryption"
4. Enter current master password
5. Click "Change Mode"

**Expected:**
- ✅ Prompt for current master password validation
- ✅ Progress indication during re-encryption
- ✅ Success message
- ✅ Master password removed from keychain
- ✅ Validation test removed from YAML
- ✅ Accounts encrypted with Standard mode
- ✅ Backup created

#### Test Case 3: Any → Plaintext

**Steps:**
1. Start with any encrypted mode
2. Click "Change Encryption Mode..."
3. Select "Plaintext"
4. Confirm warning dialog

**Expected:**
- ✅ Warning dialog about plaintext risks
- ✅ Require explicit confirmation
- ✅ Progress indication
- ✅ Passwords stored as plaintext
- ✅ Backup created

### CLI Test Cases

#### Test Case 4: CLI Standard → Enhanced

**Command:**
```bash
ruby lich.rbw --change-encryption-mode enhanced
```

**Expected interaction:**
```
Changing encryption mode: standard → enhanced
Accounts to re-encrypt: 3

Enter new master password: [input]
Confirm new master password: [input]
✓ New master password accepted

Re-encrypting accounts...
  3/3 accounts processed

✓ Encryption mode changed: standard → enhanced
✓ 3 accounts re-encrypted
✓ Backup saved: /path/entry.yaml.bak
```

**Exit code:** 0

#### Test Case 5: CLI Enhanced → Standard (with validation)

**Command:**
```bash
ruby lich.rbw --change-encryption-mode standard
```

**Expected interaction:**
```
Changing encryption mode: enhanced → standard
Accounts to re-encrypt: 3

Current mode is Enhanced encryption.
Enter current master password: [input]
✓ Master password validated

Re-encrypting accounts...
  3/3 accounts processed

✓ Encryption mode changed: enhanced → standard
✓ 3 accounts re-encrypted
✓ Backup saved: /path/entry.yaml.bak
```

**Exit code:** 0

#### Test Case 6: CLI to Plaintext (with warning)

**Command:**
```bash
ruby lich.rbw --change-encryption-mode plaintext
```

**Expected interaction:**
```
Changing encryption mode: standard → plaintext
Accounts to re-encrypt: 3

⚠️ WARNING: Plaintext mode disables encryption
Passwords will be stored unencrypted and visible in the file.

Continue? (yes/no): yes

Re-encrypting accounts...
  3/3 accounts processed

✓ Encryption mode changed: standard → plaintext
✓ 3 accounts re-encrypted
✓ Backup saved: /path/entry.yaml.bak
```

**Exit code:** 0

---

## Acceptance Criteria

### GUI Implementation
- [ ] "Change Encryption Mode..." button added to Account Management tab
- [ ] Button always visible and enabled
- [ ] Mode selection dialog shows current mode
- [ ] All three modes selectable (Plaintext, Standard, Enhanced)
- [ ] FROM Enhanced: Master password validation required
- [ ] TO Enhanced: New master password prompt (enter twice)
- [ ] TO Plaintext: Warning dialog with explicit confirmation
- [ ] Progress indication during re-encryption
- [ ] Success/failure messaging
- [ ] Backup created before changes
- [ ] Keychain updated (store/delete as appropriate)

### CLI Implementation
- [ ] `--change-encryption-mode MODE` parameter works
- [ ] Short form `-cem MODE` works
- [ ] FROM Enhanced: Prompts for current master password
- [ ] TO Enhanced: Prompts for new master password (or accepts --master-password)
- [ ] TO Plaintext: Warning and confirmation
- [ ] Progress indication (accounts processed)
- [ ] Exit codes correct (0=success, 1=error, 2=not found, 3=invalid mode)
- [ ] Backup created before changes
- [ ] Error handling and rollback on failure

### Functionality
- [ ] All mode transitions work (6 transitions)
- [ ] Passwords decrypt/encrypt correctly
- [ ] YAML encryption_mode field updated
- [ ] Validation test added/removed (Enhanced mode)
- [ ] Keychain updated (store/delete)
- [ ] Backup mechanism works
- [ ] Rollback on failure works

### Code Quality
- [ ] SOLID + DRY principles followed
- [ ] Security-conscious (no password logging)
- [ ] Clear error messages
- [ ] Follows existing UI/CLI patterns
- [ ] Progress indication implemented
- [ ] YARD documentation on all public methods

### Testing
- [ ] Manual test: GUI Standard → Enhanced ✅
- [ ] Manual test: GUI Enhanced → Standard ✅
- [ ] Manual test: GUI any → Plaintext ✅
- [ ] Manual test: CLI Standard → Enhanced ✅
- [ ] Manual test: CLI Enhanced → Standard ✅
- [ ] Manual test: CLI to Plaintext ✅
- [ ] Manual test: Wrong password (Enhanced exit) ✅
- [ ] Manual test: Cancel operations ✅

### Git
- [ ] Branch: `feat/change-encryption-mode`
- [ ] Conventional commit: `feat(all): implement change encryption mode (FR-4)`
- [ ] Clean commit history

---

## Edge Cases

1. **Cancel during master password prompt** - No changes made
2. **Wrong master password (Enhanced exit)** - Clear error, retry allowed
3. **Password mismatch (Enhanced entry)** - Clear error, retry allowed
4. **STDIN unavailable (CLI)** - Clear error, graceful exit
5. **Keychain unavailable (Enhanced)** - Error, no mode change
6. **Re-encryption fails mid-process** - Rollback to backup
7. **Already in target mode** - Info message, no operation
8. **No accounts exist** - Still updates mode, no re-encryption needed

---

## Success Criteria

**Definition of Done:**
1. ✅ GUI button and dialog functional
2. ✅ CLI parameter functional
3. ✅ All 6 mode transitions work
4. ✅ Master password validation (FROM Enhanced)
5. ✅ Master password creation (TO Enhanced)
6. ✅ Plaintext warning and confirmation
7. ✅ Progress indication working
8. ✅ Backup mechanism working
9. ✅ Keychain integration working
10. ✅ All test cases passing
11. ✅ Error handling and rollback working
12. ✅ Commit pushed to branch

**Estimated completion:** 6-8 hours

---

**Status:** Ready for CLI Claude execution
**Dependencies:** None (builds on fix/cli-master-password-defects)
**Blocker:** None
