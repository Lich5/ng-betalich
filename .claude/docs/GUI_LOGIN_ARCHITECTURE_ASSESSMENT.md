# GUI Login System Architecture Assessment

**Assessment Date:** October 30, 2025
**Scope:** `/lib/common/gui-login.rb` and `/lib/common/gui/` supporting modules
**Assessment Level:** Senior Architecture & Code Quality Review
**Status:** Complete - Ready for Implementation Planning

---

## TABLE OF CONTENTS

1. [Executive Summary](#executive-summary)
2. [SOLID Principles Analysis](#solid-principles-analysis)
3. [Security Analysis](#security-analysis)
4. [Code Quality Findings](#code-quality-findings)
5. [Recommendations by Priority](#recommendations-by-priority)
6. [Implementation Tracking](#implementation-tracking)

---

## EXECUTIVE SUMMARY

The Lich 5 GUI login system demonstrates **good foundational design** but suffers from **architectural violations, security concerns, and code maintainability issues**.

### Key Findings

**Strengths:**
- ✅ Clean separation of concerns (tabs, utilities, state management)
- ✅ Callbacks and pub-sub pattern for cross-tab communication
- ✅ Good parameter object patterns (LoginParams, UIConfig, CallbackParams)
- ✅ Proper error handling with rescue blocks

**Critical Issues:**
- ❌ **CRITICAL:** Passwords stored in plaintext (see Security #1)
- ❌ File permissions not verified (see Security #3)
- ❌ No input validation on authentication (see Security #4)
- ❌ Uninitialized @default_icon variable (see Code Quality)

**Architectural Issues:**
- ❌ SRP violated: Large classes with multiple responsibilities
- ❌ OCP violated: Hardcoded game/frontend mappings
- ❌ ISP violated: CallbackParams requires 10+ attributes, most unused
- ❌ DIP violated: Direct dependencies on concrete classes
- ❌ Code duplication: 7+ instances of similar code across files

**Overall Assessment:** **6.5/10** - Functional but needs architectural refactoring

---

## SOLID PRINCIPLES ANALYSIS

### 1. Single Responsibility Principle (SRP) - VIOLATED

#### Problem A: Multiple Responsibilities in gui-login.rb

**File:** `gui-login.rb` lines 214-505
**Issue:** `setup_gui_window` handles 5+ distinct responsibilities:
1. Creating tab instances (composition)
2. Setting up cross-tab communication (pubsub)
3. Configuring notebook layout (UI construction)
4. Configuring window properties (window management)
5. Managing conversion state (state management)

```ruby
def setup_gui_window
  Gtk.queue {
    @window = nil
    @msgbox = Lich::Common::GUI::Utilities.create_message_dialog(parent: @window, icon: @default_icon)
    create_tab_instances           # Responsibility 1
    setup_cross_tab_communication  # Responsibility 2
    setup_notebook                 # Responsibility 3
    configure_window               # Responsibility 4
    hide_optional_elements         # Responsibility 5
  }
end
```

**Impact:** Changes to any concern require modifying this single method, increasing coupling and test complexity.

#### Problem B: SavedLoginTab Mixing Multiple Concerns

**File:** `saved_login_tab.rb` (~1000+ lines)
**Issue:** Single class handles:
1. Tab UI creation (lines 147-300+)
2. Favorites management business logic (lines 614-720)
3. Theme application (lines 267-285)
4. Entry data management (lines 64-82)
5. Button click handling (lines 522-610)
6. State persistence (refresh_data method)

**Impact:** 1000+ line class is difficult to test, understand, and modify.

---

### 2. Open/Closed Principle (OCP) - PARTIALLY VIOLATED

#### Problem A: Hardcoded Game/Frontend Mappings

**File:** `utilities.rb` lines 52-102

Hardcoded switch statement:
```ruby
def self.game_code_to_realm(game_code)
  case game_code
  when "GS3" then "GS Prime"
  when "GSF" then "GS Shattered"
  when "GSX" then "GS Platinum"
  # ... etc
  else
    game_code
  end
end
```

**Problem:** Adding a new game requires code modification. Should be extensible through configuration.

**Better Approach:** Use configuration hash:
```ruby
GAME_CODE_MAP = YAML.load_file('game_codes.yaml')

def self.game_code_to_realm(game_code)
  GAME_CODE_MAP[game_code] || game_code
end
```

#### Problem B: Tab Behavior Hardcoded in create_tab_instances

**File:** `gui-login.rb` lines 277-411
**Issue:** All callback handlers are hardcoded into the tab creation method. Adding new behavior requires modifying core logic.

---

### 3. Liskov Substitution Principle (LSP) - WELL-DESIGNED

**Status:** ✅ This area follows LSP well

Parameter objects demonstrate good LSP adherence:
- Both `SavedLoginTab` and `ManualLoginTab` can accept `CallbackParams` polymorphically
- Interface consistency is maintained

---

### 4. Interface Segregation Principle (ISP) - VIOLATED

#### Problem A: CallbackParams Contains 10+ Unused Attributes

**File:** `parameter_objects.rb` lines 112-141

```ruby
class CallbackParams
  attr_accessor :on_play, :on_remove, :on_save, :on_error,
                :on_theme_change, :on_layout_change, :on_sort_change,
                :on_add_character, :on_favorites_change, :on_favorites_reorder
end
```

**Issues:**
- SavedLoginTab doesn't use `:on_save` (manual-only feature)
- ManualLoginTab doesn't use `:on_remove` (saved-only feature)
- Both don't use `:on_add_character`, `:on_layout_change`, `:on_sort_change`
- Clients must pass ALL callbacks even if they only use 2-3

**Better Design:** Segregate into smaller interfaces:
```ruby
module SavedLoginCallbacks
  def on_play(launch_data); end
  def on_remove(login_info); end
  def on_theme_change(state); end
  def on_favorites_change(params); end
end

module ManualLoginCallbacks
  def on_play(launch_data); end
  def on_save(launch_data); end
  def on_error(message); end
  def on_theme_change(state); end
end
```

---

### 5. Dependency Inversion Principle (DIP) - VIOLATED

#### Problem A: Direct Dependencies on Concrete Classes

**File:** `gui-login.rb` lines 378-397

```ruby
@saved_login_tab = Lich::Common::GUI::SavedLoginTab.new(
  @window,
  @entry_data,
  @theme_state,
  @tab_layout_state,
  @autosort_state,
  @default_icon,
  DATA_DIR,
  saved_login_callbacks
)

@manual_login_tab = Lich::Common::GUI::ManualLoginTab.new(
  @window,
  @entry_data,
  @theme_state,
  @default_icon,
  DATA_DIR,
  manual_login_callbacks,
  @autosort_state
)
```

**Problems:**
1. High-level module depends on implementation details
2. No abstraction layer for tab management
3. Hard to test without actual GTK objects
4. Hard to add new tab types without modifying core
5. Parameter passing is repetitive and error-prone

**Better Approach:** Use factory/builder:
```ruby
class TabFactory
  def create_saved_login_tab(config)
    SavedLoginTab.new(config)
  end

  def create_manual_login_tab(config)
    ManualLoginTab.new(config)
  end
end
```

#### Problem B: Direct Dependencies on YamlState Module

**Multiple files:** `saved_login_tab.rb` line 69, `gui-login.rb` line 249, `manual_login_tab.rb` line 81

```ruby
@entry_data = Lich::Common::GUI::YamlState.load_saved_entries(@data_dir, @ui_config.autosort_state)
```

**Problem:** All clients are coupled to YamlState implementation. Changing storage format requires updating multiple files.

**Better Approach:** Inject a data repository abstraction:
```ruby
class DataRepository
  def load_entries(autosort_state); end
  def save_entries(data); end
  def add_favorite(user, char, game, frontend); end
end

# Use dependency injection:
@saved_login_tab = SavedLoginTab.new(config, data_repository)
```

---

## SECURITY ANALYSIS

### CRITICAL: Plaintext Password Storage 🔴

**Severity:** CRITICAL
**File:** `yaml_state.rb` lines 57-89
**Status:** ACTIVE THREAT

#### Current Implementation

Passwords stored in plaintext in YAML file:

```yaml
# entry.yaml (generated by save_entries)
accounts:
  MYACCOUNT:
    password: MyPlaintextPassword123  # 🔴 UNENCRYPTED
    characters:
      - char_name: MyCharacter
        game_code: GS3
        game_name: GemStone IV
```

Code explicitly acknowledges the issue (line 79):
```ruby
file.puts "# WARNING: Passwords are stored in plain text"
```

#### Risk Assessment

- **Impact:** Complete account compromise if machine is breached
- **Likelihood:** HIGH - If machine is compromised or file is accessed
- **Scope:** All stored game accounts
- **Regulatory:** Violates data protection best practices

#### Attack Vectors

1. **Local Access:** Anyone with file system access can read passwords
2. **Backups:** Unencrypted backups expose credentials
3. **Version Control:** Accidentally committed files expose history
4. **Cloud Sync:** Cloud services may store plaintext in sync directories

#### Required Fix Priority

**MUST FIX BEFORE PRODUCTION** - This is non-negotiable

See section: **Password Encryption Implementation Plan**

---

### HIGH: Unsanitized Path Handling 🟠

**Severity:** HIGH
**File:** `yaml_state.rb` lines 13-15
**Status:** POTENTIAL THREAT

#### Current Implementation

```ruby
def self.yaml_file_path(data_dir)
  File.join(data_dir, "entry.yaml")
end
```

#### Attack Vector

If `data_dir` is user-controlled:
```ruby
# Attacker could write to arbitrary locations
data_dir = "/var/www/public"      # Write YAML to web root
data_dir = "../../sensitive"       # Path traversal to parent directories
data_dir = "/etc/passwd"           # Overwrite system files
```

#### Recommended Fix

```ruby
def self.yaml_file_path(data_dir)
  expanded = File.expand_path(data_dir)
  base_dir = File.expand_path(Lich::LOGIN_DATA_DIR)

  # Ensure path is within expected directory
  unless expanded.start_with?(base_dir)
    raise SecurityError, "Path traversal attempt detected: #{expanded}"
  end

  File.join(expanded, "entry.yaml")
end
```

---

### MEDIUM: File Permissions Not Verified 🟡

**Severity:** MEDIUM
**File:** `utilities.rb` lines 142-172
**Status:** ACTIVE WEAKNESS

#### Current Implementation

```ruby
File.open(file_path, 'w') do |file|
  file.write(content)
  file.flush
  file.fsync
end
```

#### Problem

- Files created with default umask (often 0022 on Unix)
- Results in permissions like `-rw-r--r--` (644)
- Any user on system can read passwords

#### Recommended Fix

```ruby
def self.safe_file_operation(file_path, operation, content = nil)
  case operation
  when :write
    # Create with restrictive permissions (600 = rw-------)
    File.open(file_path, 'w', 0600) do |file|
      file.write(content)
    end
    true
  end
end
```

---

### MEDIUM: No Input Validation on Login Data 🟡

**Severity:** MEDIUM
**File:** `authentication.rb` lines 17-37
**Status:** POTENTIAL THREAT

#### Current Implementation

```ruby
def self.authenticate(account:, password:, character: nil, game_code: nil, legacy: false)
  if character && game_code
    EAccess.auth(
      account: account,      # ❌ No validation
      password: password,    # ❌ No validation
      character: character,  # ❌ No validation
      game_code: game_code   # ❌ No validation
    )
```

#### Risks

- SQL injection if EAccess uses SQL
- Account enumeration attacks (test which accounts exist)
- Brute force attacks (no rate limiting visible)
- Information disclosure (error messages could leak account info)

#### Recommended Fix

```ruby
def self.authenticate(account:, password:, character: nil, game_code: nil, legacy: false)
  # Validate inputs
  raise ArgumentError, "Account is required" if account.blank?
  raise ArgumentError, "Password is required" if password.blank?
  raise ArgumentError, "Account invalid" unless valid_account_format?(account)

  if character
    raise ArgumentError, "Character invalid" unless valid_character_format?(character)
  end

  if game_code
    raise ArgumentError, "Game code invalid" unless valid_game_code?(game_code)
  end

  EAccess.auth(
    account: account,
    password: password,
    character: character,
    game_code: game_code,
    legacy: legacy
  )
end

private

def self.valid_account_format?(account)
  account.match?(/\A[a-zA-Z0-9_-]{3,20}\z/)
end

def self.valid_character_format?(character)
  character.match?(/\A[a-zA-Z0-9\s'-]{2,20}\z/)
end

def self.valid_game_code?(code)
  %w[GS3 GSF GSX GST DR DRF DRT].include?(code)
end
```

---

### MEDIUM: No HTTPS/TLS Enforcement 🟡

**Severity:** MEDIUM
**File:** `authentication.rb` (All authentication calls)
**Status:** ASSUMPTION - Unknown if properly enforced

#### Risk

Man-in-the-middle attacks on authentication requests could intercept credentials

#### Recommended Verification

Ensure EAccess module enforces:
- HTTPS only for authentication endpoints
- TLS certificate verification
- No downgrades to HTTP

---

### LOW: Sensitive Data in Logs 🟢

**Severity:** LOW
**File:** `manual_login_tab.rb` lines 558, 583
**Status:** POTENTIAL ISSUE

#### Current Implementation

```ruby
Lich.log "error: Error saving login entry: #{e.message}"
Lich.log "info: Character data prepared: #{launch_data}"  # launch_data contains auth info
```

#### Risk

If logs are shared or exposed, authentication data could leak

#### Recommended Fix

```ruby
def self.sanitize_for_logging(data)
  data.dup.tap do |d|
    d.delete(:password)
    d.delete(:auth_token)
  end
end

Lich.log "info: Character login prepared: #{sanitize_for_logging(launch_data)}"
```

---

### LOW: Weak Validation in YamlState Conversions 🟢

**Severity:** LOW
**File:** `yaml_state.rb` lines 336-379
**Status:** POTENTIAL ISSUE

#### Current Implementation

```ruby
def self.convert_legacy_to_yaml_format(entry_data)
  entry_data.each do |entry|
    # No validation that entry has required fields
    normalized_username = normalize_account_name(entry[:user_id])  # What if nil?
    character_data = {
      'char_name' => normalize_character_name(entry[:char_name]),
      'game_code' => entry[:game_code],  # No validation
    }
```

#### Risk

Corrupted or malicious entry data could cause silent failures

#### Recommended Fix

```ruby
def self.convert_legacy_to_yaml_format(entry_data)
  validate_entry_data!(entry_data)

  entry_data.each do |entry|
    # ... proceed with validated data
  end
end

private

def self.validate_entry_data!(entries)
  raise ArgumentError, "Entry data must be an array" unless entries.is_a?(Array)

  entries.each do |entry|
    raise ArgumentError, "User ID required" if entry[:user_id].blank?
    raise ArgumentError, "Password required" if entry[:password].blank?
    raise ArgumentError, "Character name required" if entry[:char_name].blank?
    raise ArgumentError, "Game code required" if entry[:game_code].blank?
  end
end
```

---

## CODE QUALITY FINDINGS

### Unused Methods

#### SavedLoginTab - Two unused public methods

**File:** `saved_login_tab.rb`

1. **`create_custom_launch_entry` (lines 784-786)**
   ```ruby
   def create_custom_launch_entry
     @custom_launch_entry = LoginTabUtils.create_custom_launch_entry
   end
   ```
   - Never called anywhere in codebase
   - Custom launch entry created via UI element hash instead
   - **Status:** Dead code - remove

2. **`create_custom_launch_dir` (lines 792-794)**
   ```ruby
   def create_custom_launch_dir
     @custom_launch_dir = LoginTabUtils.create_custom_launch_dir
   end
   ```
   - Never called anywhere in codebase
   - **Status:** Dead code - remove

### Unused Variables

#### Empty Callback Implementations

**File:** `gui-login.rb` lines 312-337

1. **`on_add_character` callback** (lines 312-314)
   ```ruby
   on_add_character: ->(character:, instance:, frontend:) {
     # Handle adding a character
   },
   ```
   - Empty implementation, only comment placeholder
   - Called from SavedLoginTab line 738 but does nothing
   - **Status:** Incomplete feature

2. **`on_layout_change` callback** (lines 332-334)
   ```ruby
   on_layout_change: ->(state) {
     # Handle layout change
   },
   ```
   - Empty implementation
   - **Status:** Incomplete feature

3. **`on_sort_change` callback** (lines 335-337)
   ```ruby
   on_sort_change: ->(state) {
     # Handle sort change
   },
   ```
   - Empty implementation
   - **Status:** Incomplete feature

#### Uninitialized Instance Variable

**File:** `gui-login.rb` (used in lines 219, 384, 393, 467)

`@default_icon` variable:
- Created but never assigned a value in `initialize_login_state()`
- Passed to message dialogs, icons won't display
- Used in multiple places but always nil
- **Status:** Bug - will cause icons not to render

#### Local Variables in ManualLoginTab

**File:** `manual_login_tab.rb` lines 117-119

```ruby
def apply_theme_to_ui_elements
  # Removed useless assignment to ui_elements
  # Removed useless assignment to providers
```

Comments indicate developers deliberately removed unused variables.

---

### Documentation Quality Issues

#### Duplicate/Conflicting Documentation

**File:** `saved_login_tab.rb` lines 498-509

Duplicated docstring headers:
```ruby
# Creates a character entry in the tabbed layout
# Builds a UI element for a single character entry
#
# @param account_box [Gtk::Box] Box to add the character entry to
# @param login_info [Hash] Login information for the character
# Creates a character entry with favorites support  # DUPLICATE
# Builds UI elements for a single character with play, remove, and favorites buttons
# Enhanced with favorites functionality and visual indicators
```

**Issue:** Inconsistent formatting and duplicated descriptions.

#### Missing @return Documentation

**Multiple files:** 4+ methods missing @return type documentation

#### Misleading Documentation

**File:** `gui-login.rb` lines 162-186

```ruby
# Recursively finds the refresh button in a container widget
# ...
def find_refresh_button_in_container(container)
```

**Issues:**
- Doesn't document what "refresh button" means (label == "Refresh")
- No warning about hardcoded label matching

---

### Code Duplication

#### Duplicate Error Handling

**File:** `manual_login_tab.rb` lines 598-612 vs `saved_login_tab.rb` lines 649-658

Same error dialog creation appears in both files:
```ruby
dialog = Gtk::MessageDialog.new(
  parent: @parent,
  flags: :modal,
  type: :error,
  buttons: :ok,
  message: "Failed to update favorite status: #{e.message}"
)
dialog.set_icon(@default_icon) if @default_icon
dialog.run
dialog.destroy
```

**Recommendation:** Extract to utility:
```ruby
def self.show_error_dialog(parent, message, icon = nil)
  dialog = Gtk::MessageDialog.new(
    parent: parent,
    flags: :modal,
    type: :error,
    buttons: :ok,
    message: message
  )
  dialog.set_icon(icon) if icon
  dialog.run
  dialog.destroy
end
```

#### Duplicate Sorting Logic

**Files:** `utilities.rb` lines 180-192 AND `state.rb` lines 15-38

Both implement identical sorting logic:
```ruby
if autosort_state
  entries.sort do |a, b|
    [a[:game_name], a[:user_id], a[:char_name]] <=> [b[:game_name], b[:user_id], b[:char_name]]
  end
else
  entries.sort do |a, b|
    [a[:user_id].downcase, a[:char_name]] <=> [b[:user_id].downcase, b[:char_name]]
  end
end
```

**Recommendation:** Consolidate into single implementation in YamlState.

#### Duplicate Theme Application

**Files:** `manual_login_tab.rb` lines 121-144 AND `saved_login_tab.rb` lines 267-280

Both duplicate theme application logic:
- Check theme state
- Apply providers conditionally
- Override background colors
- Handle button styling

**Recommendation:** Extract to ThemeUtils.

---

### Debug Output in Production Code

**File:** `login_tab_utils.rb` line 91

```ruby
elsif (ev.button == 3)
  pp "I would be adding to a team tab"  # 🔴 Debug output left in code
end
```

**Issue:** Incomplete functionality, debug statement left in production code

**Action:** Either implement or remove.

---

## RECOMMENDATIONS BY PRIORITY

### Priority 1: CRITICAL (Do Immediately)

#### 1.1 🔴 ENCRYPT PASSWORDS

**Status:** PLANNED
**Effort:** 8-12 hours
**Impact:** HIGH - Fixes critical security vulnerability

See detailed implementation plan: **Password Encryption Implementation Plan** (below)

**Tasks:**
- [ ] Design encryption scheme (AES-256-CBC with key derivation)
- [ ] Implement encryption/decryption utilities
- [ ] Create transparent decryption in authentication flow
- [ ] Migrate existing plaintext passwords to encrypted format
- [ ] Add file permission verification (mode 0600)
- [ ] Testing: Verify zero regression on login flow
- [ ] Documentation: Update PASSWORD_HANDLING.md

#### 1.2 🔴 FIX @default_icon INITIALIZATION

**Status:** READY TO IMPLEMENT
**Effort:** 30 minutes
**Impact:** MEDIUM - Icons won't display in dialogs

**File:** `gui-login.rb`
**Current:** Variable used but never assigned
**Fix:** Initialize in `initialize_login_state` method

```ruby
def initialize_login_state
  # ... existing code ...
  @default_icon = Gtk::Pixbuf.new(file: icon_path) rescue nil
end
```

#### 1.3 🔴 REMOVE DEBUG OUTPUT

**Status:** READY TO IMPLEMENT
**Effort:** 15 minutes
**Impact:** LOW - Cleanup

**File:** `login_tab_utils.rb` line 91
**Fix:** Remove `pp "I would be adding to a team tab"` or implement feature

---

### Priority 2: HIGH (Do This Sprint)

#### 2.1 🟠 REDUCE PARAMETER EXPLOSION

**Status:** PLANNED
**Effort:** 6-8 hours
**Impact:** MEDIUM - Improves maintainability

**Current Problem:**
- SavedLoginTab: 8 parameters
- ManualLoginTab: 7 parameters
- Repetitive, error-prone instantiation

**Solution:** Create configuration object:
```ruby
class TabConfiguration
  attr_accessor :parent, :entry_data, :theme_state, :icon,
                :data_dir, :callbacks, :tab_layout_state, :autosort_state
end
```

#### 2.2 🟠 SIMPLIFY TAB INSTANTIATION

**Status:** PLANNED
**Effort:** 4-6 hours
**Impact:** MEDIUM - Reduces coupling

**Current Code:** Direct instantiation of 2 different tab classes
**Solution:** Use factory pattern

```ruby
class TabFactory
  def self.create_saved_login_tab(config)
    SavedLoginTab.new(config)
  end

  def self.create_manual_login_tab(config)
    ManualLoginTab.new(config)
  end
end
```

#### 2.3 🟠 EXTRACT COMMON ERROR DIALOGS

**Status:** READY TO IMPLEMENT
**Effort:** 2-3 hours
**Impact:** MEDIUM - DRY up error handling

**Solution:** Create utility method in Utilities module:
```ruby
def self.show_error_dialog(parent, message, icon = nil)
  dialog = Gtk::MessageDialog.new(
    parent: parent,
    flags: :modal,
    type: :error,
    buttons: :ok,
    message: message
  )
  dialog.set_icon(icon) if icon
  dialog.run
  dialog.destroy
end
```

#### 2.4 🟠 VALIDATE FILE PATHS

**Status:** READY TO IMPLEMENT
**Effort:** 1-2 hours
**Impact:** HIGH - Prevents path traversal attacks

**File:** `yaml_state.rb` lines 13-15

#### 2.5 🟠 REMOVE UNUSED METHODS

**Status:** READY TO IMPLEMENT
**Effort:** 30 minutes
**Impact:** LOW - Cleanup

**File:** `saved_login_tab.rb`
- [ ] Remove `create_custom_launch_entry`
- [ ] Remove `create_custom_launch_dir`

---

### Priority 3: MEDIUM (Next Sprint/Refactor)

#### 3.1 🟡 CONSOLIDATE SORTING LOGIC

**Status:** PLANNED
**Effort:** 2-3 hours
**Impact:** MEDIUM - Eliminates duplication

**Files:** `utilities.rb` + `state.rb`
**Solution:** Keep single implementation in `YamlState.sort_entries`

#### 3.2 🟡 EXTRACT THEME APPLICATION LOGIC

**Status:** PLANNED
**Effort:** 3-4 hours
**Impact:** MEDIUM - Reduces duplication

**Files:** `manual_login_tab.rb` + `saved_login_tab.rb`
**Solution:** Move to `ThemeUtils` or `Components` module

#### 3.3 🟡 BREAK APART LARGE CLASSES

**Status:** PLANNED
**Effort:** 16-20 hours
**Impact:** HIGH - Improves testability and maintainability

**SavedLoginTab (1000+ lines):**
```
SavedLoginTab (300 lines) - UI orchestration
├─ SavedEntryRenderer (200 lines) - Renders entry UI
├─ FavoriteButtonController (150 lines) - Favorite button logic
├─ AccountGroupController (150 lines) - Account grouping logic
└─ EntryDataManager (100 lines) - Data loading/caching
```

#### 3.4 🟡 SEGREGATE CALLBACK INTERFACES

**Status:** PLANNED
**Effort:** 4-6 hours
**Impact:** MEDIUM - Follows ISP principle

Create separate callback modules for each tab type.

#### 3.5 🟡 COMPLETE CALLBACK IMPLEMENTATIONS

**Status:** PLANNED
**Effort:** 4-6 hours
**Impact:** LOW - Feature completion

Implement:
- `on_add_character` callback
- `on_layout_change` callback
- `on_sort_change` callback

---

### Priority 4: LOW (Nice to Have)

#### 4.1 🟢 INPUT VALIDATION

**Status:** PLANNED
**Effort:** 2-3 hours
**Impact:** MEDIUM - Security hardening

Add validation in `authentication.rb` authenticate method.

#### 4.2 🟢 SANITIZE SENSITIVE DATA IN LOGS

**Status:** PLANNED
**Effort:** 1-2 hours
**Impact:** LOW - Prevents credential leaks

Create `sanitize_for_logging` utility method.

#### 4.3 🟢 FIX DOCUMENTATION

**Status:** PLANNED
**Effort:** 2-3 hours
**Impact:** LOW - Documentation

Remove duplicate docstrings, add @return types.

#### 4.4 🟢 VERIFY VALIDATION IN CONVERSIONS

**Status:** PLANNED
**Effort:** 1-2 hours
**Impact:** LOW - Data integrity

Add validation in `yaml_state.rb` conversion methods.

---

## PASSWORD ENCRYPTION IMPLEMENTATION PLAN

### OVERVIEW

Implement transparent password encryption for stored credentials while maintaining:
- ✅ Existing UI/UX (no additional dialogs or steps)
- ✅ One-click play functionality
- ✅ Automatic password decryption on demand
- ✅ Zero regression in login flow
- ✅ Backward compatibility with existing plaintext data

### APPROACH SUMMARY

1. **Encryption Layer:** Create `PasswordVault` class that encrypts/decrypts passwords
2. **Storage:** Store encrypted passwords in YAML with encryption metadata
3. **Decryption:** Decrypt transparently when needed for authentication
4. **Migration:** Automatically migrate existing plaintext passwords
5. **Key Management:** Use OS-independent derivation key from user's account

### DESIGN

#### Layer 1: Encryption Utilities (`password_cipher.rb`)

```ruby
module Lich
  module Common
    module GUI
      class PasswordCipher
        # Uses AES-256-CBC for encryption
        # Key derived from machine + user ID

        def self.encrypt(password, key_seed = nil)
          # Returns: { iv: Base64, ciphertext: Base64 }
        end

        def self.decrypt(encrypted_hash, key_seed = nil)
          # Returns: plaintext password
        end

        private

        def self.derive_key(key_seed)
          # Derives consistent 256-bit key from seed
          # Uses PBKDF2 or similar
        end
      end
    end
  end
end
```

#### Layer 2: Entry Data Wrapper (`encrypted_entry.rb`)

```ruby
module Lich
  module Common
    module GUI
      class EncryptedEntry
        attr_reader :user_id, :char_name, :game_code

        def initialize(entry_hash)
          @user_id = entry_hash[:user_id]
          @char_name = entry_hash[:char_name]
          @game_code = entry_hash[:game_code]
          @encrypted_password = entry_hash[:encrypted_password]
          @encryption_version = entry_hash[:encryption_version]
        end

        def password
          # Transparently decrypt on access
          @decrypted_password ||= PasswordCipher.decrypt(@encrypted_password)
        end

        def to_h
          # Returns entry hash with encrypted password
        end
      end
    end
  end
end
```

#### Layer 3: Modified YamlState

```ruby
# yaml_state.rb - key changes:

def self.save_entries(data_dir, entry_data)
  yaml_file = yaml_file_path(data_dir)

  # Convert legacy to YAML AND encrypt passwords
  yaml_data = entry_data.map { |entry|
    encrypted_entry = {
      user_id: entry[:user_id],
      password_encrypted: PasswordCipher.encrypt(entry[:password]),
      encryption_version: 1,
      # ... other fields
    }
  }

  File.write(yaml_file, YAML.dump(yaml_data), mode: 0600)
end

def self.load_saved_entries(data_dir, autosort_state)
  # Loads YAML and wraps entries in EncryptedEntry for transparent decryption
  entries = yaml_data.map { |e| EncryptedEntry.new(e) }
  sort_entries_with_favorites(entries, autosort_state)
end
```

#### Layer 4: Transparent Authentication Flow

**No changes to existing callbacks:**

```ruby
# Existing code in manual_login_tab.rb:
if @callbacks.on_play
  @callbacks.on_play.call(launch_data)  # launch_data includes password
end

# The password in launch_data is automatically decrypted from EncryptedEntry
```

### IMPLEMENTATION STEPS

#### Phase 1: Create Encryption Layer (2-3 hours)

**File:** `.github/actions/format-body/action.yaml`... NO, create:
**File:** `lib/common/gui/password_cipher.rb`

```ruby
require 'openssl'
require 'base64'

module Lich
  module Common
    module GUI
      class PasswordCipher
        ALGORITHM = 'aes-256-cbc'
        ITERATIONS = 100000

        def self.encrypt(password, key_seed = nil)
          key_seed ||= default_key_seed
          key = derive_key(key_seed)

          cipher = OpenSSL::Cipher.new(ALGORITHM)
          cipher.encrypt
          cipher.key = key

          iv = cipher.random_iv
          ciphertext = cipher.update(password) + cipher.final

          {
            iv: Base64.strict_encode64(iv),
            ciphertext: Base64.strict_encode64(ciphertext)
          }
        end

        def self.decrypt(encrypted_hash, key_seed = nil)
          key_seed ||= default_key_seed
          key = derive_key(key_seed)

          cipher = OpenSSL::Cipher.new(ALGORITHM)
          cipher.decrypt
          cipher.key = key
          cipher.iv = Base64.strict_decode64(encrypted_hash[:iv])

          plaintext = cipher.update(Base64.strict_decode64(encrypted_hash[:ciphertext]))
          plaintext += cipher.final
          plaintext
        rescue OpenSSL::Cipher::CipherError
          raise "Failed to decrypt password - invalid key or corrupted data"
        end

        private

        def self.derive_key(seed)
          # PBKDF2 with 100,000 iterations
          OpenSSL::PKCS5.pbkdf2_hmac(
            seed,
            'lich_login_salt',  # Static salt (not ideal but simple)
            ITERATIONS,
            32,  # 256 bits for AES-256
            'SHA256'
          )
        end

        def self.default_key_seed
          # Combine machine and user ID for deterministic key
          "#{Lich::ACCOUNT_NAME}:#{Socket.gethostname}"
        end
      end
    end
  end
end
```

#### Phase 2: Create EncryptedEntry Wrapper (1-2 hours)

**File:** `lib/common/gui/encrypted_entry.rb`

```ruby
module Lich
  module Common
    module GUI
      class EncryptedEntry
        attr_reader :user_id, :char_name, :game_code, :game_name, :frontend,
                    :custom_launch, :custom_launch_dir, :is_favorite, :favorite_order

        def initialize(entry_hash)
          @user_id = entry_hash[:user_id]
          @password_encrypted = entry_hash[:password_encrypted]
          @encryption_version = entry_hash[:encryption_version]
          @char_name = entry_hash[:char_name]
          @game_code = entry_hash[:game_code]
          @game_name = entry_hash[:game_name]
          @frontend = entry_hash[:frontend]
          @custom_launch = entry_hash[:custom_launch]
          @custom_launch_dir = entry_hash[:custom_launch_dir]
          @is_favorite = entry_hash[:is_favorite] || false
          @favorite_order = entry_hash[:favorite_order]
          @favorite_added = entry_hash[:favorite_added]

          @decrypted_password = nil
        end

        # Transparent password decryption on access
        def password
          @decrypted_password ||= begin
            if @password_encrypted.is_a?(Hash)
              PasswordCipher.decrypt(@password_encrypted)
            else
              # Fallback for plaintext passwords (migration)
              @password_encrypted
            end
          rescue => e
            Lich.log "error: Failed to decrypt password: #{e.message}"
            nil
          end
        end

        # For compatibility with existing code expecting hash access
        def [](key)
          case key
          when :user_id then @user_id
          when :password then password
          when :char_name then @char_name
          when :game_code then @game_code
          when :game_name then @game_name
          when :frontend then @frontend
          when :custom_launch then @custom_launch
          when :custom_launch_dir then @custom_launch_dir
          when :is_favorite then @is_favorite
          when :favorite_order then @favorite_order
          else nil
          end
        end

        def to_h
          {
            user_id: @user_id,
            password_encrypted: @password_encrypted,
            encryption_version: @encryption_version,
            char_name: @char_name,
            game_code: @game_code,
            game_name: @game_name,
            frontend: @frontend,
            custom_launch: @custom_launch,
            custom_launch_dir: @custom_launch_dir,
            is_favorite: @is_favorite,
            favorite_order: @favorite_order
          }
        end
      end
    end
  end
end
```

#### Phase 3: Modify YamlState (3-4 hours)

**File:** `lib/common/gui/yaml_state.rb` (key changes)

```ruby
# Load method
def self.load_saved_entries(data_dir, autosort_state)
  yaml_file = yaml_file_path(data_dir)
  dat_file = File.join(data_dir, "entry.dat")

  if File.exist?(yaml_file)
    yaml_data = YAML.load_file(yaml_file)
    yaml_data = migrate_to_favorites_format(yaml_data)

    # Wrap entries in EncryptedEntry for transparent decryption
    entries = convert_yaml_to_legacy_format(yaml_data)
    encrypted_entries = entries.map { |e| EncryptedEntry.new(e) }

    sort_entries_with_favorites(encrypted_entries, autosort_state)
  elsif File.exist?(dat_file)
    # Load legacy format and automatically migrate
    legacy_entries = State.load_saved_entries(data_dir, autosort_state)

    # Encrypt passwords and save as YAML
    yaml_data = convert_legacy_to_yaml_with_encryption(legacy_entries)
    save_yaml_file(yaml_file, yaml_data)

    # Return wrapped entries
    entries = convert_yaml_to_legacy_format(yaml_data)
    entries.map { |e| EncryptedEntry.new(e) }
  else
    []
  end
end

# Save method
def self.save_entries(data_dir, entry_data)
  yaml_file = yaml_file_path(data_dir)

  yaml_data = entry_data.map { |entry|
    password = entry.is_a?(EncryptedEntry) ? entry.password : entry[:password]

    {
      'user_id' => entry[:user_id],
      'password_encrypted' => PasswordCipher.encrypt(password),
      'encryption_version' => 1,
      'char_name' => entry[:char_name],
      'game_code' => entry[:game_code],
      'game_name' => entry[:game_name],
      'frontend' => entry[:frontend],
      'custom_launch' => entry[:custom_launch],
      'custom_launch_dir' => entry[:custom_launch_dir],
      'is_favorite' => entry[:is_favorite],
      'favorite_order' => entry[:favorite_order]
    }
  }

  Utilities.safe_file_operation(yaml_file, :write, YAML.dump(yaml_data), mode: 0600)
  true
end
```

#### Phase 4: Update Authentication Flow (1 hour)

**No code changes needed in tabs - EncryptedEntry transparently returns password**

Verify that:
```ruby
# In manual_login_tab.rb, this still works:
launch_data = {
  user_id: entry[:user_id],
  password: entry[:password],  # Automatically decrypted from EncryptedEntry
  char_name: entry[:char_name],
  # ...
}

EAccess.auth(
  account: entry[:user_id],
  password: entry[:password],  # Automatically decrypted
  character: char_name
)
```

#### Phase 5: Migration of Existing Data (2 hours)

**File:** `yaml_state.rb` - new method

```ruby
def self.migrate_plaintext_to_encrypted(data_dir)
  yaml_file = yaml_file_path(data_dir)
  return false unless File.exist?(yaml_file)

  begin
    yaml_data = YAML.load_file(yaml_file)

    # Check if already encrypted
    first_account = yaml_data['accounts'].values.first
    return true if first_account['password'].is_a?(Hash) && first_account['password']['iv']

    # Encrypt all plaintext passwords
    yaml_data['accounts'].each do |_username, account_data|
      if account_data['password'] && !account_data['password'].is_a?(Hash)
        account_data['password_encrypted'] = PasswordCipher.encrypt(account_data['password'])
        account_data['encryption_version'] = 1
        account_data.delete('password')  # Remove plaintext
      end
    end

    # Save with restricted permissions
    File.write(yaml_file, YAML.dump(yaml_data), mode: 0600)

    Lich.log "info: Passwords migrated to encrypted format"
    true
  rescue => e
    Lich.log "error: Failed to migrate passwords: #{e.message}"
    false
  end
end
```

Call during initialization:
```ruby
def initialize_login_state
  # ... existing code ...

  # Auto-migrate plaintext passwords on first run
  YamlState.migrate_plaintext_to_encrypted(DATA_DIR)

  @entry_data = YamlState.load_saved_entries(DATA_DIR, @autosort_state)
end
```

#### Phase 6: Testing (2-3 hours)

**Test scenarios:**
1. ✅ Load plaintext passwords (legacy migration)
2. ✅ Save new passwords encrypted
3. ✅ Decrypt passwords on demand (no UI change)
4. ✅ One-click play with encrypted password
5. ✅ Password saving from manual entry
6. ✅ Favorite functionality with encrypted passwords
7. ✅ File permissions set to 0600
8. ✅ YAML file created with encryption metadata

---

## IMPLEMENTATION TRACKING

### Current Status

| Item | Status | Priority | Effort | Notes |
|------|--------|----------|--------|-------|
| **Password Encryption** | 🟡 Planned | CRITICAL | 8-12h | See detailed plan above |
| @default_icon initialization | ✅ Ready | CRITICAL | 30m | Simple fix |
| Remove debug output | ✅ Ready | CRITICAL | 15m | Remove pp statement |
| Path validation | ✅ Ready | HIGH | 1-2h | Add path sanitization |
| Reduce parameters | 🟡 Planned | HIGH | 6-8h | Configuration object |
| Error dialog extraction | ✅ Ready | HIGH | 2-3h | DRY up duplicates |
| Consolidate sorting | 🟡 Planned | MEDIUM | 2-3h | Eliminate duplication |
| Extract theme logic | 🟡 Planned | MEDIUM | 3-4h | DRY up theming |
| Break apart classes | 🟡 Planned | MEDIUM | 16-20h | Major refactor |
| Callback segregation | 🟡 Planned | MEDIUM | 4-6h | Follow ISP |
| Input validation | 🟡 Planned | LOW | 2-3h | Security hardening |
| Data sanitization | ✅ Ready | LOW | 1-2h | Simple logging fix |

---

## DOCUMENT HISTORY

- **2025-10-30:** Initial assessment completed - Senior Architect Review
- **Sections:** Executive Summary, SOLID Analysis (5 principles), Security Analysis (7 issues), Code Quality (findings), Recommendations (4 priorities), Password Encryption Plan (detailed)

