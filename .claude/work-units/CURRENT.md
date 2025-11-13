# Work Unit: Windows Keychain Support via PowerShell PasswordVault

**Created:** 2025-11-08
**Estimated Effort:** 4-6 hours
**Branch:** `feat/windows-keychain-passwordvault`

---

## Task

Implement Windows keychain support for Master Password mode using PowerShell PasswordVault API. Enable 80% of user base (Windows 10+ users) to use Enhanced/Master Password encryption mode.

---

## Prerequisites

**Base Branch:** `feat/password-encryption-core`

**Branch Creation Instructions:**
```bash
git fetch origin feat/password-encryption-core
git checkout feat/password-encryption-core
git checkout -b feat/windows-keychain-passwordvault
# Do NOT merge feat/password-encryption-core - branch from it only
# Keep changes minimal - only Windows keychain implementation
```

- [ ] Branch created: `feat/windows-keychain-passwordvault` from `feat/password-encryption-core`
- [ ] Context read: `.claude/docs/AUDIT_PR38_CORRECTED.md` (Windows gap analysis)
- [ ] Dependencies available: Windows 10+ with PowerShell (built-in)

---

## Setup

```bash
git fetch origin feat/password-encryption-core
git checkout feat/password-encryption-core
git checkout -b feat/windows-keychain-passwordvault
```

---

## Files

**Modify:**
- `lib/common/gui/master_password_manager.rb` - Implement Windows keychain methods (lines 171-188)
- `lib/common/gui/conversion_ui.rb` - Add Windows version check for Enhanced mode availability

---

## Implementation Details

### 1. Windows Version Detection

Add method to check if Windows 10+ (required for PasswordVault):

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

### 2. Update `windows_keychain_available?`

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

### 3. Implement `store_windows_keychain`

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

### 4. Implement `retrieve_windows_keychain`

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

### 5. Update `conversion_ui.rb`

Ensure Enhanced mode is hidden (not just disabled) on Windows < 10:

```ruby
# Around line 103, update the keychain availability check:
unless MasterPasswordManager.keychain_available?
  master_radio.sensitive = false
  master_radio.visible = false if OS.windows?  # Hide on Windows if unavailable
  Lich.log "info: Master password mode disabled - Keychain tools not available on this system"
end
```

---

## Acceptance Criteria

- [ ] `windows_10_or_later?` detects Windows version correctly
- [ ] `windows_keychain_available?` returns true on Windows 10+ with PasswordVault
- [ ] `windows_keychain_available?` returns false on Windows < 10
- [ ] `store_windows_keychain` stores password successfully
- [ ] `retrieve_windows_keychain` retrieves stored password correctly
- [ ] `delete_windows_keychain` removes stored password
- [ ] Passwords with special characters handled correctly (shell escaping)
- [ ] Enhanced mode hidden in conversion dialog on Windows < 10
- [ ] Enhanced mode available in conversion dialog on Windows 10+
- [ ] RuboCop passes (0 offenses)
- [ ] Code follows SOLID + DRY principles
- [ ] YARD documentation complete for new methods
- [ ] Committed to branch with conventional commit: `feat(all): add Windows keychain support via PowerShell PasswordVault`

---

## Conventional Commit Format (CRITICAL)

**Your commit MUST use this format:**
```
feat(all): add Windows keychain support via PowerShell PasswordVault
```

**This is a feature** because it enables Master Password mode for Windows users.

---

## Context

**Read before starting:**
- `.claude/docs/CLI_PRIMER.md` (ground rules, project context, quality standards)
- `.claude/docs/AUDIT_PR38_CORRECTED.md` (Windows gap section, lines 311-336)
- `.claude/docs/BRD_Password_Encryption.md` (FR-1, FR-2 - platform requirements)

**Key Context:**
- Windows users are ~80% of user base
- Current stub blocks Master Password mode entirely on Windows
- Windows 10+ required for PasswordVault API
- PowerShell is built-in on Windows 10+
- Passwords must be piped via stdin (not command line) for security

**Security Note:** Never pass passwords as command-line arguments. Use stdin piping to PowerShell.

---

## Rollback Plan

**If implementation fails:**

1. **Revert changes:**
   ```bash
   git checkout feat/password-encryption-core -- lib/common/gui/master_password_manager.rb
   git checkout feat/password-encryption-core -- lib/common/gui/conversion_ui.rb
   ```

2. **Restore stub behavior:**
   - Windows keychain methods return `false`/`nil`
   - Enhanced mode disabled on all Windows systems
   - Users fall back to Plaintext/Standard modes

3. **Verify restoration:**
   ```bash
   bundle exec rubocop lib/common/gui/master_password_manager.rb lib/common/gui/conversion_ui.rb
   ```

---

## Edge Cases to Handle

1. **PowerShell execution policy blocked**
   - Use `-ExecutionPolicy Bypass` flag if needed
   - Gracefully fail → `keychain_available?` returns false

2. **PasswordVault permissions denied**
   - Corporate environment may restrict API
   - Catch exception → return false

3. **Password with PowerShell special chars**
   - Single quotes, backticks, $variables
   - Use stdin piping (already handled)

4. **Windows version detection fails**
   - PowerShell not available
   - Assume not available → return false

5. **Existing passwords in PasswordVault**
   - Always remove before adding (implemented)
   - Prevents duplicate credential errors

---

## Questions/Blockers

**None anticipated.** Implementation approach validated with product owner.

**If stuck:**
1. Test PowerShell script manually on Windows 10+ system
2. Check PowerShell error output via stderr
3. Verify PasswordVault is not disabled by Group Policy
4. Ask product owner for Windows test environment access if needed

---

**When complete:**
1. Run RuboCop: `bundle exec rubocop`
2. Verify on Windows 10+ if possible
3. Archive this file to `archive/002-windows-keychain-passwordvault.md`
4. Await next work unit
