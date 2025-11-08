# Step 2: PR Decomposition Strategy (DRAFT)

**Date:** 2025-11-08
**Status:** DRAFT - Awaiting User Approval
**Context:** Break PR #38 into manageable, beta-ready chunks

---

## STRATEGY OVERVIEW

**Goal:** Deliver password encryption to beta incrementally without triggering premature 5.14.0 release

**Approach:** Layer PRs on existing `pre/beta` branch, curate in phases, merge to main post-beta as single 5.13.0 release

**Key Principle:** Each PR must be complete, tested, holistic deliverable (not artificially split features)

---

## PHASE BREAKDOWN

### Phase 0: Merge Foundation (PR #7)
**Branch:** `eo-996`
**Title:** `feat(all): clean login refactor for yaml and account management`
**Target:** `main` first, then curate to `pre/beta`

**Why Separate:**
- Standalone YAML refactor (no encryption)
- Needed by all subsequent encryption work
- Already exists as discrete PR

**Action:**
1. Merge #7 → `main` (triggers release prep for features accumulated since 5.12.11)
2. Curate #7 → `pre/beta` (adds to existing beta.0 content)

**Decision Needed:** Accept that merging #7 as `feat(all)` will trigger release-please PR on main?

---

### Phase 1: Core Encryption (Beta-Ready Subset)
**Scope:** Plaintext + Standard encryption ONLY
**Title:** `chore(all): add password encryption foundation`
**Rationale for `chore`:** Infrastructure, no user-facing controls (manual YAML edit required to test)

**Contents:**
- `password_cipher.rb` - AES-256-CBC encryption (plaintext + standard modes)
- `yaml_state.rb` - Encryption integration
- `master_password_manager.rb` - Keychain (macOS/Linux, Windows stubbed with TODO)
- Test fixes:
  - ✅ Fix infomon_spec.rb pollution (isolate NilClass patch)
  - ✅ All 380 tests passing cleanly
- Spec compliance fixes:
  - Decision: PBKDF2 iterations (10K with ADR OR 100K breaking change)
  - Decision: Salt string (keep current OR align with BRD)
  - Terminology: Align `:account_name` → `:standard` naming

**Explicitly Exclude:**
- Enhanced mode (master password) - defer until Windows keychain ready
- SSH Key mode - not implemented
- UI controls for mode switching - defer
- Password recovery workflow - defer

**Acceptance Criteria:**
- 380/380 RSpec tests pass (including infomon fix)
- 0 RuboCop offenses
- Encryption works for plaintext + standard modes
- Decryption transparent to existing code
- Zero regression on existing login workflows
- ADRs documented for any BRD deviations

**Deliverable:** Functional encryption foundation, testable via manual YAML edits

---

### Phase 2: Enhanced Mode + UI (Post-Beta)
**Scope:** Master password encryption + user controls
**Title:** `feat(all): add enhanced password encryption with master password`

**Prerequisites:**
- Phase 1 merged and stable in beta
- Windows keychain implemented
- Beta testing complete, bugs fixed

**Contents:**
- Windows keychain implementation (credential manager via PowerShell)
- Enhanced mode (`:master_password`) promoted from foundation to full support
- UI controls:
  - "Change Encryption Mode" button (FR-4)
  - "Change Account Password" button (FR-5)
  - "Change Master Password" button (FR-6)
- Password recovery workflow (FR-8)
- Migration UI for first-run encryption selection

**Acceptance Criteria:**
- Cross-platform keychain support (macOS/Linux/Windows)
- UI allows seamless mode switching
- Master password validation (dual-layer: keychain + PBKDF2)
- Recovery workflow handles forgotten passwords
- All FR-3, FR-4, FR-5, FR-6, FR-8 requirements met

---

### Phase 3: SSH Key Mode (Post-Beta)
**Scope:** Developer-focused SSH key encryption
**Title:** `feat(all): add SSH key-based password encryption`

**Prerequisites:**
- Phase 2 merged and stable
- Enhanced mode proven in production

**Contents:**
- SSH key signature-based encryption
- UI integration (key selection dialog)
- "Change SSH Key" button (FR-7)
- SSH key fingerprint validation

**Acceptance Criteria:**
- SSH key mode works on all platforms
- UI for key selection + validation
- FR-7 requirements met

---

## BETA WORKFLOW

### Beta Sequence
1. **Curate** Phase 0 + Phase 1 → `pre/beta` branch
2. **Prepare-prerelease** → updates RP PR #37 with new content
3. **Merge RP PR #37** → creates `5.13.0-beta.1` tag
4. **Beta testing period** (duration TBD)
5. Bugs fixed via additional curates → `5.13.0-beta.2`, `.3`, etc.

### Post-Beta to Stable
1. Merge Phase 0 PR → `main` (if not already merged)
2. Merge Phase 1 PR → `main` (curated version, tested in beta)
3. prepare-stable workflow accumulates both
4. Single RP PR created: "Release 5.13.0" (bundles all changes)
5. Merge RP PR → creates `v5.13.0` stable release

**Critical:** All PRs merge as `chore(all):` EXCEPT the final RP PR which naturally uses `chore(main): release 5.13.0`

---

## IMMEDIATE ACTIONS NEEDED

### User Decisions Required

**Decision 1: PBKDF2 Iterations**
- Option A: Keep 10,000 iterations, document deviation in ADR
- Option B: Change to 100,000 (BRD compliance), re-encrypt test data
- **Recommendation:** Option A for speed, plan migration path in ADR

**Decision 2: Salt String**
- Option A: Keep current `"lich5-password-encryption-#{mode}"`
- Option B: Change to BRD `'lich5-login-salt-v1'` (BREAKING - requires decrypt-all workflow)
- **Recommendation:** Option A, document in ADR as intentional deviation

**Decision 3: PR #7 Merge Timing**
- Option A: Merge #7 to main now, accept release-please PR creation
- Option B: Curate #7 directly to pre/beta, skip main merge until post-beta
- **Recommendation:** Option A (normal workflow)

**Decision 4: Phase 1 Scope**
- Confirmed: Plaintext + Standard modes only?
- Exclude Enhanced mode until Windows keychain ready?

---

## WORK UNITS FOR CLI CLAUDE

### WU-002: Fix Test Pollution + Spec Compliance
**Estimated:** 2-3 hours

**Tasks:**
1. Fix infomon_spec.rb pollution (isolate NilClass patch to spec only)
2. Apply Decision 1 (PBKDF2 iterations)
3. Apply Decision 2 (Salt string)
4. Align terminology: `:account_name` → `:standard` throughout codebase
5. Verify 380/380 tests pass
6. Create ADRs for any BRD deviations
7. Commit + push to new branch: `fix/password-encryption-phase1-prep`

### WU-003: Windows Keychain Implementation (Post-Beta)
**Estimated:** 4-6 hours

**Tasks:**
1. Implement `windows_keychain_available?`
2. Implement `store_windows_keychain`
3. Implement `retrieve_windows_keychain`
4. Implement `delete_windows_keychain`
5. Cross-platform testing
6. Update master_password_manager_spec.rb
7. Commit to branch: `feat/windows-keychain`

### WU-004: Enhanced Mode UI Controls (Post-Beta)
**Estimated:** 6-8 hours

**Tasks:**
1. Account Manager UI: "Change Encryption Mode" button
2. Account Manager UI: "Change Account Password" button
3. Account Manager UI: "Change Master Password" button
4. Password recovery workflow UI
5. Migration UI (first-run encryption selection)
6. Integration tests
7. Commit to branch: `feat/encryption-ui-controls`

---

## RISKS & MITIGATIONS

**Risk 1: Test Pollution Resurfaces**
- Mitigation: Add RSpec global config to detect future pollution
- Mitigation: Run full suite in CI on every commit

**Risk 2: Breaking Changes During Beta**
- Mitigation: Phase 1 is minimal scope (plaintext + standard only)
- Mitigation: Extensive beta testing before stable merge

**Risk 3: Windows Users Can't Test Enhanced Mode**
- Mitigation: Phase 1 excludes enhanced mode
- Mitigation: Document limitation clearly in beta notes

---

## SUCCESS METRICS

**Phase 1 Beta Success:**
- ✅ 380/380 tests passing
- ✅ 0 RuboCop offenses
- ✅ Zero regression (existing login workflows unchanged)
- ✅ Plaintext + Standard modes functional
- ✅ Beta users can encrypt passwords (manual YAML edit)
- ✅ Passwords decrypt transparently

**Post-Beta Success:**
- ✅ All 4 encryption modes working
- ✅ Cross-platform (macOS/Linux/Windows)
- ✅ UI controls for all mode management
- ✅ Password recovery workflow functional
- ✅ Production release as 5.13.0 (not 5.14.0)

---

**END OF DRAFT - AWAITING USER APPROVAL**
