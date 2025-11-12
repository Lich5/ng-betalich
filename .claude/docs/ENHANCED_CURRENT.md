# Work Unit: Enhanced Encryption Mode with Cross-Platform Keychain (PR-Enhanced)

**Created:** 2025-11-09
**Estimated Effort:** 6-8 hours
**Branch:** `feat/password-encryption-enhanced`
**PR Title:** `feat(all): add enhanced encryption with master password`

---

## Starting Point

**Branch from:** `feat/password-encryption-standard` (PR-Standard - completed)
**Source material:** PR #38 branch `feat/password_encrypts` + Windows keychain implementation
**What exists in base:** Plaintext + Standard encryption modes working
**What you're adding:** Enhanced mode with OS keychain support (macOS/Linux/Windows 10+)
**What you're excluding:** SSH Key mode, CLI support (those go in PR-SSH)

---

## Prerequisites

- [ ] PR-Standard complete: `feat/password-encryption-standard` merged or ready
- [ ] Branch created: `feat/password-encryption-enhanced` (you'll do this)
- [ ] Context read: `.claude/docs/AUDIT_PR38_CORRECTED.md` (Windows gap analysis)
- [ ] Context read: `.claude/work-units/CURRENT.md` (Windows keychain work unit)

---

## Objective

Add **Enhanced encryption mode** to the existing Standard mode foundation:
- Add `:enhanced` mode to PasswordCipher
- Implement cross-platform OS keychain support (macOS/Linux/Windows 10+)
- Add master password prompts and validation
- Update conversion dialog to show Enhanced option
- Platform-aware tests (Windows 10+ detection)
- All 380+ tests pass

---

## Files to Add from PR #38

### Category 1: New Files (Enhanced Mode Infrastructure)

**Copy these files from PR #38 and update terminology:**

```bash
# From PR #38 branch feat/password_encrypts:
lib/common/gui/master_password_manager.rb  → Update `:master_password` to `:enhanced`
lib/common/gui/master_password_prompt.rb   → Update terminology
lib/common/gui/master_password_prompt_ui.rb → Update UI strings
spec/master_password_manager_spec.rb       → Update test descriptions
spec/master_password_prompt_spec.rb        → Update test descriptions
```

**Critical:** After copying, perform global terminology update:
- `:master_password` → `:enhanced`
- Comments: "master password" → "enhanced encryption"
- UI labels: "Master Password" → "Enhanced Encryption" (except password entry prompts)

---

### Category 2: Files to Modify (Add Enhanced Mode)

| File | Current State (PR-Standard) | What to Add | Source |
|------|-----------------------|-------------|--------|
| `lib/common/gui/password_cipher.rb` | Has `:plaintext`, `:standard` | Add `:enhanced` mode case | PR #38 lines 132-135 |
| `lib/common/gui/conversion_ui.rb` | Shows 2 options | Add Enhanced radio button | PR #38 lines 103-106 |
| `lib/common/gui/yaml_state.rb` | Standard encryption | Add Enhanced mode support | PR #38 lines 115-116 |
| `spec/password_cipher_spec.rb` | Standard tests only | Add Enhanced mode tests | PR #38 lines 40-66 |

---

## Windows Keychain Implementation (CRITICAL)

**This PR must include complete Windows support** - not stubs.

### Current State in PR #38
PR #38 has **stub implementations** for Windows:
```ruby
# lib/common/gui/master_password_manager.rb:175-180 (PR #38)
def self.store_windows_keychain(_password)
  Lich.log "warning: Master password storage not fully implemented for Windows"
  false  # ← STUB
end

def self.retrieve_windows_keychain
  nil  # ← STUB
end
```

### What You Must Implement

**Use PowerShell PasswordVault API** (Windows 10+ only)

#### 1. Windows Version Detection
```ruby
private_class_method def self.windows_10_or_later?
  return false unless OS.windows?

  # Get Windows version via PowerShell
  version_cmd = '[System.Environment]::OSVersion.Version.Major'
  major = `powershell -NoProfile -Command "#{version_cmd}"`.strip.to_i

  # Windows 10 = version 10, Windows 11 = version 10 (yes, really)
  major >= 10
rescue
  false
end
```

#### 2. Update `windows_keychain_available?`
Replace line 172 stub:
```ruby
private_class_method def self.windows_keychain_available?
  return false unless windows_10_or_later?

  # Test if PasswordVault is accessible
  test_script = <<~POWERSHELL
    try {
      $vault = New-Object Windows.Security.Credentials.PasswordVault
      Write-Output "available"
    } catch {
      Write-Output "unavailable"
    }
  POWERSHELL

  result = `powershell -NoProfile -Command "#{test_script}"`.strip
  result == "available"
rescue
  false
end
```

#### 3. Implement `store_windows_keychain`
Replace lines 175-180:
```ruby
private_class_method def self.store_windows_keychain(password)
  ps_script = <<~POWERSHELL
    $vault = New-Object Windows.Security.Credentials.PasswordVault
    try {
      $existing = $vault.Retrieve('#{KEYCHAIN_SERVICE}', 'lich5')
      $vault.Remove($existing)
    } catch {}

    $password = [Console]::In.ReadLine()
    $cred = New-Object Windows.Security.Credentials.PasswordCredential('#{KEYCHAIN_SERVICE}', 'lich5', $password)
    $vault.Add($cred)
    Write-Output "success"
  POWERSHELL

  result = IO.popen(['powershell', '-NoProfile', '-Command', ps_script], 'r+') do |io|
    io.puts password
    io.close_write
    io.read.strip
  end

  result == "success"
rescue StandardError => e
  Lich.log "error: Failed to store Windows keychain: #{e.message}"
  false
end
```

#### 4. Implement `retrieve_windows_keychain`
Replace lines 182-184:
```ruby
private_class_method def self.retrieve_windows_keychain
  ps_script = <<~POWERSHELL
    try {
      $vault = New-Object Windows.Security.Credentials.PasswordVault
      $cred = $vault.Retrieve('#{KEYCHAIN_SERVICE}', 'lich5')
      $cred.RetrievePassword()
      Write-Output $cred.Password
    } catch {
      Write-Output ""
    }
  POWERSHELL

  output = `powershell -NoProfile -Command "#{ps_script}"`.strip
  output.empty? ? nil : output
rescue
  nil
end
```

**Reference:** See `.claude/work-units/CURRENT.md` for full Windows keychain work unit details.

---

## Implementation Steps

### Step 1: Create Branch from PR-Standard
```bash
cd /home/user/ng-betalich
git fetch origin
git checkout feat/password-encryption-standard
git pull origin feat/password-encryption-standard
git checkout -b feat/password-encryption-enhanced
```

### Step 2: Extract Enhanced Mode Files from PR #38
```bash
# Extract master password manager (will rename symbols later):
git show feat/password_encrypts:lib/common/gui/master_password_manager.rb > lib/common/gui/master_password_manager.rb

# Extract prompts:
git show feat/password_encrypts:lib/common/gui/master_password_prompt.rb > lib/common/gui/master_password_prompt.rb
git show feat/password_encrypts:lib/common/gui/master_password_prompt_ui.rb > lib/common/gui/master_password_prompt_ui.rb

# Extract tests:
git show feat/password_encrypts:spec/master_password_manager_spec.rb > spec/master_password_manager_spec.rb
git show feat/password_encrypts:spec/master_password_prompt_spec.rb > spec/master_password_prompt_spec.rb
```

### Step 3: Implement Windows Keychain Support
**Edit `lib/common/gui/master_password_manager.rb`:**

1. Add `windows_10_or_later?` method (see "Windows Keychain Implementation" above)
2. Update `windows_keychain_available?` (replace line 172)
3. Implement `store_windows_keychain` (replace lines 175-180)
4. Implement `retrieve_windows_keychain` (replace lines 182-184)
5. Keep `delete_windows_keychain` as-is (already implemented in PR #38)

### Step 4: Update Terminology (`:master_password` → `:enhanced`)

**Global find/replace in all newly added files:**
```bash
# In all extracted files, replace:
# :master_password → :enhanced
# "master_password" (in method names) → "enhanced" (where appropriate)
# Comments about "master password" → "enhanced encryption"
```

**Exceptions (keep "master password"):**
- Password entry prompts: "Enter your master password" (user-facing, clear meaning)
- Variable names holding password: `master_password` variable OK
- Keychain service name: May need to keep for backward compatibility

**Files to update:**
- `lib/common/gui/master_password_manager.rb`
- `lib/common/gui/master_password_prompt.rb`
- `lib/common/gui/master_password_prompt_ui.rb`
- `spec/master_password_manager_spec.rb`
- `spec/master_password_prompt_spec.rb`

### Step 5: Add `:enhanced` Mode to PasswordCipher
**Edit `lib/common/gui/password_cipher.rb`:**

Add Enhanced mode case to `encrypt` and `decrypt` methods:
```ruby
def self.encrypt(password, mode, key = nil)
  case mode
  when :plaintext
    password
  when :standard
    # ... existing standard implementation ...
  when :enhanced  # ← ADD THIS
    # Extract from PR #38 lines 132-135 (was :master_password)
    raise ArgumentError, 'Enhanced mode requires a master password' if key.nil?
    encrypt_with_key(password, key, 'lich5-password-encryption-enhanced')
  else
    raise ArgumentError, "Unknown encryption mode: #{mode}"
  end
end
```

Do the same for `decrypt` method.

### Step 6: Update Conversion UI
**Edit `lib/common/gui/conversion_ui.rb`:**

Add Enhanced radio button (3rd option):
```ruby
# After Standard radio button (~line 100):
enhanced_radio = Gtk::RadioButton.new(label: "Enhanced Encryption (recommended)", member: plaintext_radio)

# Add platform detection (~line 103):
unless MasterPasswordManager.keychain_available?
  enhanced_radio.sensitive = false
  enhanced_radio.visible = false if OS.windows?  # Hide on Windows <10
  Lich.log "info: Enhanced mode disabled - Keychain not available"
end
```

Update mode selection logic to handle `:enhanced` option.

### Step 7: Add Enhanced Tests to password_cipher_spec.rb
**Edit `spec/password_cipher_spec.rb`:**

Add Enhanced mode test block (extract from PR #38 lines 40-66):
```ruby
describe 'enhanced mode' do
  let(:master_password) { 'SecurePassword123!' }

  it 'encrypts and decrypts with master password' do
    encrypted = PasswordCipher.encrypt('mypassword', :enhanced, master_password)
    expect(encrypted).not_to eq('mypassword')

    decrypted = PasswordCipher.decrypt(encrypted, :enhanced, master_password)
    expect(decrypted).to eq('mypassword')
  end

  # ... more tests ...
end
```

### Step 8: Update yaml_state.rb for Enhanced Mode
**Edit `lib/common/gui/yaml_state.rb`:**

Add Enhanced mode handling in `encrypt_password` and `decrypt_password`:
```ruby
def encrypt_password(game_code, char_name, password, mode)
  case mode
  when :plaintext
    password
  when :standard
    # ... existing ...
  when :enhanced
    # Ensure master password exists
    ensure_master_password_exists
    master_password = MasterPasswordManager.retrieve_master_password
    PasswordCipher.encrypt(password, :enhanced, master_password)
  end
end
```

### Step 9: Run Tests
```bash
bundle exec rspec
# Expected: All tests pass (380+ examples)
# Watch for platform-specific skips on Windows <10
```

### Step 10: Run RuboCop
```bash
bundle exec rubocop lib/common/gui/master_password_manager.rb
bundle exec rubocop spec/master_password_manager_spec.rb
# Expected: 0 offenses
```

### Step 11: Verify Windows Implementation
```bash
# Check for stub remnants:
grep -n "not fully implemented" lib/common/gui/master_password_manager.rb
# Expected: 0 results (stub removed)

# Verify Windows methods exist:
grep -n "def.*windows_keychain" lib/common/gui/master_password_manager.rb
# Expected: 4 matches (available?, store, retrieve, delete)

# Verify Windows 10+ detection:
grep -n "windows_10_or_later" lib/common/gui/master_password_manager.rb
# Expected: Method definition + usage in availability check
```

### Step 12: Verify Terminology Update
```bash
# Should return 0 in code (OK in comments/strings):
grep -r ":master_password" lib/common/gui/

# Should show :enhanced instead:
grep -r ":enhanced" lib/common/gui/password_cipher.rb
# Expected: 2+ matches (encrypt and decrypt methods)
```

### Step 13: Commit
```bash
git add .
git commit -m "$(cat <<'EOF'
feat(all): add enhanced encryption with master password

Adds OS keychain-based enhanced encryption mode:
- Enhanced mode with master password stored in OS keychain
- Cross-platform support: macOS (security), Linux (secret-tool), Windows 10+ (PasswordVault)
- Windows version detection (Windows 10+ required for PasswordVault API)
- Master password prompts and validation (PBKDF2 100K iterations)
- Platform-aware tests with graceful skips
- Conversion dialog enhanced option (disabled on Windows <10)

Completes cross-platform enhanced encryption support.

Related: BRD Password Encryption Phase 3 (Enhanced Mode)
EOF
)"
```

### Step 14: Push
```bash
git push -u origin feat/password-encryption-enhanced
```

---

## Acceptance Criteria

### Code Quality
- [ ] Branch created: `feat/password-encryption-enhanced` from `feat/password-encryption-standard`
- [ ] All Enhanced mode files extracted and added
- [ ] Windows keychain fully implemented (not stubbed)
- [ ] Terminology updated: `:master_password` → `:enhanced`
- [ ] RuboCop clean: 0 offenses

### Windows Keychain Implementation
- [ ] `windows_10_or_later?` method detects Windows version
- [ ] `windows_keychain_available?` returns true on Windows 10+
- [ ] `store_windows_keychain` stores password via PasswordVault
- [ ] `retrieve_windows_keychain` retrieves password correctly
- [ ] `delete_windows_keychain` removes password
- [ ] Passwords with special characters handled (stdin piping)
- [ ] PowerShell errors caught gracefully

### Functionality
- [ ] PasswordCipher supports `:enhanced` mode
- [ ] Conversion dialog shows 3 options: Plaintext, Standard, Enhanced
- [ ] Enhanced option disabled on Windows <10 (with tooltip)
- [ ] Enhanced option enabled on macOS, Linux, Windows 10+
- [ ] Master password prompt shown when Enhanced selected
- [ ] Password validation uses PBKDF2 100K iterations
- [ ] Keychain stores/retrieves master password correctly

### Tests
- [ ] All prior tests still pass (380+ examples)
- [ ] Enhanced mode tests comprehensive
- [ ] Platform-aware tests (skip on unavailable platforms)
- [ ] Windows 10+ detection tests
- [ ] Keychain integration tests (mock or skip if unavailable)

### Platform Compatibility
- [ ] macOS: Enhanced mode works with `security` command
- [ ] Linux: Enhanced mode works with `secret-tool`
- [ ] Windows 10+: Enhanced mode works with PasswordVault
- [ ] Windows <10: Enhanced option hidden/disabled gracefully

### Code Standards
- [ ] SOLID + DRY principles followed
- [ ] YARD documentation on all new methods
- [ ] Security best practices (passwords via stdin, not command args)
- [ ] Error handling comprehensive

### Git Hygiene
- [ ] Conventional commit: `feat(all): add enhanced encryption with master password`
- [ ] Branch pushed: `git push -u origin feat/password-encryption-enhanced`
- [ ] Clean diff (only adds Enhanced mode)
- [ ] No merge conflicts with PR-Standard base

### Verification Commands
```bash
# All should pass:
grep -n "not fully implemented" lib/common/gui/master_password_manager.rb | wc -l  # Expected: 0
grep -r ":master_password" lib/common/gui/ | wc -l                                  # Expected: 0 (code), OK (comments)
bundle exec rspec                                                                    # Expected: All pass
bundle exec rubocop                                                                  # Expected: 0 offenses
git log --oneline -1                                                                 # Expected: feat(all): add enhanced...
```

---

## Edge Cases to Handle

### 1. PowerShell Execution Policy Blocked
- Use `-ExecutionPolicy Bypass` if needed
- Gracefully fail → `keychain_available?` returns false

### 2. PasswordVault Permissions Denied
- Corporate environments may restrict API
- Catch exception → return false

### 3. Password with PowerShell Special Characters
- Single quotes, backticks, $variables
- Use stdin piping (already implemented)

### 4. Windows Version Detection Fails
- PowerShell not available
- Assume not available → return false

### 5. Existing Passwords in PasswordVault
- Always remove before adding (implemented)
- Prevents duplicate credential errors

---

## What Comes Next

**After this PR is complete:**
- ✅ PR-Enhanced ready for beta testing (Enhanced mode all platforms)
- ⏭️ **Next work unit:** SSH_KEY_CURRENT.md (branches from this PR)
- 🚫 **Do not start SSH Key work** until PR-Enhanced tests pass

**Dependencies:**
- PR-SSH (SSH Key mode) will branch from this PR's branch
- Fix-MasterPassword (Master Password change UI) can branch from this PR
- This PR must be stable first

---

## Troubleshooting

### "Windows tests failing"
- Verify Windows 10+ detection works
- Check PowerShell is accessible
- Ensure PasswordVault API not blocked by Group Policy

### "Keychain tests failing on Linux/macOS"
- Tests should skip if keychain unavailable
- Check `secret-tool` or `security` command availability

### "Terminology still shows :master_password"
- Run global find/replace again
- Check conversion_ui.rb, password_cipher.rb carefully

### "Tests pass individually but fail in suite"
- Verify infomon pollution not affecting (should be fixed in PR-Standard)
- Check for test ordering issues

---

## Context References

**Read before starting:**
- `.claude/docs/CLI_PRIMER.md` - Ground rules
- `.claude/docs/ADR_SESSION_011C_TERMINOLOGY.md` - Terminology decisions
- `.claude/work-units/CURRENT.md` - Windows keychain work unit (original)
- `.claude/docs/AUDIT_PR38_CORRECTED.md` - Windows gap analysis
- `.claude/docs/BRD_Password_Encryption.md` - Requirements (Phase 3: Enhanced)

---

**END OF WORK UNIT**

When complete, archive this file to `.claude/docs/archive/ENHANCED_COMPLETED.md` and await next work unit.
