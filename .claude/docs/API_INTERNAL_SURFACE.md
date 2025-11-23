# Internal API Surface - Lich 5 Password Encryption

**Document Purpose:** Document internal interfaces between password encryption modules
**Last Updated:** 2025-11-23
**Audience:** Developers working on password encryption implementation
**Status:** Specification for current implementation

---

## Overview

Internal APIs are used by password encryption modules to coordinate encryption, key derivation, and keychain operations. These interfaces are NOT part of the public API and should not be called from outside the encryption module suite.

### Module Dependencies

```
YamlState
  ├── PasswordCipher (encrypt/decrypt)
  ├── MasterPasswordManager (keychain operations)
  └── ValidationTest (master password validation)

AccountManager
  ├── YamlState (save/load)
  └── PasswordCipher (when updating passwords)

EncryptedEntry
  └── PasswordCipher (transparent decryption)
```

---

## PasswordCipher Internal API

**Location:** `lib/common/gui/password_cipher.rb`

### Key Derivation (Internal)

#### `self.derive_key(password, salt, iterations) -> String`

Derives encryption key from password using PBKDF2.

**Access Level:** Private (only used internally)

**Parameters:**
- `password` (String) - Password or master password
- `salt` (String) - Salt string for PBKDF2
- `iterations` (Integer) - Number of PBKDF2 iterations

**Returns:**
- String (32 bytes) - Derived key

**Algorithm:**
```
Key = PBKDF2-HMAC-SHA256(
  password:
  password_or_master_password,
  salt:
  salt,
  iterations:
  iterations,
  length:
  32  # 256 bits for AES-256
)
```

**Example (internal use only):**
```ruby
# Never call directly - used internally by encrypt/decrypt
key = PasswordCipher.send(:derive_key, "DOUG", "lich5-login-salt-v1", 10_000)
```

---

### Mode-Specific Key Derivation

#### Standard Mode (Account Name)

```ruby
salt = 'lich5-login-salt-v1'
key = derive_key(account_name, salt, 10_000)
```

**Properties:**
- Deterministic (same account name always produces same key)
- Cross-device (any device can decrypt with same account name)
- No additional secrets needed

---

#### Enhanced Mode (Master Password)

```ruby
salt = 'lich5-login-salt-v1'
key = derive_key(master_password, salt, 10_000)
```

**Properties:**
- Depends on master password
- Requires master password to decrypt
- Different per user (different master password = different key)

---

#### Validation Test Mode (Enhanced Mode Only)

```ruby
validation_salt = random_32_bytes  # generated per file
validation_key = derive_key(master_password, validation_salt, 100_000)
validation_hash = SHA256(validation_key)
```

**Properties:**
- Uses 100,000 iterations (security-first, one-time operation)
- Random salt per file (prevents rainbow table attacks)
- Stored in entry.yaml for password validation

---

### IV Management (Internal)

#### `self.generate_iv -> String`

Generates random IV for encryption.

**Returns:**
- String (16 bytes) - Random initialization vector

**Encoding:** Base64 when stored

**Fresh IV Per Operation:** Each encrypt() call generates new IV

**Example:**
```ruby
# Internal - used by encrypt method
iv = PasswordCipher.send(:generate_iv)
# => "x8KpP2VGnqI7LM3wQRsT1A=="
```

---

## MasterPasswordManager Internal API

**Location:** `lib/common/gui/master_password_manager.rb`

### Keychain Service Names

#### Service Name Constant

```ruby
KEYCHAIN_SERVICE = 'lich5.master_password'
```

**Properties:**
- Fixed name (same across all Lich installations)
- Multi-installation support: Only retrieves if file's security_mode = :enhanced

**Keychain Keys by Platform:**
- macOS: `security` command via Keychain.app
- Linux: `secret-tool` command via libsecret/GNOME Keyring
- Windows: Not yet implemented

---

### Keychain Operations (Internal)

#### `self.store_in_keychain(service, password) -> Boolean`

Platform-specific keychain storage.

**Access Level:** Private (only MasterPasswordManager uses)

**Parameters:**
- `service` (String) - Service name (typically KEYCHAIN_SERVICE)
- `password` (String) - Master password to store

**Returns:**
- Boolean - true if successful

**Platform Implementation:**

**macOS:**
```bash
echo "PASSWORD" | security add-generic-password -s SERVICE -w -
```

**Linux:**
```bash
secret-tool store --label SERVICE lich5 master_password PASSWORD
```

**Error Handling:**
- Returns false if keychain unavailable
- Logs error for debugging
- Graceful fallback to password prompts

---

#### `self.retrieve_from_keychain(service) -> String or nil`

Platform-specific keychain retrieval.

**Parameters:**
- `service` (String) - Service name

**Returns:**
- String - Password from keychain
- nil - Service/password not found

**Platform Implementation:**

**macOS:**
```bash
security find-generic-password -s SERVICE -w
```

**Linux:**
```bash
secret-tool lookup lich5 master_password
```

---

#### `self.delete_from_keychain(service) -> Boolean`

Platform-specific keychain deletion.

**Parameters:**
- `service` (String) - Service name

**Returns:**
- Boolean - true if deleted

**When Used:**
- When switching away from Enhanced mode
- When changing master password

---

### Platform Detection (Internal)

#### `self.macos_keychain_available? -> Boolean`

Checks for macOS Keychain availability.

**Implementation:**
```ruby
!!system('which security >/dev/null 2>&1')
```

**Caching:** Results cached (no repeated system calls)

---

#### `self.linux_keychain_available? -> Boolean`

Checks for Linux libsecret availability.

**Implementation:**
```ruby
!!system('which secret-tool >/dev/null 2>&1')
```

---

#### `self.windows_keychain_available? -> Boolean`

Checks for Windows Credential Manager.

**Current Status:** Returns false (not yet implemented)

**Future Implementation:**
```ruby
return false unless windows_10_or_later?
# PowerShell test for cmdkey availability
```

---

## YamlState Internal API

**Location:** `lib/common/gui/yaml_state.rb`

### YAML Structure

#### Entry Schema (All Modes)

```yaml
security_mode: plaintext|standard|enhanced
master_password_test:  # Enhanced mode only
  validation_salt: "base64_encoded_salt"
  validation_hash: "sha256_hash"
  validation_version: 1
accounts:
  ACCOUNT_NAME:
    password: "plaintext_only"  # Plaintext mode only
    password_encrypted:  # Standard/Enhanced modes
      iv: "base64_iv"
      ciphertext: "base64_ciphertext"
      version: 1
    characters:
      - char_name: "Name"
        game_code: "GS3"
        game_name: "GemStone IV"
        frontend: "avalon"
        is_favorite: true
        favorite_order: 1
```

---

### Internal Loading Process

#### `self.load_from_file -> Hash`

Raw YAML loading (before decryption).

**Access Level:** Private

**Returns:**
- Hash - Raw YAML data structure

**Process:**
1. Read entry.yaml
2. Parse YAML
3. Return raw data (passwords still encrypted)

---

#### `self.decrypt_passwords(raw_data, security_mode, **options) -> Hash`

Decrypts all passwords in loaded data.

**Access Level:** Private

**Parameters:**
- `raw_data` (Hash) - Loaded YAML structure
- `security_mode` (Symbol) - Encryption mode
- `options` (Hash) - Mode-specific options

**Returns:**
- Hash - Same structure with decrypted passwords

**Process:**
1. Iterate accounts
2. For each account, call PasswordCipher.decrypt()
3. Replace encrypted_password with plaintext password
4. Return modified structure

---

### Internal Saving Process

#### `self.encrypt_passwords(accounts, security_mode, **options) -> Hash`

Encrypts all passwords before saving.

**Access Level:** Private

**Parameters:**
- `accounts` (Hash) - Accounts with plaintext passwords
- `security_mode` (Symbol) - Encryption mode
- `options` (Hash) - Mode-specific options

**Returns:**
- Hash - Modified structure with encrypted passwords

**Process:**
1. Iterate accounts
2. For each account, call PasswordCipher.encrypt()
3. Replace plaintext password with encrypted structure
4. Return modified structure

---

#### `self.write_to_file(data) -> Boolean`

Writes encrypted data to entry.yaml.

**Access Level:** Private

**Side Effects:**
1. Creates backup: entry.yaml.bak
2. Writes entry.yaml
3. Sets file permissions: 0600 (Unix/macOS)

---

## EncryptedEntry Wrapper (Internal)

**Location:** `lib/common/gui/encrypted_entry.rb`

### Purpose

Transparent password decryption wrapper. Existing code accesses `entry[:password]` and receives plaintext transparently.

---

### Hash Interface Compatibility

#### Implemented Methods

```ruby
entry[:password]          # Returns decrypted password
entry.password            # Dot notation also works
entry[:characters]        # Non-password fields work normally
entry.keys                # Lists all keys
entry.each { |k, v| ... } # Iteration support
```

---

### Decryption Caching

#### Memory Management

**Behavior:**
- Plaintext password cached in memory after first access
- Remains in memory until GC (garbage collection)
- Not explicitly cleared (relies on GC)

**Rationale:**
- Passwords already in memory during authentication
- Attempting to zero memory is futile in Ruby
- GC handles memory lifecycle

---

## Validation Test Utilities (Internal)

**Location:** `lib/common/gui/master_password_manager.rb`

### PBKDF2 Validation

#### `self.derive_validation_key(password, salt) -> String`

Derives key for validation test.

**Algorithm:**
```
Key = PBKDF2-HMAC-SHA256(
  password: password,
  salt: salt,
  iterations: 100_000,
  length: 32
)
```

**Note:** Uses 100,000 iterations (not 10,000) for security-first validation

---

#### `self.hash_validation_key(key) -> String`

Hashes derived key for storage.

**Algorithm:**
```
Hash = SHA256(key)
```

**Purpose:**
- Prevent plaintext validation key storage
- Enable constant-time comparison

---

#### `self.constant_time_compare(hash1, hash2) -> Boolean`

Secure password comparison.

**Implementation:** Uses Ruby's `secure_compare` to prevent timing attacks

**Rationale:**
- Normal string comparison (`==`) is timing-dependent
- Attacker can brute-force passwords by measuring response time
- Constant-time comparison prevents this attack

---

## File Corruption Detection (Internal)

**Location:** `lib/common/gui/yaml_state.rb`

### Corruption Types & Detection

#### Type 1: YAML Parse Error

**Trigger:**
```ruby
YAML.load_file('entry.yaml') raises Psych::SyntaxError
```

**Handling:**
```ruby
begin
  data = YAML.load_file('entry.yaml')
rescue Psych::SyntaxError => e
  # File corrupted - offer backup restoration
  if File.exist?('entry.yaml.bak')
    # Offer to restore from backup
  end
end
```

---

#### Type 2: Decryption Failure

**Trigger:**
```ruby
PasswordCipher.decrypt(...) raises OpenSSL::Cipher::CipherError
```

**Causes:**
- Wrong master password (Enhanced mode)
- File tampering
- IV/ciphertext corruption

**Handling:**
- Enhanced mode: Suggest password recovery
- Other modes: Trigger password recovery workflow

---

#### Type 3: Both Files Corrupt

**Trigger:**
```ruby
both entry.yaml and entry.yaml.bak fail to load/decrypt
```

**Handling:**
- Offer "Re-enter Accounts" option
- Delete corrupted files
- Start fresh with manual entry

---

## Error Recovery Workflows (Internal)

### Master Password Recovery Flow

**Scenario:** Enhanced mode, master password forgotten/lost

**Process:**
1. Detect: `PasswordCipher.decrypt raises OpenSSL::Cipher::CipherError`
2. Prompt: "Cannot decrypt passwords"
3. Choice: "Select new encryption mode"
4. Re-entry: Prompt for each account password
5. Save: Create new entry.yaml with new mode
6. Backup: Save old file as `entry.yaml.unrecoverable.{timestamp}`

---

### Keychain Unavailable Fallback

**Scenario:** Linux, `secret-tool` not installed, but file is Enhanced mode

**Process:**
1. Load entry.yaml (encrypted)
2. Try: Retrieve from keychain → fails
3. Fallback: Prompt user for master password
4. Decrypt: Use user-entered password
5. Continue: Normal operation

---

## Testing Interfaces (Internal)

### Test Helpers

**Location:** `spec/support/password_encryption_helpers.rb`

#### `create_test_encrypted_password(password, mode, **options) -> Hash`

Creates test encrypted password structure.

**Used in:** RSpec tests

**Example:**
```ruby
encrypted = create_test_encrypted_password("password", :standard)
# Returns: { iv: "...", ciphertext: "...", version: 1 }
```

---

#### `create_test_account(name, password, **options) -> Hash`

Creates test account structure.

**Used in:** RSpec tests

**Example:**
```ruby
account = create_test_account("DOUG", "password")
# Returns: Account hash with encrypted password
```

---

## Implementation Notes

### Ruby Standard Library Usage

**No external gems required.**

**Used Standard Library:**
- `openssl` - AES-256-CBC encryption, PBKDF2, SHA256
- `digest` - SHA256 hashing
- `securerandom` - Random IV generation
- `base64` - IV/ciphertext encoding
- `yaml` - File format
- `fileutils` - File operations

---

### Performance Considerations

**Bottlenecks:**
- PBKDF2 key derivation (10k iterations = ~5ms per password)
- Validation test (100k iterations = ~50ms, one-time only)
- File I/O (entry.yaml read/write = ~100ms)

**Optimization Opportunities:**
- Parallel decryption (thread pool) - Not recommended for single-threaded GTK
- Key caching - Already done per-mode
- Lazy decryption - Not practical (all passwords needed for recovery)

---

### Thread Safety

**Current Status:** NOT thread-safe

**Thread-Unsafe Operations:**
- YamlState.save_entries
- YamlState.load_entries
- Keychain operations (platform-dependent)

**Safe Usage:** Call from main GTK thread only

---

## Future Internal Changes

### Planned Refactoring

**Phase 3 (Post-Beta):**
- Extract mode-specific logic into separate modules (StandardEncryption, EnhancedEncryption, SshKeyEncryption)
- Create EncryptionMode interface for extensibility

**Phase 4 (Post-Beta):**
- If SSH Key mode added: Add `SshKeyManager` module (similar to MasterPasswordManager)

---

**End of Internal API Surface**

