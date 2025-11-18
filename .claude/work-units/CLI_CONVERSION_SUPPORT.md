# Work Unit: CLI Conversion Support (Feature)

**Created:** 2025-11-18
**Type:** Feature
**Estimated Effort:** 4-6 hours
**Base Branch:** `fix/cli-master-password-defects`
**Target Branch:** `feat/cli-conversion-support`
**Priority:** Medium

---

## Feature Overview

**Feature:** Enable headless conversion from `entry.dat` to `entry.yaml` via CLI parameters.

**Current Behavior:**
- GUI detects `entry.dat` (no `entry.yaml`) and triggers conversion dialog automatically
- CLI has no conversion capability - requires GUI launch

**Desired Behavior:**
- CLI detects conversion state
- Reports state with helpful guidance
- Suggests next CLI command
- Executes conversion via parameters
- Minimal interaction (headless-friendly)

**Use Cases:**
- Server deployments (no GUI available)
- Automation scripts
- Docker containers
- CI/CD pipelines
- Batch conversions across multiple systems

---

## Design Decisions

### Detection vs. Execution

**Two-step process:**

1. **Detection Step** - Report state, suggest command, exit
   ```bash
   ruby lich.rbw --change-account-password DOUG NewPass123

   # Output:
   # error: Conversion required
   #
   # Your account data needs to be converted from the legacy format.
   #
   # To convert, run:
   #   ruby lich.rbw --convert-accounts --mode standard
   #
   # Conversion modes:
   #   plaintext - No encryption (accessibility mode)
   #   standard  - Basic encryption (recommended)
   #   enhanced  - Strong encryption with master password
   ```

2. **Execution Step** - Perform conversion
   ```bash
   ruby lich.rbw --convert-accounts --mode standard

   # Performs conversion, reports success
   ```

**Rationale:**
- Explicit conversion action (no surprises)
- Clear guidance to user
- Scriptable and automatable
- Follows CLI philosophy: report and suggest, don't auto-execute

---

## Implementation Plan

### Part 1: State Detection

#### File: cli_password_manager.rb (MODIFY)

**Add state detection method:**

```ruby
# Check if conversion is needed (entry.dat exists, entry.yaml doesn't)
#
# @param data_dir [String] Data directory
# @return [Boolean] true if conversion needed
def self.conversion_needed?(data_dir)
  yaml_file = Lich::Common::GUI::YamlState.yaml_file_path(data_dir)
  legacy_file = File.join(data_dir, 'entry.dat')

  !File.exist?(yaml_file) && File.exist?(legacy_file)
end

# Report conversion state and exit with guidance
#
# @return [Integer] Exit code (2 = conversion needed)
def self.report_conversion_needed
  puts "error: Conversion required"
  puts ""
  puts "Your account data needs to be converted from the legacy format."
  puts ""
  puts "To convert, run:"
  puts "  ruby lich.rbw --convert-accounts --mode MODE"
  puts ""
  puts "Conversion modes:"
  puts "  plaintext - No encryption (accessibility mode)"
  puts "  standard  - Basic encryption (recommended for most users)"
  puts "  enhanced  - Strong encryption with master password"
  puts ""
  puts "Example:"
  puts "  ruby lich.rbw --convert-accounts --mode standard"
  puts ""
  Lich.log "info: CLI operation blocked - conversion needed"
  2  # Exit code: conversion needed
end
```

**Integrate into existing operations:**

```ruby
def self.change_account_password(account, new_password)
  data_dir = Lich.datadir

  # Check if conversion needed
  if conversion_needed?(data_dir)
    return report_conversion_needed
  end

  # ... rest of existing logic ...
end

def self.add_account(account, password, frontend = nil)
  data_dir = Lich.datadir

  # Check if conversion needed
  if conversion_needed?(data_dir)
    return report_conversion_needed
  end

  # ... rest of existing logic ...
end

def self.change_master_password(old_password, new_password = nil)
  data_dir = Lich.datadir

  # Check if conversion needed
  if conversion_needed?(data_dir)
    return report_conversion_needed
  end

  # ... rest of existing logic ...
end
```

---

### Part 2: Conversion Execution

#### File: cli_password_manager.rb (MODIFY)

**Add conversion method:**

```ruby
# Convert legacy entry.dat to entry.yaml format
#
# @param mode [Symbol] Encryption mode (:plaintext, :standard, :enhanced)
# @param master_password [String, nil] Master password (for Enhanced mode)
# @return [Integer] Exit code (0=success, 1=error, 2=not found, 3=invalid mode)
def self.convert_accounts(mode, master_password = nil)
  data_dir = Lich.datadir
  yaml_file = Lich::Common::GUI::YamlState.yaml_file_path(data_dir)
  legacy_file = File.join(data_dir, 'entry.dat')

  # Validate mode
  valid_modes = [:plaintext, :standard, :enhanced]
  unless valid_modes.include?(mode)
    puts "error: Invalid conversion mode: #{mode}"
    puts "Valid modes: plaintext, standard, enhanced"
    Lich.log "error: CLI conversion failed - invalid mode: #{mode}"
    return 3
  end

  # Check legacy file exists
  unless File.exist?(legacy_file)
    puts "error: Legacy file not found: #{legacy_file}"
    Lich.log "error: CLI conversion failed - legacy file not found"
    return 2
  end

  # Check if already converted
  if File.exist?(yaml_file)
    puts "info: Already converted (#{yaml_file} exists)"
    Lich.log "info: CLI conversion skipped - already converted"
    return 0
  end

  begin
    puts "Legacy Account Conversion"
    puts "========================="
    puts ""
    puts "Source: #{legacy_file}"
    puts "Target: #{yaml_file}"
    puts "Mode:   #{mode}"
    puts ""

    # Enhanced mode: Get master password
    if mode == :enhanced
      if master_password.nil?
        print "Enter new master password: "
        input = $stdin.gets
        if input.nil?
          puts "error: Unable to read password from STDIN"
          Lich.log "error: CLI conversion failed - stdin unavailable"
          return 1
        end
        master_password = input.strip

        print "Confirm master password: "
        input = $stdin.gets
        if input.nil?
          puts "error: Unable to read password from STDIN"
          Lich.log "error: CLI conversion failed - stdin unavailable"
          return 1
        end
        confirm_password = input.strip

        unless master_password == confirm_password
          puts "error: Passwords do not match"
          Lich.log "error: CLI conversion failed - password confirmation mismatch"
          return 1
        end
      end

      if master_password.length < 8
        puts "error: Master password must be at least 8 characters"
        Lich.log "error: CLI conversion failed - password too short"
        return 1
      end

      puts "✓ Master password accepted"
      puts ""
    end

    # Plaintext warning
    if mode == :plaintext
      puts "⚠️ WARNING: Plaintext mode disables encryption"
      puts "Passwords will be stored unencrypted and visible in the file."
      puts ""
      print "Continue? (yes/no): "
      input = $stdin.gets
      if input.nil? || input.strip.downcase != 'yes'
        puts "Cancelled"
        Lich.log "info: CLI conversion cancelled by user"
        return 0
      end
      puts ""
    end

    # Load legacy data
    puts "Loading legacy accounts..."
    legacy_data = Marshal.load(File.binread(legacy_file))

    unless legacy_data.is_a?(Hash)
      puts "error: Invalid legacy file format"
      Lich.log "error: CLI conversion failed - invalid legacy format"
      return 1
    end

    account_count = legacy_data.length
    puts "✓ #{account_count} accounts found"
    puts ""

    # Convert and encrypt accounts
    puts "Converting accounts..."
    converted_accounts = {}

    legacy_data.each_with_index do |(account_name, account_info), index|
      print "\r  #{index + 1}/#{account_count} accounts processed"

      # Extract password from legacy format
      plaintext_password = account_info[:password] || account_info['password']

      # Encrypt based on mode
      encrypted_password = case mode
                           when :plaintext
                             plaintext_password
                           when :standard
                             Lich::Common::GUI::PasswordCipher.encrypt(
                               plaintext_password,
                               mode: :standard,
                               account_name: account_name
                             )
                           when :enhanced
                             Lich::Common::GUI::PasswordCipher.encrypt(
                               plaintext_password,
                               mode: :enhanced,
                               account_name: account_name,
                               master_password: master_password
                             )
                           end

      # Extract frontend (if present)
      frontend = account_info[:frontend] || account_info['frontend'] || ''

      # Build converted account entry
      converted_accounts[account_name] = {
        'password' => encrypted_password,
        'frontend' => frontend,
        'characters' => []  # Will be populated on next login
      }
    end
    puts ""  # Newline after progress

    # Build YAML structure
    yaml_data = {
      'version' => '1.0',
      'encryption_mode' => mode.to_s,
      'accounts' => converted_accounts
    }

    # Enhanced mode: Add validation test and store in keychain
    if mode == :enhanced
      validation_test = Lich::Common::GUI::MasterPasswordManager.create_validation_test(master_password)
      yaml_data['master_password_validation_test'] = validation_test

      unless Lich::Common::GUI::MasterPasswordManager.store_master_password(master_password)
        puts "error: Failed to store master password in OS keychain"
        Lich.log "error: CLI conversion failed - keychain storage failed"
        return 1
      end
    end

    # Save YAML file
    File.open(yaml_file, 'w', 0o600) do |file|
      file.write(YAML.dump(yaml_data))
    end

    # Backup legacy file
    backup_file = "#{legacy_file}.bak"
    FileUtils.cp(legacy_file, backup_file)

    puts ""
    puts "✓ Conversion complete"
    puts "✓ #{account_count} accounts converted"
    puts "✓ Encryption mode: #{mode}"
    puts "✓ YAML file: #{yaml_file}"
    puts "✓ Legacy backup: #{backup_file}"

    if mode == :enhanced
      puts "✓ Master password stored in OS keychain"
    end

    puts ""
    puts "You can now use Lich with the new format."
    Lich.log "info: CLI conversion successful - #{account_count} accounts, mode: #{mode}"
    return 0

  rescue StandardError => e
    puts "error: Conversion failed: #{e.message}"
    Lich.log "error: CLI conversion failed: #{e.message}"
    return 1
  end
end
```

---

### Part 3: CLI Parameter Registration

#### File: argv_options.rb (MODIFY)

**Add conversion parameter:**

```ruby
# In CliOperations module
elsif arg =~ /^--convert-accounts$/ || arg =~ /^-ca$/
  require_relative '../util/cli_password_manager'

  # Get mode from next argument
  mode_arg = ARGV[ARGV.index(arg) + 1]

  if mode_arg.nil? || mode_arg.start_with?('--')
    puts 'error: Missing conversion mode'
    puts 'Usage: ruby lich.rbw --convert-accounts --mode MODE [--master-password PASSWORD]'
    puts '       ruby lich.rbw -ca --mode MODE [-mp PASSWORD]'
    puts 'Modes: plaintext, standard, enhanced'
    exit 1
  end

  # Check for --mode flag (preferred) or direct mode argument
  mode = if ARGV.include?('--mode')
           mode_index = ARGV.index('--mode')
           ARGV[mode_index + 1]&.to_sym
         else
           mode_arg.to_sym
         end

  # Check for optional master password (for Enhanced mode)
  master_password = nil
  mp_index = ARGV.index('--master-password') || ARGV.index('-mp')
  if mp_index
    master_password = ARGV[mp_index + 1]
  end

  exit Lich::Util::CLI::PasswordManager.convert_accounts(mode, master_password)
```

---

## Testing Strategy

### Test Case 1: Detection - Report Conversion Needed

**Setup:**
- Fresh environment with `entry.dat`
- No `entry.yaml` exists

**Command:**
```bash
ruby lich.rbw --change-account-password DOUG NewPass123
```

**Expected output:**
```
error: Conversion required

Your account data needs to be converted from the legacy format.

To convert, run:
  ruby lich.rbw --convert-accounts --mode MODE

Conversion modes:
  plaintext - No encryption (accessibility mode)
  standard  - Basic encryption (recommended for most users)
  enhanced  - Strong encryption with master password

Example:
  ruby lich.rbw --convert-accounts --mode standard
```

**Expected exit code:** 2

---

### Test Case 2: Conversion - Standard Mode

**Setup:** Same as Test Case 1

**Command:**
```bash
ruby lich.rbw --convert-accounts --mode standard
```

**Expected output:**
```
Legacy Account Conversion
=========================

Source: /path/entry.dat
Target: /path/entry.yaml
Mode:   standard

Loading legacy accounts...
✓ 5 accounts found

Converting accounts...
  5/5 accounts processed

✓ Conversion complete
✓ 5 accounts converted
✓ Encryption mode: standard
✓ YAML file: /path/entry.yaml
✓ Legacy backup: /path/entry.dat.bak

You can now use Lich with the new format.
```

**Expected exit code:** 0

**Verification:**
```bash
# Check YAML file created
ls -l /path/entry.yaml

# Check encryption mode
grep encryption_mode /path/entry.yaml
# Should show: encryption_mode: standard

# Check legacy backup created
ls -l /path/entry.dat.bak
```

---

### Test Case 3: Conversion - Enhanced Mode (Interactive)

**Command:**
```bash
ruby lich.rbw --convert-accounts --mode enhanced
```

**Expected interaction:**
```
Legacy Account Conversion
=========================

Source: /path/entry.dat
Target: /path/entry.yaml
Mode:   enhanced

Enter new master password: [input]
Confirm master password: [input]
✓ Master password accepted

Loading legacy accounts...
✓ 5 accounts found

Converting accounts...
  5/5 accounts processed

✓ Conversion complete
✓ 5 accounts converted
✓ Encryption mode: enhanced
✓ YAML file: /path/entry.yaml
✓ Legacy backup: /path/entry.dat.bak
✓ Master password stored in OS keychain

You can now use Lich with the new format.
```

**Expected exit code:** 0

---

### Test Case 4: Conversion - Enhanced Mode (Provided Password)

**Command:**
```bash
ruby lich.rbw --convert-accounts --mode enhanced --master-password MyPassword123
```

**Expected output:** (No password prompts)
```
Legacy Account Conversion
=========================

Source: /path/entry.dat
Target: /path/entry.yaml
Mode:   enhanced

Loading legacy accounts...
✓ 5 accounts found

Converting accounts...
  5/5 accounts processed

✓ Conversion complete
✓ 5 accounts converted
✓ Encryption mode: enhanced
✓ YAML file: /path/entry.yaml
✓ Legacy backup: /path/entry.dat.bak
✓ Master password stored in OS keychain

You can now use Lich with the new format.
```

**Expected exit code:** 0

---

### Test Case 5: Conversion - Plaintext Mode (With Warning)

**Command:**
```bash
ruby lich.rbw --convert-accounts --mode plaintext
```

**Expected interaction:**
```
Legacy Account Conversion
=========================

Source: /path/entry.dat
Target: /path/entry.yaml
Mode:   plaintext

⚠️ WARNING: Plaintext mode disables encryption
Passwords will be stored unencrypted and visible in the file.

Continue? (yes/no): yes

Loading legacy accounts...
✓ 5 accounts found

Converting accounts...
  5/5 accounts processed

✓ Conversion complete
✓ 5 accounts converted
✓ Encryption mode: plaintext
✓ YAML file: /path/entry.yaml
✓ Legacy backup: /path/entry.dat.bak

You can now use Lich with the new format.
```

**Expected exit code:** 0

---

### Test Case 6: Already Converted

**Setup:** `entry.yaml` already exists

**Command:**
```bash
ruby lich.rbw --convert-accounts --mode standard
```

**Expected output:**
```
info: Already converted (/path/entry.yaml exists)
```

**Expected exit code:** 0

---

### Test Case 7: Invalid Mode

**Command:**
```bash
ruby lich.rbw --convert-accounts --mode invalid
```

**Expected output:**
```
error: Invalid conversion mode: invalid
Valid modes: plaintext, standard, enhanced
```

**Expected exit code:** 3

---

### Test Case 8: Legacy File Not Found

**Setup:** No `entry.dat` file

**Command:**
```bash
ruby lich.rbw --convert-accounts --mode standard
```

**Expected output:**
```
error: Legacy file not found: /path/entry.dat
```

**Expected exit code:** 2

---

## Acceptance Criteria

### Detection
- [ ] Detects conversion state (entry.dat exists, entry.yaml doesn't)
- [ ] Reports state with clear guidance
- [ ] Suggests specific CLI command
- [ ] Blocks CLI operations until converted (with helpful message)
- [ ] Exit code 2 when conversion needed

### Conversion Execution
- [ ] `--convert-accounts --mode MODE` parameter works
- [ ] Short form `-ca --mode MODE` works
- [ ] Standard mode conversion works
- [ ] Enhanced mode conversion works (interactive)
- [ ] Enhanced mode conversion works (provided password)
- [ ] Plaintext mode conversion works (with warning)
- [ ] Progress indication (accounts processed)
- [ ] Legacy file backed up (entry.dat.bak)
- [ ] YAML file created with correct structure
- [ ] Encryption mode field correct
- [ ] Master password stored in keychain (Enhanced mode)
- [ ] Validation test created (Enhanced mode)

### Error Handling
- [ ] Invalid mode detected (exit code 3)
- [ ] Legacy file missing detected (exit code 2)
- [ ] Already converted detected (exit code 0, info message)
- [ ] Password mismatch detected (Enhanced mode)
- [ ] Password too short detected (< 8 chars, Enhanced mode)
- [ ] STDIN unavailable handled gracefully
- [ ] Keychain failure handled (Enhanced mode)
- [ ] Corrupted legacy file handled

### Code Quality
- [ ] SOLID + DRY principles followed
- [ ] Security-conscious (no password logging)
- [ ] Clear, helpful error messages
- [ ] Progress indication
- [ ] Follows existing CLI patterns
- [ ] YARD documentation on all public methods

### Testing
- [ ] Manual test: Detection works ✅
- [ ] Manual test: Standard conversion ✅
- [ ] Manual test: Enhanced conversion (interactive) ✅
- [ ] Manual test: Enhanced conversion (provided password) ✅
- [ ] Manual test: Plaintext conversion (warning) ✅
- [ ] Manual test: Already converted ✅
- [ ] Manual test: Invalid mode ✅
- [ ] Manual test: Legacy file missing ✅

### Git
- [ ] Branch: `feat/cli-conversion-support`
- [ ] Conventional commit: `feat(cli): add headless conversion support`
- [ ] Clean commit history

---

## Edge Cases

1. **Corrupted entry.dat** - Clear error message, exit gracefully
2. **Partial conversion (crash mid-way)** - No YAML created, entry.dat intact
3. **STDIN unavailable** - Clear error for password prompts
4. **Keychain unavailable (Enhanced)** - Error, no conversion
5. **Empty entry.dat** - Converts successfully (0 accounts)
6. **Legacy format variations** - Handle symbol vs string keys
7. **Missing password field in legacy** - Handle gracefully (skip account or use empty string)
8. **Permission denied writing YAML** - Clear error, no backup creation

---

## Integration with GUI

**GUI behavior should remain unchanged:**
- GUI automatically detects and shows conversion dialog
- GUI workflow independent of CLI
- Both CLI and GUI can convert (idempotent - checks if already converted)

**Coexistence:**
- CLI conversion creates same YAML structure as GUI
- GUI can read CLI-converted files
- CLI can read GUI-converted files
- No conflicts or incompatibilities

---

## Documentation Updates

**Add to CLI help/usage:**
```
Conversion:
  --convert-accounts --mode MODE [--master-password PASSWORD], -ca
      Convert legacy entry.dat to entry.yaml format
      Modes: plaintext, standard, enhanced

      Examples:
        ruby lich.rbw --convert-accounts --mode standard
        ruby lich.rbw --convert-accounts --mode enhanced --master-password MyPass123
```

---

## Success Criteria

**Definition of Done:**
1. ✅ Detection works - reports state and suggests command
2. ✅ Conversion parameter works - all modes
3. ✅ Standard mode conversion works
4. ✅ Enhanced mode conversion works (interactive + provided)
5. ✅ Plaintext mode conversion works (with warning)
6. ✅ Progress indication working
7. ✅ Legacy backup created
8. ✅ YAML structure correct
9. ✅ Keychain integration working (Enhanced)
10. ✅ All test cases passing
11. ✅ Error handling working
12. ✅ Commit pushed to branch

**Estimated completion:** 4-6 hours

---

**Status:** Ready for CLI Claude execution
**Dependencies:** None (builds on fix/cli-master-password-defects)
**Blocker:** None
