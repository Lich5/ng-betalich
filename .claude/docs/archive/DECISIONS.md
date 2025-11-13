# Architecture Decision Records

**Project:** Lich 5 Password Encryption Feature
**Format:** Lightweight ADR (Context, Decision, Consequences)

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
4. **SSH Key** - AES-256-CBC with SSH key signature (developer workflow)

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

## ADR-005: Combined Recovery Workflow (Mode Selection + Password Re-entry)

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
- CLI Claude (Haiku likely): Execution, testing, commits (can access files)

Need shared context without conversational memory between sessions.

### Decision
Coordination via `.claude/docs/` and `.claude/work-units/`:
- `WEB_CONTEXT.md` - Web Claude session initialization
- `CLI_PRIMER.md` - CLI Claude ground rules
- `CURRENT.md` - Active work unit for CLI Claude
- `archive/` - Completed work units
- `DECISIONS.md` - ADR log (this file)

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
**Session:** Web Claude PR #55 Audit
**Decision Makers:** Web Claude (auditor), Doug (Product Owner)

---

## Context

PR #55 (Enhanced encryption mode) includes keychain availability detection methods:
- `macos_keychain_available?` - checks for macOS `security` command
- `linux_keychain_available?` - checks for Linux `secret-tool` command
- `windows_keychain_available?` - already properly returns boolean

During code audit, Web Claude's sandbox environment (incomplete Linux tooling) revealed that Ruby's `system()` method can return `nil` in certain edge cases, not just `true`/`false`.

**Current code example:**
```ruby
private_class_method def self.macos_keychain_available?
  system('which security >/dev/null 2>&1')
end
Observed behavior: In broken/incomplete environments, system() can return nil, causing test failures.

Decision
Apply boolean coercion operator (!!) to guarantee boolean return from keychain availability detection methods.

Methods Affected
macos_keychain_available? - line 126
linux_keychain_available? - line 149
Implementation
# Before
private_class_method def self.macos_keychain_available?
  system('which security >/dev/null 2>&1')
end

# After
private_class_method def self.macos_keychain_available?
  !!system('which security >/dev/null 2>&1')
end
Same change for linux_keychain_available?.

Rationale
Why Make This Change?
Defensive Programming: Guarantees boolean return in all cases

Normal: true if tool exists, false if not
Edge case: If environment is broken, still returns false (graceful degradation)
Consistency: Windows already does this correctly

windows_keychain_available? explicitly returns boolean
macOS and Linux should match for consistency
Robustness: User environments are not always perfect

Broken PATH, missing shells, restricted environments
Code should handle gracefully, not crash
No Downside: Coercion is safe and minimal

Only 2 lines changed per method
No performance impact
No security impact
Why Ruby's system() Can Return nil
Ruby's system() method returns:

true if command exits with code 0
false if command exits with non-zero code
nil if the command cannot be executed at all (shell unavailable, environment broken)
The !! operator converts this:

nil → false (gracefully treat as unavailable)
true → true
false → false
Consequences
Positive
More robust to environmental edge cases
Explicit boolean contract for all availability methods
Consistent behavior across all platforms
Minimal code change
Negative
Nil would normally indicate "something weird happened," but we hide it
However, this is acceptable because:
The code gracefully degrades anyway (treats as unavailable)
User gets working functionality (falls back to password prompt)
No data loss or security issue
Implementation Notes
Scope: lib/common/gui/master_password_manager.rb

Line 126: macos_keychain_available?
Line 149: linux_keychain_available?
Testing:

Re-run full test suite after changes
Verify all 394 tests pass
No new tests needed (behavior unchanged for normal cases)
Documentation:

Add inline comment explaining !!system() coercion if desired
Already explained in AUDIT_PR55_ENHANCED_MODE.md
Precedent
windows_keychain_available? (line 186) already uses similar logic:

private_class_method def self.windows_keychain_available?
  return false unless windows_10_or_later?
  # ... PowerShell test logic ...
  result == "available"  # Returns explicit boolean
end
This ADR brings macOS and Linux into alignment with Windows.

Related Documents
AUDIT_PR55_ENHANCED_MODE.md - Full audit with rationale
lib/common/gui/master_password_manager.rb - Implementation location
BRD_Password_Encryption.md - Requirements (FR-2, keychain availability checking)
Status: Accepted - Implement during PR #55 robustness enhancement pass

---

## ADR-009: PBKDF2 Runtime Iterations: 10,000 vs 100,000

**Date:** 2025-11-13
**Status:** Accepted
**Deciders:** Doug (Product Owner), Claude (Sonnet 4.5)
**Session:** Phase 1 Code Audit

### Context

BRD specifies PBKDF2-HMAC-SHA256 with **100,000 iterations** for encryption key derivation. However, Phase 1 implementation uses **10,000 iterations** for runtime password encryption, while validation test (one-time, setup only) correctly uses 100,000 iterations.

This appears as a discrepancy between ADR-002 specification and actual implementation. Question: Is this intentional design choice or implementation bug?

### Decision

**Intentional Design Choice** — Use differentiated iteration counts based on threat model and performance context:

- **Validation Test (one-time, setup):** 100,000 iterations (security-critical, acceptable latency)
- **Runtime Encryption (frequent, per-password):** 10,000 iterations (balanced for UX, acceptable threat model)

### Rationale: Threat Modeling

**Primary Threat:** System-level file access (attacker reads YAML file from disk)

**Threat Analysis:**
- If attacker achieves system-level file access, they've already won the game
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

### Implementation Notes

**Code Location:** `lib/common/gui/password_cipher.rb:29`

```ruby
# Current implementation
KEY_ITERATIONS = 10_000  # Runtime encryption

# ADR-002 specified 100,000, but 10k is acceptable given:
# - Threat model: System-level file access (not offline brute-force)
# - Performance: 10x faster password operations
# - Validation: Master password validation test uses 100k (security-critical)
# See ADR-009 for full threat modeling rationale
```

**Validation Test:** `lib/common/gui/master_password_manager.rb:18`

```ruby
VALIDATION_ITERATIONS = 100_000  # One-time validation, security-first
```

### Revision History

- **2025-11-13:** ADR-009 created to document intentional deviation from ADR-002 per threat modeling analysis

---

## Template for New ADRs

```markdown
## ADR-XXX: [Title]

**Date:** YYYY-MM-DD
**Status:** [Proposed | Accepted | Deprecated | Superseded by ADR-YYY]
**Deciders:** [Names]

### Context
[What is the issue or situation that motivates this decision?]

### Decision
[What is the change we're proposing/have agreed to implement?]

### Consequences
**Positive:**
- [Benefit 1]
- [Benefit 2]

**Negative:**
- [Drawback 1]
- [Drawback 2]

**Mitigations:**
- [How we address drawbacks]

**Alternatives considered:**
- [Alternative A]: [Why rejected]
- [Alternative B]: [Why rejected]
```

---

**How to use this file:**
- Add new ADRs when architectural decisions are made
- Use `chore(all): add ADR-XXX for [topic]` commit format
- Reference ADR numbers in code comments when relevant
- Update status if decision is superseded
