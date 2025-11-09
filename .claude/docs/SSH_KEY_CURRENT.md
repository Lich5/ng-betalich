# Work Unit: SSH Key Encryption Mode + CLI Support (PR #3)

**Created:** 2025-11-09
**Estimated Effort:** 8-12 hours
**Branch:** `feat/password-encryption-ssh-key`
**PR Title:** `feat(all): add SSH key encryption and CLI support`

---

## Starting Point

**Branch from:** `feat/password-encryption-enhanced` (PR #2 - completed)
**Source material:** BRD Password Encryption (ENC-4: SSH Key Mode), CLI requirements
**What exists in base:** Plaintext + Standard + Enhanced modes working
**What you're adding:** SSH Key mode (signature-based encryption) + CLI password encryption support
**What you're excluding:** Master password change UI, SSH key change UI (those are Fix PRs)

---

## Prerequisites

- [ ] PR #2 complete: `feat/password-encryption-enhanced` merged or ready
- [ ] Branch created: `feat/password-encryption-ssh-key` (you'll do this)
- [ ] Context read: `.claude/docs/BRD_Password_Encryption.md` (ENC-4 requirements)
- [ ] SSH key infrastructure understood (signature generation, key formats)

---

## Objective

Implement **SSH Key encryption mode** and **CLI support** for all encryption modes:

### SSH Key Mode Features
- Use SSH key signature as encryption key (deterministic, no password storage)
- SSH key file selection UI
- Support common key formats (RSA, Ed25519, ECDSA)
- Signature generation via `ssh-keygen`
- Cross-platform SSH key handling

### CLI Support Features
- Detect when running in CLI mode (non-GTK)
- Terminal-based password prompts
- Encryption mode selection via command-line args or prompts
- Support all 4 modes (Plaintext, Standard, Enhanced, SSH Key)

---

## Files to Create (New Implementation)

### SSH Key Mode Infrastructure

**1. `lib/common/gui/ssh_key_manager.rb`** (new file ~150 lines)
```ruby
# Manages SSH key selection, validation, and signature generation
module SSHKeyManager
  # Check if SSH key encryption is available
  def self.ssh_available?
    # Verify ssh-keygen command exists
  end

  # Prompt user to select SSH key file
  def self.select_key_file
    # GTK file chooser dialog
    # Default: ~/.ssh/id_rsa, ~/.ssh/id_ed25519
  end

  # Generate signature from SSH key
  def self.generate_signature(key_path, data)
    # Use ssh-keygen -Y sign
    # Or use Ruby SSH library
  end

  # Validate SSH key file
  def self.valid_key?(key_path)
    # Check file exists, readable, valid SSH key format
  end

  # Get key fingerprint (for display)
  def self.key_fingerprint(key_path)
    # Use ssh-keygen -lf
  end
end
```

**2. `spec/ssh_key_manager_spec.rb`** (new file ~100 lines)
- SSH availability detection
- Key file selection
- Signature generation
- Key validation
- Fingerprint extraction

---

### CLI Mode Support

**3. `lib/common/cli/password_prompt.rb`** (new file ~80 lines)
```ruby
# Terminal-based password prompts (non-GTK)
module CLI
  module PasswordPrompt
    # Prompt for password (with echo disabled)
    def self.prompt_password(label = "Password")
      # Use io/console for hidden input
    end

    # Prompt for encryption mode selection
    def self.prompt_mode_selection
      # Show menu: 1) Plaintext, 2) Standard, 3) Enhanced, 4) SSH Key
    end

    # Prompt for SSH key file path
    def self.prompt_ssh_key_file
      # Text input with default ~/.ssh/id_rsa
    end
  end
end
```

**4. `spec/cli/password_prompt_spec.rb`** (new file ~60 lines)
- Mock IO for terminal prompts
- Mode selection validation
- Password entry (mocked)

---

## Files to Modify (Add SSH Key Mode)

### 1. password_cipher.rb - Add `:ssh_key` Mode
**Edit `lib/common/gui/password_cipher.rb`:**

```ruby
def self.encrypt(password, mode, key = nil)
  case mode
  when :plaintext
    password
  when :standard
    # ... existing ...
  when :enhanced
    # ... existing ...
  when :ssh_key  # ← ADD THIS
    raise ArgumentError, 'SSH key mode requires a signature key' if key.nil?
    # Key is SSH signature bytes
    encrypt_with_key(password, key, 'lich5-password-encryption-ssh-key')
  else
    raise ArgumentError, "Unknown encryption mode: #{mode}"
  end
end
```

Update `decrypt` method similarly.

---

### 2. conversion_ui.rb - Add SSH Key Option
**Edit `lib/common/gui/conversion_ui.rb`:**

Add 4th radio button:
```ruby
ssh_key_radio = Gtk::RadioButton.new(label: "SSH Key Encryption (for developers)", member: plaintext_radio)

# Add SSH key file selection
ssh_key_file_entry = Gtk::Entry.new
ssh_key_browse_button = Gtk::Button.new(label: "Browse...")

# Connect browse button to SSH key file chooser
ssh_key_browse_button.signal_connect('clicked') do
  key_path = SSHKeyManager.select_key_file
  ssh_key_file_entry.text = key_path if key_path
end

# Disable if SSH not available
unless SSHKeyManager.ssh_available?
  ssh_key_radio.sensitive = false
  Lich.log "info: SSH key mode disabled - ssh-keygen not found"
end
```

Update mode selection logic to handle `:ssh_key` option and store selected key path.

---

### 3. yaml_state.rb - SSH Key Mode Support
**Edit `lib/common/gui/yaml_state.rb`:**

```ruby
def encrypt_password(game_code, char_name, password, mode, ssh_key_path = nil)
  case mode
  when :plaintext
    password
  when :standard
    # ... existing ...
  when :enhanced
    # ... existing ...
  when :ssh_key
    raise ArgumentError, 'SSH key path required' if ssh_key_path.nil?
    # Generate signature from key
    signature = SSHKeyManager.generate_signature(ssh_key_path, 'lich5-password-salt')
    PasswordCipher.encrypt(password, :ssh_key, signature)
  end
end
```

Store SSH key path in YAML metadata for decryption.

---

### 4. password_cipher_spec.rb - Add SSH Key Tests
**Edit `spec/password_cipher_spec.rb`:**

```ruby
describe 'ssh_key mode' do
  let(:ssh_signature) { 'mock_ssh_signature_bytes' }  # Mock signature

  it 'encrypts and decrypts with SSH key signature' do
    encrypted = PasswordCipher.encrypt('mypassword', :ssh_key, ssh_signature)
    expect(encrypted).not_to eq('mypassword')

    decrypted = PasswordCipher.decrypt(encrypted, :ssh_key, ssh_signature)
    expect(decrypted).to eq('mypassword')
  end

  it 'raises error if signature missing' do
    expect {
      PasswordCipher.encrypt('mypassword', :ssh_key, nil)
    }.to raise_error(ArgumentError, /SSH key mode requires/)
  end

  # ... more tests ...
end
```

---

### 5. Add CLI Detection and Routing
**Edit `lib/common/gui-login.rb` or main entry point:**

Detect CLI mode and route to CLI password handling:
```ruby
if CLI_MODE  # Define based on environment or args
  require_relative 'cli/password_prompt'
  # Use CLI::PasswordPrompt instead of GTK dialogs
else
  # Existing GTK UI flow
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
git checkout -b feat/password-encryption-ssh-key
```

### Step 2: Implement SSH Key Manager
Create `lib/common/gui/ssh_key_manager.rb`:

**Key methods to implement:**
1. `ssh_available?` - Check for `ssh-keygen` command
2. `select_key_file` - GTK file chooser for SSH keys
3. `generate_signature(key_path, data)` - Generate deterministic signature
4. `valid_key?(key_path)` - Validate SSH key file
5. `key_fingerprint(key_path)` - Get key fingerprint for display

**Signature Generation Approach:**
```ruby
def self.generate_signature(key_path, data)
  # Option 1: Use ssh-keygen -Y sign (SSH 8.2+)
  # Option 2: Use net-ssh gem to load key and sign
  # Option 3: Use OpenSSL to load key and generate signature

  # Recommended: ssh-keygen for consistency
  # Write data to temp file, sign it, read signature
end
```

### Step 3: Implement CLI Password Prompts
Create `lib/common/cli/password_prompt.rb`:

```ruby
require 'io/console'

module CLI
  module PasswordPrompt
    def self.prompt_password(label = "Password")
      print "#{label}: "
      password = STDIN.noecho(&:gets).chomp
      puts  # Newline after hidden input
      password
    end

    def self.prompt_mode_selection
      puts "Select encryption mode:"
      puts "1) Plaintext (no encryption)"
      puts "2) Standard Encryption"
      puts "3) Enhanced Encryption (requires keychain)"
      puts "4) SSH Key Encryption"
      print "Choice [2]: "

      choice = gets.chomp
      choice = '2' if choice.empty?

      case choice
      when '1' then :plaintext
      when '2' then :standard
      when '3' then :enhanced
      when '4' then :ssh_key
      else
        puts "Invalid choice, using Standard"
        :standard
      end
    end

    def self.prompt_ssh_key_file
      default = File.expand_path('~/.ssh/id_rsa')
      print "SSH key file [#{default}]: "
      path = gets.chomp
      path.empty? ? default : path
    end
  end
end
```

### Step 4: Add SSH Key Mode to PasswordCipher
Edit `lib/common/gui/password_cipher.rb` to add `:ssh_key` case (see "Files to Modify" above)

### Step 5: Update Conversion UI
Edit `lib/common/gui/conversion_ui.rb` to add SSH Key radio button and file chooser

### Step 6: Update yaml_state.rb
Add SSH Key mode handling to `encrypt_password` and `decrypt_password`

### Step 7: Write Tests
Create comprehensive tests:
- `spec/ssh_key_manager_spec.rb`
- `spec/cli/password_prompt_spec.rb`
- Update `spec/password_cipher_spec.rb` with SSH Key tests

### Step 8: Run Tests
```bash
bundle exec rspec
# Expected: All tests pass (400+ examples now)
```

### Step 9: Run RuboCop
```bash
bundle exec rubocop lib/common/gui/ssh_key_manager.rb
bundle exec rubocop lib/common/cli/password_prompt.rb
# Expected: 0 offenses
```

### Step 10: Manual Testing (if possible)
```bash
# Test SSH key signature generation:
ruby -r ./lib/common/gui/ssh_key_manager.rb -e "puts SSHKeyManager.generate_signature('~/.ssh/id_rsa', 'test')"

# Test CLI prompts:
ruby -r ./lib/common/cli/password_prompt.rb -e "puts CLI::PasswordPrompt.prompt_mode_selection"
```

### Step 11: Commit
```bash
git add .
git commit -m "$(cat <<'EOF'
feat(all): add SSH key encryption and CLI support

Adds SSH key-based encryption and CLI mode support:
- SSH Key mode: Uses SSH key signature as encryption key
- SSH key selection UI with file chooser
- Key validation and fingerprint display
- Signature generation via ssh-keygen
- CLI password prompts (non-GTK mode)
- CLI encryption mode selection
- Support for all 4 modes in CLI
- Cross-platform SSH key handling

Completes all 4 encryption modes from BRD.

Related: BRD Password Encryption Phase 4 (SSH Key Mode)
EOF
)"
```

### Step 12: Push
```bash
git push -u origin feat/password-encryption-ssh-key
```

---

## Acceptance Criteria

### SSH Key Mode Implementation
- [ ] SSHKeyManager module complete
- [ ] `ssh_available?` detects ssh-keygen command
- [ ] `select_key_file` shows GTK file chooser
- [ ] `generate_signature` produces deterministic signature
- [ ] `valid_key?` validates SSH key files
- [ ] `key_fingerprint` extracts fingerprint
- [ ] PasswordCipher supports `:ssh_key` mode
- [ ] Conversion UI shows SSH Key option
- [ ] SSH Key option disabled if ssh-keygen unavailable

### CLI Support Implementation
- [ ] CLI::PasswordPrompt module complete
- [ ] `prompt_password` hides input (io/console)
- [ ] `prompt_mode_selection` shows menu, validates choice
- [ ] `prompt_ssh_key_file` accepts path input
- [ ] CLI mode detection works
- [ ] All 4 modes accessible from CLI

### Functionality
- [ ] SSH Key encryption works end-to-end
- [ ] SSH signature is deterministic (same key = same ciphertext for same password)
- [ ] SSH key file stored in YAML metadata
- [ ] Decryption retrieves correct key file
- [ ] CLI mode can encrypt/decrypt all modes
- [ ] GTK mode still works (no regression)

### Tests
- [ ] All prior tests still pass (380+ examples)
- [ ] SSH Key mode tests comprehensive
- [ ] CLI prompt tests (mocked IO)
- [ ] Cross-platform SSH key tests
- [ ] Signature generation tests

### Platform Compatibility
- [ ] macOS: SSH key mode works
- [ ] Linux: SSH key mode works
- [ ] Windows: SSH key mode works (if ssh-keygen available)
- [ ] CLI mode works on all platforms

### Code Standards
- [ ] SOLID + DRY principles
- [ ] YARD documentation complete
- [ ] Security best practices (key file permissions checked)
- [ ] Error handling comprehensive
- [ ] RuboCop clean: 0 offenses

### Git Hygiene
- [ ] Conventional commit: `feat(all): add SSH key encryption and CLI support`
- [ ] Branch pushed: `git push -u origin feat/password-encryption-ssh-key`
- [ ] Clean diff (only adds SSH Key + CLI features)
- [ ] No merge conflicts with PR #2 base

### Verification Commands
```bash
# All should pass:
bundle exec rspec                                                    # Expected: All pass (400+)
bundle exec rubocop                                                  # Expected: 0 offenses
ls lib/common/gui/ssh_key_manager.rb                                # Expected: exists
ls lib/common/cli/password_prompt.rb                                # Expected: exists
grep -n ":ssh_key" lib/common/gui/password_cipher.rb | wc -l       # Expected: 2+ (encrypt, decrypt)
git log --oneline -1                                                 # Expected: feat(all): add SSH...
```

---

## Edge Cases to Handle

### 1. SSH Key File Not Found
- Validate path before signature generation
- Show error dialog or prompt for different key

### 2. SSH Key Encrypted with Passphrase
- ssh-keygen will prompt for passphrase (acceptable)
- Document that user must enter passphrase on first use

### 3. Unsupported SSH Key Format
- Validate key type (RSA, Ed25519, ECDSA)
- Show error for unsupported types

### 4. ssh-keygen Not Available
- Disable SSH Key option gracefully
- Log warning to user

### 5. CLI Mode Without TTY
- Detect non-interactive shell
- Fall back to config file or error

---

## What Comes Next

**After this PR is complete:**
- ✅ PR #3 ready for beta testing (all 4 modes + CLI support)
- ⏭️ **Next work units:** Fix PRs (Master Password change, SSH Key change)
- 🚫 **Do not start Fix PRs** until PR #3 tests pass

**Dependencies:**
- Fix #1 (Master Password change) branches from PR #2
- Fix #2 (SSH Key change) branches from PR #3
- Both Fix PRs can be developed in parallel

---

## Troubleshooting

### "SSH signature generation fails"
- Verify ssh-keygen version (need 8.2+ for -Y sign)
- Try alternative: net-ssh gem or OpenSSL
- Check key file permissions (600 required)

### "CLI prompts not hiding password"
- Ensure io/console gem available
- Check TTY detection
- Test in actual terminal (not IDE console)

### "Tests failing for SSH mode"
- Mock SSH signature in tests (don't require real keys)
- Skip tests if ssh-keygen unavailable
- Use test fixtures for key files

### "Conversion UI too crowded"
- Consider tabbed interface or wizard
- Group modes by complexity
- Add tooltips for each option

---

## Context References

**Read before starting:**
- `.claude/docs/CLI_PRIMER.md` - Ground rules
- `.claude/docs/BRD_Password_Encryption.md` - Requirements (ENC-4: SSH Key)
- `.claude/docs/ADR_SESSION_011C_PR_DECOMPOSITION.md` - PR structure

**SSH Key Resources:**
- `man ssh-keygen` - Signature generation options
- Ruby net-ssh gem documentation
- OpenSSL Ruby bindings

---

**END OF WORK UNIT**

When complete, archive this file to `.claude/docs/archive/SSH_KEY_COMPLETED.md` and await next work unit.
