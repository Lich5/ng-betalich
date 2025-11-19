# Work Unit: Lich::UI Phase 4 - Core Lich Migration

**Branch:** `feat/lich-ui-abstraction`
**Phase:** 4 of 4 (GTK3 Track - Final)
**Dependencies:** Phase 3 APPROVED (Login GUI migration successful, top 10 scripts passing)
**Estimated Effort:** 20-30 hours
**Status:** Blocked (waiting for Phase 3 approval)

---

## Objective

Migrate **all remaining GTK3 calls** in core Lich to use `Lich::UI` abstraction. This completes the migration, making Lich ready for future framework changes (GTK4, Glimmer SWT, etc.).

**Critical Success Gate:** 50-60 scripts must work with zero errors after this migration.

---

## Success Criteria

- [ ] All GTK3 calls in `lib/` replaced with `Lich::UI` (except internal UI components)
- [ ] Settings/preferences dialogs migrated
- [ ] Game connection UI migrated
- [ ] Status windows/notifications migrated
- [ ] All core features functional
- [ ] Top 10 scripts: zero errors (regression)
- [ ] Extended test suite: 50-60 scripts - zero errors
- [ ] Unit tests for all migrated components
- [ ] RuboCop clean (0 offenses)
- [ ] Documentation complete

---

## Scope - Files to Migrate

### Discovery Phase (Required First)

Before migration, audit **all** GTK3 usage in core Lich:

```bash
# Find all GTK3 usage in lib/
grep -r "Gtk::" lib/ --include="*.rb" > gtk3_usage_inventory.txt
grep -r "Gtk\." lib/ --include="*.rb" >> gtk3_usage_inventory.txt

# Exclude already-migrated files
grep -v "gui-login" gtk3_usage_inventory.txt > remaining_gtk3.txt
```

**Expected file categories:**

### Category 1: Settings/Preferences
- `lib/common/settings.rb` - Settings dialogs
- `lib/common/preferences.rb` - User preferences UI (if exists)

### Category 2: Game Connection/Status
- Any connection status windows
- Network error dialogs
- Reconnection prompts

### Category 3: Script Management
- Script control dialogs (if any)
- Script error notifications

### Category 4: Utility Dialogs
- File choosers
- Confirmation prompts
- Info/warning/error messages

### Category 5: Advanced UI (Defer if Complex)
- Custom widgets (may keep GTK3 backend temporarily)
- Complex layouts (Gtk::Builder)
- Advanced controls (TreeView, etc.)

---

## Technical Requirements

### 1. Complete GTK3 Usage Audit

**Deliverable:** `GTK3_MIGRATION_INVENTORY.md`

```markdown
# GTK3 Migration Inventory - Phase 4

## Summary
- Total GTK3 calls: XXX
- Simple (migrate now): XXX
- Complex (defer): XXX
- Already migrated (Phase 3): XXX

## By File

### lib/common/settings.rb
- Line 45: Gtk::Dialog.new - SIMPLE
- Line 67: Gtk.queue - SIMPLE
- Line 89: Gtk::FileChooserDialog - SIMPLE (use UI.file_chooser)

### lib/common/some_feature.rb
- Line 123: Gtk::Builder - COMPLEX (defer)
- Line 145: Gtk::TreeView - COMPLEX (defer)

... etc
```

### 2. Extend Lich::UI as Needed

Based on audit, may need to add methods:

**Example additions to `BaseBackend`:**

```ruby
# lib/common/ui/base_backend.rb

# List selection dialog
# @param message [String] Prompt message
# @param items [Array<String>] Items to choose from
# @param title [String] Dialog title
# @return [String, nil] Selected item or nil
def self.choose(message, items, title: 'Choose')
  raise NotImplementedError
end

# Multi-file chooser
# @param title [String] Dialog title
# @param multiple [Boolean] Allow multiple selection
# @return [Array<String>] Selected file paths
def self.choose_files(title: 'Choose Files', multiple: false)
  raise NotImplementedError
end

# Progress dialog (for long operations)
# @param title [String] Dialog title
# @param message [String] Progress message
# @yield Block to execute with progress callback
# @return [void]
def self.with_progress(title: 'Processing', message: 'Please wait...')
  raise NotImplementedError
end

# Status notification (non-blocking)
# @param message [String] Status message
# @param duration [Integer] Milliseconds to display
# @return [void]
def self.notify(message, duration: 3000)
  raise NotImplementedError
end
```

**Implement in GTK3Backend:**

```ruby
# lib/common/ui/gtk3_backend.rb

def self.choose(message, items, title: 'Choose')
  result = nil
  queue do
    dialog = Gtk::Dialog.new(title: title)

    label = Gtk::Label.new(message)
    combo = Gtk::ComboBoxText.new
    items.each { |item| combo.append_text(item) }
    combo.active = 0

    dialog.child.pack_start(label, padding: 10)
    dialog.child.pack_start(combo, padding: 10)
    dialog.add_button(Gtk::Stock::CANCEL, Gtk::ResponseType::CANCEL)
    dialog.add_button(Gtk::Stock::OK, Gtk::ResponseType::OK)

    dialog.show_all

    if dialog.run == Gtk::ResponseType::OK
      result = combo.active_text
    end

    dialog.destroy
  end
  result
end

# ... implement other methods similarly
```

### 3. Migration Patterns (Same as Phase 3)

Follow same patterns as Phase 3:
- `Gtk.queue` → `UI.queue`
- `Gtk::MessageDialog` → `UI.alert/confirm`
- `Gtk::Dialog` → `UI.prompt`
- `Gtk::FileChooserDialog` → `UI.file_chooser`
- Complex widgets → Defer or wrap in `UI.queue { <GTK3 code> }`

### 4. Backward Compatibility

Maintain for complex widgets not yet abstracted:

```ruby
# For complex UI not yet abstracted, keep GTK3:
UI.queue do
  # Complex GTK3 code here
  builder = Gtk::Builder.new
  # ... etc
end
```

This allows gradual migration without blocking progress.

---

## Implementation Steps

### Step 1: Discovery and Planning

1. Run GTK3 audit (see Scope section)
2. Create `GTK3_MIGRATION_INVENTORY.md`
3. Categorize all findings (simple vs complex)
4. Identify required new `Lich::UI` methods
5. Estimate effort per file

### Step 2: Extend Lich::UI

1. Add new methods to `BaseBackend`
2. Implement in `GTK3Backend`
3. Write unit tests for new methods
4. Verify tests pass

### Step 3: Migrate Files (Incremental)

**Priority order:**
1. High-traffic files (settings, common dialogs)
2. Medium-traffic files (game connection, status)
3. Low-traffic files (rarely-used features)
4. Complex files last (or defer)

**Process per file:**
```bash
# 1. Migrate file
# 2. Run unit tests
rspec spec/ui/

# 3. Run integration tests
rspec spec/integration/

# 4. Manual test affected features
ruby lich.rbw
# - Test specific feature
# - Verify no errors

# 5. Commit if successful
git add <file>
git commit -m "chore(ui): migrate <file> to Lich::UI"
```

### Step 4: Extended Script Testing (50-60 Scripts)

After all files migrated, run extended test suite:

**File:** `spec/integration/extended_script_compatibility_spec.rb`

```ruby
RSpec.describe 'Extended Script Compatibility', :integration do
  EXTENDED_SCRIPTS = %w[
    # Top 10 (already tested in Phase 3)
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

    # Extended suite (40-50 more)
    drinfomon.lic
    infomon.lic
    spellmonitor.lic
    healdown.lic
    watchme.lic
    sell-loot.lic
    go2-helper.lic
    mapdb.lic
    # ... 30-40 more popular scripts
  ].freeze

  before(:all) do
    Lich::UI.init(:gtk3)
    # Simulate game connection
  end

  EXTENDED_SCRIPTS.each do |script_name|
    it "runs #{script_name} without errors" do
      script_path = find_script(script_name)
      skip "#{script_name} not found" unless script_path

      errors = []

      # Start script, run for 10 seconds, collect errors
      begin
        timeout(10) do
          Script.start(script_name)
        end
      rescue Timeout::Error
        # Script running is OK
      rescue => e
        errors << e.message
      end

      expect(errors).to be_empty, "#{script_name} had errors: #{errors}"
    end
  end
end
```

### Step 5: Performance and Memory Testing

After migration, verify no performance regressions:

```ruby
# spec/performance/ui_performance_spec.rb
RSpec.describe 'Lich::UI Performance' do
  it 'alert method completes in < 100ms' do
    elapsed = Benchmark.realtime do
      UI.alert("Test message")
    end
    expect(elapsed).to be < 0.1
  end

  it 'queue method has minimal overhead' do
    elapsed = Benchmark.realtime do
      1000.times { UI.queue { } }
    end
    expect(elapsed).to be < 1.0  # 1000 calls in < 1s
  end
end
```

### Step 6: Documentation

**File:** `.claude/docs/ADR_CORE_LICH_UI_MIGRATION.md`

Document:
- What was migrated
- What was deferred (and why)
- New `Lich::UI` methods added
- Performance impact
- Testing results

---

## Testing Strategy

### Unit Tests
- Test all new `Lich::UI` methods
- Test migrated components
- Mock GTK3 to avoid UI during tests

### Integration Tests
- **Top 10 scripts:** Regression test (must still pass)
- **Extended suite (50-60 scripts):** Comprehensive test
- Connection workflows
- Settings changes
- Game interactions

### Manual Testing
- Full Lich workflow: start → login → connect → run scripts → exit
- Settings modifications
- All GUI features
- Error scenarios (network failures, etc.)

### Performance Testing
- Benchmark UI operations
- Memory usage comparison (before/after)
- Startup time comparison

---

## Acceptance Criteria Checklist

- [ ] GTK3 audit complete (`GTK3_MIGRATION_INVENTORY.md`)
- [ ] All simple GTK3 calls migrated to `Lich::UI`
- [ ] Complex GTK3 calls documented and deferred (with plan)
- [ ] New `Lich::UI` methods added as needed
- [ ] Unit tests: 30+ examples, all passing
- [ ] Integration tests: Top 10 scripts - zero errors
- [ ] Integration tests: 50-60 scripts - zero errors
- [ ] Performance tests: No regressions
- [ ] RuboCop: 0 offenses
- [ ] Documentation: ADR and developer guide updated
- [ ] Manual testing: Full workflow successful

---

## Script Testing Strategy

### Tier 1: Top 10 Scripts (Critical)
**Must pass with zero errors:**
1. bigshot.lic
2. go2.lic
3. repository.lic
4. waggle.lic
5. loot.lic
6. buff.lic
7. sloot.lic
8. afk.lic
9. autostart.lic
10. xptrack.lic

### Tier 2: Extended Suite (50-60 Scripts)
**Sample additional scripts:**
- drinfomon.lic
- infomon.lic
- spellmonitor.lic
- healdown.lic
- watchme.lic
- sell-loot.lic
- go2-helper.lic
- mapdb.lic
- roomnumber.lic
- narost.lic
- ... (40-50 more based on usage analytics)

**Source for script list:**
- User analytics (most-run scripts)
- Community forum (most-discussed scripts)
- GitHub repository (most-starred scripts)

**Testing methodology:**
1. Run each script for 10-30 seconds
2. Capture stdout, stderr, exceptions
3. Flag any errors
4. Categorize errors (UI-related vs script bugs)

---

## Risks and Mitigations

| Risk | Mitigation |
|------|------------|
| Complex widgets hard to abstract | Defer to future work, document in ADR |
| Performance degradation | Benchmark, optimize delegation layer |
| Script incompatibilities | Maintain backward compat, test extensively |
| Incomplete abstraction | Document limitations, plan future phases |
| Long testing time (60 scripts) | Parallelize tests, automate where possible |

---

## Deferred Work (Known Limitations)

Document items deferred to future work:

### Complex Widgets (Future Phase)
- `Gtk::Builder` / Glade XML integration
- `Gtk::TreeView` advanced features
- Custom drawn widgets
- Embedded HTML/WebKit views

**Interim solution:** Wrap in `UI.queue { <GTK3 code> }`

### Platform-Specific Features
- macOS menu bar integration
- Windows system tray
- Linux desktop notifications

**Interim solution:** Platform detection, graceful degradation

---

## Deliverables

1. ✅ `GTK3_MIGRATION_INVENTORY.md` - Complete audit
2. ✅ Extended `Lich::UI` methods (as needed)
3. ✅ All simple GTK3 calls migrated
4. ✅ `spec/ui/` - Unit tests for new methods
5. ✅ `spec/integration/extended_script_compatibility_spec.rb` - 50-60 scripts
6. ✅ `spec/performance/ui_performance_spec.rb` - Performance tests
7. ✅ `.claude/docs/ADR_CORE_LICH_UI_MIGRATION.md` - Migration notes
8. ✅ Top 10 scripts: **ZERO ERRORS**
9. ✅ Extended suite (50-60 scripts): **ZERO ERRORS**
10. ✅ RuboCop clean, all tests passing
11. ✅ Documentation: Complete developer guide

---

## Completion Criteria

Phase 4 is **COMPLETE** when:

### Functional
- [ ] All core Lich features work
- [ ] Login → Connect → Scripts → Exit (full workflow)
- [ ] Settings/preferences functional
- [ ] All dialogs migrated or documented as deferred

### Testing
- [ ] Top 10 scripts: 100% passing
- [ ] Extended suite (50-60): 95%+ passing (document any failures)
- [ ] Unit tests: 95%+ coverage
- [ ] Performance: No regressions

### Quality
- [ ] RuboCop: 0 offenses
- [ ] No deprecation warnings
- [ ] Code review passed

### Documentation
- [ ] ADR complete
- [ ] Developer guide updated
- [ ] Deferred work documented
- [ ] Migration notes for script authors

---

## Next Steps After Phase 4

After Phase 4 completion, Lich is ready for:

### Option A: GTK4 Backend
- Implement `Lich::UI::GTK4Backend`
- Test with GTK4
- Migrate complex widgets

### Option B: Glimmer SWT Backend
- See `POC_JRUBY_GLIMMER_SWT.md`
- Implement `Lich::UI::GlimmerSWTBackend`
- Test with JRuby

### Option C: Production Release
- Release with GTK3 backend
- Gather user feedback
- Plan next backend based on feedback

---

**Created:** 2025-11-19
**Last Updated:** 2025-11-19
**Status:** Blocked (waiting for Phase 3 approval)
