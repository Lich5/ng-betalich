# Work Unit: POC - JRuby + Glimmer DSL for SWT

**Branch:** `poc/jruby-glimmer-swt`
**Type:** Proof of Concept (Parallel to GTK3 track)
**Dependencies:** Phase 1 (Lich::UI architecture) SHOULD be complete for best integration
**Estimated Effort:** 16-24 hours
**Status:** Ready (can run in parallel with Phases 2-4)

---

## Objective

Create a minimal proof-of-concept demonstrating Lich running on JRuby with Glimmer DSL for SWT. The POC validates:

1. **JRuby compatibility:** Lich core works on JRuby
2. **Glimmer SWT viability:** Login GUI renders and functions
3. **Script compatibility:** MRI Ruby scripts work in JRuby context
4. **Performance:** Acceptable startup time and responsiveness

**Success threshold:** If >85% of core functionality works, proceed to full implementation.

---

## Success Criteria

- [ ] Lich starts on JRuby without errors
- [ ] Login window displays using Glimmer DSL for SWT
- [ ] Login window exits cleanly
- [ ] Basic game connection works
- [ ] At least 1 simple script runs successfully
- [ ] Performance: Startup < 10 seconds
- [ ] Memory: Reasonable footprint (< 500MB)
- [ ] Documentation: POC report with findings

---

## Scope - Minimal POC

### In Scope (Must Work)
1. ✅ Lich starts (`ruby lich.rbw` → `jruby lich.rbw`)
2. ✅ Login window appears (Glimmer SWT)
3. ✅ Login window closes cleanly
4. ✅ Basic network connection (connect to game)
5. ✅ Load and run 1-2 simple scripts

### Out of Scope (Defer)
- ❌ Full feature parity with GTK3
- ❌ Complex scripts (bigshot, etc.)
- ❌ All tabs/features in login window
- ❌ Production-ready error handling
- ❌ Packaging/distribution

---

## Technical Requirements

### 1. Environment Setup

**Install JRuby:**
```bash
# macOS (Homebrew)
brew install jruby

# Or use rbenv
rbenv install jruby-9.4.5.0
rbenv local jruby-9.4.5.0

# Verify
jruby -v
# jruby 9.4.5.0 (3.1.4) ...
```

**Install Glimmer DSL for SWT:**
```bash
jruby -S gem install glimmer-dsl-swt
```

**Verify Glimmer:**
```bash
jruby -e "require 'glimmer-dsl-swt'; puts Glimmer::VERSION"
```

### 2. Implement Lich::UI::GlimmerSWTBackend

**File:** `lib/common/ui/glimmer_swt_backend.rb`

```ruby
# lib/common/ui/glimmer_swt_backend.rb
require 'glimmer-dsl-swt'

module Lich
  module UI
    class GlimmerSWTBackend < BaseBackend
      @initialized = false
      @display = nil

      def self.init
        return if @initialized
        @display = Glimmer::SWT::DisplayProxy.instance.swt_display
        @initialized = true
      end

      def self.alert(message, title: 'Alert', type: :info)
        queue do
          Glimmer::SWT::MessageBox.new(@display.shells.first) do |message_box|
            message_box.text = title
            message_box.message = message
            message_box.style = swt_message_style(type)
            message_box.open
          end
        end
      end

      def self.confirm(message, title: 'Confirm')
        result = nil
        queue do
          message_box = Glimmer::SWT::MessageBox.new(@display.shells.first) do |mb|
            mb.text = title
            mb.message = message
            mb.style = SWT::ICON_QUESTION | SWT::YES | SWT::NO
          end
          result = (message_box.open == SWT::YES)
        end
        result
      end

      def self.prompt(message, title: 'Input', default: '', password: false)
        result = nil
        queue do
          Glimmer::SWT::ShellProxy.new do
            text title
            composite {
              layout_data :fill, :fill, true, true

              label {
                text message
              }

              @entry = text(password ? :password : :none) {
                text default
                layout_data :fill, :center, true, false
              }

              composite {
                row_layout {
                  type :horizontal
                }

                button {
                  text 'OK'
                  on_widget_selected {
                    result = @entry.text
                    @shell.close
                  }
                }

                button {
                  text 'Cancel'
                  on_widget_selected {
                    @shell.close
                  }
                }
              }
            }
          end.open
        end
        result
      end

      def self.queue(&block)
        if @display.thread == Thread.current
          block.call
        else
          @display.async_exec(&block)
        end
      end

      def self.window(title:, width: 800, height: 600, &block)
        Glimmer::SWT::ShellProxy.new do
          text title
          minimum_size width, height
          block&.call(self)
        end
      end

      def self.file_chooser(title: 'Choose File', action: :open, filters: [])
        result = nil
        queue do
          dialog = Glimmer::SWT::FileDialog.new(@display.shells.first, swt_file_style(action))
          dialog.text = title

          # Set filters
          if filters.any?
            filter_names = filters.map { |f| f[:name] }
            filter_extensions = filters.map { |f| f[:patterns] }
            dialog.filter_names = filter_names
            dialog.filter_extensions = filter_extensions
          end

          result = dialog.open
        end
        result
      end

      def self.main
        Glimmer::SWT::DisplayProxy.instance.start_event_loop
      end

      def self.quit
        @display&.wake
        @display&.dispose
      end

      private

      def self.swt_message_style(type)
        case type
        when :info then SWT::ICON_INFORMATION | SWT::OK
        when :warning then SWT::ICON_WARNING | SWT::OK
        when :error then SWT::ICON_ERROR | SWT::OK
        else SWT::ICON_INFORMATION | SWT::OK
        end
      end

      def self.swt_file_style(action)
        case action
        when :open then SWT::OPEN
        when :save then SWT::SAVE
        else SWT::OPEN
        end
      end
    end
  end
end
```

### 3. Minimal Login Window (Glimmer)

**File:** `lib/common/gui-login-swt.rb` (POC version)

```ruby
# lib/common/gui-login-swt.rb
require 'glimmer-dsl-swt'

module Lich
  class LoginWindowSWT
    include Glimmer

    def launch
      shell {
        text 'Lich Login'
        minimum_size 400, 300

        composite {
          layout_data :fill, :fill, true, true

          label {
            text 'Lich Login - Glimmer SWT POC'
            font height: 16, style: :bold
          }

          label {
            text 'Account Name:'
          }

          @account_entry = text {
            layout_data :fill, :center, true, false
          }

          label {
            text 'Password:'
          }

          @password_entry = text(:password) {
            layout_data :fill, :center, true, false
          }

          composite {
            row_layout {
              type :horizontal
            }

            button {
              text 'Connect'
              on_widget_selected {
                connect_to_game
              }
            }

            button {
              text 'Exit'
              on_widget_selected {
                @shell.close
              }
            }
          }
        }

        on_shell_closed {
          puts "Login window closed"
          UI.quit
        }
      }.open
    end

    private

    def connect_to_game
      account = @account_entry.text
      password = @password_entry.text

      if account.empty? || password.empty?
        UI.alert("Please enter account name and password", type: :warning)
        return
      end

      puts "Connecting to game with account: #{account}"
      # TODO: Actual connection logic
      UI.alert("Connection successful! (POC)", type: :info)
    end
  end
end
```

### 4. Modify lich.rbw for JRuby

**File:** `lich.rbw` (conditional JRuby path)

```ruby
# lich.rbw (add JRuby detection)

if RUBY_PLATFORM == 'java'
  # JRuby mode - use Glimmer SWT
  require_relative 'lib/common/ui'
  Lich::UI.init(:glimmer_swt)

  require_relative 'lib/common/gui-login-swt'
  Lich::LoginWindowSWT.new.launch
  Lich::UI.main
else
  # MRI Ruby mode - use GTK3 (existing code)
  # ... existing GTK3 code ...
end
```

### 5. JRuby Compatibility Fixes

**Common issues to address:**

#### Issue 1: File Paths
```ruby
# MRI Ruby
__FILE__  # Works

# JRuby
__FILE__  # May return Java-style paths

# Fix: Use File.expand_path consistently
File.expand_path(__FILE__)
```

#### Issue 2: Threading
```ruby
# MRI Ruby threads work differently than JRuby
# Use Java threads if needed in JRuby

if RUBY_PLATFORM == 'java'
  java_import java.lang.Thread
end
```

#### Issue 3: C Extensions
```ruby
# Some gems with C extensions won't work in JRuby
# Use Java equivalents or pure Ruby alternatives
```

---

## Implementation Steps

### Step 1: Environment Setup

1. Install JRuby (see Technical Requirements)
2. Install Glimmer DSL for SWT
3. Create POC branch:
   ```bash
   git checkout -b poc/jruby-glimmer-swt
   ```

### Step 2: Implement Glimmer SWT Backend

1. Create `lib/common/ui/glimmer_swt_backend.rb`
2. Implement all `BaseBackend` methods
3. Test manually:
   ```bash
   jruby -e "require './lib/common/ui'; Lich::UI.init(:glimmer_swt); Lich::UI.alert('Test')"
   ```

### Step 3: Create Minimal Login Window

1. Create `lib/common/gui-login-swt.rb`
2. Implement basic login form
3. Test:
   ```bash
   jruby -r './lib/common/ui' -r './lib/common/gui-login-swt' -e "Lich::UI.init(:glimmer_swt); Lich::LoginWindowSWT.new.launch; Lich::UI.main"
   ```

### Step 4: Modify lich.rbw

1. Add JRuby detection
2. Conditionally load SWT vs GTK3
3. Test full startup:
   ```bash
   jruby lich.rbw
   ```

### Step 5: Test Script Compatibility

**Simple test script:** `test-script.lic`
```ruby
# test-script.lic
puts "Script started"
UI.alert("Hello from script!")
puts "Script finished"
```

Run script:
```bash
jruby lich.rbw
# In Lich, load script
```

### Step 6: Performance and Memory Testing

```bash
# Measure startup time
time jruby lich.rbw

# Measure memory (macOS)
jruby -J-Xmx256m lich.rbw  # Test with 256MB heap
jruby -J-Xmx512m lich.rbw  # Test with 512MB heap

# Profile (if slow)
jruby --profile lich.rbw
```

### Step 7: Document Findings

Create POC report (see Deliverables).

---

## Testing Strategy

### Functional Tests

- [ ] Lich starts on JRuby
- [ ] Login window displays
- [ ] Account name entry functional
- [ ] Password entry functional (masked)
- [ ] Connect button responds
- [ ] Exit button closes cleanly
- [ ] UI.alert works
- [ ] UI.confirm works
- [ ] UI.prompt works
- [ ] Simple script loads and runs

### Performance Tests

- [ ] Startup time < 10 seconds
- [ ] Memory usage < 500MB
- [ ] UI responsiveness (no lag)

### Compatibility Tests

- [ ] Core Lich modules load
- [ ] Network connection works
- [ ] File I/O works (settings, etc.)
- [ ] At least 1 script from top 10 works

---

## Acceptance Criteria Checklist

- [ ] JRuby environment set up
- [ ] Glimmer SWT installed and working
- [ ] `Lich::UI::GlimmerSWTBackend` implemented
- [ ] Minimal login window functional
- [ ] Lich starts and exits cleanly on JRuby
- [ ] At least 1 script runs successfully
- [ ] Performance acceptable (< 10s startup)
- [ ] POC report completed

---

## POC Report Template

**File:** `.claude/docs/POC_JRUBY_GLIMMER_SWT_REPORT.md`

```markdown
# POC Report: JRuby + Glimmer DSL for SWT

**Date:** YYYY-MM-DD
**JRuby Version:** X.X.X
**Glimmer Version:** X.X.X

## Summary

Brief summary of POC results (success/failure, major findings).

## Environment

- OS: macOS / Linux / Windows
- JRuby version: X.X.X
- Glimmer DSL for SWT version: X.X.X
- Java version: OpenJDK X / Oracle JDK X

## Functional Results

### Lich Startup
- ✅/❌ Starts without errors
- Startup time: X seconds
- Memory usage: X MB

### Login Window
- ✅/❌ Displays correctly
- ✅/❌ Account entry functional
- ✅/❌ Password entry functional
- ✅/❌ Connect button works
- ✅/❌ Exit button works

### UI Methods
- ✅/❌ UI.alert
- ✅/❌ UI.confirm
- ✅/❌ UI.prompt
- ✅/❌ UI.file_chooser

### Script Compatibility
- ✅/❌ Simple script runs
- Scripts tested: [list]
- Success rate: X%

## Performance Metrics

| Metric | Target | Actual | Pass/Fail |
|--------|--------|--------|-----------|
| Startup time | < 10s | X s | ✅/❌ |
| Memory usage | < 500MB | X MB | ✅/❌ |
| UI responsiveness | No lag | [description] | ✅/❌ |

## Compatibility Issues

List any compatibility issues found:
1. Issue description
2. Issue description
...

## Accessibility

- ✅/❌ Screen reader support (native SWT)
- ✅/❌ Keyboard navigation
- ✅/❌ High contrast mode

## Recommendations

### ✅ PROCEED to full implementation if:
- All core functionality works
- Performance acceptable
- Script compatibility > 85%
- No critical blockers

### ⚠️ REVISE POC if:
- Performance unacceptable
- Script compatibility < 85%
- Major functionality missing

### ❌ ABANDON if:
- Critical blockers (JRuby incompatibility)
- Performance deal-breakers (> 30s startup)
- Script compatibility < 50%

## Next Steps

Based on POC results:
- If PROCEED: Plan full Glimmer SWT implementation
- If REVISE: Address issues and re-test
- If ABANDON: Consider alternative frameworks
```

---

## Risks and Mitigations

| Risk | Mitigation |
|------|------------|
| JRuby incompatibilities | Test core modules early, identify issues |
| Slow startup time | Profile and optimize, consider nailgun |
| High memory usage | Tune JVM heap, profile allocations |
| Script compatibility issues | Test top 10 scripts, document incompatibilities |
| Glimmer learning curve | Use Glimmer examples, community support |
| SWT platform issues | Test on macOS, Linux, Windows |

---

## Deliverables

1. ✅ `lib/common/ui/glimmer_swt_backend.rb` - Backend implementation
2. ✅ `lib/common/gui-login-swt.rb` - Minimal login window
3. ✅ Modified `lich.rbw` with JRuby detection
4. ✅ `.claude/docs/POC_JRUBY_GLIMMER_SWT_REPORT.md` - Results report
5. ✅ Test script(s) demonstrating compatibility
6. ✅ Performance benchmarks
7. ✅ **DECISION:** PROCEED / REVISE / ABANDON

---

## Decision Gate: Proceed to Full Implementation?

### ✅ PROCEED if:
- POC demonstrates > 85% core functionality works
- Performance acceptable (< 10s startup, < 500MB memory)
- Script compatibility validated (at least 1-2 scripts work)
- Accessibility meets requirements (SWT native support)
- No critical blockers identified

### ⚠️ REVISE if:
- Performance marginal (10-15s startup)
- Some compatibility issues found but fixable
- Minor functionality gaps

### ❌ ABANDON if:
- Critical JRuby incompatibilities
- Unacceptable performance (> 30s startup)
- Script compatibility < 50%
- Major accessibility gaps

---

## Next Phase (If PROCEED)

1. **Full Glimmer SWT Implementation:**
   - Implement all login window tabs
   - Migrate all core Lich GUI to Glimmer
   - Test with top 10 scripts
   - Test with extended suite (50-60 scripts)

2. **Packaging:**
   - Create standalone JAR with JRuby embedded
   - Platform-specific installers (macOS .app, Windows .exe, Linux AppImage)

3. **Production Release:**
   - Beta testing with users
   - Performance optimization
   - Bug fixes
   - Documentation

---

**Created:** 2025-11-19
**Last Updated:** 2025-11-19
**Status:** Ready (can run parallel to GTK3 track)
