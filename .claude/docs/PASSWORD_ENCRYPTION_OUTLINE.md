# Password Encryption Implementation - High-Level Outline

## VISION

Encrypt stored passwords while maintaining:
- **Zero UI/UX changes** - User sees no difference, no additional dialogs
- **One-click functionality** - "Play" button decrypts transparently
- **Backward compatibility** - Existing plaintext passwords auto-migrate
- **Zero regression** - All existing workflows continue unchanged

---

## ARCHITECTURE OVERVIEW

```
┌─────────────────────────────────────────────────────────────┐
│                    GUI Login Tabs                           │
│                                                             │
│  SavedLoginTab         ManualLoginTab       AccountManagerUI│
│      │                      │                     │         │
│      └──────────┬───────────┘                     │         │
│                 │ (uses entry data)               │         │
│                 ▼                                 │         │
│         ┌─────────────────┐                       │         │
│         │  Entry Objects  │                       │         │
│         │ (EncryptedEntry)│◄──────────────────────┘         │
│         └─────────┬───────┘                                 │
│                   │ (transparent password access)           │
│                   ▼                                         │
│         ┌─────────────────────┐                             │
│         │  PasswordCipher     │                             │
│         │  .decrypt(data)     │                             │
│         └────────┬────────────┘                             │
│                  │                                         │
│                  ▼                                         │
│         Plaintext Password (RAM only, never stored)        │
│                  │                                         │
│                  ▼                                         │
│         EAccess.auth(account, password)                    │
│         ├─ Sent to game server via HTTPS                  │
│         └─ Never written to disk                          │
│                                                            │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│              Storage Layer                                 │
│                                                             │
│  entry.yaml (Disk - Encrypted)                            │
│  ────────────────────────────────────                      │
│  accounts:                                                  │
│    ACCOUNT1:                                                │
│      password_encrypted:                                    │
│        iv: "BASE64_ENCODED_IV"                             │
│        ciphertext: "BASE64_ENCODED_CIPHERTEXT"             │
│      encryption_version: 1                                  │
│      characters:                                            │
│        - char_name: Mychar                                 │
│          game_code: GS3                                    │
│                                                             │
│  File permissions: 0600 (rw-------)                        │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## KEY DESIGN PRINCIPLES

### 1. **Transparent Decryption**

```ruby
# User code doesn't change at all:
entry[:password]  # Returns plaintext, automatically decrypted

# Decryption happens transparently in EncryptedEntry:
def password
  @decrypted_password ||= PasswordCipher.decrypt(@password_encrypted)
end
```

**Result:** All existing code (`authentication.rb`, `login_tab_utils.rb`, etc.) works unchanged.

### 2. **No Key Management Complexity**

```
Key Seed = "USERNAME:HOSTNAME"
        ↓ (PBKDF2, 100,000 iterations)
        ↓
Encryption Key (256-bit)
```

**Result:** Same key on same machine for same user, deterministic, no external key storage needed.

### 3. **Layered Migration**

```
Step 1: Read plaintext passwords from entry.yaml
        ↓
Step 2: Auto-encrypt on load (if not already encrypted)
        ↓
Step 3: Save back encrypted
        ↓
Step 4: Next app startup, loads already-encrypted version
```

**Result:** No breaking changes, no user intervention needed.

### 4. **Zero Password in Logs/Memory**

```
Encrypted Form: Stored in YAML, encrypted in memory
Decrypted Form: Only in RAM, only when needed for auth, then discarded
                Never written to disk, never logged, never cached
```

**Result:** Even if logs are compromised, credentials are safe.

---

## IMPLEMENTATION BREAKDOWN

### Layer 1: Encryption Utilities (NEW FILE)

**File:** `lib/common/gui/password_cipher.rb` (70-100 lines)

```ruby
class PasswordCipher
  ALGORITHM = 'aes-256-cbc'
  ITERATIONS = 100000

  def self.encrypt(password)
    # Returns: { iv: "...", ciphertext: "..." }
  end

  def self.decrypt(encrypted_hash)
    # Returns: plaintext password
  end

  private

  def self.derive_key(seed)
    # PBKDF2 key derivation
  end

  def self.default_key_seed
    # Deterministic key from machine + user
  end
end
```

**Purpose:** Single source of truth for all encryption/decryption logic

---

### Layer 2: Entry Wrapper (NEW FILE)

**File:** `lib/common/gui/encrypted_entry.rb` (80-120 lines)

```ruby
class EncryptedEntry
  def initialize(entry_hash)
    # Store encrypted password, other fields
    @password_encrypted = entry_hash[:password_encrypted]
    @user_id = entry_hash[:user_id]
    # ... other attributes
  end

  def password
    # Transparently decrypt on access
    @decrypted_password ||= PasswordCipher.decrypt(@password_encrypted)
  end

  def [](key)
    # Support hash-like access for backward compatibility
    case key
    when :password then password
    when :user_id then @user_id
    # ... etc
    end
  end

  def to_h
    # For saving back to YAML (encrypted form)
  end
end
```

**Purpose:** Transparent decryption wrapper, maintains backward compatibility

---

### Layer 3: YamlState Modifications (EXISTING FILE)

**File:** `lib/common/gui/yaml_state.rb` (key changes)

```ruby
# Key changes:

# 1. Load method returns EncryptedEntry objects
def self.load_saved_entries(data_dir, autosort_state)
  yaml_data = YAML.load_file(...)
  entries = convert_yaml_to_legacy_format(yaml_data)
  encrypted_entries = entries.map { |e| EncryptedEntry.new(e) }
  sort_entries_with_favorites(encrypted_entries, autosort_state)
end

# 2. Save method encrypts passwords
def self.save_entries(data_dir, entry_data)
  encrypted_data = entry_data.map { |entry|
    password = entry.is_a?(EncryptedEntry) ? entry.password : entry[:password]
    {
      user_id: entry[:user_id],
      password_encrypted: PasswordCipher.encrypt(password),
      # ... other fields
    }
  }
  File.write(yaml_file, YAML.dump(encrypted_data), mode: 0600)
end

# 3. Auto-migration on first load
def self.migrate_plaintext_to_encrypted(data_dir)
  # Checks if already encrypted, if not, encrypts and saves
end
```

**Purpose:** Bridge between encrypted storage and decrypted usage

---

### Layer 4: File Permissions (EXISTING FILE)

**File:** `lib/common/gui/utilities.rb` (modification)

```ruby
def self.safe_file_operation(file_path, operation, content = nil)
  case operation
  when :write
    # Change from mode 'w' to mode 'w' with 0600 permissions
    File.open(file_path, 'w', 0600) do |file|
      file.write(content)
    end
    true
  end
end
```

**Purpose:** Ensure only user can read password file

---

### Layer 5: Initialization (EXISTING FILE)

**File:** `lib/common/gui-login.rb` (modification)

```ruby
def initialize_login_state
  # ... existing code ...

  # Auto-migrate plaintext passwords (one-time)
  Lich::Common::GUI::YamlState.migrate_plaintext_to_encrypted(DATA_DIR)

  # Load entries as EncryptedEntry objects
  @entry_data = Lich::Common::GUI::YamlState.load_saved_entries(DATA_DIR, @autosort_state)

  # ... rest unchanged
end
```

**Purpose:** Trigger migration and load encrypted entries

---

## WORKFLOW: ONE-CLICK PLAY EXAMPLE

### Current (Plaintext)

```
User clicks "Play"
  ↓
SavedLoginTab finds entry:
  entry = { user_id: "ACCOUNT", password: "MyPassword123" }
  ↓
Calls on_play callback with launch_data
  ↓
launch_data[:password] = "MyPassword123" (plaintext)
  ↓
EAccess.auth(...password: "MyPassword123"...)
  ↓
Sent to game server via HTTPS
```

### New (Encrypted, Zero Changes)

```
User clicks "Play"
  ↓
SavedLoginTab finds entry:
  entry = EncryptedEntry {
    @password_encrypted = { iv: "...", ciphertext: "..." }
  }
  ↓
Calls on_play callback with launch_data
  ↓
launch_data[:password] = entry[:password]
                         ↓
                    EncryptedEntry.password getter
                         ↓
                    PasswordCipher.decrypt(...)
                         ↓
                    Returns plaintext "MyPassword123"
  ↓
launch_data[:password] = "MyPassword123" (decrypted)
  ↓
EAccess.auth(...password: "MyPassword123"...)
  ↓
Sent to game server via HTTPS
```

**Key Point:** Tab code sees no difference - `entry[:password]` returns plaintext in both cases!

---

## WORKFLOW: SAVE NEW PASSWORD EXAMPLE

### Current (Plaintext)

```
User enters password in manual login
  ↓
ManualLoginTab saves to YAML:
  entry = {
    user_id: "ACCOUNT",
    password: "NewPassword456"  # plaintext saved to file
  }
  ↓
YamlState.save_entries(...entry_data...)
  ↓
File.write("entry.yaml", plaintext password)
```

### New (Encrypted)

```
User enters password in manual login
  ↓
ManualLoginTab saves to YAML:
  entry = {
    user_id: "ACCOUNT",
    password: "NewPassword456"  # still plaintext in memory
  }
  ↓
YamlState.save_entries(...entry_data...)
  ↓
For each entry:
  encrypted = PasswordCipher.encrypt(entry[:password])
  yaml_entry[:password_encrypted] = encrypted
  ↓
File.write("entry.yaml", encrypted password)
  ↓
File.chmod(0600) # Only user can read
```

**Key Point:** Code calling save_entries() doesn't change - it passes plaintext, YamlState encrypts on write!

---

## WORKFLOW: LOGIN WITH CHARACTER NAME ONLY

### New Capability (Optional Enhancement)

```
# Future: Support logging in with just character name
# (Password decryption handled automatically)

user_selects_character("Mychar")
  ↓
Entry found by character name:
  entry = EncryptedEntry {
    user_id: "ACCOUNT",
    @password_encrypted: {...}
  }
  ↓
Trigger login with entry
  ↓
EAccess.auth(
  account: entry[:user_id],           # "ACCOUNT"
  password: entry[:password],         # Auto-decrypts
  character: "Mychar"
)
  ↓
Password never explicitly shown, never typed, just used
```

---

## DATA MIGRATION PATH

### Scenario 1: Fresh Install

```
User starts Lich for first time
  ↓
No entry.yaml exists
  ↓
User manually enters login
  ↓
ManualLoginTab saves to YAML
  ↓
YamlState.save_entries() encrypts password
  ↓
entry.yaml created with encrypted password
```

### Scenario 2: Existing Installation (Plaintext)

```
User upgrades Lich
  ↓
initialize_login_state() called
  ↓
YamlState.migrate_plaintext_to_encrypted() runs
  ↓
Detects plaintext passwords in entry.yaml
  ↓
For each plaintext password:
  encrypted = PasswordCipher.encrypt(plaintext)

  Update YAML:
    password: "plaintext"          # ❌ REMOVED
    password_encrypted: {...}      # ✅ ADDED
    encryption_version: 1          # ✅ ADDED
  ↓
Save updated entry.yaml (encrypted)
  ↓
Next load, all passwords are encrypted
```

### Scenario 3: Already Encrypted (Idempotent)

```
User restarts Lich
  ↓
migrate_plaintext_to_encrypted() runs
  ↓
Detects encryption_version = 1
  ↓
Skips migration (already encrypted)
  ↓
Loads and uses encrypted entries
```

---

## FILE CHANGES SUMMARY

| File | Change Type | Impact | LOC |
|------|-------------|--------|-----|
| `password_cipher.rb` | NEW | Encryption/decryption | 80-100 |
| `encrypted_entry.rb` | NEW | Transparent wrapper | 80-120 |
| `yaml_state.rb` | MODIFIED | Load/save encrypted | +50-60 |
| `utilities.rb` | MODIFIED | File permissions | +5 |
| `gui-login.rb` | MODIFIED | Auto-migration | +3 |
| Tab files | NO CHANGE | Zero code changes | 0 |
| Authentication | NO CHANGE | Uses plaintext from wrapper | 0 |

**Total New Code:** ~160-220 lines
**Total Modified Code:** ~60 lines
**Tab Code Changes:** 0 lines (backward compatible)

---

## TESTING CHECKLIST

### Unit Tests (PasswordCipher)

- [ ] encrypt() produces consistent output for same input on same day
- [ ] decrypt() recovers original password
- [ ] decrypt() with wrong key raises error
- [ ] decrypt() with corrupted data raises error
- [ ] Special characters handled correctly
- [ ] Empty password handled
- [ ] Very long password (500+ chars) handled

### Integration Tests (YamlState)

- [ ] Load plaintext passwords from legacy entry.yaml
- [ ] Auto-migrate plaintext to encrypted format
- [ ] Encrypted entries loaded and return correct plaintext
- [ ] Save new entries encrypted
- [ ] Multiple accounts with different passwords
- [ ] File created with 0600 permissions
- [ ] Plaintext migration is idempotent (can run multiple times)

### UI Tests (Tabs)

- [ ] Saved login: one-click play with encrypted password
- [ ] Manual login: save new password encrypted
- [ ] Favorites: add/remove favorites with encrypted passwords
- [ ] Account manager: show encrypted accounts
- [ ] Refresh: reload encrypted entries
- [ ] Theme change: works with encrypted entries
- [ ] Export/backup: encrypted file backup

### Regression Tests

- [ ] All existing workflows work unchanged
- [ ] No UI changes visible to user
- [ ] No additional dialogs or prompts
- [ ] Error messages clear if decryption fails
- [ ] Fallback to plaintext if decryption unavailable
- [ ] Performance impact negligible (<100ms per decrypt)

---

## FAILURE MODES & RECOVERY

### Issue: Cannot Decrypt Password

**Cause:** Wrong machine, wrong user, corrupted data

**Recovery:**
```ruby
def password
  @decrypted_password ||= begin
    PasswordCipher.decrypt(@password_encrypted)
  rescue => e
    Lich.log "error: Decryption failed: #{e.message}"
    nil  # Return nil, UI shows "password unavailable"
  end
end
```

**User Experience:** Entry appears but can't login with it, user re-enters password

### Issue: Migration Fails

**Cause:** Corrupted YAML, permission denied, disk full

**Recovery:**
```ruby
def self.migrate_plaintext_to_encrypted(data_dir)
  # Backup original before migration
  backup_file = "#{yaml_file}.backup"
  FileUtils.cp(yaml_file, backup_file) if File.exist?(yaml_file)

  begin
    # ... migration logic ...
  rescue => e
    # Restore from backup
    FileUtils.cp(backup_file, yaml_file) if File.exist?(backup_file)
    Lich.log "error: Migration failed, restored backup: #{e.message}"
  end
end
```

**User Experience:** Automatic rollback if migration fails, no data loss

---

## PERFORMANCE IMPACT

### Encryption Cost

- **Encrypt:** ~5-10ms per password (PBKDF2 with 100k iterations)
- **Decrypt:** ~5-10ms per password (same PBKDF2)
- **First load:** +100-200ms (one-time key derivation + PBKDF2)
- **Subsequent loads:** Negligible (key cached in memory)

**Acceptable?** YES - User won't notice, happens once at startup

### Memory Impact

- **Plaintext passwords in memory:** Only during active use
- **Decrypted password lifetime:** Until next GC or manual clear
- **Typical impact:** <50KB (even 1000 characters × 1000 accounts)

**Acceptable?** YES - Modern machines have plenty of memory

---

## SECURITY PROPERTIES

| Property | Status | Note |
|----------|--------|------|
| Passwords encrypted at rest | ✅ YES | AES-256-CBC |
| Passwords encrypted in transit | ✅ YES | Already using HTTPS |
| Passwords encrypted in memory | ✅ PARTIAL | Decrypted only when needed |
| Key management | ✅ DETERMINISTIC | Derived from machine+user |
| No hardcoded keys | ✅ YES | Key seed varies per machine |
| File permissions | ✅ 0600 | Only user can read |
| Backward compatible | ✅ YES | Auto-migrates |
| No external dependencies | ✅ YES | Uses Ruby standard library |
| Survives machine compromise | ⚠️ PARTIAL | But better than plaintext |

---

## IMPLEMENTATION ORDER

1. **Create `password_cipher.rb`** - Core encryption logic
2. **Create `encrypted_entry.rb`** - Transparent wrapper
3. **Modify `yaml_state.rb`** - Encryption on load/save
4. **Modify `utilities.rb`** - File permissions
5. **Modify `gui-login.rb`** - Auto-migration trigger
6. **Write tests** - Unit + integration
7. **Manual testing** - All workflows
8. **Deploy & monitor** - Watch for errors

---

## ROLLBACK PLAN

If encryption needs to be removed:

```ruby
# Temporary: In YamlState.load_saved_entries()
def self.decrypt_for_fallback(encrypted_hash)
  # Keep plaintext as fallback during decryption failure
  if encrypted_hash.is_a?(Hash) && encrypted_hash[:iv]
    PasswordCipher.decrypt(encrypted_hash)
  else
    encrypted_hash  # Assume plaintext
  end
end

# If we need to disable encryption entirely:
# 1. Modify save_entries() to write plaintext
# 2. Keep decrypt logic for reading
# 3. Eventually plaintext takes over
```

**Impact:** Low - Data remains readable, just stored differently

---

## SUCCESS CRITERIA

- ✅ All passwords encrypted in storage
- ✅ Zero UI/UX changes visible to users
- ✅ One-click play works without additional steps
- ✅ Existing plaintext passwords auto-migrate
- ✅ No code changes needed in tab implementations
- ✅ File permissions set to 0600
- ✅ All regression tests pass
- ✅ Performance impact < 200ms on load

