# Work Unit: Lich::UI Phase 2 - Script API Modernization

**Branch:** `feat/lich-ui-abstraction`
**Phase:** 2 of 4 (GTK3 Track)
**Dependencies:** Phase 1 (Lich::UI GTK3 Backend) MUST be complete
**Estimated Effort:** 6-8 hours
**Status:** Blocked (waiting for Phase 1)

---

## Objective

Modernize `lib/common/script.rb` to inject `Lich::UI` into script bindings, allowing scripts to use the UI abstraction layer instead of calling GTK3 directly. This enables future framework migration without breaking 1000+ scripts.

---

## Success Criteria

- [ ] `UI = Lich::UI` injected into all script bindings
- [ ] Scripts can call `UI.alert`, `UI.confirm`, `UI.prompt` seamlessly
- [ ] Zero regression on existing script behavior
- [ ] Backward compatibility: `Gtk.queue` still works (deprecated path)
- [ ] Top 10 scripts tested: zero errors
- [ ] RuboCop clean (0 offenses)
- [ ] Documentation updated

---

## Technical Requirements

### 1. Modify Script Binding Injection

**File:** `lib/common/script.rb`

Current pattern (approximately):
```ruby
def self.start(script_name, args = nil)
  script_binding = TRUSTED_SCRIPT_BINDING.call
  # ... load script data ...
  eval(script_data, script_binding, script_name)
end
```

**New pattern:**
```ruby
def self.start(script_name, args = nil)
  script_binding = TRUSTED_SCRIPT_BINDING.call

  # Inject Lich::UI into script binding
  inject_ui_namespace(script_binding)

  # ... load script data ...
  eval(script_data, script_binding, script_name)
end

private

# Inject UI namespace into script binding
# @param binding [Binding] Script binding context
# @return [void]
def self.inject_ui_namespace(binding)
  eval('UI = Lich::UI', binding)

  # Optional: Inject deprecation warnings for direct GTK access
  # eval('Gtk = Lich::UI::DeprecatedGtkProxy', binding) if ENV['LICH_WARN_GTK']
end
```

### 2. Backward Compatibility Layer (Optional)

**File:** `lib/common/ui/deprecated_gtk_proxy.rb`

Optionally create a proxy to warn scripts using direct GTK calls:

```ruby
# lib/common/ui/deprecated_gtk_proxy.rb
module Lich
  module UI
    class DeprecatedGtkProxy
      def self.queue(&block)
        warn "[DEPRECATION] Direct Gtk.queue is deprecated. Use UI.queue instead."
        Lich::UI.queue(&block)
      end

      def self.method_missing(method, *args, **kwargs, &block)
        # Pass through to real GTK3 but log deprecation
        warn "[DEPRECATION] Direct Gtk.#{method} is deprecated. Use Lich::UI abstraction."
        require 'gtk3' unless defined?(Gtk)
        Gtk.public_send(method, *args, **kwargs, &block)
      end

      def self.respond_to_missing?(method, include_private = false)
        require 'gtk3' unless defined?(Gtk)
        Gtk.respond_to?(method) || super
      end
    end
  end
end
```

**Note:** This is optional. If enabled via `ENV['LICH_WARN_GTK'] = 'true'`, it helps identify scripts that need migration.

### 3. Script Examples

**Before (existing scripts):**
```ruby
# bigshot.lic (example)
Gtk.queue do
  dialog = Gtk::MessageDialog.new(
    message: "Configuration saved"
  )
  dialog.run
  dialog.destroy
end
```

**After (modernized scripts - future):**
```ruby
# bigshot.lic (modernized)
UI.alert("Configuration saved")
```

**Backward Compatible (during transition):**
```ruby
# Scripts can still use Gtk.queue - it still works
Gtk.queue do
  # ... existing GTK code ...
end
```

---

## Implementation Steps

### Step 1: Review Script.rb Structure

Read `lib/common/script.rb` completely to understand:
- How `TRUSTED_SCRIPT_BINDING` is created
- Where script data is loaded
- Where eval is called
- Any existing namespace injections

### Step 2: Implement UI Injection

Add `inject_ui_namespace` method to `Script` class:

```ruby
# lib/common/script.rb
class Script
  # ... existing code ...

  def self.start(script_name, args = nil)
    script_binding = TRUSTED_SCRIPT_BINDING.call

    # NEW: Inject Lich::UI
    inject_ui_namespace(script_binding)

    # ... rest of existing code ...
    eval(script_data, script_binding, script_name)
  end

  private

  def self.inject_ui_namespace(binding)
    # Make Lich::UI available as 'UI' in script context
    eval('UI = Lich::UI', binding)
  end
end
```

### Step 3: Write Unit Tests

**File:** `spec/script_ui_injection_spec.rb`

```ruby
RSpec.describe Script, 'UI injection' do
  describe '.inject_ui_namespace' do
    it 'injects UI constant into binding' do
      binding = TOPLEVEL_BINDING.dup
      Script.send(:inject_ui_namespace, binding)

      result = eval('defined?(UI)', binding)
      expect(result).to eq('constant')
    end

    it 'UI refers to Lich::UI' do
      binding = TOPLEVEL_BINDING.dup
      Script.send(:inject_ui_namespace, binding)

      ui_class = eval('UI', binding)
      expect(ui_class).to eq(Lich::UI)
    end
  end

  describe '.start with UI injection' do
    it 'allows script to call UI.alert' do
      # Create minimal script that uses UI
      script_content = <<~RUBY
        UI.alert("Test message")
      RUBY

      # Mock Lich::UI.alert
      allow(Lich::UI).to receive(:alert)

      # Start script (stub file loading)
      allow(Script).to receive(:load_script_data).and_return(script_content)
      Script.start('test_script.lic')

      expect(Lich::UI).to have_received(:alert).with("Test message")
    end

    it 'maintains backward compatibility with Gtk.queue' do
      # Existing scripts using Gtk.queue should still work
      script_content = <<~RUBY
        Gtk.queue { puts "Still works" }
      RUBY

      allow(Script).to receive(:load_script_data).and_return(script_content)

      expect { Script.start('legacy_script.lic') }.not_to raise_error
    end
  end
end
```

### Step 4: Integration Testing with Real Scripts

Create test harness to run top 10 scripts:

**File:** `spec/integration/script_ui_compatibility_spec.rb`

```ruby
RSpec.describe 'Script UI Compatibility', :integration do
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

  before(:each) do
    # Initialize Lich::UI with GTK3 backend
    Lich::UI.init(:gtk3)
  end

  TOP_10_SCRIPTS.each do |script_name|
    it "loads #{script_name} without errors" do
      script_path = find_script(script_name)
      skip "#{script_name} not found" unless script_path

      expect {
        Script.start(script_name)
      }.not_to raise_error
    end
  end

  def find_script(name)
    # Search common script locations
    [
      "scripts/#{name}",
      "../scripts/#{name}",
      ENV['LICH_SCRIPTS_DIR'] && File.join(ENV['LICH_SCRIPTS_DIR'], name)
    ].compact.find { |path| File.exist?(path) }
  end
end
```

### Step 5: Documentation Updates

**File:** `.claude/docs/SCRIPT_UI_MIGRATION_GUIDE.md`

```markdown
# Script UI Migration Guide

## For Script Authors

### Using Lich::UI in Scripts

As of Lich 5.x, scripts can use the `UI` namespace for framework-independent UI operations.

#### Alert Dialog
```ruby
# Old way (GTK3-specific)
Gtk.queue do
  dialog = Gtk::MessageDialog.new(message: "Hello")
  dialog.run
  dialog.destroy
end

# New way (framework-independent)
UI.alert("Hello")
```

#### Confirmation Dialog
```ruby
# Old way
confirmed = false
Gtk.queue do
  dialog = Gtk::MessageDialog.new(type: :question, buttons_type: :yes_no, message: "Continue?")
  confirmed = (dialog.run == Gtk::ResponseType::YES)
  dialog.destroy
end

# New way
confirmed = UI.confirm("Continue?")
```

#### Text Input Prompt
```ruby
# Old way
result = nil
Gtk.queue do
  dialog = Gtk::Dialog.new
  entry = Gtk::Entry.new
  # ... complex setup ...
  result = entry.text if dialog.run == Gtk::ResponseType::OK
  dialog.destroy
end

# New way
result = UI.prompt("Enter value:")
```

### Backward Compatibility

Existing GTK3 code continues to work. Migration to `UI` namespace is **optional** but **recommended** for future compatibility.

### Why Migrate?

- **Future-proof:** Works with GTK4, Glimmer SWT, or other future backends
- **Simpler:** Less boilerplate code
- **Cross-platform:** Backend handles platform-specific quirks
```

---

## Testing Strategy

### Phase 2A: Unit Tests
- Test UI injection into script binding
- Test UI constant availability
- Test method delegation

### Phase 2B: Integration Tests (Top 10 Scripts)
Test these scripts load without errors:
1. `bigshot.lic` - Complex Gtk::Builder UI
2. `go2.lic` - Navigation, minimal UI
3. `repository.lic` - Item storage
4. `waggle.lic` - Character management
5. `loot.lic` - Item looting
6. `buff.lic` - Spell management
7. `sloot.lic` - Advanced looting
8. `afk.lic` - AFK detection
9. `autostart.lic` - Startup automation
10. `xptrack.lic` - Experience tracking

**Success criteria:** All 10 scripts start without errors (existing GTK calls still work via backward compatibility).

### Phase 2C: Manual Testing
- Run Lich with Phase 1 + Phase 2 changes
- Start each top 10 script manually
- Verify no console errors
- Verify existing UI dialogs still appear

---

## Acceptance Criteria Checklist

- [ ] `inject_ui_namespace` method added to `Script` class
- [ ] `UI = Lich::UI` injected into all script bindings
- [ ] Unit tests: 8+ examples, all passing
- [ ] Integration tests: Top 10 scripts load without errors
- [ ] RuboCop: 0 offenses
- [ ] Documentation: Migration guide created
- [ ] Manual testing: Top 10 scripts run successfully
- [ ] Zero regression: Existing GTK code still works

---

## Risks and Mitigations

| Risk | Mitigation |
|------|------------|
| Script binding conflicts | Use unique namespace (`UI` not likely to conflict) |
| Performance overhead | Delegation is lightweight, minimal impact |
| Script compatibility | Maintain full backward compatibility with GTK3 |
| Testing coverage | Test top 10 represents ~70% of active user scripts |

---

## Deliverables

1. ✅ Modified `lib/common/script.rb` with UI injection
2. ✅ `spec/script_ui_injection_spec.rb` - Unit tests
3. ✅ `spec/integration/script_ui_compatibility_spec.rb` - Integration tests
4. ✅ `.claude/docs/SCRIPT_UI_MIGRATION_GUIDE.md` - Developer documentation
5. ✅ Top 10 scripts tested: zero errors
6. ✅ RuboCop clean, tests passing

---

## Next Phase

**Phase 3:** Login GUI Migration (`LICH_UI_PHASE_3_LOGIN_GUI.md`)

After Phase 2 completes with top 10 scripts passing, proceed to Phase 3 to migrate `gui-login.rb` to `Lich::UI`.

---

**Created:** 2025-11-19
**Last Updated:** 2025-11-19
**Status:** Blocked (waiting for Phase 1 completion)
