# Refactor Plan: Login-Shared Architecture

**Status:** Registered for future implementation (low priority, necessary but not urgent)
**Date Created:** 2025-11-20
**Complexity Level:** Medium
**Estimated Effort:** 3-4 hours
**Risk Level:** Low

---

## Executive Summary

The login system currently has GUI-specific code mixed with domain logic, making it difficult to support multiple interfaces (GUI, CLI, etc.) without duplication. This refactor separates **login domain logic** from **presentation logic** by creating `lib/common/login-shared/` directory, allowing both GUI and CLI layers to share authentication, password encryption, and entry management.

**Key Outcome:** Single source of truth for login operations; clean separation between domain and presentation layers.

---

## Current Problem

**Root Issue:** `gui-login.rb` is focused on GUI mechanics (tabs, buttons, dialogs) rather than the actual login flow.

### Current Architecture

```
lib/main/main.rb (CLI login)
  ├─ Raw YAML loading
  ├─ No password decryption
  ├─ Direct EAccess.auth calls
  └─ Scattered logic

lib/common/gui-login.rb (GUI login)
  ├─ Uses YamlState (with GUI coupling)
  ├─ Uses Authentication wrapper
  ├─ Uses UI-specific modules
  └─ Mixes domain logic with UI

lib/common/gui/ (mixed concerns)
  ├─ authentication.rb (pure domain, wrongly located)
  ├─ password_manager.rb (pure domain, wrongly located)
  ├─ password_cipher.rb (pure crypto, wrongly located)
  ├─ yaml_state.rb (95% domain, 5% GUI coupled)
  ├─ master_password_manager.rb (pure platform abstraction)
  ├─ saved_login_tab.rb (GUI only)
  ├─ manual_login_tab.rb (GUI only)
  └─ ... (other UI components)
```

**Result:** CLI login can't reuse password decryption logic without pulling in Gtk dependencies.

---

## Proposed Solution

Create a **domain-focused login layer** separate from presentation layers.

### Target Architecture

```
lib/common/
  ├─ login-shared/                       (NEW - domain logic, no UI)
  │  ├─ authentication.rb                (moved from gui/)
  │  ├─ password_manager.rb              (moved from gui/)
  │  ├─ password_cipher.rb               (moved from gui/)
  │  ├─ master_password_manager.rb       (moved from gui/)
  │  └─ yaml_state.rb                    (refactored - remove Gtk calls)
  │
  ├─ gui/                                (GUI presentation layer)
  │  ├─ saved_login_tab.rb               (unchanged)
  │  ├─ manual_login_tab.rb              (unchanged)
  │  ├─ login_tab_utils.rb               (unchanged)
  │  ├─ account_manager_ui.rb            (unchanged)
  │  ├─ conversion_ui.rb                 (unchanged)
  │  ├─ master_password_prompt_ui.rb     (unchanged)
  │  └─ ... (other UI components)
  │
  ├─ cli/                                (CLI execution layer - added separately)
  │  └─ cli_login.rb                     (new CLI login flow)
  │
  ├─ gui-login.rb                        (refactored - now a GUI wrapper)
  │
  └─ cli-login.rb                        (future - main entry point for CLI)

lib/util/
  ├─ login_helpers.rb                    (unchanged - already correctly located)
  └─ ... (other utilities)
```

---

## Detailed Module Analysis

### Modules Ready to Extract (No Changes Needed)

#### 1. `password_cipher.rb` → `login-shared/password_cipher.rb`

**Status:** ✅ EASY - No GUI dependencies

- Pure cryptography module
- AES-256-CBC encryption/decryption
- PBKDF2 key derivation
- Base64 encoding/decoding
- No framework dependencies beyond standard library (`openssl`, `base64`)

**Effort:** 1-2 minutes (just move the file and update requires)

---

#### 2. `password_manager.rb` → `login-shared/password_manager.rb`

**Status:** ✅ EASY - No GUI dependencies

- Mode-aware password retrieval
- Mode-aware password change coordination
- Encryption mode handling (:plaintext, :standard, :enhanced)
- Zero GUI coupling

**Dependencies:** Only `PasswordCipher` (which is also being extracted)

**Effort:** 1-2 minutes (move and update requires)

---

#### 3. `authentication.rb` → `login-shared/authentication.rb`

**Status:** ✅ EASY - No GUI dependencies

- Wrapper around `EAccess.auth()` game server API
- Launch data preparation
- Frontend-specific formatting
- Already correctly designed for reuse

**Dependencies:** Only `EAccess` (external game API)

**Effort:** 1-2 minutes (move and update requires)

---

#### 4. `master_password_manager.rb` → `login-shared/master_password_manager.rb`

**Status:** ✅ EASY - Platform abstraction, not GUI

- OS detection for keychain backends (macOS, Linux, Windows)
- Platform-specific credential storage abstraction
- PBKDF2 validation test creation
- Secure password comparison

**Note:** This is platform-specific code, not GUI-specific. Both CLI and GUI need keychain access.

**Dependencies:**
- `WindowsCredentialManager` (FFI wrapper - also move to login-shared/)
- Standard library: `openssl`, `securerandom`, `base64`, `os`

**Effort:** 2-3 minutes (move files and update requires)

---

### Module Requiring Minor Refactoring

#### 5. `yaml_state.rb` → `login-shared/yaml_state.rb` (WITH REFACTOR)

**Status:** ⚠️ HARD - Has GUI coupling in recovery flow

**Current State:**
- 95% pure domain logic (YAML I/O, password encryption/decryption coordination, entry management)
- 5% GUI coupled (recovery flow only)

**GUI Coupling Details:**

Lines 255-297: `decrypt_password_with_recovery()` method

```ruby
def self.decrypt_password_with_recovery(encrypted_password, mode:, account_name: nil,
                                       master_password: nil, validation_test: nil)
  # Try normal decryption first
  return decrypt_password(...)
rescue StandardError => e
  # Only attempt recovery for enhanced mode with missing master password
  if mode.to_sym == :enhanced && e.message.include?("Master password not found") && validation_test
    # LINE 264: Calls UI dialog
    recovery_result = MasterPasswordPromptUI.show_recovery_dialog(validation_test)

    # LINE 268: Gtk.main_quit on cancel
    if recovery_result.nil?
      Gtk.main_quit
      return nil
    end

    # ... handle recovery ...

    # LINE 288: Another Gtk.main_quit
    if !continue_session
      Gtk.main_quit
    end
  end
end
```

**Refactoring Strategy:**

Replace GUI-coupled recovery with exception-based approach:

```ruby
# In login-shared/yaml_state.rb
def self.decrypt_password(encrypted_password, mode:, account_name: nil, master_password: nil)
  # ... normal decryption logic ...
rescue StandardError => e
  if mode.to_sym == :enhanced && e.message.include?("Master password not found")
    # Raise exception with validation test attached
    raise MasterPasswordRecoveryNeeded.new(validation_test: validation_test)
  else
    raise
  end
end

# Custom exception
class MasterPasswordRecoveryNeeded < StandardError
  attr_reader :validation_test

  def initialize(validation_test:)
    @validation_test = validation_test
    super("Master password not found in Keychain")
  end
end
```

**Then in GUI layer:**

```ruby
# In gui/yaml_state_gui.rb or within gui-login.rb
def self.load_saved_entries_with_recovery(data_dir, autosort_state)
  Lich::Common::LoginShared::YamlState.load_saved_entries(data_dir, autosort_state)
rescue Lich::Common::LoginShared::MasterPasswordRecoveryNeeded => e
  # Show UI dialog
  recovery_result = MasterPasswordPromptUI.show_recovery_dialog(e.validation_test)

  if recovery_result.nil?
    Gtk.main_quit
    return []
  end

  # Retry with recovered password
  retry_load_with_master_password(data_dir, autosort_state, recovery_result[:password])
end
```

**Advantages:**
- `login-shared/yaml_state.rb` becomes pure domain logic
- GUI layer explicitly handles recovery
- CLI layer can raise the exception and handle gracefully (no Gtk.main_quit)
- Clear separation of concerns

**Effort:** 1.5-2 hours

---

### Already Correctly Located

#### `login_helpers.rb` → No change

**Status:** ✅ Correctly in `lib/util/`

- Already pure domain logic (character search, game code mappings, process spawning)
- No GUI or framework dependencies
- Shared by both GUI and CLI

**Effort:** 0 (no change needed)

---

## Risk Assessment

### Regression Risk: **LOW**

**Factors:**
1. ✅ No circular dependencies between modules
2. ✅ Clear module boundaries
3. ✅ 5 of 6 files are pure domain logic (zero changes needed)
4. ✅ Only 1 file requires refactoring (yaml_state.rb)
5. ✅ Refactoring is straightforward (exception-based instead of direct Gtk calls)

**Testing Strategy:**
- Existing specs for each module continue to pass
- New specs for exception handling in recovery flow
- Integration tests for GUI + CLI paths
- No changes to external APIs (public methods signatures unchanged)

---

## Implementation Roadmap

### Phase 1: Prepare (15 minutes)
- [ ] Create `lib/common/login-shared/` directory
- [ ] Create new `MasterPasswordRecoveryNeeded` exception class
- [ ] Write specs for exception handling

### Phase 2: Refactor yaml_state.rb (1.5-2 hours)
- [ ] Extract recovery logic to exception-based approach
- [ ] Create exception class
- [ ] Update specs to verify exception is raised
- [ ] Verify GUI recovery still works via exception handling
- [ ] Verify CLI can catch exception and handle gracefully

### Phase 3: Move Clean Modules (30 minutes)
- [ ] Move `password_cipher.rb`
- [ ] Move `password_manager.rb`
- [ ] Move `authentication.rb`
- [ ] Move `master_password_manager.rb`
- [ ] Move `windows_credential_manager.rb`
- [ ] Update all requires in lib/common/gui/ to import from login-shared

### Phase 4: Move and Refactor yaml_state.rb (30 minutes)
- [ ] Move yaml_state.rb with refactored recovery
- [ ] Create GUI wrapper in gui-login.rb that catches exception

### Phase 5: Update GUI Layer (30 minutes)
- [ ] Update gui-login.rb to catch `MasterPasswordRecoveryNeeded`
- [ ] Update SavedLoginTab, ManualLoginTab to use refactored flow

### Phase 6: Enable CLI Reuse (Already done in separate branch)
- [ ] CLI can now use login-shared modules without Gtk dependency
- [ ] cli/cli_login.rb can catch exception and handle CLI-appropriate recovery

### Phase 7: Validation (30 minutes)
- [ ] Run full spec suite
- [ ] Integration tests (GUI login + CLI login)
- [ ] Regression testing across both flows

**Total Estimated Time:** 3-4 hours
**Suitable for:** 1-2 developer session(s)

---

## Benefits After Refactor

1. **Code Reuse:** Both GUI and CLI use identical authentication/encryption logic
2. **Maintainability:** Single source of truth for password operations
3. **Testing:** Can test login logic without GUI dependencies
4. **Extensibility:** Future interfaces (API, mobile, etc.) can reuse login-shared
5. **Clarity:** Clear separation between domain (what we do) and presentation (how we show it)

---

## Dependencies Affected

**Files that need require updates:**
- `lib/common/gui-login.rb` - Import from login-shared
- `lib/common/gui/saved_login_tab.rb` - Import from login-shared
- `lib/common/gui/manual_login_tab.rb` - Import from login-shared
- `lib/common/gui/account_manager.rb` - Import from login-shared
- `lib/common/gui/password_change.rb` - Import from login-shared
- `lib/util/cli_password_manager.rb` - Import from login-shared

**No changes needed:**
- `lib/util/login_helpers.rb` - Already standalone
- External gems - No new dependencies

---

## Open Questions

1. Should `login_helpers.rb` move to `login-shared/` or stay in `lib/util/`?
   - **Current Decision:** Stay in `lib/util/` (it's a general utility module, not login-specific)
   - **Alternative:** Move to `login-shared/` for consistency

2. Should we create `cli-login.rb` at `lib/common/cli-login.rb` or `lib/main/cli_login.rb`?
   - **Current Decision:** `lib/common/cli/cli_login.rb` to mirror GUI structure
   - This is separate from the login-shared refactor

---

## Related Issues

- GitHub Issue (to be created): Link this document in the issue
- Branch: `docs/login-shared-refactor-plan`
- GUI Login Assessment: `.claude/docs/GUI_LOGIN_ARCHITECTURE_ASSESSMENT.md`

---

## Notes for Implementation

1. **Start with refactoring yaml_state.rb** - That's the only real complexity. Once the exception pattern is in place, moving other modules is trivial.

2. **Preserve existing behavior** - The refactor should not change any public method signatures or return values. Only the internal recovery mechanism changes.

3. **Use exception tests** - When writing specs, test that exceptions are properly raised and caught.

4. **Integration first** - After the refactor, immediately verify both GUI and CLI login flows work end-to-end.

5. **Incremental merge** - Consider merging each phase separately to main rather than one giant refactor PR. This makes it easier to revert if issues arise.

---

## Sign-Off

This refactor is:
- ✅ **Necessary** - Current architecture prevents code reuse
- ❌ **Not urgent** - Current system works; this is technical debt
- ✅ **Well-understood** - Clear path forward with low regression risk
- ✅ **Deferred appropriately** - Implement after CLI separation is complete

**Recommended scheduling:** After CLI login (lib/common/cli/cli_login.rb) is working and tested.
