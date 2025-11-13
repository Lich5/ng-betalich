# Work Unit: Core Encryption Implementation (lib/ only, no specs)

**Objective:** Implement password encryption in production code only (no test files)

**Starting Point:** Branch from `eo-996` (PR 7, YAML foundation)
**Source:** Copy files from `feat/password_encrypts` (PR 38) - lib/ directory only
**Expected Output:** Feature branch with core encryption working, testable by Ellipsis linter
**Target Size:** ~1,700-1,800 lines (vs. 3,500+ with tests)

---

## Summary

This work unit implements Standard + Enhanced password encryption modes in production code. Test files are deferred to a follow-up PR to keep this PR small enough for Ellipsis code linting.

Core features included:
- AES-256-CBC encryption (Standard mode)
- Master Password + keychain support (Enhanced mode)
- Encryption integration into YAML save/load
- Conversion UI with mode selection
- File permissions security (0600)

Test files deferred (will be added in follow-up PR).

---

## Execution Steps

### Step 1: Setup Branch

```bash
git fetch origin eo-996:eo-996
git checkout eo-996
git checkout -b feat/password-encryption-core
```

### Step 2: Copy Core Encryption Files

**New GUI modules (lib/common/gui/):**
```bash
git show origin/feat/password_encrypts:lib/common/gui/password_cipher.rb > lib/common/gui/password_cipher.rb
git show origin/feat/password_encrypts:lib/common/gui/master_password_manager.rb > lib/common/gui/master_password_manager.rb
git show origin/feat/password_encrypts:lib/common/gui/master_password_prompt.rb > lib/common/gui/master_password_prompt.rb
git show origin/feat/password_encrypts:lib/common/gui/master_password_prompt_ui.rb > lib/common/gui/master_password_prompt_ui.rb
git show origin/feat/password_encrypts:lib/common/gui/password_manager.rb > lib/common/gui/password_manager.rb
```

**New olib utility modules (lib/gemstone/olib/):**
```bash
mkdir -p lib/gemstone/olib
git show origin/feat/password_encrypts:lib/gemstone/olib/command.rb > lib/gemstone/olib/command.rb
git show origin/feat/password_encrypts:lib/gemstone/olib/container.rb > lib/gemstone/olib/container.rb
git show origin/feat/password_encrypts:lib/gemstone/olib/containers.rb > lib/gemstone/olib/containers.rb
git show origin/feat/password_encrypts:lib/gemstone/olib/exist.rb > lib/gemstone/olib/exist.rb
git show origin/feat/password_encrypts:lib/gemstone/olib/item.rb > lib/gemstone/olib/item.rb
```

### Step 3: Copy Modified Production Files

**Modified GUI modules:**
```bash
git show origin/feat/password_encrypts:lib/common/gui/account_manager.rb > lib/common/gui/account_manager.rb
git show origin/feat/password_encrypts:lib/common/gui/conversion_ui.rb > lib/common/gui/conversion_ui.rb
git show origin/feat/password_encrypts:lib/common/gui/password_change.rb > lib/common/gui/password_change.rb
git show origin/feat/password_encrypts:lib/common/gui/utilities.rb > lib/common/gui/utilities.rb
git show origin/feat/password_encrypts:lib/common/gui/yaml_state.rb > lib/common/gui/yaml_state.rb
```

**Root config files:**
```bash
git show origin/feat/password_encrypts:lib/common/game-loader.rb > lib/common/game-loader.rb
git show origin/feat/password_encrypts:lib/version.rb > lib/version.rb
git show origin/feat/password_encrypts:Gemfile > Gemfile
```

### Step 4: Update Dependencies

```bash
bundle install
```

### Step 5: Verify Syntax

```bash
ruby -c lib/common/gui/password_cipher.rb
ruby -c lib/common/gui/master_password_manager.rb
ruby -c lib/common/gui/master_password_prompt.rb
ruby -c lib/common/gui/master_password_prompt_ui.rb
ruby -c lib/common/gui/password_manager.rb
ruby -c lib/common/gui/account_manager.rb
ruby -c lib/common/gui/conversion_ui.rb
ruby -c lib/common/gui/password_change.rb
ruby -c lib/common/gui/utilities.rb
ruby -c lib/common/gui/yaml_state.rb
ruby -c lib/common/game-loader.rb
ruby -c lib/gemstone/olib/command.rb
ruby -c lib/gemstone/olib/container.rb
ruby -c lib/gemstone/olib/containers.rb
ruby -c lib/gemstone/olib/exist.rb
ruby -c lib/gemstone/olib/item.rb
```

All should return silently (no output = success).

### Step 6: Check Ellipsis Linting

Run your Ellipsis linter to validate code quality:
```bash
# Your ellipsis command here (adjust as needed)
ellipsis check
# or
bundle exec rubocop
```

Expected: Linter processes successfully without overwhelming file count.

### Step 7: Commit and Push

```bash
git add .
git commit -m "feat(all): add core password encryption (Standard and Enhanced modes)"
git push -u origin feat/password-encryption-core
```

---

## Verification Checklist

Before pushing, verify:

- [ ] All new files exist in lib/common/gui/
- [ ] All olib files exist in lib/gemstone/olib/
- [ ] All modified files updated
- [ ] Gemfile updated with `os` gem
- [ ] No syntax errors (all `ruby -c` checks passed)
- [ ] No test files added (yaml_state_spec.rb NOT included)
- [ ] No spec/ files modified
- [ ] No uncommitted changes: `git status` shows clean
- [ ] Branch name is `feat/password-encryption-core`
- [ ] Commit message follows convention: `feat(all): ...`

---

## Files Included

**New (10 files):**
- lib/common/gui/password_cipher.rb
- lib/common/gui/master_password_manager.rb
- lib/common/gui/master_password_prompt.rb
- lib/common/gui/master_password_prompt_ui.rb
- lib/common/gui/password_manager.rb
- lib/gemstone/olib/command.rb
- lib/gemstone/olib/container.rb
- lib/gemstone/olib/containers.rb
- lib/gemstone/olib/exist.rb
- lib/gemstone/olib/item.rb

**Modified (8 files):**
- lib/common/gui/account_manager.rb
- lib/common/gui/conversion_ui.rb
- lib/common/gui/password_change.rb
- lib/common/gui/utilities.rb
- lib/common/gui/yaml_state.rb
- lib/common/game-loader.rb
- lib/version.rb
- Gemfile

**Deferred (to follow-up PR):**
- spec/password_cipher_spec.rb
- spec/master_password_manager_spec.rb
- spec/master_password_prompt_spec.rb
- spec/master_password_prompt_ui_spec.txt
- spec/yaml_state_spec.rb (modifications)
- spec/yaml_state_spec.txt

---

## Exit Criteria

PR is ready when:
1. ✅ All lib/ files copied without errors
2. ✅ No syntax errors
3. ✅ Ellipsis linter processes successfully
4. ✅ No test files included
5. ✅ Branch pushed to GitHub

Report: Complete or Blocked (with error details)

---

## Notes

**Important:**
- This PR has NO test files—those are deferred
- The code is testable (can be manually verified), but automated tests come in follow-up PR
- All core encryption logic is complete: Standard mode, Enhanced mode, keychain, UI
- File size: ~1,700-1,800 lines (vs. 3,500+ with tests)
- Ellipsis should be able to process this cleanly

**Follow-up PR (after this merges):**
- Add all spec files (password_cipher_spec, master_password_manager_spec, etc.)
- Refactor yaml_state_spec.rb
- Run full test suite
- Merge with branch protection + all tests green

