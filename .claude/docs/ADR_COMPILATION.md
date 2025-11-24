# Architecture Decision Record (ADR) Compilation

**Project:** Lich 5 Password Encryption Feature
**Last Updated:** 2025-11-23
**Document Purpose:** Complete, consolidated view of all architectural decisions

---

## Table of Contents

1. [ADR-001: Four Encryption Modes](#adr-001-four-encryption-modes)
2. [ADR-002: AES-256-CBC with PBKDF2 Key Derivation](#adr-002-aes-256-cbc-with-pbkdf2-key-derivation)
3. [ADR-003: Transparent Decryption via EncryptedEntry Wrapper](#adr-003-transparent-decryption-via-encryptedentry-wrapper)
4. [ADR-004: PBKDF2 Validation Test for Enhanced Mode](#adr-004-pbkdf2-validation-test-for-enhanced-mode)
5. [ADR-005: Combined Recovery Workflow](#adr-005-combined-recovery-workflow)
6. [ADR-006: Web Claude / CLI Claude Coordination via Shared Docs](#adr-006-web-claude--cli-claude-coordination-via-shared-docs)
7. [ADR-007: Conventional Commit Restriction (Temporary)](#adr-007-conventional-commit-restriction-temporary)
8. [ADR-008: Boolean Return Guarantee for Keychain Availability Detection](#adr-008-boolean-return-guarantee-for-keychain-availability-detection)
9. [ADR-009: PBKDF2 Runtime Iterations: 10,000 vs 100,000](#adr-009-pbkdf2-runtime-iterations-10000-vs-100000)
10. [ADR-010: SSH Key Encryption Mode Removal](#adr-010-ssh-key-encryption-mode-removal)
11. [ADR-011: Unified Standard+Enhanced PR Instead of Decomposition](#adr-011-unified-standardenhanced-pr-instead-of-decomposition)
12. [ADR-012: Encryption Mode Terminology Alignment](#adr-012-encryption-mode-terminology-alignment)

---

## ADR-001: Four Encryption Modes

**Date:** 2025-11-01
**Status:** Accepted
**Deciders:** Doug (Product Owner), Claude (Sonnet 4.5)

### Context

Lich 5 stores game account passwords in plaintext YAML files, creating security risk. User base has diverse needs:
- Accessibility users (screen readers) need plaintext file access
- Casual users need simplicity with better security than plaintext
- Power users need strong encryption without complexity
- Developers want SSH key-based encryption (no "another password")

### Decision

Implement four encryption modes:
1. **Plaintext** - No encryption (accessibility)
2. **Standard** - AES-256-CBC with account name as key (deterministic, cross-device)
3. **Enhanced** - AES-256-CBC with master password (strong, per-device setup)
4. **SSH Key** - AES-256-CBC with SSH key signature (developer workflow) [*Later removed - see ADR-010*]

### Consequences

**Positive:**
- Accommodates all user personas
- Provides upgrade path (plaintext → standard → enhanced)
- No breaking changes (plaintext remains supported)
- Developer-friendly option (SSH keys)

**Negative:**
- Increased complexity (4 modes vs 1)
- Testing overhead (each mode must be tested)
- UI complexity (mode selection, mode changes)

**Mitigations:**
- Phased implementation (Standard first, then Enhanced, then SSH)
- Clear UI guidance on mode selection
- Comprehensive testing per phase

---

## ADR-002: AES-256-CBC with PBKDF2 Key Derivation

**Date:** 2025-11-01
**Status:** Accepted
**Deciders:** Doug (Product Owner), Claude (Sonnet 4.5)

### Context

Need to choose encryption algorithm and key derivation approach. Requirements:
- Industry-standard security
- Ruby standard library only (no external gems)
- Performance acceptable (<100ms per password)
- Cross-platform (macOS, Windows, Linux)

### Decision

- **Algorithm:** AES-256-CBC
- **Key Derivation:** PBKDF2-HMAC-SHA256, 100,000 iterations
- **IV:** Random 16 bytes per encryption operation
- **Output:** Base64-encoded {iv, ciphertext}

### Consequences

**Positive:**
- AES-256-CBC is battle-tested, widely accepted
- PBKDF2 resists brute-force attacks
- Ruby standard library support (openssl)
- 100k iterations balance security vs performance
- Random IV per operation prevents pattern analysis

**Negative:**
- CBC mode requires careful IV handling
- PBKDF2 slower than modern alternatives (Argon2, scrypt)
- Performance overhead (~10-50ms per password)

**Alternatives considered:**
- AES-GCM: Better but requires Ruby 2.6+ gcm support
- Argon2: Better but requires external gem
- scrypt: Better but requires external gem

---

## ADR-003: Transparent Decryption via EncryptedEntry Wrapper

**Date:** 2025-11-01
**Status:** Accepted
**Deciders:** Doug (Product Owner), Claude (Sonnet 4.5)

### Context

Need to encrypt passwords without breaking existing code. Current code accesses passwords via `entry[:password]` and expects plaintext. Requirement: Zero regression on existing workflows.

### Decision

Create `EncryptedEntry` wrapper class that:
- Stores password in encrypted form
- Decrypts transparently when `entry[:password]` accessed
- Provides hash-like interface for backward compatibility
- Caches decrypted password in memory (until GC)

### Consequences

**Positive:**
- Zero code changes in tabs (SavedLoginTab, ManualLoginTab)
- Zero code changes in authentication flow
- Transparent migration (old code works unchanged)
- Centralized encryption logic
- Easy to test (wrapper is isolated)

**Negative:**
- Plaintext password in memory after first access
- Extra layer of indirection
- Must maintain hash-like interface compatibility

**Mitigations:**
- Memory risk acceptable (passwords already in memory during auth)
- Clear documentation on memory lifecycle
- Comprehensive compatibility tests

---

## ADR-004: PBKDF2 Validation Test for Enhanced Mode

**Date:** 2025-11-01
**Status:** Accepted
**Deciders:** Doug (Product Owner), Claude (Sonnet 4.5)

### Context

Enhanced mode stores master password in OS keychain. Risk: User enters wrong password during setup, gets stored in keychain, cannot decrypt existing passwords. Need validation before keychain storage.

### Decision

Store PBKDF2-based validation test in YAML:

```yaml
master_password_test:
  validation_salt: "random_32_bytes_base64"
  validation_hash: "SHA256(PBKDF2(master_password, salt, 100k, 32))"
  validation_version: 1
```

Before storing in keychain:
1. Derive key from entered password
2. Hash the derived key
3. Compare to stored validation_hash (constant-time)
4. Only store if match

### Consequences

**Positive:**
- Prevents wrong password in keychain
- Cryptographically sound (PBKDF2 + SHA256)
- Constant-time comparison prevents timing attacks
- Random salt per file (no rainbow tables)

**Negative:**
- Adds ~50ms to master password validation
- Additional YAML fields
- More complex setup flow

**Alternatives considered:**
- Encrypt sample data: Rejected (reveals plaintext structure)
- No validation: Rejected (user frustration if wrong password stored)

---

## ADR-005: Combined Recovery Workflow

**Date:** 2025-11-01
**Status:** Accepted
**Deciders:** Doug (Product Owner), Claude (Sonnet 4.5)

### Context

When decryption fails (forgot master password, lost SSH key, file corruption), user must re-enter all passwords. Question: Separate dialogs for mode selection and password entry, or combined?

### Decision

Combined workflow in single dialog sequence:
1. Show "Cannot decrypt passwords" message
2. List affected accounts
3. User selects NEW encryption mode (can be different)
4. Prompt for new mode credentials (if Enhanced/SSH)
5. Sequential prompts for each account password
6. Create new entry.yaml with new mode
7. Backup unrecoverable file with timestamp

### Consequences

**Positive:**
- Simpler UX (one workflow vs two)
- User makes all decisions upfront
- Clearer that this is a fresh start
- Can switch modes during recovery

**Negative:**
- Longer single workflow
- Cannot abort mid-recovery easily

**Mitigations:**
- Clear progress indication
- Allow cancel at any step (restart from beginning)

---

## ADR-006: Web Claude / CLI Claude Coordination via Shared Docs

**Date:** 2025-11-08
**Status:** Accepted
**Deciders:** Doug (Product Owner), Claude (Sonnet 4.5)

### Context

Two stateless AI agents must coordinate work:
- Web Claude (Sonnet): Architecture, planning, audit (cannot execute code)
- CLI Claude (Haiku): Execution, testing, commits (can access files)

Need shared context without conversational memory between sessions.

### Decision

Coordination via `.claude/docs/` and `.claude/work-units/`:
- `WEB_CONTEXT.md` - Web Claude session initialization
- `CLI_PRIMER.md` - CLI Claude ground rules
- `CURRENT.md` - Active work unit for CLI Claude
- `archive/` - Completed work units
- `DECISIONS.md` - ADR log

### Consequences

**Positive:**
- Both agents have clear context
- Work units are self-documenting
- Muscle memory initialization (`claude < CURRENT.md`)
- Historical record preserved
- No conversational state required

**Negative:**
- Extra documentation overhead
- Must keep docs in sync
- Both agents must read docs consistently

**Mitigations:**
- Templates reduce overhead
- Standardized session initialization patterns
- Commit standards enforce consistency

---

## ADR-007: Conventional Commit Restriction (Temporary)

**Date:** 2025-11-08
**Status:** Accepted (Temporary)
**Deciders:** Doug (Product Owner)

### Context

Workflow defect: `docs(gs):` pattern incorrectly triggered `prepare-stable` release workflow. Until defect fixed, need to restrict commit patterns.

### Decision

Allow ONLY these commit patterns:
- `feat(all|dr|gs): description` - Features (triggers release)
- `fix(all|dr|gs): description` - Bug fixes (triggers release)
- `chore(all): description` - Everything else

All other conventional commit types (`docs`, `refactor`, `perf`, etc.) must use `chore(all):` until workflow fixed.

### Consequences

**Positive:**
- Prevents unintended release triggers
- Simple rule (3 patterns only)
- Applies to both web and CLI Claude

**Negative:**
- Less granular commit types
- Changelog less detailed (all non-feat/fix as "chores")
- Temporary workaround vs proper fix

**Duration:** Until workflow defect repaired

---

## ADR-008: Boolean Return Guarantee for Keychain Availability Detection

**Date:** 2025-11-11
**Status:** Accepted
**Deciders:** Web Claude (auditor), Doug (Product Owner)

### Context

PR #55 (Enhanced encryption mode) includes keychain availability detection methods that use Ruby's `system()` method. In certain environments (broken/incomplete tooling), `system()` can return `nil` instead of just `true`/`false`.

### Decision

Apply boolean coercion operator (`!!`) to guarantee boolean return from keychain availability detection methods:
- `macos_keychain_available?` (line 126)
- `linux_keychain_available?` (line 149)

**Before:**
```ruby
private_class_method def self.macos_keychain_available?
  system('which security >/dev/null 2>&1')
end
```

**After:**
```ruby
private_class_method def self.macos_keychain_available?
  !!system('which security >/dev/null 2>&1')
end
```

### Rationale

**Why Make This Change:**
- **Defensive Programming:** Guarantees boolean return in all cases
- **Consistency:** Windows implementation already does this correctly
- **Robustness:** Handles broken/incomplete environments gracefully

**Ruby's system() Behavior:**
- Returns `true` if command exits with code 0
- Returns `false` if command exits with non-zero code
- Returns `nil` if command cannot be executed at all (broken environment)

The `!!` operator converts this:
- `nil` → `false` (gracefully treat as unavailable)
- `true` → `true`
- `false` → `false`

### Consequences

**Positive:**
- More robust to environmental edge cases
- Explicit boolean contract for all availability methods
- Consistent behavior across all platforms
- Minimal code change

**Negative:**
- `nil` normally indicates "something weird happened," but we hide it
- However, acceptable because code gracefully degrades anyway

---

## ADR-009: PBKDF2 Runtime Iterations: 10,000 vs 100,000

**Date:** 2025-11-13
**Status:** Accepted
**Deciders:** Doug (Product Owner), Claude (Sonnet 4.5)

### Context

BRD specifies PBKDF2-HMAC-SHA256 with **100,000 iterations** for encryption key derivation. However, Phase 1 implementation uses **10,000 iterations** for runtime password encryption, while validation test (one-time, setup only) correctly uses 100,000 iterations.

This appears as a discrepancy between ADR-002 specification and actual implementation.

### Decision

**Intentional Design Choice** — Use differentiated iteration counts based on threat model and performance context:

- **Validation Test (one-time, setup):** 100,000 iterations (security-critical, acceptable latency)
- **Runtime Encryption (frequent, per-password):** 10,000 iterations (balanced for UX, acceptable threat model)

### Rationale: Threat Modeling

**Primary Threat:** System-level file access (attacker reads YAML file from disk)

**Threat Analysis:**
- If attacker achieves system-level file access, they've already won
- They can also: read memory (intercept plaintext passwords), intercept network traffic, install keyloggers
- PBKDF2 iterations protect against offline brute-force only (attacker lacks system access)
- Against system-level threat, PBKDF2 strength is secondary concern

**Consequence of Design:**
- 10k iterations is 10x weaker than 100k against offline brute-force
- BUT: Offline brute-force is not the realistic threat
- System-level access is the threat, and at that point, PBKDF2 iterations are irrelevant
- User data at risk is game accounts (boutique games), not financial/critical infrastructure

**Performance Justification:**
- 100k iterations adds ~50ms per password operation (load, change, decrypt)
- 10k iterations adds ~5ms per password operation
- For 20-100 accounts, cumulative effect is noticeable
- User experience benefit (faster load, faster password changes) is real

### Consequences

**Positive:**
- Maintains acceptable security against system-level threat (the realistic threat)
- Improves application performance (faster password operations)
- Validation test still uses 100k (critical security-first operation)
- Differentiated approach is more nuanced than "all same"

**Negative:**
- Deviates from stated BRD specification (100k)
- Offline brute-force attack is theoretically 10x easier
- Inconsistency between validation (100k) and runtime (10k) requires explanation
- May surprise users expecting "100k iterations" security level

**Mitigations:**
- Document rationale clearly (this ADR)
- Threat model explanation in code comments (reference ADR-009)
- Validation test uses 100k (ensures setup is cryptographically robust)
- Reevaluate if performance becomes non-issue (move to 100k if warranted)

### Alternatives Considered

1. **Use 100k everywhere:**
   - ✓ Matches BRD exactly
   - ✗ Adds ~45ms per password operation (noticeable UX impact)
   - ✗ Validation test would be even slower (~100ms)

2. **Use 10k everywhere:**
   - ✓ Best performance
   - ✗ Weakens validation test (should be security-first)
   - ✗ Reduces defense against offline attack

3. **Differentiated approach (chosen):**
   - ✓ Balances security (validation) and performance (runtime)
   - ✓ Acknowledges realistic threat model
   - ✓ Validation test remains cryptographically strong
   - ✗ Inconsistency requires clear documentation

---

## ADR-010: SSH Key Encryption Mode Removal

**Date:** 2025-11-16
**Status:** DECIDED - REMOVED FROM SCOPE
**Decision Maker:** Product Owner (Doug)
**Documented By:** Web Claude

### Context

The original BRD specified **four encryption modes**, including SSH Key mode (ENC-4). This ADR documents the removal of SSH Key encryption from initial release scope.

### Decision

**SSH Key encryption mode (ENC-4) has been REMOVED from the project scope.**

**Affected BRD Sections:**
- FR-7: Change SSH Key (REMOVED)
- Phase 4: SSH Key Mode implementation (REMOVED from roadmap)
- Persona 4: Developer use case (SSH Key workflow removed)

### Rationale

**Reasons for Removal (Product Owner Decision):**

1. **Limited User Base**
   - SSH Key mode primarily benefits developers
   - Developer persona is smallest user segment
   - Most developers comfortable with Enhanced mode

2. **Complexity vs. Value**
   - Requires SSH key management education
   - Adds UI complexity for niche feature
   - Testing complexity (SSH key generation, rotation, etc.)

3. **Security Considerations**
   - Enhanced mode with strong master password provides equivalent security
   - OS keychain integration simplifies cross-device workflow
   - SSH key rotation adds operational complexity

4. **Scope Management**
   - Allows faster delivery of core features (Plaintext, Standard, Enhanced)
   - Reduces beta testing surface area
   - Can be added later if demand emerges

### Consequences

**Positive:**
✅ **Faster Time to Beta**
- Three modes instead of four reduces implementation time
- Fewer test scenarios
- Simpler UI (no SSH key file picker)

✅ **Reduced Complexity**
- No SSH key validation logic
- No SSH key fingerprint management
- No SSH key rotation workflow

✅ **Clearer User Experience**
- Three modes easier to explain (Plaintext, Standard, Enhanced)
- Reduced cognitive load during conversion dialog

**Negative:**
⚠️ **Developer Workflow**
- Developers must use master password (Enhanced mode)
- No SSH agent integration
- "Yet another password" concern remains

⚠️ **Future Feature Request**
- If users request SSH key mode, must be added post-release
- Would require architecture extension (but design already exists in BRD)

### Updated Encryption Modes

**In Scope (Implemented):**
| Mode | Description | Key Derivation | Cross-Device |
|------|-------------|----------------|--------------|
| **Plaintext** | No encryption | N/A | ✅ Seamless |
| **Standard** | Account-name key | PBKDF2(account_name, salt) | ✅ Seamless |
| **Enhanced** | Master password | PBKDF2(master_password, salt) | ⚠️ One-time prompt per device |

**Out of Scope (Removed):**
| Mode | Description | Status |
|------|-------------|--------|
| **SSH Key** | SSH key signature | ❌ **REMOVED FROM SCOPE** |

### Future Considerations

If SSH Key mode is requested later, implementation path exists:
1. Resurrect FR-7, Phase 4 specs from BRD
2. Implement `SshKeyManager` module
3. Add SSH key signature generation
4. Add UI for SSH key selection
5. Update conversion dialog to include SSH Key option

Estimated effort: 8-10 hours (per BRD Phase 4 estimate)

---

## ADR-011: Unified Standard+Enhanced PR Instead of Decomposition

**Date:** 2025-11-12
**Status:** Accepted
**Deciders:** Product Owner (Doug), Web Claude

### Context

Previous decomposition attempted to extract Standard and Enhanced modes into separate PRs. However, this approach created gaps because Standard and Enhanced are not cleanly separable in the original PR #38:
- Both depend on shared `PasswordCipher` module
- Both depend on `MasterPasswordManager` (keychain integration)
- Both are integrated into `YamlState` save/load workflow
- Both share encryption mode selection UI in `ConversionUI`

Attempting to extract incrementally introduced error-prone duplication and missed dependencies.

### Decision

**Move from 5-PR decomposition to unified 1-PR approach:**

1. **Phase 1 (Standard + Enhanced combined):** Copy all relevant files from PR #38 into single feature branch
   - Branch name: `feat/password-encryption-standard`
   - Starting point: `eo-996` (PR 7, YAML foundation)
   - Execution: Simple file copy
   - Verification: All tests pass, diff validates against PR #38
   - Result: Single, complete, testable PR

2. **Phase 2 (SSH Key mode):** Separate PR [*Note: SSH Key mode removed per ADR-010*]

3. **Phase 3 (Management UIs):** Fix PRs as needed

### Rationale

**Why Copy Works Better Than Extraction:**
- PR #38 already has working implementation + tests
- No logic complexity—just file duplication
- Verifiable: diffs must match PR #38 source
- GitHub runners will validate all tests pass
- Natural dependencies preserved automatically

**Why Extraction Failed:**
- Standard mode alone is incomplete without keychain infrastructure
- Enhanced mode can't be isolated without Standard mode's cipher logic
- Both depend on shared YAML integration
- Monolithic PR #38 doesn't have clean boundaries to extract along

### Consequences

**Positive:**
- Single feature (encryption foundation) is naturally cohesive
- Complete before/after state for testing
- No extraction gaps
- All 380+ tests run before merge

**Negative:**
- Larger PR (3,500+ lines) harder to review
- But single feature cohesion mitigates this

---

## ADR-012: Encryption Mode Terminology Alignment

**Date:** 2025-11-09
**Status:** Accepted
**Deciders:** Product Owner (Doug), Web Claude

### Context

The BRD Password Encryption specification and PR #38 implementation used inconsistent terminology:
- **BRD:** "Enhanced Mode" (ENC-3)
- **Code Implementation:** `:master_password` symbol and "Master Password" in UI

This created confusion during code review and documentation.

### Decision

**Standardize on "Enhanced" terminology across all code, documentation, and UI:**

**Code Changes:**
- Symbol: `:master_password` → `:enhanced`
- Method names: `master_password_*` → `enhanced_*` (where appropriate)
- Comments: "master password" → "enhanced encryption"
- Test descriptions: Update to use "enhanced" terminology

**UI Changes:**
- Dialog labels: "Master Password Encryption" → "Enhanced Encryption"
- Tooltips and help text: Align with "enhanced" terminology
- Error messages: Use "enhanced mode" language

**Exceptions (Keep "Master Password"):**
- **User-facing prompts:** "Enter Master Password" (clearer to users what they're entering)
- **Variable names for password values:** `master_password` variable OK when it literally holds the password value

### Rationale

1. **BRD Alignment:** BRD is the source of truth for requirements
2. **Avoid Confusion:** "Master Password" implies it unlocks everything (misleading - it's just one encryption mode)
3. **Future-Proofing:** "Enhanced" allows for future upgrades without terminology clash
4. **Consistency:** Single term across all artifacts reduces cognitive load

### Consequences

**Positive:**
- Clear alignment between BRD and implementation
- Easier code review (consistent terminology)
- Better user understanding (mode is "enhanced encryption", password is "master password")

**Negative:**
- Requires systematic rename across code
- Some internal implementation details may still use "master_password" for clarity

---

## Summary by Phase

### Phase 1: Standard Encryption (Complete)
- ADR-001: Four Encryption Modes (3 modes active after ADR-010)
- ADR-002: AES-256-CBC with PBKDF2
- ADR-003: Transparent Decryption via EncryptedEntry
- ADR-009: PBKDF2 Iterations (10k runtime, 100k validation)
- ADR-011: Unified PR approach
- ADR-012: Terminology alignment

### Phase 2: Enhanced Encryption (Complete)
- ADR-004: PBKDF2 Validation Test
- ADR-008: Boolean Return Guarantee for Keychain

### Phase 3: Mode Changes & Recovery (In Progress)
- ADR-005: Combined Recovery Workflow

### Organizational & Meta-Decisions
- ADR-006: Web/CLI Claude Coordination
- ADR-007: Commit Pattern Restriction
- ADR-010: SSH Key Mode Removal
- ADR-012: Terminology Alignment

---

## References & Related Documents

- **BRD:** `BRD_Password_Encryption.md` - Original functional requirements
- **Implementation Status:** `SESSION_STATUS.md` - Current phase status
- **Code Audit:** `AUDIT_*.md` - Quality assessments
- **Work Units:** `.claude/work-units/` - Execution tasks

---

## How to Use This Document

1. **Decision Lookup:** Use Table of Contents to find specific decision
2. **Understanding Rationale:** Read Context + Decision + Consequences sections
3. **Implementation Guidance:** Code locations and examples in each ADR
4. **Future Changes:** Reference ADR number in code comments when relevant
5. **Status Tracking:** Check Status field to know if decision is active, superseded, etc.

---

**Document Status:** COMPLETE
**Last Updated:** 2025-11-23
**Total ADRs:** 12
**Active Decisions:** 11 (1 removed per ADR-010)

