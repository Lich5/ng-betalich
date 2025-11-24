# Public API Contract - Lich 5 Password Encryption

**Document Purpose:** Define the public API surface for password encryption feature
**Last Updated:** 2025-11-23
**Status:** Specification for current implementation

---

## Overview

The password encryption feature provides three main public APIs:

1. **Account Management API** - Add/update/delete accounts with encrypted passwords
2. **Encryption Mode Management API** - Switch encryption modes, change master passwords
3. **File Persistence API** - Save/load accounts with automatic encryption/decryption

---

## Account Management API

### PasswordCipher (Public Methods)

**Location:** `lib/common/gui/password_cipher.rb`

#### Class Methods

##### `self.encrypt(password, mode, **options) -> EncryptedPassword`

Encrypts a password for storage.

**Parameters:**
- `password` (String) - Plaintext password to encrypt
- `mode` (Symbol) - Encryption mode: `:plaintext`, `:standard`, `:enhanced`
- `options` (Hash) - Mode-specific options:
  - For `:standard`: none required
  - For `:enhanced`: `master_password: "string"` required

**Returns:**
- `EncryptedPassword` object with `iv` and `ciphertext` fields

**Raises:**
- `ArgumentError` - Invalid mode or missing required options
- `OpenSSL::Cipher::CipherError` - Encryption failed

**Example:**
```ruby
# Standard mode (account-name key)
encrypted = PasswordCipher.encrypt("secret123", :standard)

# Enhanced mode (master password key)
encrypted = PasswordCipher.encrypt("secret123", :enhanced, master_password: "mypass")

# Plaintext mode (no encryption)
encrypted = PasswordCipher.encrypt("secret123", :plaintext)
```

**Consistency:** Idempotent - same password + mode returns same ciphertext (different IV each time, but decryption always succeeds)

---

##### `self.decrypt(encrypted_password, mode, **options) -> String`

Decrypts a password for use.

**Parameters:**
- `encrypted_password` (EncryptedPassword or Hash) - Encrypted password with `iv` and `ciphertext`
- `mode` (Symbol) - Encryption mode used during encryption
- `options` (Hash) - Mode-specific options:
  - For `:standard`: none required
  - For `:enhanced`: `master_password: "string"` required

**Returns:**
- String - Plaintext password

**Raises:**
- `ArgumentError` - Invalid mode or missing required options
- `OpenSSL::Cipher::CipherError` - Decryption failed (tampering detected or wrong password)

**Example:**
```ruby
# Decrypt standard mode
plaintext = PasswordCipher.decrypt(encrypted, :standard)

# Decrypt enhanced mode
plaintext = PasswordCipher.decrypt(encrypted, :enhanced, master_password: "mypass")

# Plaintext mode (returns as-is)
plaintext = PasswordCipher.decrypt(encrypted, :plaintext)
```

---

### Account Manager (Public Methods)

**Location:** `lib/common/gui/account_manager.rb`

#### Class Methods

##### `self.add_or_update_account(account_name, password, encryption_mode, **options) -> Boolean`

Adds or updates an account with encrypted password.

**Parameters:**
- `account_name` (String) - Game account name (e.g., "DOUG", "EBONDEMON")
- `password` (String) - Plaintext password to encrypt and store
- `encryption_mode` (Symbol) - `:plaintext`, `:standard`, `:enhanced`
- `options` (Hash) - Mode-specific:
  - For `:enhanced`: `master_password: "string"` required

**Returns:**
- Boolean - true if successful, false if failed

**Side Effects:**
- Creates/updates entry in in-memory account list
- Saves updated `entry.yaml` with encrypted password
- Creates backup file `entry.yaml.bak`

**Example:**
```ruby
AccountManager.add_or_update_account("DOUG", "MyPassword", :standard)
# => true (account added/updated, entry.yaml saved)

AccountManager.add_or_update_account("DOUG", "NewPassword", :enhanced, master_password: "mypass")
# => true
```

---

##### `self.get_password(account_name, encryption_mode, **options) -> String`

Retrieves plaintext password for account.

**Parameters:**
- `account_name` (String) - Account to retrieve
- `encryption_mode` (Symbol) - Encryption mode currently in use
- `options` (Hash) - Mode-specific options

**Returns:**
- String - Plaintext password

**Raises:**
- `KeyError` - Account not found
- `OpenSSL::Cipher::CipherError` - Decryption failed

**Example:**
```ruby
password = AccountManager.get_password("DOUG", :standard)
# => "MyPassword"
```

---

## Encryption Mode Management API

### Master Password Manager (Public Methods)

**Location:** `lib/common/gui/master_password_manager.rb`

#### Class Methods

##### `self.keychain_available? -> Boolean`

Checks if OS keychain is available on current system.

**Returns:**
- Boolean - true if keychain commands available, false otherwise

**Platforms:**
- macOS: Checks for `security` command
- Linux: Checks for `secret-tool` command
- Windows: Returns false (not yet implemented)

**Example:**
```ruby
if MasterPasswordManager.keychain_available?
  # Can use Enhanced mode with keychain
else
  # Will need to prompt for password each session
end
```

**Thread Safe:** Yes
**Caching:** Results cached (no repeated system calls)

---

##### `self.store_master_password(password) -> Boolean`

Stores master password in OS keychain.

**Parameters:**
- `password` (String) - Master password to store

**Returns:**
- Boolean - true if stored successfully, false if failed

**Side Effects:**
- Writes to OS keychain under service name "lich5.master_password"
- Creates validation test in entry.yaml

**Raises:**
- OSError - Keychain unavailable or write failed

**Example:**
```ruby
MasterPasswordManager.store_master_password("MyMasterPass123")
# => true
```

**Security Note:** Password stored in OS keychain, not in plaintext files

---

##### `self.retrieve_master_password -> String or nil`

Retrieves master password from OS keychain.

**Returns:**
- String - Master password from keychain, or nil if not found

**Side Effects:** None

**Raises:**
- OSError - Keychain read failed

**Example:**
```ruby
password = MasterPasswordManager.retrieve_master_password
# => "MyMasterPass123" or nil
```

---

##### `self.validate_master_password(password) -> Boolean`

Validates password against stored validation test.

**Parameters:**
- `password` (String) - Password to validate

**Returns:**
- Boolean - true if password matches validation test, false otherwise

**Algorithm:** PBKDF2 + SHA256 constant-time comparison

**Example:**
```ruby
if MasterPasswordManager.validate_master_password(entered_password)
  # Correct password, proceed with decryption
else
  # Wrong password, prompt user again
end
```

---

##### `self.create_validation_test(password) -> Hash`

Creates validation test for master password storage.

**Parameters:**
- `password` (String) - Master password to test

**Returns:**
- Hash with keys:
  - `:validation_salt` (String) - Base64-encoded random salt
  - `:validation_hash` (String) - SHA256(PBKDF2(password, salt, 100k))
  - `:validation_version` (Integer) - 1

**Example:**
```ruby
test = MasterPasswordManager.create_validation_test("MyPassword")
# Returns: {
#   validation_salt: "x8KpP2VGnqI7LM3wQRsT1A==",
#   validation_hash: "sha256hash...",
#   validation_version: 1
# }
```

---

## File Persistence API

### YamlState (Public Methods)

**Location:** `lib/common/gui/yaml_state.rb`

#### Class Methods

##### `self.load_entries -> Hash`

Loads all accounts from `entry.yaml` with automatic decryption.

**Returns:**
- Hash of `{ account_name => Account }`
- Passwords automatically decrypted based on security_mode
- Plaintext passwords transparently accessible

**Side Effects:** None

**Raises:**
- `Psych::SyntaxError` - YAML file corrupted
- `OpenSSL::Cipher::CipherError` - Decryption failed
- `FileNotFoundError` - entry.yaml not found

**Example:**
```ruby
accounts = YamlState.load_entries
# => {
#   "DOUG" => Account(password: "plaintext123", characters: [...]),
#   "EBONDEMON" => Account(password: "decrypted456", characters: [...])
# }

# Passwords automatically decrypted - existing code unchanged:
accounts["DOUG"].password  # => "plaintext123"
```

---

##### `self.save_entries(accounts) -> Boolean`

Saves all accounts to `entry.yaml` with automatic encryption.

**Parameters:**
- `accounts` (Hash) - `{ account_name => Account }`

**Returns:**
- Boolean - true if saved successfully

**Side Effects:**
- Writes entry.yaml
- Creates entry.yaml.bak backup
- Encrypts passwords based on security_mode
- Sets file permissions to 0600 (Unix/macOS)

**Raises:**
- `IOError` - Write failed
- `OpenSSL::Cipher::CipherError` - Encryption failed

**Example:**
```ruby
accounts["DOUG"].password = "NewPassword"
YamlState.save_entries(accounts)  # => true
# entry.yaml updated, passwords encrypted
```

---

##### `self.security_mode -> Symbol`

Returns current encryption mode.

**Returns:**
- Symbol: `:plaintext`, `:standard`, `:enhanced`

**Example:**
```ruby
YamlState.security_mode  # => :enhanced
```

---

##### `self.migrate_from_legacy(encryption_mode, **options) -> Boolean`

Migrates passwords from `entry.dat` (legacy format) to `entry.yaml`.

**Parameters:**
- `encryption_mode` (Symbol) - Target encryption mode
- `options` (Hash) - Mode-specific:
  - For `:enhanced`: `master_password: "string"` required

**Returns:**
- Boolean - true if migration successful

**Side Effects:**
- Creates new entry.yaml with encrypted passwords
- Preserves character metadata
- Leaves entry.dat unchanged
- Creates backup: entry.yaml.bak

**Raises:**
- `ArgumentError` - Invalid encryption mode
- `OpenSSL::Cipher::CipherError` - Encryption failed

**Example:**
```ruby
# Migrate to standard encryption
YamlState.migrate_from_legacy(:standard)  # => true

# Migrate to enhanced encryption
YamlState.migrate_from_legacy(:enhanced, master_password: "mypass")  # => true
```

---

## Data Model

### Account Structure

Accounts are Ruby Hash-like objects (via EncryptedEntry wrapper).

**Accessible Fields:**
```ruby
account[:password]           # String - plaintext (auto-decrypted)
account[:characters]         # Array<Character>
account[:characters][0][:char_name]
account[:characters][0][:game_code]
account[:characters][0][:game_name]
account[:characters][0][:frontend]
account[:characters][0][:is_favorite]
account[:characters][0][:favorite_order]
```

### Encrypted Password Structure

```ruby
encrypted_password = {
  iv: "base64_encoded_16_bytes",
  ciphertext: "base64_encoded_encrypted_data",
  version: 1
}
```

---

## Error Handling

### Common Exceptions

#### OpenSSL::Cipher::CipherError

Raised when decryption fails.

**Causes:**
- Wrong master password (Enhanced mode)
- File tampering (any mode)
- Corrupted IV or ciphertext

**User-Facing Recovery:**
- Suggest password recovery workflow
- Offer backup restoration

---

#### ArgumentError

Raised for invalid method arguments.

**Causes:**
- Invalid encryption mode
- Missing required options
- Invalid password format

**User-Facing Recovery:**
- Show error message
- Prompt to try again

---

#### OSError / SystemCallError

Raised when keychain operations fail.

**Causes:**
- Keychain service unavailable
- Permission denied
- System keychain locked

**User-Facing Recovery:**
- Graceful fallback (prompt for password)
- Log system error for debugging

---

## Usage Examples

### Complete Workflow: User Sets Up Enhanced Mode

```ruby
# 1. Migrate from legacy format
YamlState.migrate_from_legacy(:enhanced, master_password: "MyMasterPass123")

# 2. Store password in keychain (one-time per device)
MasterPasswordManager.store_master_password("MyMasterPass123")

# 3. Load accounts (automatic decryption)
accounts = YamlState.load_entries

# 4. Get plaintext password for authentication
password = accounts["DOUG"][:password]
# => "GamePassword123" (automatically decrypted)

# 5. Update account password
accounts["DOUG"][:password] = "NewGamePassword456"
YamlState.save_entries(accounts)
# => true (automatically re-encrypted)
```

### Workflow: User Forgets Master Password

```ruby
# 1. Decryption fails
accounts = YamlState.load_entries  # => OpenSSL::Cipher::CipherError

# 2. Initiate recovery
password = get_new_master_password_from_user()

# 3. Check if password correct (before storing in keychain)
if MasterPasswordManager.validate_master_password(password)
  MasterPasswordManager.store_master_password(password)
  accounts = YamlState.load_entries  # => success
else
  # Wrong password, try again
end
```

---

## Backward Compatibility

### Zero Regression Guarantee

**Existing Code Behavior:**
```ruby
# Old code accessing passwords directly - UNCHANGED
entry = @entries["DOUG"]
password = entry[:password]  # Works as before (transparently decrypted)
```

**No Code Changes Required** in:
- `SavedLoginTab`
- `ManualLoginTab`
- Authentication flow
- Character management

---

## Thread Safety

### Current Implementation

**NOT thread-safe** - designed for single-threaded GTK3 application

**Safe Patterns:**
- Call from main GTK thread only
- Serialize access to YamlState

**Unsafe Patterns:**
- Concurrent calls from multiple threads
- Background thread password operations

---

## Performance Guarantees

### Encryption/Decryption

- **Per-password:** < 10ms (with 10k PBKDF2 iterations)
- **100 accounts:** < 1 second total
- **Master password validation:** < 50ms (with 100k iterations)

### File I/O

- **Load entry.yaml:** < 500ms for 100 accounts
- **Save entry.yaml:** < 1 second for 100 accounts
- **Backup creation:** < 100ms

---

## Version Compatibility

**Target Ruby:** 3.1+
**Required Gems:** None (standard library only)
**GTK Version:** GTK3

---

## Future API Stability

### Planned Changes

**Phase 3 (Post-Beta):**
- New method: `change_encryption_mode(new_mode, **options)`
- New method: `change_master_password(old_password, new_password)`

**Phase 4 (Post-Beta):**
- New mode: `:ssh_key` (if implemented)
- New method: `change_ssh_key(new_key_path)`

---

## Support & Debugging

### Enabling Debug Logging

```ruby
YamlState.debug = true  # Enable verbose logging
```

### Common Issues

**Issue: "Cannot decrypt password"**
- Check: Is master password correct (Enhanced mode)?
- Check: Is entry.yaml corrupted?
- Check: Was entry.yaml created with different encryption mode?

**Issue: "Keychain not found"**
- Check: Is `secret-tool` (Linux) or `security` (macOS) installed?
- Fallback: Program will prompt for password each session

**Issue: "Permission denied on entry.yaml"**
- Check: File permissions (should be 0600)
- Check: User ownership of file

---

**End of Public API Contract**

