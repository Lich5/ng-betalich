# Work Unit: CLI Password Manager

**Created:** 2025-11-16
**Estimated Effort:** 2-3 hours
**Branch:** `feat/cli-password-manager`
**Priority:** CRITICAL (next day delivery)

---

## Context

**Base Branch:** main (standalone feature)
**Status:** Phase 2 - Enhanced Security features

**What exists:**
- ✅ YamlState with all encryption modes (plaintext, standard, enhanced)
- ✅ PasswordCipher with encrypt/decrypt methods
- ✅ MasterPasswordManager with keychain operations
- ✅ Account manager CRUD operations

**What's missing:**
- ❌ CLI interface for password operations
- ❌ Headless account password changes
- ❌ Headless master password changes
- ❌ Headless account creation

---

## Objective

Add CLI options to lich.rbw for headless password management operations:
- Change account passwords (all encryption modes)
- Add new accounts with all character data
- Change master password (Enhanced mode)

**Use Cases:**
- Automation scripts updating passwords
- Batch account creation
- Server deployments without GUI
- Emergency password changes

---

## Branch Setup

```bash
git fetch origin main
git checkout main
git pull origin main
git checkout -b feat/cli-password-manager
```

---

## Implementation

### File 1: lich.rbw (MODIFY - ARGV loop)

**Location:** Root `lich.rbw`

**Add to ARGV loop (after existing options, before main execution):**

```ruby
# Password management options (headless CLI)
for arg in ARGV
  if arg =~ /^--change-account-password$/
    # Usage: ruby lich.rbw --change-account-password ACCOUNT NEWPASSWORD
    require_relative 'lib/common/gui/yaml_state'
    require_relative 'lib/common/cli/password_manager'

    account = ARGV[ARGV.index(arg) + 1]
    new_password = ARGV[ARGV.index(arg) + 2]

    if account.nil? || new_password.nil?
      puts 'error: Missing required arguments'
      puts 'Usage: ruby lich.rbw --change-account-password ACCOUNT NEWPASSWORD'
      exit 1
    end

    exit Lich::Common::CLI::PasswordManager.change_account_password(account, new_password)

  elsif arg =~ /^--add-account$/
    # Usage: ruby lich.rbw --add-account ACCOUNT PASSWORD --char-name NAME --game-code CODE [--frontend FRONTEND]
    require_relative 'lib/common/gui/yaml_state'
    require_relative 'lib/common/cli/password_manager'

    account = ARGV[ARGV.index(arg) + 1]
    password = ARGV[ARGV.index(arg) + 2]

    if account.nil? || password.nil?
      puts 'error: Missing required arguments'
      puts 'Usage: ruby lich.rbw --add-account ACCOUNT PASSWORD --char-name NAME --game-code CODE [--frontend FRONTEND]'
      exit 1
    end

    # Parse optional character data
    char_name = ARGV[ARGV.index('--char-name') + 1] if ARGV.include?('--char-name')
    game_code = ARGV[ARGV.index('--game-code') + 1] if ARGV.include?('--game-code')
    frontend = ARGV[ARGV.index('--frontend') + 1] if ARGV.include?('--frontend')

    exit Lich::Common::CLI::PasswordManager.add_account(account, password, char_name, game_code, frontend)

  elsif arg =~ /^--change-master-password$/
    # Usage: ruby lich.rbw --change-master-password OLDPASSWORD NEWPASSWORD
    require_relative 'lib/common/gui/yaml_state'
    require_relative 'lib/common/gui/master_password_manager'
    require_relative 'lib/common/cli/password_manager'

    old_password = ARGV[ARGV.index(arg) + 1]
    new_password = ARGV[ARGV.index(arg) + 2]

    if old_password.nil? || new_password.nil?
      puts 'error: Missing required arguments'
      puts 'Usage: ruby lich.rbw --change-master-password OLDPASSWORD NEWPASSWORD'
      exit 1
    end

    exit Lich::Common::CLI::PasswordManager.change_master_password(old_password, new_password)
  end
end
```

---

### File 2: password_manager.rb (NEW - ~150 lines)

**Location:** `lib/common/cli/password_manager.rb`

**Purpose:** Headless password operations using existing YamlState/PasswordCipher methods

**Structure:**
```ruby
# frozen_string_literal: true

require 'yaml'
require_relative '../gui/yaml_state'
require_relative '../gui/password_cipher'
require_relative '../gui/master_password_manager'

module Lich
  module Common
    module CLI
      # Headless password management for CLI operations
      # Thin wrapper around YamlState and PasswordCipher
      module PasswordManager
        # Changes account password in entry.yaml
        # Handles all encryption modes (plaintext, standard, enhanced)
        #
        # @param account [String] Account username
        # @param new_password [String] New plaintext password
        # @return [Integer] Exit code (0=success, 1=error, 2=not found)
        def self.change_account_password(account, new_password)
          data_dir = Lich.datadir
          yaml_file = Lich::Common::GUI::YamlState.yaml_file_path(data_dir)

          unless File.exist?(yaml_file)
            puts "error: entry.yaml not found at #{yaml_file}"
            return 2
          end

          begin
            yaml_data = YAML.load_file(yaml_file)
            encryption_mode = (yaml_data['encryption_mode'] || 'plaintext').to_sym

            # Find account
            unless yaml_data['accounts'] && yaml_data['accounts'][account]
              puts "error: Account '#{account}' not found"
              return 2
            end

            # Encrypt password based on mode
            encrypted = case encryption_mode
            when :plaintext
              new_password
            when :standard
              Lich::Common::GUI::PasswordCipher.encrypt(
                new_password,
                account,
                mode: :standard
              )
            when :enhanced
              master_password = Lich::Common::GUI::MasterPasswordManager.retrieve_master_password
              if master_password.nil?
                puts 'error: Enhanced mode requires master password in keychain'
                return 1
              end
              Lich::Common::GUI::PasswordCipher.encrypt(
                new_password,
                account,
                mode: :enhanced,
                master_password: master_password
              )
            else
              puts "error: Unknown encryption mode: #{encryption_mode}"
              return 1
            end

            # Update account password
            if encryption_mode == :plaintext
              yaml_data['accounts'][account]['password'] = encrypted
            else
              yaml_data['accounts'][account]['password_encrypted'] = encrypted
            end

            # Save YAML
            File.open(yaml_file, 'w', 0600) do |file|
              file.write(YAML.dump(yaml_data))
            end

            puts "success: Password changed for account '#{account}'"
            0
          rescue StandardError => e
            puts "error: #{e.message}"
            1
          end
        end

        # Adds new account to entry.yaml
        # Creates account with character data
        #
        # @param account [String] Account username
        # @param password [String] Account password
        # @param char_name [String, nil] Character name
        # @param game_code [String, nil] Game code (GS3, DR, etc)
        # @param frontend [String, nil] Frontend (wizard, stormfront, etc)
        # @return [Integer] Exit code (0=success, 1=error)
        def self.add_account(account, password, char_name = nil, game_code = nil, frontend = nil)
          data_dir = Lich.datadir
          yaml_file = Lich::Common::GUI::YamlState.yaml_file_path(data_dir)

          # Create empty YAML if doesn't exist
          unless File.exist?(yaml_file)
            yaml_data = {
              'encryption_mode' => 'plaintext',
              'accounts' => {}
            }
          else
            yaml_data = YAML.load_file(yaml_file)
          end

          begin
            encryption_mode = (yaml_data['encryption_mode'] || 'plaintext').to_sym

            # Check if account already exists
            if yaml_data['accounts'] && yaml_data['accounts'][account]
              puts "error: Account '#{account}' already exists"
              return 1
            end

            # Encrypt password based on mode
            encrypted = case encryption_mode
            when :plaintext
              password
            when :standard
              Lich::Common::GUI::PasswordCipher.encrypt(
                password,
                account,
                mode: :standard
              )
            when :enhanced
              master_password = Lich::Common::GUI::MasterPasswordManager.retrieve_master_password
              if master_password.nil?
                puts 'error: Enhanced mode requires master password in keychain'
                return 1
              end
              Lich::Common::GUI::PasswordCipher.encrypt(
                password,
                account,
                mode: :enhanced,
                master_password: master_password
              )
            else
              puts "error: Unknown encryption mode: #{encryption_mode}"
              return 1
            end

            # Build account data
            yaml_data['accounts'] ||= {}
            account_data = {}

            if encryption_mode == :plaintext
              account_data['password'] = encrypted
            else
              account_data['password_encrypted'] = encrypted
            end

            # Add character if provided
            if char_name && game_code
              account_data['characters'] = [{
                'char_name' => char_name,
                'game_code' => game_code,
                'game_name' => game_name_from_code(game_code),
                'frontend' => frontend || 'wizard',
                'is_favorite' => false
              }]
            else
              account_data['characters'] = []
            end

            yaml_data['accounts'][account] = account_data

            # Save YAML
            File.open(yaml_file, 'w', 0600) do |file|
              file.write(YAML.dump(yaml_data))
            end

            puts "success: Account '#{account}' created"
            0
          rescue StandardError => e
            puts "error: #{e.message}"
            1
          end
        end

        # Changes master password and re-encrypts all accounts
        # Only works in Enhanced encryption mode
        #
        # @param old_password [String] Current master password
        # @param new_password [String] New master password
        # @return [Integer] Exit code (0=success, 1=error, 3=wrong mode)
        def self.change_master_password(old_password, new_password)
          data_dir = Lich.datadir
          yaml_file = Lich::Common::GUI::YamlState.yaml_file_path(data_dir)

          unless File.exist?(yaml_file)
            puts "error: entry.yaml not found at #{yaml_file}"
            return 2
          end

          begin
            yaml_data = YAML.load_file(yaml_file)
            encryption_mode = (yaml_data['encryption_mode'] || 'plaintext').to_sym

            unless encryption_mode == :enhanced
              puts "error: Master password only used in Enhanced encryption mode"
              puts "Current mode: #{encryption_mode}"
              return 3
            end

            # Validate old password
            validation_test = yaml_data['master_password_test']
            unless Lich::Common::GUI::MasterPasswordManager.validate_master_password(old_password, validation_test)
              puts 'error: Current master password incorrect'
              return 1
            end

            # Re-encrypt all accounts
            yaml_data['accounts'].each do |username, account_data|
              # Decrypt with old password
              plaintext = Lich::Common::GUI::PasswordCipher.decrypt(
                account_data['password_encrypted'],
                username,
                mode: :enhanced,
                master_password: old_password
              )

              # Encrypt with new password
              new_encrypted = Lich::Common::GUI::PasswordCipher.encrypt(
                plaintext,
                username,
                mode: :enhanced,
                master_password: new_password
              )

              account_data['password_encrypted'] = new_encrypted
            end

            # Update validation test
            new_validation = Lich::Common::GUI::MasterPasswordManager.create_validation_test(new_password)
            yaml_data['master_password_test'] = new_validation

            # Update keychain
            unless Lich::Common::GUI::MasterPasswordManager.store_master_password(new_password)
              puts 'error: Failed to update keychain'
              return 1
            end

            # Save YAML
            File.open(yaml_file, 'w', 0600) do |file|
              file.write(YAML.dump(yaml_data))
            end

            puts 'success: Master password changed'
            0
          rescue StandardError => e
            puts "error: #{e.message}"
            1
          end
        end

        private

        def self.game_name_from_code(code)
          case code.upcase
          when 'GS3' then 'GemStone IV'
          when 'DR' then 'DragonRealms'
          else code
          end
        end
      end
    end
  end
end
```

---

## Usage Examples

### Change Account Password
```bash
ruby lich.rbw --change-account-password DOUG MyNewPassword123
# Output: success: Password changed for account 'DOUG'
# Exit code: 0
```

### Add New Account
```bash
ruby lich.rbw --add-account NEWUSER SecurePass456 \
  --char-name Dionket \
  --game-code GS3 \
  --frontend wizard
# Output: success: Account 'NEWUSER' created
# Exit code: 0
```

### Change Master Password
```bash
ruby lich.rbw --change-master-password OldPassword123 NewPassword456
# Output: success: Master password changed
# Exit code: 0
```

---

## Exit Codes

| Code | Meaning | Example |
|------|---------|---------|
| 0 | Success | Operation completed |
| 1 | General error | Invalid input, encryption failed |
| 2 | Not found | Account not found, entry.yaml missing |
| 3 | Wrong mode | Master password change on non-Enhanced mode |

---

## Acceptance Criteria

### Functionality
- [ ] `--change-account-password` works for all encryption modes
- [ ] `--add-account` creates account with encryption
- [ ] `--change-master-password` re-encrypts all accounts
- [ ] All operations respect current encryption_mode
- [ ] Enhanced mode pulls master password from keychain
- [ ] Operations work headless (no GUI required)
- [ ] Exit codes match specification

### Error Handling
- [ ] Missing arguments → clear usage message + exit 1
- [ ] Account not found → clear error + exit 2
- [ ] Wrong encryption mode → clear error + exit 3
- [ ] Master password validation fails → clear error + exit 1
- [ ] Keychain unavailable (Enhanced) → clear error + exit 1

### Security
- [ ] Passwords not logged to stdout
- [ ] YAML file saved with 0600 permissions
- [ ] Master password retrieved from keychain (not prompted)
- [ ] Old password validated before re-encryption

### Code Quality
- [ ] Follows existing ARGV parsing pattern
- [ ] Uses existing YamlState/PasswordCipher methods (thin wrapper)
- [ ] YARD documentation on all public methods
- [ ] RuboCop clean: 0 offenses
- [ ] No duplication with GUI code

### Git
- [ ] Conventional commit: `feat(all): add CLI password management operations`
- [ ] Branch: `feat/cli-password-manager`
- [ ] Clean commit history

---

## Verification Commands

```bash
# Test change password
ruby lich.rbw --change-account-password TESTACCOUNT NewPassword123
echo $?  # Should be 0

# Test add account
ruby lich.rbw --add-account NEWACCOUNT Pass456 --char-name TestChar --game-code GS3
echo $?  # Should be 0

# Test change master password (Enhanced mode only)
ruby lich.rbw --change-master-password OldPass NewPass
echo $?  # Should be 0 (or 3 if not Enhanced mode)

# RuboCop
bundle exec rubocop lib/common/cli/password_manager.rb

# Verify YAML updated
cat ~/.lich/entry.yaml
```

---

## Edge Cases

### 1. Entry.yaml Doesn't Exist
- `--change-account-password`: Exit 2, error message
- `--add-account`: Create new entry.yaml with plaintext mode
- `--change-master-password`: Exit 2, error message

### 2. Enhanced Mode Without Keychain
- All operations check keychain first
- Exit 1 with clear error if master password not in keychain

### 3. Account Already Exists (add-account)
- Exit 1 with error: "Account already exists"
- Don't overwrite existing account

### 4. Wrong Encryption Mode (change-master-password)
- Exit 3 with error: "Master password only used in Enhanced mode"
- Show current mode

### 5. Missing Optional Arguments (add-account)
- Character name/game code optional
- Create account with empty characters array if not provided

---

## Testing Notes

**Manual Testing:**
1. Create test entry.yaml in plaintext mode
2. Test change-account-password with plaintext account
3. Convert to Enhanced mode via GUI
4. Test change-account-password with Enhanced account
5. Test change-master-password
6. Test add-account with all arguments
7. Test add-account with minimal arguments
8. Verify all exit codes

**Security Testing:**
- Verify passwords not echoed to terminal
- Verify YAML file permissions (0600)
- Verify master password retrieved from keychain (not prompted)

---

## Commit Message Template

```
feat(all): add CLI password management operations

Implements headless password operations for automation:
- --change-account-password ACCOUNT NEWPASSWORD
  Changes account password in entry.yaml (all modes)
- --add-account ACCOUNT PASSWORD [--char-name ...] [--game-code ...]
  Creates new account with optional character data
- --change-master-password OLDPASSWORD NEWPASSWORD
  Re-encrypts all accounts with new master password (Enhanced mode)

All operations:
- Work headless (no GUI required)
- Respect current encryption_mode
- Use existing YamlState/PasswordCipher methods
- Provide clear error messages and exit codes

Exit codes: 0=success, 1=error, 2=not found, 3=wrong mode

Related: Password Encryption Phase 2
```

---

## Rollback Plan

```bash
git reset --hard origin/main
git branch -D feat/cli-password-manager
```

---

## Dependencies

**Required files (must exist):**
- ✅ `lib/common/gui/yaml_state.rb`
- ✅ `lib/common/gui/password_cipher.rb`
- ✅ `lib/common/gui/master_password_manager.rb`

**Methods required:**
- ✅ `YamlState.yaml_file_path`
- ✅ `PasswordCipher.encrypt`
- ✅ `PasswordCipher.decrypt`
- ✅ `MasterPasswordManager.retrieve_master_password`
- ✅ `MasterPasswordManager.validate_master_password`
- ✅ `MasterPasswordManager.create_validation_test`
- ✅ `MasterPasswordManager.store_master_password`

---

## Next Steps After Completion

1. Push branch: `git push -u origin feat/cli-password-manager`
2. Manual testing on all platforms (macOS, Linux, Windows)
3. Test with all encryption modes (plaintext, standard, enhanced)
4. Create PR for review
5. Update documentation with CLI usage examples

---

**Status:** Ready for CLI Claude execution
**Estimated Completion:** 2-3 hours
**Blocker:** None (all dependencies exist)
