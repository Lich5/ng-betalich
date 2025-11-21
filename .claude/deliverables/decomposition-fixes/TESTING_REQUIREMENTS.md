# Testing Requirements: Integration and Dependency Verification

**Date:** 2025-11-12
**Purpose:** Define testing requirements to catch missing requires, methods, and integration issues
**Status:** REQUIREMENT ONLY - Do not implement yet

---

## Problem Statement

**Current testing approach missed critical gaps:**
- Missing `require_relative` statements → Not caught
- Missing methods called by other modules → Not caught
- Security regressions (file permissions) → Not caught
- Integration failures (GUI prompt fallback) → Not caught

**Root cause:** Heavy use of mocks/stubs means tests never actually load or call real dependencies.

---

## Requirement: Dual-Mode Test Support

Tests should operate in **two modes** based on environment:

### Mode 1: Full Integration (Doug's Environment)
**When:** Running on macOS/Linux with all tools installed
**Behavior:**
- Actually load all modules with `require`
- Actually call real methods (no mocking of internal dependencies)
- Actually test file operations and permissions
- Actually test keychain operations (macOS `security`, Linux `secret-tool`)
- Verify cross-module integration works end-to-end

**Example:**
```ruby
RSpec.describe Lich::Common::GUI::ConversionUI do
  # In full integration mode:
  # - Actually requires conversion_ui.rb
  # - Actually requires master_password_manager.rb (via require_relative)
  # - If require fails → Test fails (catches missing require)
  # - Actually calls MasterPasswordManager.keychain_available?
  # - If method missing → Test fails (catches missing method)

  it "checks keychain availability" do
    # Real call, no mocking
    result = Lich::Common::GUI::MasterPasswordManager.keychain_available?
    expect(result).to be_in([true, false])
  end
end
```

---

### Mode 2: Stubbed Environment (Sandbox, GitHub Actions)
**When:** Running in environments lacking tools (no keychain, no GTK, etc.)
**Behavior:**
- Still load all modules with `require` (catches missing requires)
- Stub external dependencies (keychain, GTK, filesystem)
- Stub system commands that would fail
- Focus on logic/flow testing, not integration

**Example:**
```ruby
RSpec.describe Lich::Common::GUI::ConversionUI do
  before do
    if ENV['CI'] || ENV['STUB_MODE']
      # Stub external dependencies only
      allow(Lich::Common::GUI::MasterPasswordManager).to receive(:keychain_available?).and_return(true)
      allow_any_instance_of(Gtk::Dialog).to receive(:run).and_return(Gtk::ResponseType::OK)
    end
  end

  it "checks keychain availability" do
    # Still calls the method (catches if method doesn't exist)
    result = Lich::Common::GUI::MasterPasswordManager.keychain_available?
    expect(result).to be_in([true, false])
  end
end
```

---

## Required Test Coverage

### 1. Module Loading Tests
**Purpose:** Catch missing `require_relative` statements

```ruby
RSpec.describe "Module Loading" do
  describe "GUI modules" do
    it "loads conversion_ui.rb without error" do
      expect { require_relative '../lib/common/gui/conversion_ui' }.not_to raise_error
    end

    it "loads yaml_state.rb without error" do
      expect { require_relative '../lib/common/gui/yaml_state' }.not_to raise_error
    end

    # Test that constants are defined after require
    it "defines MasterPasswordManager constant" do
      require_relative '../lib/common/gui/master_password_manager'
      expect(defined?(Lich::Common::GUI::MasterPasswordManager)).to eq('constant')
    end
  end
end
```

---

### 2. Cross-Module Dependency Tests
**Purpose:** Catch missing methods called by other modules

```ruby
RSpec.describe "Cross-Module Dependencies" do
  describe "ConversionUI → MasterPasswordManager" do
    it "can call keychain_available? method" do
      # Don't stub the method - actually call it
      expect(Lich::Common::GUI::ConversionUI).to respond_to(:conversion_needed?)
      expect(Lich::Common::GUI::MasterPasswordManager).to respond_to(:keychain_available?)

      # Actually call it (will fail if method missing)
      expect { Lich::Common::GUI::MasterPasswordManager.keychain_available? }.not_to raise_error
    end
  end

  describe "YamlState → MasterPasswordPrompt" do
    it "can call show_create_master_password_dialog method" do
      expect(Lich::Common::GUI::MasterPasswordPrompt).to respond_to(:show_create_master_password_dialog)
    end

    it "can call ensure_master_password_exists method" do
      expect(Lich::Common::GUI::YamlState).to respond_to(:ensure_master_password_exists)
    end
  end
end
```

---

### 3. File Permissions Tests
**Purpose:** Catch security regressions

```ruby
RSpec.describe "File Permissions" do
  let(:test_dir) { Dir.mktmpdir }
  let(:test_file) { File.join(test_dir, "entry.yaml") }

  after { FileUtils.rm_rf(test_dir) }

  it "creates YAML files with 0600 permissions" do
    yaml_data = { 'encryption_mode' => 'standard', 'accounts' => {} }

    Lich::Common::GUI::YamlState.save_entries(test_dir, [])

    # Check file permissions
    stat = File.stat(test_file)
    mode = stat.mode & 0777

    expect(mode).to eq(0600), "Expected 0600 but got #{mode.to_s(8)}"
  end

  it "creates backup files with secure permissions" do
    # Create initial file
    Lich::Common::GUI::YamlState.save_entries(test_dir, [])

    # Modify and save again (creates backup)
    Lich::Common::GUI::YamlState.save_entries(test_dir, [{char_name: 'Test'}])

    backup_file = test_file + '.backup'
    if File.exist?(backup_file)
      stat = File.stat(backup_file)
      mode = stat.mode & 0777
      expect(mode).to eq(0600)
    end
  end
end
```

---

### 4. Integration Flow Tests
**Purpose:** Catch end-to-end integration failures

```ruby
RSpec.describe "Integration Flows" do
  describe "Enhanced mode conversion" do
    let(:test_dir) { Dir.mktmpdir }

    before do
      # Create entry.dat file
      legacy_data = [{
        user_id: 'TESTUSER',
        password: 'testpass',
        char_name: 'Testchar',
        game_code: 'GS'
      }]
      File.open(File.join(test_dir, 'entry.dat'), 'w') do |f|
        f.write([Marshal.dump(legacy_data)].pack('m'))
      end

      if ENV['CI']
        # Stub keychain for CI
        allow(Lich::Common::GUI::MasterPasswordManager).to receive(:store_master_password).and_return(true)
        allow(Lich::Common::GUI::MasterPasswordManager).to receive(:retrieve_master_password).and_return('testmaster')
        allow(Lich::Common::GUI::MasterPasswordPrompt).to receive(:show_create_master_password_dialog).and_return('testmaster')
      end
    end

    after { FileUtils.rm_rf(test_dir) }

    it "completes enhanced mode conversion flow" do
      # This tests the FULL flow:
      # 1. YamlState.migrate_from_legacy calls
      # 2. YamlState.ensure_master_password_exists which calls
      # 3. MasterPasswordPrompt.show_create_master_password_dialog which calls
      # 4. MasterPasswordManager.store_master_password
      # 5. PasswordCipher.encrypt with master password

      result = Lich::Common::GUI::YamlState.migrate_from_legacy(
        test_dir,
        encryption_mode: :enhanced
      )

      expect(result).to be true

      yaml_file = File.join(test_dir, 'entry.yaml')
      expect(File.exist?(yaml_file)).to be true

      yaml_data = YAML.load_file(yaml_file)
      expect(yaml_data['encryption_mode']).to eq('enhanced')
    end
  end
end
```

---

## Environment Detection

**Suggested approach:**

```ruby
# spec/spec_helper.rb or login_spec_helper.rb

module TestMode
  def self.full_integration?
    # Full integration if:
    # - Not in CI
    # - Not in STUB_MODE
    # - Has required tools (security or secret-tool)
    !ENV['CI'] &&
    !ENV['STUB_MODE'] &&
    (system('which security >/dev/null 2>&1') || system('which secret-tool >/dev/null 2>&1'))
  end

  def self.stub_mode?
    !full_integration?
  end
end

RSpec.configure do |config|
  config.before(:suite) do
    if TestMode.full_integration?
      puts "Running in FULL INTEGRATION mode"
    else
      puts "Running in STUB mode (limited environment)"
    end
  end

  config.before(:each) do
    if TestMode.stub_mode?
      # Auto-stub external dependencies
      stub_keychain_operations
      stub_gtk_dialogs
      stub_system_commands
    end
  end
end
```

---

## Success Criteria

**These gaps would be caught by proper integration tests:**

1. ✅ Missing `require_relative 'master_password_manager'` in `conversion_ui.rb`
   - **Caught by:** Module loading test + cross-module dependency test

2. ✅ Missing `ensure_master_password_exists` method in `yaml_state.rb`
   - **Caught by:** Integration flow test calling `migrate_from_legacy`

3. ✅ Missing file permissions `0600`
   - **Caught by:** File permissions test checking created files

4. ✅ Missing methods in `password_change.rb` for enhanced mode
   - **Caught by:** Integration test trying to change password in enhanced mode

---

## Implementation Guidance (DO NOT IMPLEMENT YET)

**When implementing:**

1. Start with module loading tests (easiest)
2. Add cross-module dependency tests
3. Add file permissions tests
4. Add integration flow tests (most complex)
5. Test in both modes (Doug's Mac + sandbox/CI)
6. Ensure CI runs in stub mode gracefully

**Key principles:**
- Don't mock internal module methods (only external dependencies)
- Actually load modules with `require`
- Actually call methods across module boundaries
- Stub only when tools don't exist (keychain, GTK)

---

## Priority

**Priority:** HIGH - Needed to prevent future decomposition errors

**Estimated effort:** 20-30 hours
- Module loading tests: 2 hours
- Cross-module tests: 4 hours
- File permissions tests: 3 hours
- Integration flow tests: 10 hours
- Environment detection setup: 4 hours
- Testing both modes: 6 hours

---

## Notes

This requirement document captures what SHOULD exist. Do not implement until:
1. Current gaps (PR #51, PR #55) are patched and tested
2. We confirm this approach aligns with project testing strategy
3. We determine where in backlog this work should be prioritized

**This is a requirement, not a task assignment.**
