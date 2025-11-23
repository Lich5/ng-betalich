# Work Unit: Lich::UI Phase 3 - Login GUI Migration (POC)

**Branch:** `feat/lich-ui-abstraction`
**Phase:** 3 of 4 (GTK3 Track)
**Dependencies:** Phases 1 + 2 MUST be complete, top 10 scripts passing
**Estimated Effort:** 12-16 hours
**Status:** Blocked (waiting for Phases 1 + 2)

---

## Objective

Migrate `lib/common/gui-login.rb` and all related GUI components to use `Lich::UI` abstraction instead of direct GTK3 calls. This serves as the **proof-of-concept** for the migration approach.

**Critical Success Gate:** Top 10 scripts must continue to work with zero errors after this migration. If successful, proceed to Phase 4 (rest of core).

---

## Success Criteria

- [ ] `gui-login.rb` uses only `Lich::UI` calls (no direct GTK3)
- [ ] All helper GUI files migrated (`gui-manual-login.rb`, etc.)
- [ ] Login window functional: start, stop, connect to game
- [ ] All existing features working (saved entries, manual login, account management)
- [ ] Top 10 scripts: zero errors (regression test)
- [ ] Unit tests for migrated components
- [ ] RuboCop clean (0 offenses)
- [ ] Manual testing: login workflow successful

---

## Scope - Files to Migrate

### Primary Files (Core Login)
1. `lib/common/gui-login.rb` - Main login window
2. `lib/common/gui-manual-login.rb` - Manual login tab
3. `lib/common/gui-saved-login.rb` - Saved entries tab (if separate)
4. `lib/common/gui-account-management.rb` - Account management tab (if separate)

### Support Files
5. Any GTK3-specific dialogs used by login flow
6. Icon/image loading if GTK3-specific

### Files to Audit (May Need Changes)
- `lich.rbw` - Login window initialization
- `lib/common/settings.rb` - If it creates GTK dialogs

---

## Technical Requirements

### 1. Audit Current GTK3 Usage

Before migration, identify all GTK3 calls in login files:

```bash
# Search for direct GTK calls
grep -r "Gtk::" lib/common/gui-*.rb
grep -r "Gtk.queue" lib/common/gui-*.rb
grep -r "Gtk.main" lib/common/gui-*.rb
```

**Document findings:** Create inventory of GTK3 calls to migrate.

### 2. Migration Patterns

#### Pattern 1: GTK.queue → UI.queue
```ruby
# Before
Gtk.queue do
  label.text = "Connected"
end

# After
UI.queue do
  label.text = "Connected"
end
```

#### Pattern 2: MessageDialog → UI.alert
```ruby
# Before
Gtk.queue do
  dialog = Gtk::MessageDialog.new(
    parent: @window,
    flags: :modal,
    type: :error,
    buttons_type: :ok,
    message: "Connection failed"
  )
  dialog.run
  dialog.destroy
end

# After
UI.alert("Connection failed", type: :error)
```

#### Pattern 3: Confirmation Dialog → UI.confirm
```ruby
# Before
confirmed = false
Gtk.queue do
  dialog = Gtk::MessageDialog.new(
    type: :question,
    buttons_type: :yes_no,
    message: "Delete this entry?"
  )
  confirmed = (dialog.run == Gtk::ResponseType::YES)
  dialog.destroy
end

# After
confirmed = UI.confirm("Delete this entry?")
```

#### Pattern 4: Input Dialog → UI.prompt
```ruby
# Before
result = nil
Gtk.queue do
  dialog = Gtk::Dialog.new(title: "Enter Password")
  entry = Gtk::Entry.new
  entry.visibility = false
  # ... setup ...
  result = entry.text if dialog.run == Gtk::ResponseType::OK
  dialog.destroy
end

# After
result = UI.prompt("Enter Password", password: true)
```

#### Pattern 5: Complex Windows (Keep GTK3 for Now)

For complex components (Gtk::Builder, Gtk::TreeView, etc.), **defer migration**:

```ruby
# Complex UI - keep GTK3 backend for now
# Will migrate when more UI.window/UI.table methods added

Gtk.queue do
  builder = Gtk::Builder.new(string: GLADE_XML)
  window = builder['main_window']
  # ... complex layout ...
end
```

**Rationale:** Phase 3 focuses on simple dialogs and main window structure. Complex widgets will be addressed when adding richer `Lich::UI` methods.

### 3. Extended Lich::UI Methods (If Needed)

If login GUI requires methods not in Phase 1, add them:

**File:** `lib/common/ui/gtk3_backend.rb` (extend)

```ruby
# Add these methods if gui-login needs them

def self.password_prompt(message, title: 'Password')
  prompt(message, title: title, password: true)
end

def self.error(message, title: 'Error')
  alert(message, title: title, type: :error)
end

def self.warning(message, title: 'Warning')
  alert(message, title: title, type: :warning)
end

def self.info(message, title: 'Information')
  alert(message, title: title, type: :info)
end
```

---

## Implementation Steps

### Step 1: Audit and Document

1. Read all login GUI files completely
2. Create GTK3 usage inventory:
   ```markdown
   # GTK3 Usage Inventory - Login GUI

   ## gui-login.rb
   - Line 45: Gtk::Window.new
   - Line 67: Gtk.queue do
   - Line 89: Gtk::MessageDialog (error)
   - Line 112: Gtk.main_quit

   ## gui-manual-login.rb
   - Line 23: Gtk::Entry.new
   - Line 45: Gtk::Button.new
   - Line 78: Gtk.queue do

   ... etc
   ```

3. Categorize calls:
   - **Simple (migrate now):** alert, confirm, prompt, queue
   - **Complex (defer):** Gtk::Builder, Gtk::TreeView, custom widgets

### Step 2: Migrate Simple Calls First

Start with low-hanging fruit:
1. Replace all `Gtk.queue` → `UI.queue`
2. Replace all `Gtk::MessageDialog` → `UI.alert/confirm`
3. Replace all `Gtk.main_quit` → `UI.quit`

### Step 3: Test After Each File Migration

After migrating each file:
```bash
# Run unit tests
rspec spec/ui/

# Run integration tests
rspec spec/integration/script_ui_compatibility_spec.rb

# Manual test
ruby lich.rbw
# - Open login window
# - Test saved entry login
# - Test manual login
# - Test account management
```

### Step 4: Extend Lich::UI as Needed

If migration reveals missing methods:
1. Add to `BaseBackend` (interface)
2. Implement in `GTK3Backend`
3. Update tests
4. Continue migration

### Step 5: Full Regression Test

After all login GUI files migrated:

**Automated:**
```bash
rspec spec/integration/script_ui_compatibility_spec.rb
```

**Manual:**
1. Launch Lich
2. Test saved entry login
3. Test manual login
4. Test account management (add, edit, delete)
5. Connect to game
6. Run each top 10 script
7. Verify no errors in console

---

## Testing Strategy

### Unit Tests

**File:** `spec/ui/login_gui_spec.rb`

```ruby
RSpec.describe 'Login GUI with Lich::UI' do
  before(:each) do
    Lich::UI.init(:gtk3)
  end

  describe 'Saved Entry Login' do
    it 'displays login window'
    it 'loads saved entries'
    it 'connects to game on entry selection'
  end

  describe 'Manual Login' do
    it 'accepts account name input'
    it 'accepts password input'
    it 'connects to game on submit'
  end

  describe 'Account Management' do
    it 'adds new account'
    it 'edits existing account'
    it 'deletes account with confirmation'
  end

  describe 'Error Handling' do
    it 'shows error dialog on connection failure'
    it 'shows warning for invalid input'
  end
end
```

### Integration Tests (Critical Gate)

**File:** `spec/integration/login_with_scripts_spec.rb`

```ruby
RSpec.describe 'Login GUI + Script Compatibility', :integration do
  TOP_10_SCRIPTS = %w[
    bigshot.lic
    go2.lic
    repository.lic
    waggle.lic
    loot.lic
    buff.lic
    sloot.lic
    afk.lic
    autostart.lic
    xptrack.lic
  ].freeze

  before(:all) do
    # Initialize UI
    Lich::UI.init(:gtk3)

    # Simulate login sequence
    # (This may require mocking or test account)
  end

  describe 'Post-login script execution' do
    TOP_10_SCRIPTS.each do |script_name|
      it "runs #{script_name} without errors after login" do
        script_path = find_script(script_name)
        skip "#{script_name} not found" unless script_path

        errors = []
        # Capture stderr/exceptions
        Script.start(script_name)
        # Run for 5 seconds, collect errors

        expect(errors).to be_empty, "#{script_name} had errors: #{errors}"
      end
    end
  end
end
```

### Manual Testing Checklist

- [ ] Lich starts without errors
- [ ] Login window appears
- [ ] Saved entries load correctly
- [ ] Can select saved entry and connect
- [ ] Manual login tab functional
- [ ] Account management tab functional
- [ ] Can add new account
- [ ] Can edit existing account
- [ ] Can delete account (with confirmation)
- [ ] Error dialogs appear correctly
- [ ] Connection to game successful
- [ ] Top 10 scripts run without errors post-login

---

## Acceptance Criteria Checklist

- [ ] All GTK3 calls in login GUI replaced with `Lich::UI`
- [ ] Login window functional (all tabs working)
- [ ] Unit tests: 15+ examples, all passing
- [ ] Integration tests: Top 10 scripts - zero errors
- [ ] RuboCop: 0 offenses
- [ ] Manual testing: Full login workflow successful
- [ ] Documentation: Migration notes in ADR
- [ ] **GATE:** Top 10 scripts verified passing - approve/reject Phase 4

---

## Decision Gate: Proceed to Phase 4?

After Phase 3 completion, evaluate:

### ✅ APPROVE Phase 4 if:
- All top 10 scripts run without errors
- Login workflow fully functional
- No regressions detected
- Test coverage adequate (90%+)

### ⚠️ HOLD Phase 4 if:
- Any top 10 script shows errors
- Login workflow broken
- Performance issues detected
- Missing functionality

### ❌ REJECT/REVISE if:
- Multiple scripts failing
- Critical functionality broken
- Architecture issues discovered

**If APPROVED:** Proceed to Phase 4 (rest of core Lich migration)
**If HOLD:** Fix issues, re-test, re-evaluate
**If REJECTED:** Revise approach, possibly redesign `Lich::UI` API

---

## Risks and Mitigations

| Risk | Mitigation |
|------|------------|
| Complex GTK widgets hard to migrate | Defer complex widgets, keep GTK3 backend |
| Login workflow breaks | Incremental migration, test after each file |
| Scripts fail after migration | Maintain backward compatibility, comprehensive testing |
| Performance degradation | Profile code, optimize delegation if needed |

---

## Deliverables

1. ✅ Migrated `lib/common/gui-login.rb`
2. ✅ Migrated `lib/common/gui-manual-login.rb`
3. ✅ Migrated other login GUI files
4. ✅ Extended `Lich::UI` methods (if needed)
5. ✅ `spec/ui/login_gui_spec.rb` - Unit tests
6. ✅ `spec/integration/login_with_scripts_spec.rb` - Integration tests
7. ✅ `.claude/docs/ADR_LOGIN_GUI_MIGRATION.md` - Migration notes
8. ✅ Top 10 scripts tested: **ZERO ERRORS**
9. ✅ RuboCop clean, tests passing
10. ✅ **DECISION:** APPROVE/HOLD/REJECT Phase 4

---

## Next Phase

**Phase 4:** Core Lich Migration (`LICH_UI_PHASE_4_CORE_MIGRATION.md`)

**Conditional:** Only proceed if Phase 3 gate is APPROVED.

---

**Created:** 2025-11-19
**Last Updated:** 2025-11-19
**Status:** Blocked (waiting for Phases 1 + 2, top 10 scripts passing)
