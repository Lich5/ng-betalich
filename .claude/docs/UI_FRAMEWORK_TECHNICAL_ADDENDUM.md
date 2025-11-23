# UI Framework Migration: Technical Implementation Addendum

**Date:** 2025-11-19
**Purpose:** Technical pseudocode examples for UI framework migration paths
**Related:** UI_FRAMEWORK_DECISION.md

---

## OVERVIEW: LICH::UI ABSTRACTION LAYER

### When is Lich::UI Essential?

| Scenario | Lich::UI Required? | Why |
|----------|-------------------|-----|
| **Dual framework support** (core on Framework X, scripts on GTK3 during migration) | ✅ **ESSENTIAL** | Enables gradual migration, scripts can use either backend |
| **Single framework migration** (all at once, no transition period) | 🟡 **RECOMMENDED** | Future-proofs against next migration, but not strictly required |
| **Staying on GTK3** (no migration) | ❌ **NOT NEEDED** | No abstraction benefit if not migrating |
| **LibUI/FXRuby path** (simple, no Glade XML) | 🟡 **RECOMMENDED** | Simplifies script development, optional |
| **GTK4 path** (Glade XML preserved) | 🟡 **RECOMMENDED** | Less critical since Gtk::Builder still works |
| **Glimmer SWT path** (JRuby migration) | ✅ **ESSENTIAL** | Provides compatibility layer during JRuby transition |

**Bottom line:** Lich::UI is **essential for dual-framework scenarios** and **highly recommended for all paths** as future-proofing.

---

## LICH::UI ARCHITECTURE

### Core Design

```ruby
# lib/lich/ui.rb
module Lich
  module UI
    class << self
      attr_accessor :backend
    end

    # Auto-detect or manually set backend
    def self.init(backend_name = nil)
      @backend = case backend_name || ENV['LICH_UI_BACKEND']
                 when 'gtk3' then Lich::UI::GTK3Backend
                 when 'gtk4' then Lich::UI::GTK4Backend
                 when 'libui' then Lich::UI::LibUIBackend
                 when 'fxruby' then Lich::UI::FXRubyBackend
                 when 'glimmer_swt' then Lich::UI::GlimmerSWTBackend
                 else Lich::UI::GTK3Backend # Default (current state)
                 end
      @backend.init if @backend.respond_to?(:init)
    end

    # Facade methods delegate to backend
    def self.alert(message, title: "Alert")
      backend.alert(message, title: title)
    end

    def self.confirm(message, title: "Confirm")
      backend.confirm(message, title: title)
    end

    def self.window(title, width: 800, height: 600, &block)
      backend.window(title, width: width, height: height, &block)
    end

    # DSL builder for complex UIs
    def self.build(&block)
      Builder.new(backend).instance_eval(&block)
    end
  end
end
```

---

### Backend Interface Contract

```ruby
# lib/lich/ui/base_backend.rb
module Lich
  module UI
    class BaseBackend
      # Simple dialogs
      def self.alert(message, title: "Alert")
        raise NotImplementedError, "Subclass must implement alert"
      end

      def self.confirm(message, title: "Confirm")
        raise NotImplementedError, "Subclass must implement confirm"
      end

      def self.prompt(message, default: "", title: "Input")
        raise NotImplementedError, "Subclass must implement prompt"
      end

      # Window management
      def self.window(title, width: 800, height: 600, &block)
        raise NotImplementedError, "Subclass must implement window"
      end

      # Widget primitives
      def self.label(text)
        raise NotImplementedError, "Subclass must implement label"
      end

      def self.button(text, &action)
        raise NotImplementedError, "Subclass must implement button"
      end

      def self.entry(placeholder: "", &on_change)
        raise NotImplementedError, "Subclass must implement entry"
      end

      def self.checkbox(label, checked: false, &on_toggle)
        raise NotImplementedError, "Subclass must implement checkbox"
      end

      # Layout primitives
      def self.vertical_box(&block)
        raise NotImplementedError, "Subclass must implement vertical_box"
      end

      def self.horizontal_box(&block)
        raise NotImplementedError, "Subclass must implement horizontal_box"
      end

      # Event loop integration
      def self.queue(&block)
        raise NotImplementedError, "Subclass must implement queue"
      end
    end
  end
end
```

---

## BACKEND IMPLEMENTATIONS (PSEUDOCODE)

### GTK3 Backend (Current State)

```ruby
# lib/lich/ui/gtk3_backend.rb
module Lich
  module UI
    class GTK3Backend < BaseBackend
      def self.init
        # GTK3 already initialized in lich.rbw
      end

      def self.alert(message, title: "Alert")
        Gtk.queue do
          dialog = Gtk::MessageDialog.new(
            parent: nil,
            flags: :modal,
            type: :info,
            buttons: :ok,
            message: message
          )
          dialog.title = title
          dialog.run
          dialog.destroy
        end
      end

      def self.confirm(message, title: "Confirm")
        result = nil
        Gtk.queue do
          dialog = Gtk::MessageDialog.new(
            parent: nil,
            flags: :modal,
            type: :question,
            buttons: :yes_no,
            message: message
          )
          dialog.title = title
          result = (dialog.run == Gtk::ResponseType::YES)
          dialog.destroy
        end
        result
      end

      def self.window(title, width: 800, height: 600, &block)
        window = Gtk::Window.new
        window.title = title
        window.set_default_size(width, height)

        # Yield builder context if block given
        if block_given?
          builder = WindowBuilder.new(window)
          builder.instance_eval(&block)
        end

        window.show_all
        window
      end

      def self.queue(&block)
        Gtk.queue(&block)
      end

      # Helper for building windows
      class WindowBuilder
        def initialize(window)
          @window = window
          @container = Gtk::Box.new(:vertical)
          @window.add(@container)
        end

        def label(text)
          lbl = Gtk::Label.new(text)
          @container.pack_start(lbl, expand: false, fill: false, padding: 5)
          lbl
        end

        def button(text, &action)
          btn = Gtk::Button.new(label: text)
          btn.signal_connect('clicked', &action) if action
          @container.pack_start(btn, expand: false, fill: false, padding: 5)
          btn
        end

        def entry(placeholder: "", &on_change)
          ent = Gtk::Entry.new
          ent.placeholder_text = placeholder unless placeholder.empty?
          ent.signal_connect('changed') { on_change.call(ent.text) } if on_change
          @container.pack_start(ent, expand: false, fill: false, padding: 5)
          ent
        end
      end
    end
  end
end
```

---

### GTK4 Backend

```ruby
# lib/lich/ui/gtk4_backend.rb
module Lich
  module UI
    class GTK4Backend < BaseBackend
      def self.init
        # GTK4 initialization (similar to GTK3 but different API)
        # Note: GTK4 removes Gtk.queue, uses GLib::Idle.add instead
      end

      def self.alert(message, title: "Alert")
        # GTK4 uses Gtk::AlertDialog (new API)
        dialog = Gtk::AlertDialog.new(message: message)
        dialog.show(nil) # nil = no parent window
      end

      def self.confirm(message, title: "Confirm")
        # GTK4 async pattern (different from GTK3)
        dialog = Gtk::AlertDialog.new(message: message)
        dialog.buttons = ["No", "Yes"]

        # Note: GTK4 uses async callbacks, not blocking run()
        result = nil
        dialog.choose(nil) do |_source, res|
          response = dialog.choose_finish(res)
          result = (response == 1) # "Yes" button index
        end

        # In real implementation, would need to block/wait here
        result
      end

      def self.window(title, width: 800, height: 600, &block)
        # GTK4 uses Gtk::ApplicationWindow (different pattern)
        window = Gtk::Window.new
        window.title = title
        window.set_default_size(width, height)

        if block_given?
          builder = WindowBuilder.new(window)
          builder.instance_eval(&block)
        end

        window.present # GTK4 uses present() instead of show_all()
        window
      end

      def self.queue(&block)
        # GTK4 doesn't have Gtk.queue, use GLib::Idle
        GLib::Idle.add do
          block.call
          false # Don't repeat
        end
      end

      class WindowBuilder
        def initialize(window)
          @window = window
          @container = Gtk::Box.new(:vertical, 5) # GTK4 syntax
          @window.set_child(@container) # GTK4 uses set_child, not add
        end

        def label(text)
          lbl = Gtk::Label.new(text)
          @container.append(lbl) # GTK4 uses append, not pack_start
          lbl
        end

        def button(text, &action)
          btn = Gtk::Button.new(label: text)
          btn.signal_connect('clicked', &action) if action
          @container.append(btn)
          btn
        end

        def entry(placeholder: "", &on_change)
          ent = Gtk::Entry.new
          ent.placeholder_text = placeholder unless placeholder.empty?
          ent.signal_connect('changed') { on_change.call(ent.text) } if on_change
          @container.append(ent)
          ent
        end
      end
    end
  end
end
```

---

### LibUI Backend

```ruby
# lib/lich/ui/libui_backend.rb
require 'libui'

module Lich
  module UI
    class LibUIBackend < BaseBackend
      def self.init
        UI.init
      end

      def self.alert(message, title: "Alert")
        UI.msg_box(title, message)
      end

      def self.confirm(message, title: "Confirm")
        # LibUI doesn't have built-in confirm, use custom window
        result = false
        window = UI.new_window(title, 400, 100, 0)

        vbox = UI.new_vertical_box
        UI.window_set_child(window, vbox)

        label = UI.new_label(message)
        UI.box_append(vbox, label, 0)

        hbox = UI.new_horizontal_box
        UI.box_append(vbox, hbox, 0)

        yes_btn = UI.new_button("Yes")
        UI.button_on_clicked(yes_btn) do
          result = true
          UI.control_destroy(window)
          0
        end
        UI.box_append(hbox, yes_btn, 1)

        no_btn = UI.new_button("No")
        UI.button_on_clicked(no_btn) do
          result = false
          UI.control_destroy(window)
          0
        end
        UI.box_append(hbox, no_btn, 1)

        UI.window_on_closing(window) { UI.control_destroy(window); 0 }
        UI.control_show(window)

        # Note: LibUI uses event loop, this is simplified
        result
      end

      def self.window(title, width: 800, height: 600, &block)
        window = UI.new_window(title, width, height, 1) # 1 = has menubar

        if block_given?
          builder = WindowBuilder.new(window)
          builder.instance_eval(&block)
        end

        UI.window_on_closing(window) { UI.quit; 0 }
        UI.control_show(window)
        window
      end

      def self.queue(&block)
        UI.queue_main(&block)
      end

      class WindowBuilder
        def initialize(window)
          @window = window
          @container = UI.new_vertical_box
          UI.window_set_child(@window, @container)
        end

        def label(text)
          lbl = UI.new_label(text)
          UI.box_append(@container, lbl, 0)
          lbl
        end

        def button(text, &action)
          btn = UI.new_button(text)
          UI.button_on_clicked(btn, &action) if action
          UI.box_append(@container, btn, 0)
          btn
        end

        def entry(placeholder: "", &on_change)
          ent = UI.new_entry
          # LibUI doesn't have placeholder text built-in
          UI.entry_on_changed(ent) { |e| on_change.call(UI.entry_text(e)) } if on_change
          UI.box_append(@container, ent, 0)
          ent
        end
      end
    end
  end
end
```

---

### Glimmer SWT Backend

```ruby
# lib/lich/ui/glimmer_swt_backend.rb
require 'glimmer-dsl-swt'

module Lich
  module UI
    class GlimmerSWTBackend < BaseBackend
      def self.init
        # Glimmer DSL auto-initializes SWT
      end

      def self.alert(message, title: "Alert")
        shell {
          text title
          message_box {
            text title
            message message
          }.open
        }.open
      end

      def self.confirm(message, title: "Confirm")
        result = false
        shell {
          text title
          mb = message_box(:yes_no) {
            text title
            message message
          }
          result = (mb.open == Glimmer::SWT::SWTProxy::CONST_MAPPING[:yes])
        }.open
        result
      end

      def self.window(title, width: 800, height: 600, &block)
        shell {
          text title
          minimum_size width, height

          if block_given?
            builder = WindowBuilder.new(self)
            builder.instance_eval(&block)
          end
        }.open
      end

      def self.queue(&block)
        # Glimmer SWT uses sync_exec for thread-safe UI updates
        Glimmer::SWT::DisplayProxy.instance.sync_exec(&block)
      end

      class WindowBuilder
        def initialize(shell)
          @shell = shell
          @shell.instance_eval do
            @container = composite {
              layout :vertical
            }
          end
        end

        def label(text)
          @shell.instance_eval do
            @container.content {
              label {
                text text
              }
            }
          end
        end

        def button(text, &action)
          @shell.instance_eval do
            @container.content {
              button {
                text text
                on_widget_selected(&action) if action
              }
            }
          end
        end

        def entry(placeholder: "", &on_change)
          @shell.instance_eval do
            @container.content {
              text {
                message placeholder unless placeholder.empty?
                on_modify { |event| on_change.call(event.widget.text) } if on_change
              }
            }
          end
        end
      end
    end
  end
end
```

---

## SCRIPT API MODERNIZATION

### Current Script Execution (script.rb)

```ruby
# lib/common/script.rb (current - simplified)
class Script
  def self.start(script_name, args = nil)
    # Load script file
    script_data = File.read("#{SCRIPT_DIR}/#{script_name}.lic")

    # Create isolated binding
    script_binding = TRUSTED_SCRIPT_BINDING.call

    # Eval script in binding
    Thread.new do
      eval(script_data, script_binding, script_name)
    end
  end
end

# Scripts call GTK directly:
Gtk.queue do
  window = Gtk::Window.new
  # ...
end
```

---

### Modernized Script API (with Lich::UI)

```ruby
# lib/common/script.rb (modernized)
module Lich
  module Common
    class Script
      # ... existing code ...

      def self.start(script_name, args = nil)
        # Load script file
        script_data = File.read("#{SCRIPT_DIR}/#{script_name}.lic")

        # Create isolated binding WITH Lich::UI available
        script_binding = TRUSTED_SCRIPT_BINDING.call

        # Inject Lich::UI into script binding
        eval('UI = Lich::UI', script_binding)

        # Eval script in binding
        Thread.new do
          eval(script_data, script_binding, script_name)
        end
      end
    end
  end
end

# Scripts can now use abstraction:
UI.alert("Hello from script!")

# OR still call GTK directly (backwards compatible):
Gtk.queue do
  window = Gtk::Window.new
  # ...
end
```

---

### Dual Framework Support Pattern

**Use case:** Core Lich on GTK4, scripts still on GTK3 during migration

```ruby
# lib/lich.rb (main initialization)
require 'lich/ui'

# Core Lich uses GTK4
Lich::UI.init('gtk4')

# But provide GTK3 backend for scripts
module Lich
  module ScriptUI
    extend Lich::UI::GTK3Backend
  end
end

# lib/common/script.rb (modernized with dual backend)
def self.start(script_name, args = nil)
  script_data = File.read("#{SCRIPT_DIR}/#{script_name}.lic")
  script_binding = TRUSTED_SCRIPT_BINDING.call

  # Scripts get GTK3 backend by default
  eval('UI = Lich::ScriptUI', script_binding)

  # But can opt-in to new backend
  eval('UI_NEW = Lich::UI', script_binding)

  Thread.new do
    eval(script_data, script_binding, script_name)
  end
end
```

**Script migration pattern:**

```ruby
# OLD script (uses GTK3 directly):
Gtk.queue do
  window = Gtk::Window.new("Setup")
  # ... GTK3 code
end

# TRANSITIONAL script (uses ScriptUI, still GTK3):
UI.window("Setup") do
  # ... abstracted code
end

# MODERN script (uses new backend, e.g., GTK4):
UI_NEW.window("Setup") do
  # ... abstracted code
end
```

---

## MIGRATION EXAMPLES BY PATH

### Path 1: LibUI (No Lich::UI, Direct Migration)

**Timeline:** 3-4 months

**Core Lich changes:**

```ruby
# lib/lich/login.rb (before)
def show_login_window
  Gtk.queue do
    window = Gtk::Window.new
    window.title = "Lich Login"
    # ... GTK3 code
  end
end

# lib/lich/login.rb (after - direct LibUI)
def show_login_window
  UI.init if !UI.initialized?

  window = UI.new_window("Lich Login", 400, 300, 1)
  vbox = UI.new_vertical_box
  UI.window_set_child(window, vbox)

  # ... LibUI code

  UI.control_show(window)
end
```

**No Script API changes needed** - scripts continue using GTK3 directly (not recommended for long-term)

---

### Path 2: GTK4 (With Lich::UI, Gradual Migration)

**Timeline:** 6-9 months

**Phase 1: Introduce Lich::UI (Month 1-2)**

```ruby
# lib/lich/ui.rb
module Lich::UI
  # ... abstraction layer (see above)
end

# lib/lich/ui/gtk3_backend.rb
# ... GTK3 backend

# lib/lich/ui/gtk4_backend.rb
# ... GTK4 backend
```

**Phase 2: Migrate Core to GTK4 via Lich::UI (Month 3-4)**

```ruby
# lib/lich.rb
Lich::UI.init('gtk4') # Core uses GTK4

# lib/lich/login.rb (modernized)
def show_login_window
  Lich::UI.window("Lich Login", width: 400, height: 300) do
    label("Account Name:")
    entry(placeholder: "Enter account...") { |text| @account = text }
    button("Login") { do_login }
  end
end
```

**Phase 3: Scripts Still Use GTK3 (Month 3-6)**

```ruby
# lib/common/script.rb
def self.start(script_name, args = nil)
  script_binding = TRUSTED_SCRIPT_BINDING.call

  # Scripts get GTK3 backend (default during transition)
  eval('UI = Lich::UI::GTK3Backend', script_binding)

  # Core uses GTK4 backend
  # No conflict - different event loops (managed carefully)
end
```

**Phase 4: Convert Top Scripts (Month 5-6)**

```ruby
# scripts/bigshot.lic (before - Gtk::Builder XML)
# 6,487 lines of Glade XML...

# scripts/bigshot.lic (after - Lich::UI with GTK4)
# Use conversion tool to generate:
UI.window("Bigshot Setup", width: 1120, height: 750) do
  notebook do
    tab("Profiles") do
      # ... converted from Glade XML
    end
    tab("Resting") do
      # ... converted from Glade XML
    end
  end
end
```

**Phase 5: Deprecate GTK3 (Month 7-9)**

```ruby
# lib/common/script.rb (final state)
def self.start(script_name, args = nil)
  script_binding = TRUSTED_SCRIPT_BINDING.call

  # All scripts use GTK4 backend now
  eval('UI = Lich::UI', script_binding) # Defaults to GTK4

  # Deprecated: Direct GTK3 calls (log warning)
  eval(%{
    module Gtk
      def self.queue(&block)
        warn "[DEPRECATED] Direct Gtk.queue calls deprecated. Use UI.queue instead."
        Lich::UI.queue(&block)
      end
    end
  }, script_binding)
end
```

---

### Path 3: Glimmer SWT (With Lich::UI, JRuby Migration)

**Timeline:** 9-12 months

**Phase 1: JRuby Compatibility Test (Month 1-2)**

```bash
# Test top 20 scripts on JRuby
jruby -S bundle install
jruby lib/lich.rbw

# Document compatibility issues:
# - Script X: Uses C extension Y (replace with Java equivalent Z)
# - Script Y: Threading issue (fix with JRuby-safe pattern)
```

**Decision gate:** If <85% compatible → switch to GTK4 path

**Phase 2: Introduce Lich::UI with Glimmer Backend (Month 3-4)**

```ruby
# Gemfile (JRuby-specific)
gem 'glimmer-dsl-swt', '~> 4.24'

# lib/lich/ui.rb (same abstraction as other paths)
# lib/lich/ui/glimmer_swt_backend.rb (see above)

# lib/lich.rb
Lich::UI.init('glimmer_swt') # Core uses Glimmer SWT
```

**Phase 3: Migrate Core to JRuby + Glimmer (Month 4-6)**

```ruby
# lib/lich/login.rb (Glimmer SWT)
def show_login_window
  Lich::UI.window("Lich Login", width: 400, height: 300) do
    label("Account Name:")
    entry(placeholder: "Enter account...") { |text| @account = text }
    button("Login") { do_login }
  end
end

# Behind the scenes, Lich::UI::GlimmerSWTBackend renders:
shell {
  text "Lich Login"
  minimum_size 400, 300
  composite {
    layout :vertical
    label { text "Account Name:" }
    text { message "Enter account..." }
    button { text "Login"; on_widget_selected { do_login } }
  }
}.open
```

**Phase 4: Convert Scripts (Month 7-9)**

```ruby
# scripts/bigshot.lic (before - GTK3)
# ... 7,581 lines of Ruby + Glade XML

# scripts/bigshot.lic (after - Glimmer SWT via Lich::UI)
# Use Glade→Glimmer conversion tool:
UI.window("Bigshot Setup", width: 1120, height: 750) do
  tab_folder do
    tab_item("Profiles") do
      # ... converted from Glade XML to Glimmer DSL
    end
    tab_item("Resting") do
      # ... converted
    end
  end
end
```

---

## GLADE XML CONVERSION TOOLS

### GTK4 Conversion Tool (Simple)

```ruby
#!/usr/bin/env ruby
# tools/glade_to_gtk4.rb

require 'nokogiri'

class GladeToGTK4Converter
  PROPERTY_RENAMES = {
    'can-focus' => 'focusable',
    'has-focus' => 'has-focus', # unchanged
    'expand' => 'hexpand', # context-dependent
    # ... ~50 more property renames
  }

  WIDGET_RENAMES = {
    'GtkBox' => 'GtkBox', # unchanged, but packing changed
    'GtkTable' => 'GtkGrid', # deprecated in GTK4
    # ... widget changes
  }

  def convert(glade_xml_path)
    doc = Nokogiri::XML(File.read(glade_xml_path))

    # Update requires version
    doc.at('requires')['version'] = '4.0'

    # Rename properties
    doc.css('property').each do |prop|
      name = prop['name']
      prop['name'] = PROPERTY_RENAMES[name] if PROPERTY_RENAMES[name]
    end

    # Rename widgets
    doc.css('object').each do |obj|
      klass = obj['class']
      obj['class'] = WIDGET_RENAMES[klass] if WIDGET_RENAMES[klass]
    end

    # Fix packing (GTK4 changed box packing)
    doc.css('packing').each do |packing|
      # Convert GTK3 packing to GTK4 append/prepend
      # This is complex, requires context analysis
    end

    doc.to_xml
  end
end

# Usage:
# converter = GladeToGTK4Converter.new
# gtk4_xml = converter.convert('bigshot_setup.glade')
# File.write('bigshot_setup_gtk4.glade', gtk4_xml)
```

---

### Glimmer SWT Conversion Tool (Complex)

```ruby
#!/usr/bin/env ruby
# tools/glade_to_glimmer.rb

require 'nokogiri'

class GladeToGlimmerConverter
  WIDGET_MAP = {
    'GtkWindow' => 'shell',
    'GtkBox' => 'composite',
    'GtkLabel' => 'label',
    'GtkEntry' => 'text',
    'GtkButton' => 'button',
    'GtkCheckButton' => 'button(:check)',
    'GtkSpinButton' => 'spinner',
    'GtkComboBoxText' => 'combo',
    'GtkNotebook' => 'tab_folder',
    'GtkFrame' => 'group',
    # ... ~30 more mappings
  }

  def convert(glade_xml_path)
    doc = Nokogiri::XML(File.read(glade_xml_path))
    root = doc.at('object[@class="GtkWindow"]')

    generate_glimmer(root)
  end

  def generate_glimmer(node, indent = 0)
    klass = node['class']
    id = node['id']

    glimmer_widget = WIDGET_MAP[klass] || 'composite'
    code = "  " * indent + "#{glimmer_widget} {\n"

    # Properties
    node.css('> property').each do |prop|
      name = prop['name']
      value = prop.text
      code += "  " * (indent + 1) + "#{snake_case(name)} #{ruby_value(value)}\n"
    end

    # Children
    node.css('> child > object').each do |child|
      code += generate_glimmer(child, indent + 1)
    end

    code += "  " * indent + "}\n"
    code
  end

  def snake_case(str)
    str.gsub('-', '_')
  end

  def ruby_value(str)
    case str
    when 'True' then 'true'
    when 'False' then 'false'
    when /^\d+$/ then str
    else "'#{str}'"
    end
  end
end

# Usage:
# converter = GladeToGlimmerConverter.new
# glimmer_code = converter.convert('bigshot_setup.glade')
# puts glimmer_code
```

---

## EVENT LOOP MANAGEMENT (DUAL FRAMEWORK)

### The Challenge: Two Event Loops in One Process

```ruby
# Core Lich uses GTK4 event loop
Gtk.init
# ... Gtk.main (blocking)

# Scripts try to use GTK3 event loop
# Problem: Gtk.main already running (GTK4), can't run GTK3.main
```

---

### Solution 1: Nested Event Loops (Fragile)

```ruby
# lib/lich/ui/gtk3_backend.rb (for scripts)
class GTK3Backend
  def self.window(title, &block)
    # Scripts create modal GTK3 windows
    window = Gtk::Window.new
    window.set_modal(true) # Forces nested event loop
    window.title = title

    # ... build window

    window.signal_connect('destroy') { Gtk.main_quit }
    window.show_all
    Gtk.main # Nested event loop (pauses GTK4 main loop)
  end
end
```

**Problem:** Core Lich UI frozen while script window open

---

### Solution 2: Separate Thread Event Loops (Dangerous)

```ruby
# DON'T DO THIS - GTK is not thread-safe
Thread.new do
  Gtk.main # Script GTK3 event loop
end
```

**Problem:** Crashes, race conditions, undefined behavior

---

### Solution 3: Single Backend Only (Recommended)

```ruby
# All code (core + scripts) uses same backend
Lich::UI.init('gtk4') # Everyone uses GTK4

# Scripts access via abstraction:
UI.window("Script Window") do
  # ... Lich::UI DSL (backed by GTK4)
end

# Direct GTK3 calls deprecated:
Gtk.queue do # Prints warning, delegates to GTK4
  # ...
end
```

**Recommendation:** Don't do dual framework unless absolutely necessary (high fragility)

---

## WHEN LICH::UI IS ESSENTIAL

### Scenario 1: Dual Framework (ESSENTIAL)

If you want core on Framework X and scripts on Framework Y simultaneously:

✅ **MUST use Lich::UI** - It's the only way to provide abstraction layer

---

### Scenario 2: Gradual Migration (ESSENTIAL)

If you want scripts to migrate incrementally over 12-18 months:

✅ **MUST use Lich::UI** - Scripts can migrate one-by-one from old backend to new backend

---

### Scenario 3: Single Framework, Big Bang Migration (OPTIONAL)

If you're migrating everything at once (core + all scripts) in 6-9 months:

🟡 **RECOMMENDED but not essential** - Provides future-proofing

---

### Scenario 4: Future Framework Change (ESSENTIAL for future)

If you think you might migrate again in 5-10 years:

✅ **ESSENTIAL** - Prevents repeat of this entire analysis process

---

## SUMMARY: IMPLEMENTATION DECISION MATRIX

| Path | Lich::UI Needed? | Script API Modernization? | Dual Framework? | Complexity |
|------|-----------------|------------------------|---------------|------------|
| **LibUI (fast)** | 🟡 Recommended | 🟡 Recommended | ❌ Not recommended | Low |
| **FXRuby (self-contained)** | 🟡 Recommended | 🟡 Recommended | ❌ Not recommended | Low |
| **GTK4 (accessible)** | ✅ Essential (gradual migration) | ✅ Essential | 🟡 Optional (18mo transition) | Medium |
| **Glimmer SWT (best a11y)** | ✅ Essential (JRuby migration) | ✅ Essential | ❌ Not recommended | High |

**Recommendation:** Build Lich::UI for ALL paths except staying on GTK3. It's 40-60 hours well spent for future flexibility.

---

**Next Step:** After framework decision, Web Claude will provide detailed `Lich::UI` implementation architecture tailored to chosen backend.

**Session Context:** Technical addendum created 2025-11-19. Provides implementation examples for UI_FRAMEWORK_DECISION.md.
