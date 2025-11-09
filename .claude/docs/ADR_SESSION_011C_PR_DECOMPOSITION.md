# ADR: PR #38 Decomposition Strategy for Beta Release

**Date:** 2025-11-09
**Status:** Accepted
**Session:** 011CUwNHp9TzigghtU94X9aZ
**Decision Makers:** Product Owner (Doug), Web Claude

---

## Context

PR #38 (`feat/password_encrypts`) is a monolithic implementation of password encryption containing:
- Standard encryption mode (account-based)
- Enhanced encryption mode (OS keychain-based)
- Partial Windows keychain support (stubbed)
- Password change UI
- Conversion dialog with mode selection
- Comprehensive test suite

**Problem:** PR #38 is too large to review effectively (~3,255 lines added across 17 files)

**Constraint:** Product Owner uses Release Please with single-trunk workflow. All PRs must:
1. Be independently testable with passing test suite
2. Be reviewable in isolation
3. Build on each other sequentially
4. Ship together in single 5.13.0 release (not multiple releases)

---

## Decision

**Decompose PR #38 into 5 sequential PRs following BRD phases:**

### PR #1: Standard Encryption Mode
- **Branch:** `feat/password-encryption-standard` (from PR #7 base)
- **Title:** `feat(all): add standard password encryption mode`
- **Scope:**
  - Plaintext + Standard modes only
  - PasswordCipher with `:plaintext` and `:standard` modes
  - Conversion dialog (2 options: Plaintext, Standard)
  - Password change support for Standard mode
  - Tests for Standard mode only
  - **Bonus:** Infomon test pollution fix
- **Excludes:** Enhanced mode, keychain integration, master password prompts

### PR #2: Enhanced Encryption Mode
- **Branch:** `feat/password-encryption-enhanced` (from PR #1)
- **Title:** `feat(all): add enhanced encryption with master password`
- **Scope:**
  - PasswordCipher `:enhanced` mode
  - OS keychain integration (macOS/Linux/Windows)
  - Windows 10+ PasswordVault implementation
  - Master password prompts
  - Conversion dialog adds Enhanced option
  - Platform-aware tests
- **Includes:** Complete Windows keychain (not stubbed)

### PR #3: SSH Key Mode + CLI Support
- **Branch:** `feat/password-encryption-ssh-key` (from PR #2)
- **Title:** `feat(all): add SSH key encryption and CLI support`
- **Scope:**
  - PasswordCipher `:ssh_key` mode
  - SSH key signature generation
  - SSH key selection UI
  - Conversion dialog adds SSH Key option
  - CLI password encryption support (non-GTK mode)
  - Tests for SSH Key mode and CLI

### Fix #1: Master Password Change UI
- **Branch:** `fix/change-enhanced-password` (from PR #2)
- **Title:** `fix(all): add master password change workflow`
- **Scope:**
  - "Change Master Password" button in Account Manager
  - Master password change dialog
  - Re-encrypt all accounts with new master password
  - Keychain update workflow
  - Tests

### Fix #2: SSH Key Change UI
- **Branch:** `fix/change-ssh-key` (from PR #3)
- **Title:** `fix(all): add SSH key change workflow`
- **Scope:**
  - "Change SSH Key" button in Account Manager
  - SSH key change dialog
  - Re-encrypt all accounts with new SSH key
  - Tests

---

## Git Branching Strategy

```
PR #7 (eo-996) - YAML Foundation
    ↓
PR #1 (feat/password-encryption-standard)
    ↓
PR #2 (feat/password-encryption-enhanced)
    ↓
PR #3 (feat/password-encryption-ssh-key)
    ↓
Fix #1 (fix/change-enhanced-password) [branches from PR #2]
    ↓
Fix #2 (fix/change-ssh-key) [branches from PR #3]
```

**Each PR diff shows only its additions** - making review clean and focused.

---

## Test Suite Strategy

**Critical:** Each PR must have **standalone passing test suite**

### PR #1: Standard Mode Tests
- Extract `password_cipher_spec.rb` from PR #38, **remove Enhanced mode tests**
- `yaml_state_spec.rb` - Standard encryption integration
- `password_change_spec.rb` - Standard mode password changes
- `conversion_ui_spec.rb` - Plaintext + Standard options only
- **Result:** 380/380 tests pass

### PR #2: Enhanced Mode Tests
- **Add back** Enhanced mode tests to `password_cipher_spec.rb`
- New: `master_password_manager_spec.rb` (keychain integration)
- New: `master_password_prompt_spec.rb` (password UI)
- Update: `conversion_ui_spec.rb` - add Enhanced option tests
- Platform-aware tests (Windows 10+ detection, keychain availability)
- **Result:** All PR #1 tests + new Enhanced tests pass

### PR #3: SSH Key + CLI Tests
- Add SSH Key mode tests to `password_cipher_spec.rb`
- New: `ssh_key_manager_spec.rb`
- New: CLI-specific password handling tests
- Update: `conversion_ui_spec.rb` - add SSH Key option tests
- **Result:** All prior tests + SSH/CLI tests pass

### Fix #1 & #2: Change Workflow Tests
- Separate test files for change workflows
- Integration tests for UI buttons
- Re-encryption verification tests

---

## Beta Testing Workflow

**Week 1:**
- Curate: PR #7 + PR #1 → `5.13.0-beta.0`
- Test: Plaintext + Standard encryption (all platforms)

**Week 2:**
- Add: PR #2 → `5.13.0-beta.1`
- Test: Enhanced mode (macOS/Linux/Windows 10+)

**Week 3:**
- Add: PR #3 + Fix #1 + Fix #2 → `5.13.0-beta.2`
- Test: All 4 modes + CLI + management UI

**Week 4+:**
- Bug fixes → `5.13.0-beta.3`, `.4` as needed
- Validation complete

**Final Release:**
- Merge all passing PRs → main (in sequence)
- Release Please accumulates all changes
- **ONE RP PR merge** → `5.13.0` stable release

---

## Rationale

### Why This Decomposition?

1. **Follows BRD Phases:** Plain → Standard → Enhanced → SSH Key (natural progression)
2. **Independent Value:** Each PR delivers testable functionality
3. **Clean Review:** Each PR shows only its additions (not entire codebase)
4. **Risk Mitigation:** Can beta test incrementally, catch issues early
5. **No Artificial Splits:** Features aren't split mid-implementation (PasswordCipher stays whole)

### Why Not Split Differently?

**Rejected: Split by file type** (cipher vs. UI vs. tests)
- Not independently testable
- Artificial separation

**Rejected: All modes in one PR**
- Too large to review (same problem as PR #38)
- Can't beta test incrementally

**Rejected: Split Enhanced mode from Windows keychain**
- Enhanced mode incomplete without Windows (80% of users)
- Better to deliver complete cross-platform Enhanced mode

---

## Consequences

### Positive
- Each PR is reviewable in 30-60 minutes
- Beta testing is incremental and controlled
- Can abandon features that don't pass beta (e.g., if SSH Key problematic)
- Clear progression for CLI Claude (work units are sequential)
- Single 5.13.0 release at end (not 5.13, 5.14, 5.15...)

### Negative
- More PRs to manage (5 instead of 1)
- Requires discipline to maintain branch chain
- Code extraction requires surgical edits (remove Enhanced from PR #1)
- Product Owner orchestrates beta train manually

### Mitigation
- Detailed work units guide CLI Claude through extraction
- Exit criteria checklists ensure quality at each step
- Session summary preserves context for future Web Claude sessions

---

## Implementation Notes

**PR #38 Disposition:**
- After extraction verified, close PR #38 as "superseded by #1, #2, #3"
- Product Owner will delete branch after 5.13.0 release

**Extraction Process:**
- CLI Claude executes extraction via work unit documentation
- Each work unit includes file-by-file extraction map
- Surgical edits documented explicitly (what to remove, what to keep)
- Verification commands provided (grep checks, test runs)

**Terminology Update:**
- All new PRs use `:enhanced` symbol (not `:master_password`)
- See ADR_SESSION_011C_TERMINOLOGY.md

---

## Related Decisions
- ADR_SESSION_011C_TERMINOLOGY.md - `:master_password` → `:enhanced`
- Work Units: STANDARD_EXTRACTION_CURRENT.md, ENHANCED_CURRENT.md, SSH_KEY_CURRENT.md

---

**Status:** Active - Begin execution with STANDARD_EXTRACTION_CURRENT.md
