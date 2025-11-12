# Work Unit: Standard + Enhanced Encryption Modes (Unified PR)

**Objective:** Apply password encryption support (Standard + Enhanced modes) on top of PR 7 (YAML foundation)

**Starting Point:** Branch from `eo-996` (PR 7, plaintext/YAML baseline)
**Expected Output:** Clean PR that diffs only additions for Standard + Enhanced modes
**Target Verification:** Diff cleanly against `feat/password_encrypts` (PR 38)

---

## Delta Overview

This work unit extracts the Standard and Enhanced encryption modes from PR 38 into a single, cohesive PR that:
- Adds AES-256-CBC encryption (Standard mode) - account-name-based key derivation
- Adds Master Password + keychain support (Enhanced mode) - cross-platform secure storage
- Integrates encryption into password save/load workflow
- Updates UI for mode selection, prompting, and management
- Includes comprehensive tests

**Scope:**
- Production code: 23 files modified/added in `lib/` and `spec/`
- Documentation: Included in this branch but not required for feature validation
- Dependencies: Added `os` gem for platform detection

---

## File-by-File Breakdown

### NEW FILES (Core Encryption Logic)

**`lib/common/gui/password_cipher.rb`** (152 lines)
- AES-256-CBC encryption/decryption
- PBKDF2 key derivation (10k iterations)
- Supports `:standard` (account name) and `:master_password` (master password) modes
- Method: `encrypt(password, mode:, account_name:, master_password:)`
- Method: `decrypt(encrypted_password, mode:, account_name:, master_password:)`
- Custom `DecryptionError` exception

**`lib/common/gui/master_password_manager.rb`** (199 lines)
- Keychain integration for all platforms (macOS, Linux, Windows)
- Master password storage and retrieval
- Validation test creation/validation (100k iterations one-time setup)
- Cross-platform implementations:
  - macOS: `security` CLI
  - Linux: `secret-tool` (freedesktop.org Secret Service)
  - Windows: PowerShell PasswordVault API
- Methods: `keychain_available?`, `store_master_password`, `retrieve_master_password`, `create_validation_test`, `validate_master_password`, `delete_master_password`

**`lib/common/gui/master_password_prompt.rb`** (89 lines)
- Non-GUI password prompting logic
- Prompts for master password creation
- Prompts for master password entry with validation
- Handles setup flow: create → validate → store → test

**`lib/common/gui/master_password_prompt_ui.rb`** (268 lines)
- GTK3 UI for master password prompting
- Create password dialog (with confirm)
- Enter password dialog (with validation feedback)
- Accessible widgets for screen readers
- Modal dialogs with progress indication

**`lib/gemstone/olib/command.rb`** (20 lines)
**`lib/gemstone/olib/container.rb`** (44 lines)
**`lib/gemstone/olib/containers.rb`** (73 lines)
**`lib/gemstone/olib/exist.rb`** (93 lines)
**`lib/gemstone/olib/item.rb`** (56 lines)
- General-purpose utility modules (appears to be library code)
- Used by password management system

### MODIFIED FILES (Integration Points)

**`lib/common/gui/yaml_state.rb`** (~220 lines modified)
- Import: `password_cipher`, `master_password_manager`, `master_password_prompt`
- New method: `migrate_to_encryption_format(yaml_data)` - migrates existing YAML to add encryption_mode field
- Modified: `migrate_from_legacy(data_dir, encryption_mode: :plaintext)` - accepts encryption mode parameter, encrypts passwords during migration, prompts for master password if needed
- New method: `encrypt_password(password, mode:, account_name:, master_password:)` - wrapper for PasswordCipher
- New method: `decrypt_password(encrypted_password, mode:, account_name:, master_password:)` - wrapper for PasswordCipher
- Modified: `save_entries` - always encrypts on save based on entry's `:encryption_mode`
- Modified: `load_entries` - always decrypts on load based on entry's `:encryption_mode`
- Key change: File permissions set to `0600` (read-write for owner only)

**`lib/common/gui/conversion_ui.rb`** (~116 lines modified)
- Import: `master_password_manager`
- Modified: `create_conversion_dialog` - adds encryption mode selection UI
- New: Radio button group for:
  - Plaintext (not recommended)
  - Standard encryption (account-name based)
  - Master password (requires keychain)
  - Enhanced (future, disabled)
- New: Plaintext mode warning dialog
- Modified: Calls `YamlState.migrate_from_legacy` with selected `encryption_mode`
- UI size increased from 410 to 500px for new controls

**`lib/common/gui/password_change.rb`** (~58 lines modified)
- Encryption awareness updates
- Password re-encryption on change
- Calls `PasswordCipher` for encryption/decryption based on mode

**`lib/common/gui/account_manager.rb`** (~25 lines modified)
- New method: `write_yaml_with_headers(yaml_file, yaml_data)` - writes YAML with file headers
- Updates YAML write calls to use new method instead of direct `Utilities.verified_file_operation`

**`lib/common/gui/utilities.rb`** (~10 lines modified)
- Minor updates (likely documentation/import changes)

**`lib/common/game-loader.rb`** (~2 lines added)
- Require: `lib/gemstone/olib/exist.rb`
- Require: All files in `lib/gemstone/olib/**/*.rb`

**`lib/version.rb`** (version bump)
- Likely 5.13.0 or similar

### TEST FILES

**`spec/password_cipher_spec.rb`** (150 lines)
- Tests for `encrypt`/`decrypt` with :standard mode
- Tests for `encrypt`/`decrypt` with :master_password mode
- Tests for key derivation
- Tests for IV generation
- Tests for decryption error handling

**`spec/master_password_manager_spec.rb`** (117 lines)
- Tests for keychain availability detection
- Tests for password storage/retrieval
- Tests for validation test creation
- Tests for password validation
- Tests for each platform (macOS, Linux, Windows)

**`spec/master_password_prompt_spec.rb`** (270 lines)
- Tests for master password prompting logic
- Tests for password confirmation
- Tests for validation flow

**`spec/master_password_prompt_ui_spec.txt`** (472 lines)
- GTK3 UI tests (text-based)
- Dialog creation and interaction tests

**`spec/yaml_state_spec.rb`** (~944 lines, significantly refactored)
- Existing tests modified to work with encryption
- New tests for encryption/decryption during save/load
- New tests for migration with different modes
- New tests for mode handling

**`spec/yaml_state_spec.txt`** (816 lines)
- Text-based specs (similar format to UI tests)

### CONFIGURATION & BUILD FILES

**`Gemfile`** (6 lines added)
- Add gem: `os` - for OS detection (macOS/Linux/Windows)

**`CHANGELOG.md`** (7 lines added)
- Changelog entry for 5.13.0

**.release-please-manifest.json** (version bump)

**`R4LGTK3.iss`** (2 lines, Windows installer config)

---

## Execution Steps

### Phase 1: Setup

**1.1 Ensure you're on the correct branch:**
```bash
git fetch origin eo-996:eo-996
git checkout eo-996
git checkout -b feat/password-encryption-standard
```

**1.2 Update Gemfile:**
```bash
# Add to Gemfile (in appropriate section):
gem 'os'
```

**1.3 Run bundle install:**
```bash
bundle install
```

### Phase 2: Add Core Files

**2.1 Create encryption cipher:**
Create file `lib/common/gui/password_cipher.rb` with password encryption logic.
- `PasswordCipher.encrypt(password, mode: :standard, account_name: 'user')`
- `PasswordCipher.decrypt(encrypted, mode: :standard, account_name: 'user')`
- Support both `:standard` and `:master_password` modes

**2.2 Create master password manager:**
Create file `lib/common/gui/master_password_manager.rb` with keychain integration.
- Platform detection (macOS/Linux/Windows)
- Keychain storage/retrieval for each platform
- Validation test creation (100k iterations)
- Password validation

**2.3 Create master password prompting:**
Create file `lib/common/gui/master_password_prompt.rb` with non-UI prompting logic.
- `ensure_master_password_exists` - creates new or retrieves existing
- `prompt_for_master_password` - interactive entry with validation

**2.4 Create master password UI:**
Create file `lib/common/gui/master_password_prompt_ui.rb` with GTK3 dialogs.
- Password creation dialog (with confirmation)
- Password entry dialog (with validation feedback)
- Accessible widgets

**2.5 Add olib utility modules:**
Create files in `lib/gemstone/olib/`:
- `exist.rb` - existence checking utilities
- `command.rb` - command utilities
- `container.rb` - container utilities
- `containers.rb` - multiple container utilities
- `item.rb` - item utilities

### Phase 3: Integrate Encryption into Existing Modules

**3.1 Update yaml_state.rb:**
- Import: `password_cipher`, `master_password_manager`, `master_password_prompt`
- Add methods: `encrypt_password`, `decrypt_password`, `migrate_to_encryption_format`
- Modify `save_entries` to encrypt passwords before saving
- Modify `load_entries` to decrypt passwords after loading
- Modify `migrate_from_legacy` to accept `encryption_mode` parameter
- Set file permissions to `0600`
- Remove plaintext warning from file headers

**3.2 Update conversion_ui.rb:**
- Import: `master_password_manager`
- Add encryption mode selection to conversion dialog (radio buttons)
- Add warning dialog for plaintext mode
- Pass selected mode to `YamlState.migrate_from_legacy`
- Increase dialog width to 500px

**3.3 Update password_change.rb:**
- Add encryption awareness
- Encrypt password on change using appropriate mode

**3.4 Update account_manager.rb:**
- Add method: `write_yaml_with_headers` (writes YAML with proper headers)
- Update all `YAML.dump` calls to use new method

**3.5 Update game_loader.rb:**
- Add requires for olib modules

### Phase 4: Update Version & Config

**4.1 Update version:**
- Edit `lib/version.rb` - increment to 5.13.0

**4.2 Update manifest:**
- Edit `.release-please-manifest.json` - update version

**4.3 Update Windows installer:**
- Edit `R4LGTK3.iss` - update version if needed

**4.4 Update CHANGELOG:**
- Add entry for 5.13.0 with feature summary

### Phase 5: Add Tests

**5.1 Create password_cipher_spec.rb:**
- Test encrypt/decrypt for :standard mode
- Test encrypt/decrypt for :master_password mode
- Test key derivation
- Test decryption error handling
- Verify IV is random for each encryption

**5.2 Create master_password_manager_spec.rb:**
- Test keychain availability detection
- Test keychain storage/retrieval
- Test validation test creation
- Test password validation
- Test platform-specific implementations

**5.3 Create master_password_prompt_spec.rb:**
- Test password prompting
- Test confirmation matching
- Test validation flow

**5.4 Create master_password_prompt_ui_spec.txt:**
- Test GTK3 dialog creation
- Test interaction flow

**5.5 Refactor yaml_state_spec.rb:**
- Update existing tests to work with encryption
- Add tests for save/load with encryption
- Add tests for migration with different modes

**5.6 Create yaml_state_spec.txt:**
- Text-based specs following existing pattern

---

## Verification Checklist

### Code Structure
- [ ] All new files exist and have correct permissions
- [ ] All modified files have correct imports
- [ ] No syntax errors (`ruby -c` on each .rb file)
- [ ] All `require` statements resolve correctly

### Encryption Logic
- [ ] `PasswordCipher` encrypts/decrypts correctly
- [ ] Different account names produce different encrypted values
- [ ] Same account name produces consistent encryption keys
- [ ] Master password encryption works independently from account name
- [ ] IV is random on each encryption (encrypted output differs)

### Integration
- [ ] `YamlState.save_entries` encrypts passwords
- [ ] `YamlState.load_entries` decrypts passwords
- [ ] `YamlState.migrate_from_legacy` accepts `encryption_mode` parameter
- [ ] Conversion UI shows mode selection
- [ ] Master password prompting works on this platform

### Tests
- [ ] All tests pass: `bundle exec rspec spec/`
- [ ] Test output shows no skipped tests
- [ ] Coverage maintained (at least 380+ examples as per BRD)

### Platform Support
- [ ] Keychain detection works for this platform
- [ ] All tests pass (skip keychain tests if unavailable)
- [ ] Plaintext mode works on all platforms
- [ ] Standard mode works on all platforms

### File Permissions
- [ ] entry.yaml created with mode 0600
- [ ] Only owner can read entry.yaml

### Documentation
- [ ] All methods have YARD comments
- [ ] Inline comments explain complex logic
- [ ] No hardcoded passwords in code

---

## Exit Criteria

**Before marking complete:**

1. **Syntax Check:**
   ```bash
   ruby -c lib/common/gui/password_cipher.rb
   ruby -c lib/common/gui/master_password_manager.rb
   # ... all .rb files
   ```

2. **Test Run:**
   ```bash
   bundle exec rspec spec/
   # Should show passing tests, no failures
   ```

3. **File Count:**
   ```bash
   git status
   # Should show:
   # - 5 new files in lib/common/gui/ (cipher, manager, prompt, prompt_ui, modified yaml_state)
   # - 5 new files in lib/gemstone/olib/
   # - 6 new spec files
   # - Modified: conversion_ui, password_change, account_manager, utilities, game_loader, version, Gemfile, CHANGELOG, manifest, installer
   ```

4. **Diff Verification:**
   ```bash
   # Compare with feat/password_encrypts - should match closely
   git diff eo-996..HEAD -- lib/ spec/ | wc -l
   git diff eo-996..origin/feat/password_encrypts -- lib/ spec/ | wc -l
   # Line counts should be similar
   ```

5. **Feature Verification:**
   - [ ] Can select encryption mode during initial setup
   - [ ] Plaintext mode stores passwords unencrypted
   - [ ] Standard mode encrypts using account name
   - [ ] Master password mode prompts for password creation on first use
   - [ ] Master password stored in platform keychain
   - [ ] Passwords decrypt correctly when loaded
   - [ ] File permissions set to 0600

---

## Troubleshooting

### Issue: Master password prompts on every load
**Solution:** Ensure keychain storage is working. Check logs for keychain errors.

### Issue: Tests fail with "keychain not available"
**Solution:** This is expected on platforms without keychain tools. Tests should skip gracefully.

### Issue: Diff against feat/password_encrypts shows unexpected differences
**Solution:** Compare line counts and focus areas. Small differences in comments/formatting are acceptable.

### Issue: Encryption produces different outputs each time
**Solution:** This is expected! IV is random. Decrypt the output to verify it works.

### Issue: Password decryption fails
**Solution:** Check that account_name/master_password matches what was used to encrypt. Log the cipher details.

---

## Related Documents

- `.claude/docs/BRD_Password_Encryption.md` - Full requirements
- `.claude/docs/CLAUDE.md` - Architecture overview
- `.claude/docs/PASSWORD_ENCRYPTION_OUTLINE.md` - Implementation approach
- `feat/password_encrypts` branch - Reference implementation

---

## Notes

**Important:**
- This PR represents Standard + Enhanced modes combined
- No SSH Key support in this PR (that's Phase 2)
- No management UIs for password/master-password change (those are separate)
- Focus on: encryption logic, keychain integration, initial mode selection

**Terminology:**
- `:standard` = account-name-based encryption
- `:master_password` = keychain-backed master password encryption
- `:plaintext` = no encryption (backward compatible)
- `:enhanced` - alternative naming for master password (use :master_password in code)

