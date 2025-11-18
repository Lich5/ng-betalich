# Work Unit: CLI Master Password Recovery (Bug)

**Created:** 2025-11-18
**Type:** Bug Fix
**Estimated Effort:** 3-4 hours
**Base Branch:** `fix/cli-master-password-defects`
**Target Branch:** `fix/cli-master-password-recovery`
**Priority:** High

---

## Problem Statement

**Bug:** CLI mode has no recovery mechanism when master password is removed from OS keychain.

**Symptoms:**
- **GUI (works):** Detects missing keychain password via YAML validation check, triggers recovery dialog
- **CLI (broken):** No detection, likely crashes or fails with unclear error when attempting password operations

**Impact:**
- CLI operations fail catastrophically when keychain password missing
- No user-friendly error reporting
- No recovery path for headless/scripted environments

---

## Context

### GUI Recovery Flow (Reference)

**From previous audit (fix/master-password-recovery branch):**
- Detects missing keychain password
- Shows recovery dialog
- Prompts for account password re-entry
- Optionally changes encryption mode
- Uses `master_password_validation_test` in YAML to verify

### CLI Current Behavior (Broken)

**Scenario:** Master password removed from keychain, then run CLI command:
```bash
ruby lich.rbw --change-account-password DOUG NewPassword123
```

**Likely current behavior:**
```
error: Master password not found in keychain
# OR crashes with exception
```

**No recovery path provided.**

---

## Objectives

1. **Detect missing keychain password in CLI operations**
2. **Report clear, actionable error message**
3. **Exit gracefully with appropriate exit code**
4. **Provide CLI recovery mechanism** - new parameter for password recovery/reset

---

## Design Decisions

### CLI Recovery Philosophy

**Principle:** CLI should be **headless-friendly** and **scriptable**

**Recovery approach:**
- **Detection:** Check for master password in keychain before operations
- **Reporting:** Clear error message with next steps
- **Exit:** Graceful exit with specific error code
- **Recovery:** Separate CLI parameter for recovery (minimal interaction)

### Recovery Parameter Options

**Option A: `--recover-master-password` (RECOMMENDED)**
```bash
# Detects missing keychain, prompts for new master password
ruby lich.rbw --recover-master-password

# Or with new password provided (avoid process list exposure)
ruby lich.rbw --recover-master-password NEWPASSWORD
```

**Option B: `--reset-encryption` (More general)**
```bash
# Resets to different encryption mode, re-enters passwords
ruby lich.rbw --reset-encryption standard
ruby lich.rbw --reset-encryption enhanced
```

**Recommendation:** Implement **Option A** first (simpler, focused on master password recovery)

---

## Implementation Plan

### Part 1: Detection & Reporting

**File:** `lib/util/cli_password_manager.rb`

**Add validation check before Enhanced mode operations:**

```ruby
def self.validate_master_password_available(yaml_data)
  # Check if Enhanced mode
  encryption_mode = yaml_data['encryption_mode']&.to_sym
  return true unless encryption_mode == :enhanced

  # Check for validation test (indicates Enhanced mode was used)
  validation_test = yaml_data['master_password_validation_test']
  return true if validation_test.nil?  # Not Enhanced mode

  # Check keychain for password
  master_password = Lich::Common::GUI::MasterPasswordManager.retrieve_master_password

  if master_password.nil?
    puts "error: Master password not found in OS keychain"
    puts ""
    puts "This account uses Enhanced encryption, but the master password"
    puts "is missing from your system keychain."
    puts ""
    puts "To recover, run:"
    puts "  ruby lich.rbw --recover-master-password"
    puts ""
    puts "This will prompt for a new master password and update the keychain."
    Lich.log "error: CLI operation failed - master password missing from keychain"
    return false
  end

  true
end
```

**Integration points:**
- `change_account_password` - Check before attempting decrypt
- `add_account` - Check before attempting encrypt
- `change_master_password` - Already validates, but improve error message

**Exit code:** Use `2` (not found) or add new code `4` (recovery needed)

---

### Part 2: Recovery Parameter Implementation

**File:** `lib/main/argv_options.rb`

**Add new CLI operation:**

```ruby
# In CliOperations module
elsif arg =~ /^--recover-master-password$/ || arg =~ /^-rmp$/
  require_relative '../util/cli_password_manager'

  # Optional: New password from command line (next arg)
  new_password = ARGV[ARGV.index(arg) + 1]
  new_password = nil if new_password&.start_with?('--')  # Not a password, another flag

  exit Lich::Util::CLI::PasswordManager.recover_master_password(new_password)
```

**File:** `lib/util/cli_password_manager.rb`

**Add recovery method:**

```ruby
# Recover master password when keychain password is missing
#
# @param new_password [String, nil] New master password (optional, will prompt if nil)
# @return [Integer] Exit code (0=success, 1=error, 2=not found, 3=wrong mode)
def self.recover_master_password(new_password = nil)
  data_dir = Lich.datadir
  yaml_file = Lich::Common::GUI::YamlState.yaml_file_path(data_dir)

  unless File.exist?(yaml_file)
    puts "error: Login file not found: #{yaml_file}"
    Lich.log "error: CLI recover master password failed - file not found"
    return 2
  end

  begin
    yaml_data = YAML.load_file(yaml_file)
    encryption_mode = yaml_data['encryption_mode']&.to_sym

    unless encryption_mode == :enhanced
      puts "error: Not in Enhanced encryption mode (current mode: #{encryption_mode})"
      puts "Recovery only applies to Enhanced encryption"
      Lich.log "error: CLI recover master password failed - not Enhanced mode"
      return 3
    end

    validation_test = yaml_data['master_password_validation_test']
    unless validation_test
      puts "error: No master password validation test found in YAML"
      puts "This may not be a valid Enhanced encryption configuration"
      Lich.log "error: CLI recover master password failed - no validation test"
      return 1
    end

    puts "Master Password Recovery"
    puts "========================"
    puts ""
    puts "This will set a NEW master password and update the OS keychain."
    puts "All account passwords will remain encrypted and accessible."
    puts ""

    # Get new password (prompt if not provided)
    if new_password.nil?
      print "Enter new master password: "
      input = $stdin.gets
      if input.nil?
        puts "error: Unable to read password from STDIN"
        Lich.log "error: CLI recover master password failed - stdin unavailable"
        return 1
      end
      new_password = input.strip

      print "Confirm new master password: "
      input = $stdin.gets
      if input.nil?
        puts "error: Unable to read password from STDIN"
        Lich.log "error: CLI recover master password failed - stdin unavailable"
        return 1
      end
      confirm_password = input.strip

      unless new_password == confirm_password
        puts "error: Passwords do not match"
        Lich.log "error: CLI recover master password failed - confirmation mismatch"
        return 1
      end
    end

    # Validate password strength
    if new_password.length < 8
      puts "error: New master password must be at least 8 characters"
      Lich.log "error: CLI recover master password failed - password too short"
      return 1
    end

    # Store new password in keychain
    unless Lich::Common::GUI::MasterPasswordManager.store_master_password(new_password)
      puts "error: Failed to store master password in OS keychain"
      Lich.log "error: CLI recover master password failed - keychain storage failed"
      return 1
    end

    # Verify stored password can decrypt an account
    # (Test that password works with existing encrypted accounts)
    test_account = yaml_data['accounts'].first
    if test_account
      account_name, account_data = test_account
      begin
        Lich::Common::GUI::PasswordCipher.decrypt(
          account_data['password'],
          mode: :enhanced,
          account_name: account_name,
          master_password: new_password
        )

        puts ""
        puts "✓ Master password recovered successfully"
        puts "✓ Password stored in OS keychain"
        puts "✓ Account passwords remain encrypted and accessible"
        Lich.log "info: CLI master password recovery successful"
        return 0

      rescue StandardError => e
        puts ""
        puts "error: New password cannot decrypt existing accounts"
        puts "This password may not match the original master password"
        puts ""
        puts "If you've lost the original password, you will need to:"
        puts "  1. Run with GUI to trigger full recovery dialog"
        puts "  2. Re-enter all account passwords manually"
        Lich.log "error: CLI recover master password failed - password cannot decrypt: #{e.message}"

        # Remove bad password from keychain
        Lich::Common::GUI::MasterPasswordManager.delete_master_password
        return 1
      end
    else
      # No accounts to test - store password anyway
      puts ""
      puts "✓ Master password stored in OS keychain"
      puts "⚠ Warning: No accounts found to verify password"
      Lich.log "info: CLI master password recovery successful (no accounts to verify)"
      return 0
    end

  rescue StandardError => e
    puts "error: Failed to recover master password: #{e.message}"
    Lich.log "error: CLI recover master password failed: #{e.message}"
    return 1
  end
end
```

---

## Testing Strategy

### Test Case 1: Detect Missing Keychain (Change Account Password)

**Setup:**
1. Enhanced mode account exists
2. Remove master password from keychain:
   ```ruby
   Lich::Common::GUI::MasterPasswordManager.delete_master_password
   ```

**Command:**
```bash
ruby lich.rbw --change-account-password DOUG NewPassword123
```

**Expected output:**
```
error: Master password not found in OS keychain

This account uses Enhanced encryption, but the master password
is missing from your system keychain.

To recover, run:
  ruby lich.rbw --recover-master-password

This will prompt for a new master password and update the keychain.
```

**Expected exit code:** 2 or 4

### Test Case 2: Recovery with Interactive Prompt

**Setup:** Same as Test Case 1

**Command:**
```bash
ruby lich.rbw --recover-master-password
```

**Expected interaction:**
```
Master Password Recovery
========================

This will set a NEW master password and update the OS keychain.
All account passwords will remain encrypted and accessible.

Enter new master password: [user types]
Confirm new master password: [user types]

✓ Master password recovered successfully
✓ Password stored in OS keychain
✓ Account passwords remain encrypted and accessible
```

**Expected exit code:** 0

### Test Case 3: Recovery with Provided Password

**Command:**
```bash
ruby lich.rbw --recover-master-password MyNewPassword123
```

**Expected output:** (No prompts, direct success)
```
Master Password Recovery
========================

This will set a NEW master password and update the OS keychain.
All account passwords will remain encrypted and accessible.

✓ Master password recovered successfully
✓ Password stored in OS keychain
✓ Account passwords remain encrypted and accessible
```

**Expected exit code:** 0

### Test Case 4: Recovery Wrong Mode (Standard)

**Setup:** Standard mode account

**Command:**
```bash
ruby lich.rbw --recover-master-password
```

**Expected output:**
```
error: Not in Enhanced encryption mode (current mode: standard)
Recovery only applies to Enhanced encryption
```

**Expected exit code:** 3

### Test Case 5: Recovery Wrong Password

**Setup:** Enhanced mode, wrong password provided

**Command:**
```bash
ruby lich.rbw --recover-master-password WrongPassword123
```

**Expected output:**
```
Master Password Recovery
========================

This will set a NEW master password and update the OS keychain.
All account passwords will remain encrypted and accessible.

error: New password cannot decrypt existing accounts
This password may not match the original master password

If you've lost the original password, you will need to:
  1. Run with GUI to trigger full recovery dialog
  2. Re-enter all account passwords manually
```

**Expected exit code:** 1

---

## Acceptance Criteria

### Detection
- [ ] CLI detects missing keychain password before operations
- [ ] Clear error message displayed (with recovery instructions)
- [ ] Graceful exit with appropriate exit code
- [ ] Error logged (without exposing passwords)

### Recovery Parameter
- [ ] `--recover-master-password` parameter recognized
- [ ] Interactive prompt works (enter + confirm)
- [ ] Provided password works (avoids prompt)
- [ ] Password stored in keychain successfully
- [ ] Password verified against existing encrypted accounts
- [ ] Wrong password detected and keychain not corrupted

### Edge Cases
- [ ] Wrong encryption mode detected (exit code 3)
- [ ] No validation test in YAML (error reported)
- [ ] STDIN unavailable (error reported, not crash)
- [ ] Password too short (< 8 chars) rejected
- [ ] Password mismatch during confirmation rejected

### Code Quality
- [ ] SOLID + DRY principles followed
- [ ] Security-conscious (no password logging)
- [ ] Clear error messages (user-friendly)
- [ ] Consistent with existing CLI patterns

### Testing
- [ ] Manual test: Detection works (change-account-password with missing keychain)
- [ ] Manual test: Recovery with prompt works
- [ ] Manual test: Recovery with password works
- [ ] Manual test: Wrong mode detected
- [ ] Manual test: Wrong password detected

### Git
- [ ] Branch: `fix/cli-master-password-recovery`
- [ ] Conventional commit: `fix(cli): add master password recovery mechanism`
- [ ] Clean commit history

---

## Exit Codes Reference

| Code | Meaning | When Used |
|------|---------|-----------|
| 0 | Success | Operation completed |
| 1 | General error | Encryption failed, keychain unavailable, validation failed |
| 2 | Not found | Account not found, file missing |
| 3 | Wrong mode | Not Enhanced mode (recovery only for Enhanced) |
| 4 | Recovery needed (NEW) | Master password missing from keychain |

---

## Integration with Existing CLI Operations

**Updated: `change_account_password`**
```ruby
def self.change_account_password(account, new_password)
  # ... existing setup ...

  # Add validation before operation
  unless validate_master_password_available(yaml_data)
    return 4  # Recovery needed
  end

  # ... rest of existing logic ...
end
```

**Updated: `change_master_password`**
```ruby
def self.change_master_password(old_password, new_password = nil)
  # ... existing setup ...

  # Improve error message if keychain missing
  unless master_password
    puts "error: Master password not found in OS keychain"
    puts ""
    puts "To recover, run:"
    puts "  ruby lich.rbw --recover-master-password"
    puts ""
    Lich.log "error: CLI change master password failed - keychain password missing"
    return 4  # Recovery needed
  end

  # ... rest of existing logic ...
end
```

---

## Documentation Updates

**Add to CLI help/usage:**
```
Password Management:
  --change-account-password ACCOUNT NEWPASSWORD, -cap
      Change password for an existing account

  --change-master-password OLDPASSWORD [NEWPASSWORD], -cmp
      Change master password (Enhanced mode only)

  --recover-master-password [NEWPASSWORD], -rmp
      Recover master password when keychain password is missing
      (Enhanced mode only)
```

---

## Rollback Plan

**If implementation causes issues:**
1. Revert commit
2. Restore working state
3. Detection logic can be disabled without breaking existing functionality

**Low risk:** New feature, doesn't modify existing operations except error handling

---

## Success Criteria

**Definition of Done:**
1. ✅ Detection works - missing keychain detected with clear error
2. ✅ Recovery parameter works - `--recover-master-password` functional
3. ✅ Interactive prompt works - enter + confirm password
4. ✅ Provided password works - skip prompt
5. ✅ Wrong password detected - doesn't corrupt keychain
6. ✅ Exit codes correct and documented
7. ✅ Manual testing complete (all test cases pass)
8. ✅ No password logging (security verified)
9. ✅ Commit pushed to branch

**Estimated completion:** 3-4 hours (including testing)

---

**Status:** Ready for CLI Claude execution
**Dependencies:** None (builds on fix/cli-master-password-defects)
**Blocker:** None
