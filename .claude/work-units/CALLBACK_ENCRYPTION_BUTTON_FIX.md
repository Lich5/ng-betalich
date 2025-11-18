# Work Unit: Fix Change Encryption Password Button Callback (Bug)

**Created:** 2025-11-18
**Type:** Bug Fix
**Estimated Effort:** 2-3 hours
**Base Branch:** `fix/cli-master-password-defects`
**Target Branch:** `fix/callback-encryption-button`
**Priority:** Medium

---

## Problem Statement

**Bug:** "Change Encryption Password" button on Account Management tab is not enabled during initial conversion session.

**Symptoms:**
- First launch (entry.dat → entry.yaml conversion): Button remains disabled
- Subsequent launches: Button enables correctly
- Expected: Button should enable appropriately during first session

**Root Cause:**
- Callback mechanism (primarily `gui-login.rb`) updates UI after conversion completes
- New "Change Encryption Password" button not included in callback chain
- Button state only evaluated on subsequent app launches, not during initial conversion

---

## Context

**When introduced:** "Change Encryption Password" feature (FR-6 implementation)
**Affected file:** `lib/common/gui/account_manager_ui.rb` (button logic)
**Callback system:** Likely `gui-login.rb`, but may span multiple modules

**Current button logic:**
```ruby
# Line ~1137 in account_manager_ui.rb
button.visible = has_keychain
button.sensitive = has_enhanced && has_password
```

**Callback pattern investigation needed:**
- `gui-login.rb` - Primary callback coordinator
- `account_manager_ui.rb` - Button state management
- `conversion_ui.rb` - Conversion completion signals
- Other modules that respond to/update callbacks

---

## Objectives

1. **Identify callback mechanism** - Understand how conversion completion triggers UI updates
2. **Add button to callback chain** - Include "Change Encryption Password" button in updates
3. **Test initial conversion** - Verify button enables appropriately during first session
4. **Ensure no regressions** - Existing callback behavior remains unchanged

---

## Investigation Steps

### Step 1: Understand Current Callback Flow

**Files to examine:**
1. `lib/common/gui/gui-login.rb` (or `lib/gui/gui-login.rb`)
   - Search for conversion completion callbacks
   - Identify callback registration/notification pattern

2. `lib/common/gui/conversion_ui.rb`
   - Find where conversion completion is signaled
   - Look for callback invocations after conversion

3. `lib/common/gui/account_manager_ui.rb`
   - Current button state update logic
   - Method: `update_change_master_password_button_state` (or similar)

**Key questions:**
- How do callbacks propagate after conversion?
- What methods are called to refresh UI state?
- Where should button state update be added?

### Step 2: Trace Button State Logic

**Current implementation (account_manager_ui.rb ~lines 1137-1148):**
```ruby
def update_change_master_password_button_state
  has_keychain = MasterPasswordManager.keychain_available?
  @change_master_password_button.visible = has_keychain

  if has_keychain
    yaml_file = YamlState.yaml_file_path(@data_dir)
    if File.exist?(yaml_file)
      yaml_data = YAML.load_file(yaml_file)
      has_enhanced = (yaml_data['encryption_mode'] == 'enhanced')
      has_password = MasterPasswordManager.retrieve_master_password

      @change_master_password_button.sensitive = has_enhanced && has_password
    else
      @change_master_password_button.sensitive = false
    end
  end
end
```

**Questions:**
- Is this method called during initial conversion?
- Should it be added to callback chain explicitly?
- Is there a refresh/reload method that should call this?

---

## Implementation Plan

### File 1: Identify Callback Registration (Investigation)

**Likely location:** `gui-login.rb`

**Search for:**
- Conversion completion notification
- UI refresh/reload methods
- Callback registration patterns

**Example pattern to look for:**
```ruby
# After conversion completes:
@account_manager_ui.refresh_account_list  # Existing
@account_manager_ui.update_button_states  # May be missing
```

### File 2: Add Button Update to Callback Chain

**File:** `lib/common/gui/account_manager_ui.rb`

**Option A: Add to existing refresh method**
```ruby
def refresh_account_list
  # Existing refresh logic...

  # Add button state update
  update_change_master_password_button_state
end
```

**Option B: Create unified button state update**
```ruby
def update_all_button_states
  update_change_master_password_button_state
  # Other button state updates...
end

# Call from refresh_account_list
def refresh_account_list
  # Existing refresh logic...
  update_all_button_states
end
```

**Option C: Hook into conversion completion directly**
```ruby
# In conversion_ui.rb or gui-login.rb
def on_conversion_complete
  # Existing callbacks...
  @account_manager_ui.update_change_master_password_button_state
end
```

### File 3: Ensure Consistent Invocation

**Verify button state updated in all scenarios:**
1. ✅ App launch (existing - works on subsequent launches)
2. ✅ Conversion completion (NEW - currently missing)
3. ✅ Account list changes
4. ✅ Encryption mode changes

---

## Testing Strategy

### Test Case 1: Initial Conversion with Enhanced Mode

**Setup:**
1. Fresh environment with `entry.dat` (no `entry.yaml`)
2. Launch Lich

**Steps:**
1. Conversion dialog appears
2. Select "Enhanced Encryption"
3. Enter master password
4. Conversion completes
5. Account Management tab appears

**Expected:**
- ✅ "Change Encryption Password" button is visible
- ✅ "Change Encryption Password" button is enabled

**Current behavior:**
- ✅ Button is visible
- ❌ Button is disabled (BUG)

### Test Case 2: Initial Conversion with Standard Mode

**Steps:**
1. Fresh environment
2. Select "Standard Encryption"
3. Conversion completes

**Expected:**
- ✅ Button is NOT visible (no keychain in Standard mode)

### Test Case 3: Initial Conversion with Plaintext

**Steps:**
1. Fresh environment
2. Select "Plaintext"
3. Conversion completes

**Expected:**
- ✅ Button is NOT visible (no encryption)

### Test Case 4: Subsequent Launches (Regression Test)

**Steps:**
1. Launch Lich with existing `entry.yaml` (Enhanced mode)

**Expected:**
- ✅ Button visible and enabled (existing behavior - must not break)

---

## Acceptance Criteria

### Functionality
- [ ] Button state correct after initial conversion (Enhanced mode)
- [ ] Button hidden after initial conversion (Standard/Plaintext mode)
- [ ] Existing subsequent launch behavior unchanged
- [ ] Button updates when account list changes
- [ ] Button updates when encryption mode changes (if applicable)

### Code Quality
- [ ] Callback mechanism clearly documented
- [ ] No code duplication (DRY)
- [ ] Follows existing UI refresh patterns
- [ ] Minimal changes (surgical fix)

### Testing
- [ ] Manual test: Initial conversion → Enhanced → Button enabled ✅
- [ ] Manual test: Initial conversion → Standard → Button hidden ✅
- [ ] Manual test: Subsequent launch → Button state correct ✅
- [ ] Manual test: Multiple conversions (re-conversion) → Button state correct ✅

### Git
- [ ] Branch: `fix/callback-encryption-button`
- [ ] Conventional commit: `fix(gui): enable Change Encryption Password button during initial conversion`
- [ ] Clean commit history

---

## Implementation Notes

### Callback Architecture Patterns

**Pattern 1: Direct method invocation**
```ruby
# In gui-login.rb or conversion_ui.rb
def after_conversion_complete
  @account_manager_ui.refresh_account_list
  @account_manager_ui.update_change_master_password_button_state  # Add this
end
```

**Pattern 2: Refresh consolidation**
```ruby
# In account_manager_ui.rb
def refresh_ui
  refresh_account_list
  update_all_button_states
end

def update_all_button_states
  update_change_master_password_button_state
  # Future button state updates here
end
```

**Pattern 3: Signal/observer pattern** (if codebase uses this)
```ruby
# Register callback
on :conversion_complete do
  update_change_master_password_button_state
end
```

**Recommendation:** Follow existing pattern in codebase. Prefer Pattern 2 (consolidation) for maintainability.

---

## Edge Cases

1. **Conversion cancelled mid-way** - Button should remain disabled
2. **Keychain unavailable on Linux/Windows** - Button should remain hidden
3. **Master password prompt cancelled** - Button should remain disabled
4. **Re-conversion (entry.yaml exists)** - Button should update to new mode

---

## Verification Commands

```bash
# File locations
ls lib/common/gui/gui-login.rb lib/gui/gui-login.rb
ls lib/common/gui/account_manager_ui.rb
ls lib/common/gui/conversion_ui.rb

# Search for callback patterns
grep -n "refresh_account_list" lib/common/gui/*.rb
grep -n "conversion.*complete" lib/common/gui/*.rb
grep -n "update.*button" lib/common/gui/account_manager_ui.rb

# Check button method exists
grep -n "update_change_master_password_button_state" lib/common/gui/account_manager_ui.rb
```

---

## Rollback Plan

**If implementation breaks existing behavior:**
1. Revert commit
2. Restore working state
3. Investigate alternative callback mechanism

**Low risk:** This is a UI state update only, no data modification

---

## Success Criteria

**Definition of Done:**
1. ✅ Button enables during initial Enhanced conversion
2. ✅ No regression on subsequent launches
3. ✅ Manual testing complete (all test cases pass)
4. ✅ Code follows existing patterns
5. ✅ Commit pushed to branch

**Estimated completion:** 2-3 hours (including investigation and testing)

---

**Status:** Ready for CLI Claude execution
**Dependencies:** None (builds on fix/cli-master-password-defects)
**Blocker:** None
