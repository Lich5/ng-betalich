# Work Unit: Fix Failing GUI Login RSpec Tests

**Created:** 2025-11-08
**Estimated Effort:** 1-2 hours
**Branch:** PR #38 (feat/password_encrypts)

---

## Task

Fix 14 failing RSpec tests in GUI login password encryption feature caused by private class method visibility issues in test environment.

---

## Prerequisites

- [ ] Verify `gh` CLI available: `gh --version`
- [ ] Checkout PR #38: `gh pr checkout 38`
- [ ] Context read: CLI_PRIMER.md
- [ ] Bundle install complete: `bundle install`

---

## Files

**Modify:**
- lib/common/gui/master_password_prompt.rb - Remove line 87: `private_class_method :show_warning_dialog`
- lib/common/gui/yaml_state.rb - Remove line 748: `private_class_method :ensure_master_password_exists`

---

## Acceptance Criteria

- [ ] All 3 failing tests in spec/master_password_prompt_spec.rb pass:
  - spec/master_password_prompt_spec.rb[1:1:3:1] - "shows weak password warning"
  - spec/master_password_prompt_spec.rb[1:1:6:1] - password < 8 chars handling
  - spec/master_password_prompt_spec.rb[1:1:7:3] - logging when user rejects weak password
- [ ] All 11 failing tests in spec/yaml_state_spec.rb pass:
  - spec/yaml_state_spec.rb[1:1:1:1] through [1:1:3:2] - migrate_from_legacy with master_password mode
  - spec/yaml_state_spec.rb[1:2:1:1] - ensure_master_password_exists behavior
- [ ] All other existing passing tests continue to pass (zero regression)
- [ ] Code follows SOLID + DRY principles
- [ ] No security regressions introduced
- [ ] Committed to PR #38 with conventional commit
- [ ] Pushed to PR #38 (automatically updates the PR)

---

## Conventional Commit Format (CRITICAL)

**Your commit MUST use:**
```
fix(all): resolve RSpec failures for private class methods in GUI login tests
```

**NO other formats allowed.** Wrong format triggers unintended releases.

---

## Context

**Problem:** Tests are failing because they attempt to stub or call private class methods:

1. **master_password_prompt.rb:87** - `private_class_method :show_warning_dialog`
   - Tests at spec/master_password_prompt_spec.rb:46-57, :113+ try to stub this method
   - RSpec cannot easily stub private class methods without special handling

2. **yaml_state.rb:748** - `private_class_method :ensure_master_password_exists`
   - Tests at spec/yaml_state_spec.rb use `.send(:ensure_master_password_exists)` to call it
   - May need visibility adjustment or test approach change

**Read before starting:**
- CLI_PRIMER.md (ground rules, project context, quality standards)
- lib/common/gui/master_password_prompt.rb (implementation to fix)
- lib/common/gui/yaml_state.rb (implementation to fix)
- spec/master_password_prompt_spec.rb (tests expecting fixes)
- spec/yaml_state_spec.rb (tests expecting fixes)

**Test execution:**
```bash
bundle exec rspec spec/master_password_prompt_spec.rb spec/yaml_state_spec.rb
```

---

## Root Cause Analysis

### Issue 1: master_password_prompt.rb
**Location:** lib/common/gui/master_password_prompt.rb:87

```ruby
private_class_method :show_warning_dialog
```

**Impact:** Tests cannot stub this method for testing weak password validation flow.

**Options:**
1. Remove `private_class_method` declaration (simplest, method still encapsulated by module)
2. Adjust tests to use RSpec's `allow_any_instance_of` or module prepending
3. Extract method to separate testable class

### Issue 2: yaml_state.rb
**Location:** lib/common/gui/yaml_state.rb:748

```ruby
private_class_method :ensure_master_password_exists
```

**Impact:** Tests use `.send(:ensure_master_password_exists)` which works but may fail in some Ruby environments.

**Options:**
1. Remove `private_class_method` declaration (simplest)
2. Make method protected instead of private
3. Refactor to public with clear "internal use" documentation

---

## Recommended Solution

**Approach:** Remove `private_class_method` declarations for both methods.

**Rationale:**
- Methods are already encapsulated within modules (Lich::Common::GUI::MasterPasswordPrompt, Lich::Common::GUI::YamlState)
- Ruby modules provide sufficient encapsulation without needing private
- Tests can properly stub/call methods
- Maintains all functionality
- Zero security impact (methods aren't exposed outside module scope in practice)
- Simplest fix with lowest risk

**Implementation:**
1. `gh pr checkout 38` (checkout existing PR)
2. Remove line 87 from lib/common/gui/master_password_prompt.rb
3. Remove line 748 from lib/common/gui/yaml_state.rb
4. Run full test suite to verify: `bundle exec rspec spec/master_password_prompt_spec.rb spec/yaml_state_spec.rb`
5. Commit with conventional commit message
6. Push (automatically updates PR #38)

---

## Rollback Plan

**If tests still fail after removing private_class_method:**

1. Check that Lich module stub is properly defined in specs
2. Verify GTK stub in spec/master_password_prompt_spec.rb is correct
3. Check for missing requires in spec files
4. If failures persist, revert changes and use alternative approach (extract to separate class)

**Rollback command:**
```bash
git checkout HEAD -- lib/common/gui/master_password_prompt.rb lib/common/gui/yaml_state.rb
```

---

## Questions/Blockers

[CLI Claude: Add here if stuck or need clarification]

---

**When complete:** Archive this file to `archive/001-fix-gui-login-rspec-tests.md` and await next work unit.
