# Work Unit: Lich::UI Phase 1 - GTK3 Backend Architecture

**Branch:** `feat/lich-ui-abstraction`
**Phase:** 1 of 4 (GTK3 Track)
**Dependencies:** None
**Estimated Effort:** 8-12 hours
**Status:** Ready for execution

---

## Objective

Create the `Lich::UI` abstraction layer with GTK3 as the default backend, designed to support future backends (GTK4, Glimmer SWT, etc.) without breaking changes.

---

## Success Criteria

- [ ] `Lich::UI` module with clean API surface
- [ ] `Lich::UI::GTK3Backend` implements all required methods
- [ ] Backend selection via environment variable or configuration
- [ ] Comprehensive unit tests (90%+ coverage)
- [ ] RuboCop clean (0 offenses)
- [ ] Documentation (inline + YARD)
- [ ] Zero regression on existing GTK3 functionality

---

## Technical Requirements

### 1. Lich::UI Module Structure

**File:** `lib/common/ui.rb`

```ruby
# lib/common/ui.rb
module Lich
  module UI
    VERSION = '1.0.0'

    @backend = nil

    # Initialize UI backend
    # @param backend_name [String, Symbol] Backend to use (:gtk3, :gtk4, :glimmer_swt)
    # @return [void]
    def self.init(backend_name = nil)
      backend_name ||= ENV['LICH_UI_BACKEND'] || :gtk3

      @backend = case backend_name.to_sym
                 when :gtk3
                   require_relative 'ui/gtk3_backend'
                   Lich::UI::GTK3Backend
                 when :gtk4
                   require_relative 'ui/gtk4_backend'
                   Lich::UI::GTK4Backend
                 when :glimmer_swt
                   require_relative 'ui/glimmer_swt_backend'
                   Lich::UI::GlimmerSWTBackend
                 else
                   raise ArgumentError, "Unknown backend: #{backend_name}"
                 end

      @backend.init
    end

    # Get current backend
    # @return [Class] Backend class
    def self.backend
      @backend || (init && @backend)
    end

    # Delegate method calls to backend
    def self.method_missing(method, *args, **kwargs, &block)
      if backend.respond_to?(method)
        backend.public_send(method, *args, **kwargs, &block)
      else
        super
      end
    end

    def self.respond_to_missing?(method, include_private = false)
      backend.respond_to?(method) || super
    end
  end
end
```

### 2. Backend Interface Contract

**File:** `lib/common/ui/base_backend.rb`

Define the abstract interface all backends must implement:

```ruby
# lib/common/ui/base_backend.rb
module Lich
  module UI
    class BaseBackend
      # Initialize backend
      # @return [void]
      def self.init
        raise NotImplementedError, "#{self.class} must implement #init"
      end

      # Show alert dialog
      # @param message [String] Alert message
      # @param title [String] Dialog title
      # @param type [Symbol] Alert type (:info, :warning, :error)
      # @return [void]
      def self.alert(message, title: 'Alert', type: :info)
        raise NotImplementedError, "#{self.class} must implement #alert"
      end

      # Show confirmation dialog
      # @param message [String] Confirmation message
      # @param title [String] Dialog title
      # @return [Boolean] True if user confirmed
      def self.confirm(message, title: 'Confirm')
        raise NotImplementedError, "#{self.class} must implement #confirm"
      end

      # Prompt for text input
      # @param message [String] Prompt message
      # @param title [String] Dialog title
      # @param default [String] Default value
      # @param password [Boolean] Mask input as password
      # @return [String, nil] User input or nil if cancelled
      def self.prompt(message, title: 'Input', default: '', password: false)
        raise NotImplementedError, "#{self.class} must implement #prompt"
      end

      # Queue UI operation on main thread
      # @yield Block to execute on UI thread
      # @return [void]
      def self.queue(&block)
        raise NotImplementedError, "#{self.class} must implement #queue"
      end

      # Create window
      # @param title [String] Window title
      # @param width [Integer] Window width
      # @param height [Integer] Window height
      # @yield Block for window content
      # @return [Object] Window object (backend-specific)
      def self.window(title:, width: 800, height: 600, &block)
        raise NotImplementedError, "#{self.class} must implement #window"
      end

      # File chooser dialog
      # @param title [String] Dialog title
      # @param action [Symbol] Action type (:open, :save, :select_folder)
      # @param filters [Array<Hash>] File filters [{name: 'Text', patterns: ['*.txt']}]
      # @return [String, nil] Selected file path or nil
      def self.file_chooser(title: 'Choose File', action: :open, filters: [])
        raise NotImplementedError, "#{self.class} must implement #file_chooser"
      end

      # Start main event loop
      # @return [void]
      def self.main
        raise NotImplementedError, "#{self.class} must implement #main"
      end

      # Stop main event loop
      # @return [void]
      def self.quit
        raise NotImplementedError, "#{self.class} must implement #quit"
      end
    end
  end
end
```

### 3. GTK3 Backend Implementation

**File:** `lib/common/ui/gtk3_backend.rb`

Implement GTK3 backend wrapping existing GTK3 functionality:

```ruby
# lib/common/ui/gtk3_backend.rb
require 'gtk3'

module Lich
  module UI
    class GTK3Backend < BaseBackend
      @initialized = false

      def self.init
        return if @initialized
        Gtk.init if Gtk.respond_to?(:init)
        @initialized = true
      end

      def self.alert(message, title: 'Alert', type: :info)
        queue do
          dialog = Gtk::MessageDialog.new(
            parent: nil,
            flags: :modal,
            type: gtk_message_type(type),
            buttons_type: :ok,
            message: message
          )
          dialog.title = title
          dialog.run
          dialog.destroy
        end
      end

      def self.confirm(message, title: 'Confirm')
        response = nil
        queue do
          dialog = Gtk::MessageDialog.new(
            parent: nil,
            flags: :modal,
            type: :question,
            buttons_type: :yes_no,
            message: message
          )
          dialog.title = title
          response = dialog.run
          dialog.destroy
        end
        response == Gtk::ResponseType::YES
      end

      def self.prompt(message, title: 'Input', default: '', password: false)
        result = nil
        queue do
          dialog = Gtk::Dialog.new(
            title: title,
            parent: nil,
            flags: :modal,
            buttons: [
              [Gtk::Stock::CANCEL, Gtk::ResponseType::CANCEL],
              [Gtk::Stock::OK, Gtk::ResponseType::OK]
            ]
          )

          label = Gtk::Label.new(message)
          entry = Gtk::Entry.new
          entry.text = default
          entry.visibility = !password

          dialog.child.pack_start(label, padding: 10)
          dialog.child.pack_start(entry, padding: 10)
          dialog.show_all

          if dialog.run == Gtk::ResponseType::OK
            result = entry.text
          end

          dialog.destroy
        end
        result
      end

      def self.queue(&block)
        if Thread.current == Thread.main
          block.call
        else
          Gtk.queue(&block)
        end
      end

      def self.window(title:, width: 800, height: 600, &block)
        win = Gtk::Window.new(title)
        win.set_default_size(width, height)
        block.call(win) if block
        win
      end

      def self.file_chooser(title: 'Choose File', action: :open, filters: [])
        result = nil
        queue do
          dialog = Gtk::FileChooserDialog.new(
            title: title,
            parent: nil,
            action: gtk_file_chooser_action(action),
            buttons: [
              [Gtk::Stock::CANCEL, Gtk::ResponseType::CANCEL],
              [Gtk::Stock::OPEN, Gtk::ResponseType::ACCEPT]
            ]
          )

          filters.each do |filter_spec|
            filter = Gtk::FileFilter.new
            filter.name = filter_spec[:name]
            filter_spec[:patterns].each { |p| filter.add_pattern(p) }
            dialog.add_filter(filter)
          end

          if dialog.run == Gtk::ResponseType::ACCEPT
            result = dialog.filename
          end

          dialog.destroy
        end
        result
      end

      def self.main
        Gtk.main
      end

      def self.quit
        Gtk.main_quit
      end

      private

      def self.gtk_message_type(type)
        case type
        when :info then Gtk::MessageType::INFO
        when :warning then Gtk::MessageType::WARNING
        when :error then Gtk::MessageType::ERROR
        else Gtk::MessageType::INFO
        end
      end

      def self.gtk_file_chooser_action(action)
        case action
        when :open then Gtk::FileChooserAction::OPEN
        when :save then Gtk::FileChooserAction::SAVE
        when :select_folder then Gtk::FileChooserAction::SELECT_FOLDER
        else Gtk::FileChooserAction::OPEN
        end
      end
    end
  end
end
```

### 4. Configuration Support

**File:** Update `lib/common/settings.rb` or create `lib/common/ui_config.rb`

```ruby
# lib/common/ui_config.rb
module Lich
  module UI
    class Config
      DEFAULT_BACKEND = :gtk3

      def self.backend
        ENV['LICH_UI_BACKEND']&.to_sym || DEFAULT_BACKEND
      end

      def self.backend=(name)
        ENV['LICH_UI_BACKEND'] = name.to_s
      end
    end
  end
end
```

---

## Implementation Steps

### Step 1: Create Directory Structure
```bash
mkdir -p lib/common/ui
```

### Step 2: Create Base Files
1. `lib/common/ui.rb` - Main module
2. `lib/common/ui/base_backend.rb` - Abstract interface
3. `lib/common/ui/gtk3_backend.rb` - GTK3 implementation
4. `lib/common/ui_config.rb` - Configuration

### Step 3: Write Unit Tests
**File:** `spec/ui/lich_ui_spec.rb`

```ruby
RSpec.describe Lich::UI do
  describe '.init' do
    it 'initializes GTK3 backend by default'
    it 'initializes specified backend'
    it 'raises error for unknown backend'
  end

  describe '.backend' do
    it 'returns current backend'
    it 'auto-initializes if not initialized'
  end

  describe 'method delegation' do
    it 'delegates alert to backend'
    it 'delegates confirm to backend'
    it 'delegates prompt to backend'
  end
end
```

**File:** `spec/ui/gtk3_backend_spec.rb`

```ruby
RSpec.describe Lich::UI::GTK3Backend do
  describe '.init' do
    it 'initializes GTK3 once'
    it 'is idempotent'
  end

  describe '.alert' do
    it 'shows info alert'
    it 'shows warning alert'
    it 'shows error alert'
  end

  describe '.confirm' do
    it 'returns true when confirmed'
    it 'returns false when cancelled'
  end

  describe '.prompt' do
    it 'returns user input'
    it 'returns nil when cancelled'
    it 'masks password input'
  end

  describe '.queue' do
    it 'executes block on UI thread'
    it 'executes immediately if on main thread'
  end
end
```

### Step 4: Integration with Lich Core

Update `lich.rbw` to initialize Lich::UI:

```ruby
# lich.rbw (early in boot sequence)
require_relative 'lib/common/ui'

Lich::UI.init  # Initialize default backend
```

### Step 5: Documentation

- Inline YARD documentation for all public methods
- Architecture decision record: `ADR_LICH_UI_ABSTRACTION.md`
- Developer guide: `LICH_UI_DEVELOPER_GUIDE.md`

---

## Testing Strategy

### Unit Tests
- Test `Lich::UI` module initialization
- Test backend delegation
- Test GTK3Backend methods (mocked GTK3)
- Edge cases: nil values, empty strings, cancelled dialogs

### Integration Tests
- Backend switching (GTK3 ↔ future backends)
- Configuration via ENV variable
- Thread safety (queue method)

### Manual Tests
- Run Lich with GTK3 backend
- Verify existing GTK dialogs still work
- No visual changes to user

---

## Acceptance Criteria Checklist

- [ ] All files created in correct locations
- [ ] `Lich::UI.init` works with default (GTK3) backend
- [ ] `Lich::UI.alert`, `.confirm`, `.prompt` delegate correctly
- [ ] `Lich::UI::GTK3Backend` implements all BaseBackend methods
- [ ] Unit tests: 20+ examples, 90%+ coverage
- [ ] RuboCop: 0 offenses
- [ ] Documentation: All public methods have YARD docs
- [ ] Zero regression: Existing GTK3 functionality unchanged
- [ ] Architecture: Extensible for GTK4, Glimmer SWT

---

## Risks and Mitigations

| Risk | Mitigation |
|------|------------|
| GTK3 threading issues | Use `queue` for all GTK operations |
| Performance overhead | Keep delegation lightweight (method_missing) |
| Incomplete interface | Review all GTK usage in codebase before finalizing |
| Breaking existing code | Phase 1 adds new code only, no replacements yet |

---

## Deliverables

1. ✅ `lib/common/ui.rb` - Core module
2. ✅ `lib/common/ui/base_backend.rb` - Interface contract
3. ✅ `lib/common/ui/gtk3_backend.rb` - GTK3 implementation
4. ✅ `lib/common/ui_config.rb` - Configuration
5. ✅ `spec/ui/lich_ui_spec.rb` - Unit tests
6. ✅ `spec/ui/gtk3_backend_spec.rb` - Backend tests
7. ✅ `.claude/docs/ADR_LICH_UI_ABSTRACTION.md` - Architecture decision
8. ✅ RuboCop clean, tests passing

---

## Next Phase

**Phase 2:** Script API Modernization (`LICH_UI_PHASE_2_SCRIPT_API.md`)

After this phase completes, proceed to Phase 2 to inject `Lich::UI` into script bindings.

---

**Created:** 2025-11-19
**Last Updated:** 2025-11-19
**Status:** Ready for CLI execution
