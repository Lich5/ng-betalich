# Branch Dependency Stack

**Purpose:** Track branch creation order, dependencies, and merge sequence. Survives session compaction.

**Last Updated:** 2025-11-18 21:35 UTC

---

## Current Branch Stack

### Foundation: Rebased Branch
- **Branch:** `rebase-work` (local only, not pushed due to GitHub degradation)
- **Based on:** `origin/fix/preserve-validation-test-on-removal` @ 6a3221d
- **Content:** Rebased commits from `origin/fix/master-password-recovery` (19 commits)
- **Status:** Ready, contains encryption fix (password encryption in add_or_update_account)
- **Note:** This is the stable foundation for all subsequent work
- **Push:** Pending GitHub service restoration - command: `git push --force-with-lease origin rebase-work:fix/master-password-recovery`

---

## Defect Work Units (In Order of Execution)

### Defect 1: CALLBACK_ENCRYPTION_BUTTON_FIX ✅ COMPLETE
- **Work Unit:** `.claude/work-units/CALLBACK_ENCRYPTION_BUTTON_FIX.md`
- **Branch:** `fix/callback-button-enable-on-conversion`
- **Based on:** `rebase-work` (rebased fix/master-password-recovery)
- **Description:** Enable "Change Encryption Password" button during initial conversion session
- **Files modified:** `lib/common/gui/account_manager_ui.rb`, `lib/common/gui-login.rb`
- **Final Commit:** 8cc34c8 - refactor(gui): remove debug logging, keep only critical info messages
- **Total Commits:** 10 commits (initial fix + 9 timing/GTK3 fixes + cleanup)
- **Effort:** 2-3 hours (actual: ~3 hours including timing race condition diagnosis)
- **Priority:** Medium
- **Status:** ✅ COMPLETE - Pushed to GitHub
- **Acceptance:** ✅ Button appears immediately after conversion, correct order, correct state
- **Testing:** ✅ Manual - all conversion scenarios verified, button state correct on subsequent launches
- **Validation:** ✅ 25 RSpec tests pass, RuboCop clean, syntax OK
- **Key Fix:** Deferred callback registration until @notebook exists, passed encryption_mode through notification to avoid stale YAML reads, GTK3-compatible tab reordering with event loop timing

### Defect 2: CLI_MASTER_PASSWORD_RECOVERY
- **Work Unit:** `.claude/work-units/CLI_MASTER_PASSWORD_RECOVERY.md`
- **Branch:** `fix/cli-keychain-recovery-detection` (to be created)
- **Based on:** `fix/callback-button-enable-on-conversion` (completed defect 1)
- **Description:** Add CLI recovery mechanism when master password removed from keychain
- **Files modified:** `lib/util/cli_password_manager.rb`, `lib/main/argv_options.rb`
- **Effort:** 3-4 hours
- **Priority:** High
- **Status:** NOT STARTED
- **Acceptance:** CLI detects missing keychain, provides recovery parameter
- **Testing:** Manual - missing keychain scenarios, recovery workflows

---

## Merge Order (Critical for Integration)

When branches are ready to push and merge:

1. **First:** Push `rebase-work` → `fix/master-password-recovery` on GitHub
   - Command: `git push --force-with-lease origin rebase-work:fix/master-password-recovery`
   - Wait: GitHub service restoration required
   - Status: PENDING (awaiting GitHub service)

2. **Second:** After Defect 1 (callback button) is complete: ✅ PUSHED
   - Branch: `fix/callback-button-enable-on-conversion`
   - Commit: 8cc34c8
   - Status: ON GITHUB - Ready for PR
   - Action: Create PR to merge into `fix/master-password-recovery`
   - PR URL: https://github.com/Lich5/ng-betalich/pull/new/fix/callback-button-enable-on-conversion

3. **Third:** After Defect 2 (CLI recovery) is complete: IN PROGRESS
   - Branch: `fix/cli-keychain-recovery-detection`
   - Status: TO BE CREATED
   - Action: Create from fix/callback-button-enable-on-conversion, implement CLI recovery
   - Merge: Into `fix/callback-button-enable-on-conversion` (layered dependency)

---

## Local Branch Status

| Branch | Type | Status | Based On | Contains |
|--------|------|--------|----------|----------|
| `main` | main | clean | origin/main | production |
| `features-test` | ephemeral | working | rebase-work + pr99 | test merge of encryption fix |
| `rebase-work` | local+remote | ready | origin/fix/preserve-validation-test-on-removal | rebased fix/master-password-recovery (pushed) |
| `fix/callback-button-enable-on-conversion` | feature | ON GITHUB | rebase-work | defect 1 fix (commit 8cc34c8) - PUSHED |
| `fix/cli-keychain-recovery-detection` | feature | to create | fix/callback-button-enable-on-conversion | defect 2 fix (pending) |

---

## Session Continuity Checklist

**If session compacts, verify this state immediately:**

- [ ] `git status` shows clean working tree
- [ ] `git branch -a` shows at minimum: `rebase-work`, `features-test`
- [ ] `git log rebase-work -1` shows commit 6a3221d or ancestor
- [ ] Review this file to understand current branch stack
- [ ] Check TodoWrite status for active work
- [ ] Identify which defect is currently being worked (from TodoWrite)

---

## Notes on GitHub Degradation

**As of 2025-11-18 20:39 UTC:** Git Operations experiencing degraded availability

**Impact:**
- Cannot push `rebase-work` to remote
- All branch pushes blocked until service restores
- Local work continues unaffected
- Plan to push when service returns

**Recovery steps when service restores:**
1. Check GitHub status page
2. Attempt: `git push --force-with-lease origin rebase-work:fix/master-password-recovery`
3. If successful, proceed with creating defect branches
4. If failed, wait and retry

---

## Important Commands Reference

```bash
# View current branch stack
git branch -av

# Switch to base branch for new defect
git checkout rebase-work

# Create new defect branch
git checkout -b fix/callback-button-enable-on-conversion

# View what's in rebase-work vs origin
git log --oneline origin/fix/preserve-validation-test-on-removal..rebase-work

# See files that would be modified
git diff origin/fix/preserve-validation-test-on-removal..rebase-work -- lib/

# When GitHub recovers, push the stack
git push --force-with-lease origin rebase-work:fix/master-password-recovery
```

---

**Signature:** CLI Claude
**Integrity:** This document is the authoritative source for branch dependency tracking
**Update:** Whenever a new branch is created or status changes
