# Work Unit: Standard + Enhanced Encryption Modes (Unified PR)

**Objective:** Create a feature PR with Standard and Enhanced password encryption modes

**Starting Point:** Branch from `eo-996` (PR 7, YAML foundation)
**Source:** Copy files from `feat/password_encrypts` (PR 38)
**Expected Output:** Feature branch ready for testing and review

---

## Summary

PR 38 contains Standard + Enhanced encryption modes fully implemented and tested. Rather than decompose it, we copy the complete, working implementation into a new feature branch. This PR will:

- Add AES-256-CBC encryption (Standard mode) - account-name-based
- Add Master Password + keychain support (Enhanced mode) - cross-platform
- Integrate encryption into password save/load workflow
- Include encryption mode selection during setup
- Include comprehensive test suite

---

## Execution Steps

### Step 1: Setup Branch

```bash
git fetch origin eo-996:eo-996
git checkout eo-996
git checkout -b feat/password-encryption-standard
```

### Step 2: Copy New Files from feat/password_encrypts

**GUI Modules (lib/common/gui/):**
```bash
git show origin/feat/password_encrypts:lib/common/gui/password_cipher.rb > lib/common/gui/password_cipher.rb
git show origin/feat/password_encrypts:lib/common/gui/master_password_manager.rb > lib/common/gui/master_password_manager.rb
git show origin/feat/password_encrypts:lib/common/gui/master_password_prompt.rb > lib/common/gui/master_password_prompt.rb
git show origin/feat/password_encrypts:lib/common/gui/master_password_prompt_ui.rb > lib/common/gui/master_password_prompt_ui.rb
git show origin/feat/password_encrypts:lib/common/gui/password_manager.rb > lib/common/gui/password_manager.rb
```

**Spec Files (spec/):**
```bash
git show origin/feat/password_encrypts:spec/password_cipher_spec.rb > spec/password_cipher_spec.rb
git show origin/feat/password_encrypts:spec/master_password_manager_spec.rb > spec/master_password_manager_spec.rb
git show origin/feat/password_encrypts:spec/master_password_prompt_spec.rb > spec/master_password_prompt_spec.rb
git show origin/feat/password_encrypts:spec/master_password_prompt_ui_spec.txt > spec/master_password_prompt_ui_spec.txt
git show origin/feat/password_encrypts:spec/yaml_state_spec.txt > spec/yaml_state_spec.txt
```

### Step 3: Copy Modified Files from feat/password_encrypts

**GUI Modules (lib/common/gui/):**
```bash
git show origin/feat/password_encrypts:lib/common/gui/account_manager.rb > lib/common/gui/account_manager.rb
git show origin/feat/password_encrypts:lib/common/gui/conversion_ui.rb > lib/common/gui/conversion_ui.rb
git show origin/feat/password_encrypts:lib/common/gui/password_change.rb > lib/common/gui/password_change.rb
git show origin/feat/password_encrypts:lib/common/gui/utilities.rb > lib/common/gui/utilities.rb
git show origin/feat/password_encrypts:lib/common/gui/yaml_state.rb > lib/common/gui/yaml_state.rb
```

**Root Config Files:**
```bash
git show origin/feat/password_encrypts:lib/common/game-loader.rb > lib/common/game-loader.rb
git show origin/feat/password_encrypts:lib/version.rb > lib/version.rb
git show origin/feat/password_encrypts:Gemfile > Gemfile
```

**Spec Files:**
```bash
git show origin/feat/password_encrypts:spec/yaml_state_spec.rb > spec/yaml_state_spec.rb
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
```

All should return silently (no output = success).

### Step 6: Run Test Suite

```bash
bundle exec rspec spec/
```

Expected result: All tests pass (380+ examples as per requirements).

### Step 7: Commit and Push

```bash
git add .
git commit -m "feat(all): add standard and enhanced password encryption modes"
git push -u origin feat/password-encryption-standard
```

---

## Verification Checklist

Before pushing, verify:

- [ ] All new files exist in lib/common/gui/
- [ ] All modified files updated in lib/common/gui/
- [ ] All spec files copied to spec/
- [ ] Gemfile updated with `os` gem
- [ ] No syntax errors (all `ruby -c` checks passed)
- [ ] All tests pass: `bundle exec rspec spec/`
- [ ] No uncommitted changes: `git status` shows clean
- [ ] Branch name is `feat/password-encryption-standard`
- [ ] Commit message follows convention: `feat(all): ...`

---

## Files Copied

**New (11 files):**
- lib/common/gui/password_cipher.rb
- lib/common/gui/master_password_manager.rb
- lib/common/gui/master_password_prompt.rb
- lib/common/gui/master_password_prompt_ui.rb
- lib/common/gui/password_manager.rb
- spec/password_cipher_spec.rb
- spec/master_password_manager_spec.rb
- spec/master_password_prompt_spec.rb
- spec/master_password_prompt_ui_spec.txt
- spec/yaml_state_spec.txt

**Modified (9 files):**
- lib/common/gui/account_manager.rb
- lib/common/gui/conversion_ui.rb
- lib/common/gui/password_change.rb
- lib/common/gui/utilities.rb
- lib/common/gui/yaml_state.rb
- lib/common/game-loader.rb
- lib/version.rb
- Gemfile
- spec/yaml_state_spec.rb

---

## Exit Criteria

PR is complete when:
1. ✅ All files copied without errors
2. ✅ No syntax errors
3. ✅ All tests pass
4. ✅ Branch pushed to GitHub
5. ✅ GitHub runners pass all checks

Report: Complete or Blocked (with error details)

