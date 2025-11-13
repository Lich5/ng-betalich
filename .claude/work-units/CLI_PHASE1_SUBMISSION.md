# CLI Phase 1 Submission: Core Encryption Implementation

**For:** CLI Claude (Project Execution)
**Status:** Ready for Execution
**Date:** 2025-11-13
**Session:** Web Claude Architecture Planning

---

## Executive Summary

Phase 1 implements the complete Standard + Enhanced password encryption foundation for Lich 5, enabling 80% of user base (all platforms) to use secure Master Password mode.

**Target:** Feature branch `feat/password-encryption-core` with 11 files (5 new, 6 modified), ~1,200-1,400 lines of production code.

**Outcome:** Self-contained, testable PR ready for human review and GitHub CI validation.

---

## Prerequisites Verification

✅ **Base branch:** `eo-996` (PR 7, YAML foundation) - exists on origin
✅ **Source branch:** `feat/password_encrypts` (PR 38) - exists on origin
✅ **Work unit:** `CORE_ENCRYPTION_LIB_ONLY.md` - finalized and committed to main
✅ **Dependencies:** Ruby 3.3.6, Bundler, RSpec, RuboCop configured
✅ **Ruby linter:** `bundle exec rubocop` available

---

## Execution Work Unit

**Primary reference:** `.claude/work-units/CORE_ENCRYPTION_LIB_ONLY.md`

This work unit specifies:
- **7 execution steps** (setup, copy, verify, test, lint, commit, push)
- **11 files** with exact source paths and target locations
- **Syntax verification** commands for all 10 Ruby files
- **Verification checklist** (11 items)
- **Conventional commit** format: `feat(all): add core password encryption (Standard and Enhanced modes)`

---

## Files Summary

**New (5 files):**
- `lib/common/gui/password_cipher.rb` - AES-256-CBC encryption/decryption
- `lib/common/gui/master_password_manager.rb` - Cross-platform keychain integration (includes **Windows stubs** - implemented in Phase 2)
- `lib/common/gui/master_password_prompt.rb` - Non-UI password prompting
- `lib/common/gui/master_password_prompt_ui.rb` - GTK3 dialog UI
- `lib/common/gui/password_manager.rb` - Mode-aware password coordinator

**Modified (6 files):**
- `lib/common/gui/account_manager.rb` - YAML saving with headers
- `lib/common/gui/conversion_ui.rb` - Encryption mode selection UI
- `lib/common/gui/password_change.rb` - Re-encryption on password change
- `lib/common/gui/utilities.rb` - Minor updates
- `lib/common/gui/yaml_state.rb` - Encryption/decryption integration (~220 lines modified)
- `Gemfile` - Add `os`, `base64`, `json` gems

**Deferred (to Phase 3):**
- All `spec/` test files (5+ files with 300+ test cases)

---

## Acceptance Criteria

Execute `CORE_ENCRYPTION_LIB_ONLY.md` Step 1-7 and verify:

- [ ] Step 1: Branch setup complete (`git checkout -b feat/password-encryption-core`)
- [ ] Step 2: All 5 new files copied successfully (no errors from `git show`)
- [ ] Step 3: All 6 modified files copied successfully
- [ ] Step 4: `bundle install` succeeds with no errors
- [ ] Step 5: All 10 `ruby -c` syntax checks pass silently (no output = success)
- [ ] Step 6: Ellipsis linter (`bundle exec rubocop`) runs without overwhelming output
- [ ] Step 7a: `git add .` stages all changes
- [ ] Step 7b: `git commit -m "feat(all): add core password encryption (Standard and Enhanced modes)"` succeeds
- [ ] Step 7c: `git push -u origin feat/password-encryption-core` succeeds
- [ ] Final: `git status` shows "Your branch is ahead of 'origin/main' by 1 commit"
- [ ] Final: Branch exists on origin (visible in GitHub UI)

---

## Expected Outcome

✅ **New PR:** `feat/password-encryption-core` with clear title and description
✅ **Diff size:** ~1,200-1,400 lines (human-reviewable)
✅ **Test coverage:** Deferred (Phase 3 follow-up PR)
✅ **Functionality:** Standard and Enhanced modes complete; Windows stubs in place for Phase 2
✅ **Quality gates:** Ellipsis linter passes, syntax clean, conventional commit format

---

## Phase Sequence

```
Phase 1 (NOW)  → feat/password-encryption-core
               → Standard + Enhanced modes (complete encryption foundation)
               → 11 files (5 new, 6 modified), ~1,200-1,400 lines
               ↓
Phase 2 (NEXT) → feat/windows-keychain-passwordvault (new branch based on Phase 1)
               → Windows-specific PasswordVault implementation (CODE ONLY)
               → 2 files: master_password_manager.rb, conversion_ui.rb
               → Replace Windows stubs with real PowerShell implementation
               → No tests (deferred to Phase 3)
               ↓
Phase 3 (LATER) → Test suite + management UIs
                → All spec files + password/SSH key change workflows
                → Full test validation (380+ tests)
```

---

## Failure Handling

If execution fails at any step:

1. **Syntax error on Step 5:** Check modified file for typos; refer to PR #38 source for validation
2. **Bundle install fails:** Verify Gemfile was copied correctly (should add `os`, `base64`, `json`)
3. **Linter warnings on Step 6:** Review RuboCop output; adjust formatting as needed (no logic changes)
4. **Git push fails:** Verify branch name is exactly `feat/password-encryption-core` and git config is correct

**Rollback plan:** All steps are idempotent—can retry from any step after fixing issues.

---

## Context & Resources

**Read if unclear:**
- `.claude/work-units/CORE_ENCRYPTION_LIB_ONLY.md` - Detailed step-by-step execution instructions
- `.claude/docs/BRD_Password_Encryption.md` - Feature requirements
- `.claude/docs/CLI_PRIMER.md` - Ground rules and expectations

**Key insight:**
This is a **copy-based approach**, not extraction. PR #38 already has working implementation; Phase 1 copies the complete delta between PR 7 and PR 38 into a single, self-contained feature branch. No logic changes—verification via diff against PR #38 source.

---

## Sign-Off

**Web Claude:** Submitted for CLI Claude execution
**Status:** ✅ Ready
**Risk Level:** Low (copy-based, verified against working source PR #38)

All prerequisites met. Execute `CORE_ENCRYPTION_LIB_ONLY.md` Steps 1-7 in sequence. Report completion status when finished.

---

**Next submission after merge:** Phase 2 (Windows Keychain) - `CURRENT.md` ready in `.claude/work-units/`
