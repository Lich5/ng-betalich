# Work Unit: Extract Standard Encryption Mode (PR #1)

**Created:** 2025-11-09
**Estimated Effort:** 4-6 hours
**Branch:** `feat/password-encryption-standard`
**PR Title:** `feat(all): add standard password encryption mode`

---

## Starting Point

**Branch from:** `eo-996` (PR #7 - YAML foundation)
**Source material:** PR #38 branch `feat/password_encrypts`
**What exists in base:** YAML refactor, account management, plaintext storage only
**What you're adding:** Standard encryption mode (account-based AES-256-CBC)
**What you're excluding:** Enhanced mode, keychain integration, SSH key mode

---

## Prerequisites

- [x] PR #7 (`eo-996`) exists and is available
- [x] PR #38 (`feat/password_encrypts`) exists for extraction
- [x] Ruby environment set up (bundle installed)
- [ ] Branch created: `feat/password-encryption-standard` (you'll do this)

---

## Objective

Extract **Standard encryption mode only** from PR #38 into a standalone, testable PR that:
- Adds PasswordCipher with Plaintext + Standard modes
- Adds conversion dialog with 2 options (Plaintext, Standard)
- Supports password changes for Standard mode
- Passes all tests (380/380)
- Uses `:enhanced` terminology (NOT `:master_password`)

---

## Files to Extract from PR #38

### Category 1: New Files (Copy Entire File, Then Edit)

**Copy these files from PR #38:**
```bash
# From PR #38 branch feat/password_encrypts:
lib/common/gui/password_cipher.rb
spec/password_cipher_spec.rb
```

**Then perform surgical edits** (see "Code Surgery" section below)

---

### Category 2: Existing Files to Modify

**These files exist in PR #7 - add encryption integration:**

| File | Base (PR #7) | Changes from PR #38 | What to Add |
|------|--------------|---------------------|-------------|
| `lib/common/gui/yaml_state.rb` | Account management | Lines 155-163, 172-181 | `encrypt_password`, `decrypt_password` methods |
| `lib/common/gui/password_change.rb` | Password change UI | Lines 237-249, 274 | Standard encryption support in password change |
| `lib/common/gui/conversion_ui.rb` | Legacy conversion | Lines 94-100, 189-214 | Encryption mode selection (Plaintext, Standard only) |

**How to merge:**
1. Check out `eo-996` branch
2. Open each file
3. View corresponding file in PR #38 (use `git show feat/password_encrypts:path/to/file.rb`)
4. Manually copy relevant sections from PR #38 into PR #7 version
5. **Remove any Enhanced mode references** during copy

---

### Category 3: DO NOT COPY (Enhanced Mode Files)

**These files must NOT appear in PR #1:**
- ❌ `lib/common/gui/master_password_manager.rb`
- ❌ `lib/common/gui/master_password_prompt.rb`
- ❌ `lib/common/gui/master_password_prompt_ui.rb`
- ❌ `spec/master_password_manager_spec.rb`
- ❌ `spec/master_password_prompt_spec.rb`

**Verification:**
```bash
# Should return "file not found" for all:
ls lib/common/gui/master_password_manager.rb
ls lib/common/gui/master_password_prompt.rb
```

---

## Code Surgery Required

### 1. password_cipher.rb - Remove Enhanced Mode

**File:** `lib/common/gui/password_cipher.rb`

**Current PR #38 structure:**
```ruby
def self.encrypt(password, mode, key = nil)
  case mode
  when :plaintext
    password
  when :standard
    # ... standard implementation ...
  when :master_password   # ← REMOVE THIS
    # ... enhanced implementation ...
  when :enhanced          # ← This might exist if PR #38 was updated
    # ... enhanced implementation ...
  end
end
```

**What to do:**
1. **Remove** the `when :master_password` block entirely
2. **Remove** the `when :enhanced` block entirely (if exists)
3. **Keep** only `:plaintext` and `:standard` cases
4. **Remove** any helper methods that reference `:master_password` or `:enhanced`

**Verification after edit:**
```bash
grep -n "master_password" lib/common/gui/password_cipher.rb
# Expected: 0 results

grep -n ":enhanced" lib/common/gui/password_cipher.rb
# Expected: 0 results (except in comments explaining future modes)
```

---

### 2. password_cipher_spec.rb - Remove Enhanced Tests

**File:** `spec/password_cipher_spec.rb`

**What to remove:**
- All `describe 'master_password mode'` blocks
- All `describe 'enhanced mode'` blocks
- Any `it` examples that test `:master_password` or `:enhanced` modes

**What to keep:**
- All `describe 'standard mode'` blocks
- All `describe 'plaintext mode'` blocks
- Error handling tests (invalid mode, missing params)
- Edge case tests (special chars, unicode, long passwords)

**Verification after edit:**
```bash
grep -n "master_password" spec/password_cipher_spec.rb
# Expected: 0 results

grep -n ":enhanced" spec/password_cipher_spec.rb
# Expected: 0 results
```

---

### 3. conversion_ui.rb - Show Only 2 Options

**File:** `lib/common/gui/conversion_ui.rb`

**Current PR #38 shows 4 radio buttons:**
1. Plaintext
2. Standard
3. Master Password / Enhanced ← HIDE THIS
4. SSH Key (future, disabled) ← HIDE THIS

**What to do:**
- **Keep:** Plaintext radio button
- **Keep:** Standard radio button (set as default)
- **Remove/Comment out:** Enhanced/Master Password radio button
- **Remove/Comment out:** SSH Key radio button

**Result:**
User sees only 2 options:
- Plaintext (no encryption - least secure)
- Standard Encryption (basic encryption) ← DEFAULT SELECTED

**Verification:**
```bash
# Should find only 2 radio button definitions:
grep -n "Gtk::RadioButton" lib/common/gui/conversion_ui.rb | wc -l
# Expected: 2 (plaintext + standard)
```

---

### 4. Terminology Update: All Files

**Global find/replace:**

| Find | Replace | Scope |
|------|---------|-------|
| `:master_password` | `:enhanced` | All files (if any exist after surgery) |
| `master_password` (in comments) | `enhanced encryption` | Comments only |
| "Master Password" (UI strings) | "Enhanced Encryption" | UI labels |

**Exceptions (DO NOT REPLACE):**
- Literal password variables named `master_password` (OK if they hold a password value)
- Historical comments referencing PR #38

**Verification:**
```bash
# Should return 0 results in new code:
grep -r ":master_password" lib/common/gui/password_cipher.rb
grep -r ":master_password" spec/password_cipher_spec.rb

# Should return 0 results in new code:
grep -r "Master Password" lib/common/gui/conversion_ui.rb
```

---

## Implementation Steps

### Step 1: Create Branch
```bash
cd /home/user/ng-betalich
git fetch origin
git checkout eo-996
git pull origin eo-996
git checkout -b feat/password-encryption-standard
```

### Step 2: Extract password_cipher.rb
```bash
# View PR #38 version:
git show feat/password_encrypts:lib/common/gui/password_cipher.rb > /tmp/password_cipher_pr38.rb

# Copy to your branch:
cp /tmp/password_cipher_pr38.rb lib/common/gui/password_cipher.rb

# Now edit the file to remove Enhanced mode (see "Code Surgery" section)
# Use your preferred editor
```

### Step 3: Extract password_cipher_spec.rb
```bash
# View PR #38 version:
git show feat/password_encrypts:spec/password_cipher_spec.rb > /tmp/password_cipher_spec_pr38.rb

# Copy to your branch:
cp /tmp/password_cipher_spec_pr38.rb spec/password_cipher_spec.rb

# Edit to remove Enhanced mode tests
```

### Step 4: Update yaml_state.rb
```bash
# View PR #38 version:
git show feat/password_encrypts:lib/common/gui/yaml_state.rb > /tmp/yaml_state_pr38.rb

# Manually merge encryption methods into your existing yaml_state.rb
# Copy lines 155-163 (encrypt_password)
# Copy lines 172-181 (decrypt_password)
# Integrate into your file
```

### Step 5: Update conversion_ui.rb
```bash
# View PR #38 version:
git show feat/password_encrypts:lib/common/gui/conversion_ui.rb > /tmp/conversion_ui_pr38.rb

# Manually add encryption mode selection
# Add ONLY Plaintext + Standard radio buttons
```

### Step 6: Update password_change.rb
```bash
# View PR #38 version:
git show feat/password_encrypts:lib/common/gui/password_change.rb > /tmp/password_change_pr38.rb

# Add Standard mode encryption support
# Copy relevant sections (lines 237-249, 274)
```

### Step 7: Run Tests
```bash
bundle exec rspec
# Expected: 380/380 passing (or close - verify no new failures)
```

### Step 8: Run RuboCop
```bash
bundle exec rubocop lib/common/gui/password_cipher.rb
bundle exec rubocop spec/password_cipher_spec.rb
# Expected: 0 offenses
```

### Step 9: Verify Clean Extraction
```bash
# Should return 0 results:
grep -r "master_password" lib/ spec/ | grep -v "Binary"

# Should return 0 results:
grep -r ":enhanced" lib/ | grep -v "comment about future"

# Should NOT have these files:
ls lib/common/gui/master_password_manager.rb
# Expected: No such file or directory
```

### Step 10: Commit
```bash
git add .
git commit -m "$(cat <<'EOF'
feat(all): add standard password encryption mode

Adds AES-256-CBC encryption for account passwords:
- Plaintext mode (no encryption, backward compatible)
- Standard mode (account-based key derivation)
- Conversion dialog for encryption mode selection
- Password change support for encrypted passwords
- Comprehensive test coverage (Standard mode only)

Enhanced mode (keychain-based) will be added in subsequent PR.

Related: BRD Password Encryption Phase 2 (Standard Mode)
EOF
)"
```

### Step 11: Push
```bash
git push -u origin feat/password-encryption-standard
```

---

## Acceptance Criteria

### Code Quality
- [ ] Branch created: `feat/password-encryption-standard` from `eo-996`
- [ ] All files extracted per map above
- [ ] Enhanced mode fully removed (grep verification passes)
- [ ] Terminology updated (`:master_password` → `:enhanced` if any remain)
- [ ] No master_password_manager.rb or related files present

### Functionality
- [ ] PasswordCipher supports `:plaintext` mode (passthrough)
- [ ] PasswordCipher supports `:standard` mode (AES-256-CBC)
- [ ] Conversion dialog shows 2 options: Plaintext, Standard
- [ ] Standard mode selected by default
- [ ] Plaintext warning dialog shown if user selects Plaintext
- [ ] Password change works for Standard mode
- [ ] Encryption/decryption transparent to user

### Tests
- [ ] 380/380 RSpec tests pass (or all existing tests + new Standard tests)
- [ ] `password_cipher_spec.rb` has comprehensive Standard mode coverage
- [ ] No Enhanced mode tests present
- [ ] Platform compatibility tests pass (all OS)

### Code Standards
- [ ] RuboCop clean: 0 offenses
- [ ] YARD documentation present on new methods
- [ ] Inline comments explain encryption flow
- [ ] Code follows SOLID + DRY principles

### Git Hygiene
- [ ] Conventional commit message: `feat(all): add standard password encryption mode`
- [ ] Branch pushed: `git push -u origin feat/password-encryption-standard`
- [ ] No merge conflicts with PR #7 base
- [ ] Clean diff (only adds Standard mode, doesn't modify unrelated code)

### Verification Commands
```bash
# All should pass:
grep -r "master_password" lib/ spec/ | wc -l  # Expected: 0
ls lib/common/gui/master_password_manager.rb   # Expected: not found
bundle exec rspec                               # Expected: 380/380 pass
bundle exec rubocop                             # Expected: 0 offenses
git log --oneline -1                            # Expected: feat(all): ...
```

---

## What Comes Next

**After this PR is complete and reviewed:**
- ✅ PR #1 ready for beta testing (Plaintext + Standard modes)
- ⏭️ **Next work unit:** ENHANCED_CURRENT.md (builds on this branch)
- 🚫 **Do not start next work unit** until PR #1 tests pass and is pushed

**Dependencies:**
- PR #2 (Enhanced mode) will branch from this PR's branch
- Windows keychain work (existing CURRENT.md) goes into PR #2
- This PR must be complete and stable first

---

## Troubleshooting

### "Tests failing after extraction"
- Verify you removed ALL Enhanced mode code from password_cipher.rb
- Check that conversion_ui.rb doesn't reference Enhanced option
- Ensure no lingering `:master_password` symbols

### "RuboCop offenses"
- Run `bundle exec rubocop -A` to auto-correct
- Review remaining offenses manually
- Justify any intentional violations in comments

### "Merge conflicts with PR #7"
- You branched from wrong base - should be `eo-996`
- Delete branch and restart from Step 1

### "Can't find files in PR #38"
- Verify PR #38 branch exists: `git branch -a | grep password_encrypts`
- Fetch latest: `git fetch origin`
- Use `git show` commands from Step 2-6

---

## Context References

**Read before starting:**
- `.claude/docs/CLI_PRIMER.md` - Ground rules, commit standards
- `.claude/docs/ADR_SESSION_011C_TERMINOLOGY.md` - Terminology decisions
- `.claude/docs/ADR_SESSION_011C_PR_DECOMPOSITION.md` - Why this decomposition
- `.claude/docs/BRD_Password_Encryption.md` - Requirements (Phase 2: Standard)

---

**END OF WORK UNIT**

When complete, archive this file to `.claude/docs/archive/STANDARD_EXTRACTION_COMPLETED.md` and await next work unit.
