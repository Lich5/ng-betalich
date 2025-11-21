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
  if arg =~ /^--change-account-password$/ || arg =~ /^-cap$/
    # Usage: ruby lich.rbw --change-account-password ACCOUNT NEWPASSWORD
    #    or: ruby lich.rbw -cap ACCOUNT NEWPASSWORD
    require_relative 'lib/common/gui/yaml_state'
    require_relative 'lib/common/cli/password_manager'

    account = ARGV[ARGV.index(arg) + 1]
    new_password = ARGV[ARGV.index(arg) + 2]

    if account.nil? || new_password.nil?
      puts 'error: Missing required arguments'
      puts 'Usage: ruby lich.rbw --change-account-password ACCOUNT NEWPASSWORD'
      puts '   or: ruby lich.rbw -cap ACCOUNT NEWPASSWORD'
      exit 1
    end

    exit Lich::Common::CLI::PasswordManager.change_account_password(account, new_password)

  elsif arg =~ /^--add-account$/ || arg =~ /^-aa$/
    # Usage: ruby lich.rbw --add-account ACCOUNT PASSWORD [--frontend FRONTEND]
    #    or: ruby lich.rbw -aa ACCOUNT PASSWORD [--frontend FRONTEND]
    require_relative 'lib/common/gui/yaml_state'
    require_relative 'lib/common/gui/authentication'
    require_relative 'lib/common/cli/password_manager'

    account = ARGV[ARGV.index(arg) + 1]
    password = ARGV[ARGV.index(arg) + 2]

    if account.nil? || password.nil?
      puts 'error: Missing required arguments'
      puts 'Usage: ruby lich.rbw --add-account ACCOUNT PASSWORD [--frontend FRONTEND]'
      puts '   or: ruby lich.rbw -aa ACCOUNT PASSWORD [--frontend FRONTEND]'
      exit 1
    end

    # Parse optional frontend
    frontend = ARGV[ARGV.index('--frontend') + 1] if ARGV.include?('--frontend')

    exit Lich::Common::CLI::PasswordManager.add_account(account, password, frontend)

  elsif arg =~ /^--change-master-password$/ || arg =~ /^-cmp$/
    # Usage: ruby lich.rbw --change-master-password OLDPASSWORD
    #    or: ruby lich.rbw -cmp OLDPASSWORD
    require_relative 'lib/common/gui/yaml_state'
    require_relative 'lib/common/gui/master_password_manager'
    require_relative 'lib/common/cli/password_manager'

    old_password = ARGV[ARGV.index(arg) + 1]

    if old_password.nil?
      puts 'error: Missing required arguments'
      puts 'Usage: ruby lich.rbw --change-master-password OLDPASSWORD'
      puts '   or: ruby lich.rbw -cmp OLDPASSWORD'
      puts 'Note: New password will be prompted for confirmation'
      exit 1
    end

    exit Lich::Common::CLI::PasswordManager.change_master_password(old_password)
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
              Lich.log "error: CLI change password failed - account '#{account}' not found"
              return 2
            end

            Lich.log "info: Changing password for account '#{account}' (mode: #{encryption_mode})"

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
                Lich.log 'error: CLI change password failed - master password not in keychain'
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
              Lich.log "error: CLI change password failed - unknown encryption mode: #{encryption_mode}"
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
            Lich.log "info: Password changed successfully for account '#{account}'"
            0
          rescue StandardError => e
            # CRITICAL: Only log e.message, NEVER log password values
            puts "error: #{e.message}"
            Lich.log "error: CLI change password failed for '#{account}': #{e.message}"
            1
          end
        end

        # Adds new account to entry.yaml
        # Authenticates with game servers to fetch all characters
        # Mimics GUI "Add Account" behavior
        #
        # @param account [String] Account username
        # @param password [String] Account password
        # @param frontend [String, nil] Frontend (wizard, stormfront, avalon, or nil to prompt/use predominant)
        # @return [Integer] Exit code (0=success, 1=error, 2=auth failed)
        def self.add_account(account, password, frontend = nil)
          data_dir = Lich.datadir
          yaml_file = Lich::Common::GUI::YamlState.yaml_file_path(data_dir)

          begin
            # Check if account already exists
            if File.exist?(yaml_file)
              yaml_data = YAML.load_file(yaml_file)
              if yaml_data['accounts'] && yaml_data['accounts'][account]
                puts "error: Account '#{account}' already exists"
                puts "Use --change-account-password to update the password."
                Lich.log "error: CLI add account failed - account '#{account}' already exists"
                return 1
              end
            end

            Lich.log "info: Adding account '#{account}' via CLI"

            # Authenticate with game servers to fetch characters (like GUI does)
            puts "Authenticating with game servers..."
            Lich.log "info: Authenticating account '#{account}' with game servers"
            auth_data = Lich::Common::GUI::Authentication.authenticate(
              account: account,
              password: password,
              legacy: true
            )

            unless auth_data && auth_data.is_a?(Array) && !auth_data.empty?
              puts "error: Authentication failed or no characters found"
              Lich.log "error: CLI add account failed - game server authentication failed for '#{account}'"
              return 2
            end

            Lich.log "info: Authentication successful - found #{auth_data.length} character(s)"

            # Determine frontend
            selected_frontend = if frontend
              # Frontend provided via --frontend flag
              Lich.log "info: Using provided frontend: #{frontend}"
              frontend
            else
              # Check predominant frontend in YAML, or prompt
              predominant = determine_predominant_frontend(yaml_file)
              if predominant
                puts "Using predominant frontend: #{predominant}"
                Lich.log "info: Using predominant frontend: #{predominant}"
                predominant
              else
                # Prompt user
                prompt_for_frontend
              end
            end

            # Convert authentication data to character list
            character_list = auth_data.map do |char_data|
              {
                'char_name' => char_data[:char_name],
                'game_code' => char_data[:game_code],
                'game_name' => char_data[:game_name],
                'frontend' => selected_frontend || '',
                'is_favorite' => false
              }
            end

            # Save account + characters using AccountManager
            if Lich::Common::GUI::AccountManager.add_or_update_account(data_dir, account, password, character_list)
              puts "success: Account '#{account}' added with #{character_list.length} character(s)"
              Lich.log "info: Account '#{account}' added successfully with #{character_list.length} character(s)"
              if selected_frontend.nil? || selected_frontend.empty?
                puts "note: Frontend not set - use GUI to configure or rerun with --frontend"
                Lich.log "warning: No frontend set for account '#{account}'"
              end
              0
            else
              puts "error: Failed to save account"
              Lich.log "error: CLI add account failed - could not save account '#{account}'"
              1
            end
          rescue StandardError => e
            # CRITICAL: Only log e.message, NEVER log password values
            puts "error: #{e.message}"
            Lich.log "error: CLI add account failed for '#{account}': #{e.message}"
            1
          end
        end

        # Determines predominant frontend from existing YAML accounts
        # @param yaml_file [String] Path to entry.yaml
        # @return [String, nil] Predominant frontend or nil
        def self.determine_predominant_frontend(yaml_file)
          return nil unless File.exist?(yaml_file)

          yaml_data = YAML.load_file(yaml_file)
          return nil unless yaml_data['accounts']

          frontend_counts = Hash.new(0)
          yaml_data['accounts'].each do |_username, account_data|
            next unless account_data['characters']
            account_data['characters'].each do |char|
              fe = char['frontend']
              frontend_counts[fe] += 1 if fe && !fe.empty?
            end
          end

          return nil if frontend_counts.empty?
          frontend_counts.max_by { |_fe, count| count }&.first
        end

        # Prompts user for frontend selection
        # @return [String, nil] Selected frontend or nil (user skipped)
        def self.prompt_for_frontend
          puts "\nSelect frontend (or press Enter to skip):"
          puts "  1. wizard"
          puts "  2. stormfront"
          puts "  3. avalon"
          print "Choice (1-3 or Enter): "

          choice = $stdin.gets.strip
          return nil if choice.empty?

          case choice
          when '1' then 'wizard'
          when '2' then 'stormfront'
          when '3' then 'avalon'
          else
            puts "Invalid choice, skipping frontend selection"
            nil
          end
        end

        # Changes master password and re-encrypts all accounts
        # Only works in Enhanced encryption mode
        # Prompts for new password confirmation
        #
        # @param old_password [String] Current master password
        # @return [Integer] Exit code (0=success, 1=error, 3=wrong mode)
        def self.change_master_password(old_password)
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
              Lich.log "error: CLI change master password failed - wrong encryption mode: #{encryption_mode}"
              return 3
            end

            Lich.log "info: Starting CLI master password change"

            # Validate old password
            validation_test = yaml_data['master_password_test']
            unless Lich::Common::GUI::MasterPasswordManager.validate_master_password(old_password, validation_test)
              puts 'error: Current master password incorrect'
              Lich.log 'error: CLI change master password failed - incorrect current password'
              return 1
            end

            Lich.log "info: Current master password validated successfully"

            # Prompt for new password
            print "Enter new master password: "
            new_password = $stdin.gets.strip

            print "Confirm new master password: "
            confirm_password = $stdin.gets.strip

            unless new_password == confirm_password
              puts "error: Passwords do not match"
              Lich.log "error: CLI change master password failed - password confirmation mismatch"
              return 1
            end

            if new_password.length < 8
              puts "error: Password must be at least 8 characters"
              Lich.log "error: CLI change master password failed - password too short"
              return 1
            end

            account_count = yaml_data['accounts'].length
            Lich.log "info: Re-encrypting #{account_count} account(s) with new master password"

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
              Lich.log 'error: CLI change master password failed - keychain update failed'
              return 1
            end

            # Save YAML
            File.open(yaml_file, 'w', 0600) do |file|
              file.write(YAML.dump(yaml_data))
            end

            puts 'success: Master password changed'
            Lich.log 'info: Master password changed successfully via CLI'
            0
          rescue StandardError => e
            # CRITICAL: Only log e.message, NEVER log password values
            puts "error: #{e.message}"
            Lich.log "error: CLI change master password failed: #{e.message}"
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
# Long form
ruby lich.rbw --change-account-password DOUG MyNewPassword123
# Output: success: Password changed for account 'DOUG'
# Exit code: 0

# Short form
ruby lich.rbw -cap DOUG MyNewPassword123
# Output: success: Password changed for account 'DOUG'
# Exit code: 0
```

### Add New Account
```bash
# Long form
ruby lich.rbw --add-account NEWUSER SecurePass456 --frontend wizard
# Output: Authenticating with game servers...
# Output: success: Account 'NEWUSER' added with 3 character(s)
# Exit code: 0

# Short form
ruby lich.rbw -aa NEWUSER SecurePass456 --frontend wizard
# Output: Authenticating with game servers...
# Output: success: Account 'NEWUSER' added with 3 character(s)
# Exit code: 0

# Without frontend (will prompt or use predominant)
ruby lich.rbw -aa NEWUSER SecurePass456
# Output: Authenticating with game servers...
# Output: Using predominant frontend: stormfront
# Output: success: Account 'NEWUSER' added with 3 character(s)
# Exit code: 0
```

### Change Master Password
```bash
# Long form (prompts for new password)
ruby lich.rbw --change-master-password OldPassword123
# Prompts: Enter new master password:
# Prompts: Confirm new master password:
# Output: success: Master password changed
# Exit code: 0

# Short form (prompts for new password)
ruby lich.rbw -cmp OldPassword123
# Prompts: Enter new master password:
# Prompts: Confirm new master password:
# Output: success: Master password changed
# Exit code: 0
```

---

## Exit Codes

| Code | Meaning | Example |
|------|---------|---------|
| 0 | Success | Operation completed |
| 1 | General error | Invalid input, encryption failed, passwords don't match |
| 2 | Not found / Auth failed | Account not found, entry.yaml missing, game server authentication failed |
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
- [ ] Passwords not logged to stdout or debug logs
- [ ] **CRITICAL**: NEVER log password values, account passwords, or master passwords
- [ ] Only log `#{e.message}`, usernames, and operation status
- [ ] YAML file saved with 0600 permissions
- [ ] Master password retrieved from keychain (not prompted for change-account-password)
- [ ] Old password validated before re-encryption (change-master-password)
- [ ] New master password strength enforced (8+ characters minimum)

### Logging
- [ ] Use `Lich.log "prefix: message"` format for all debug logging
- [ ] Prefixes: `error:`, `warning:`, `info:` as appropriate
- [ ] Log CLI operation starts: `Lich.log "info: Adding account '#{account}' via CLI"`
- [ ] Log successful operations: `Lich.log "info: Password changed successfully for account '#{account}'"`
- [ ] Log errors with context: `Lich.log "error: CLI change password failed for '#{account}': #{e.message}"`
- [ ] Log authentication attempts: `Lich.log "info: Authenticating account '#{account}' with game servers"`
- [ ] **CRITICAL**: Only log error messages (`#{e.message}`), never password values

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
# Test change password (short option)
ruby lich.rbw -cap TESTACCOUNT NewPassword123
echo $?  # Should be 0

# Test add account (short option)
ruby lich.rbw -aa NEWACCOUNT Pass456 --frontend wizard
echo $?  # Should be 0 (after game server authentication)

# Test change master password (Enhanced mode only, prompts for new password)
ruby lich.rbw -cmp OldPass
# Enter new password when prompted
# Confirm new password when prompted
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
- --change-account-password|-cap ACCOUNT NEWPASSWORD
  Changes account password in entry.yaml (all modes)
- --add-account|-aa ACCOUNT PASSWORD [--frontend FRONTEND]
  Authenticates with game servers, creates account with all characters
  Uses predominant frontend from YAML or prompts user if not specified
- --change-master-password|-cmp OLDPASSWORD
  Re-encrypts all accounts with new master password (Enhanced mode)
  Prompts for new password with confirmation (8+ characters required)

All operations:
- Work headless (no GUI required)
- Support short options (-cap, -aa, -cmp)
- Respect current encryption_mode
- Use existing YamlState/PasswordCipher/Authentication methods
- Provide clear error messages and exit codes

Exit codes: 0=success, 1=error, 2=not found/auth failed, 3=wrong mode

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
