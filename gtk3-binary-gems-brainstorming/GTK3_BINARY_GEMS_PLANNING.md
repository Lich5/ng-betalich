# GTK3 Binary Gems for Lich5: Planning & Brainstorming

**Date:** 2025-12-28
**Purpose:** Plan the creation of precompiled binary GTK3 gems for Lich5
**Status:** Brainstorming / Planning Phase
**Distribution Strategy:** Initially bundled with Lich5 installers

---

## Executive Summary

This document captures the planning and brainstorming for creating precompiled binary gems for the GTK3 stack used by Lich5. The goal is to recreate what the ruby-gnome team used to provide: "fat" binary gems that drastically simplify installation by bundling precompiled native extensions and GTK3 runtime libraries.

**Current State:**
```
❌ Users install: GTK3 system libraries → Ruby → Compile gems → Hope it works
```

**Target State:**
```
✅ Users install: Lich5 installer → Everything works immediately
```

---

## 1. The Complete GTK3 Gem Ecosystem

Based on current ruby-gnome 4.3.4 (latest as of Dec 2025), here's the **complete dependency tree**:

### Core Dependency Chain

```
gtk3 (4.3.4)
├── atk (4.3.4) - Accessibility Toolkit
│   ├── glib2 (4.3.4)
│   │   ├── native-package-installer (>= 1.0.3)
│   │   └── pkg-config (>= 1.3.5)
│   └── rake (>= 0)
│
└── gdk3 (4.3.4) - Graphics/Display
    ├── cairo-gobject (4.3.4)
    │   ├── cairo (>= 1.16.2)
    │   │   ├── native-package-installer (>= 1.0.3)
    │   │   ├── pkg-config (>= 1.2.2)
    │   │   └── red-colors (>= 0)
    │   └── glib2 (4.3.4) [see above]
    │
    ├── gdk_pixbuf2 (4.3.4) - Image Loading
    │   ├── gio2 (4.3.4)
    │   │   ├── fiddle (>= 0) - standard library
    │   │   └── gobject-introspection (4.3.4)
    │   │       └── glib2 (4.3.4) [see above]
    │   └── rake (>= 0)
    │
    ├── pango (4.3.4) - Text Rendering
    │   ├── cairo-gobject (4.3.4) [see above]
    │   └── gobject-introspection (4.3.4) [see above]
    │
    └── rake (>= 0)
```

### Unique Ruby Gems Required

**Core GTK Stack (must be binary gems):**
1. **gtk3** - Main GUI toolkit
2. **gdk3** - Graphics/display backend
3. **atk** - Accessibility toolkit
4. **gdk_pixbuf2** - Image loading/manipulation
5. **pango** - Text rendering/layout
6. **cairo-gobject** - GObject bindings for Cairo
7. **gio2** - GIO (file/network I/O)
8. **gobject-introspection** - Dynamic language bindings
9. **glib2** - Core GLib library
10. **cairo** - 2D graphics library (1.17.13 or >= 1.16.2)

**Helper Gems (pure Ruby, no compilation needed):**
- **fiddle** - Standard library (FFI)
- **rake** - Build tool
- **native-package-installer** - System package helper
- **pkg-config** - Build configuration helper
- **red-colors** - Color utilities

### Additional Optional Gems in Ruby-GNOME

These are NOT needed for basic Lich5 GTK3 functionality, but listed for completeness:

**Extended UI:**
- gtksourceview3/4/5 - Source code editing widget
- webkit-gtk / webkit2-gtk - Web rendering
- adwaita - GNOME theme

**Graphics/Media:**
- gdk4 / gsk4 / gtk4 - GTK4 stack
- graphene1 - Graphics math library
- gstreamer - Multimedia framework
- clutter / clutter-gdk / clutter-gstreamer / clutter-gtk - Animation framework
- rsvg2 - SVG rendering
- poppler - PDF rendering
- gegl - Image processing

**Desktop Integration:**
- vte3/vte4 - Terminal emulator widget
- wnck3 - Window manager integration
- libhandy - Adaptive UI components
- libsecret - Password/secret storage

**Office/Data:**
- gsf - Structured file library
- goffice / gnumeric - Office suite components

**For Lich5, we only need the Core GTK Stack (10 gems).**

---

## 2. Binary Gem Architecture & Mechanics

### What is a Binary Gem?

A binary gem (also called "native gem") contains:
1. **Precompiled native extensions** (`.so` on Linux, `.bundle` on macOS, `.dll` on Windows)
2. **Ruby bindings** (pure Ruby code)
3. **Platform metadata** in gem name (e.g., `gtk3-4.3.4-x64-mingw32.gem`)
4. **(Optionally) Bundled C libraries** - GTK3 runtime DLLs/dylibs

### Fat Gems vs Platform-Specific Gems

**Platform-Specific Gems:**
```
gtk3-4.3.4-x86_64-linux.gem
gtk3-4.3.4-x86_64-darwin.gem
gtk3-4.3.4-x64-mingw32.gem
```
- One gem per platform
- RubyGems automatically selects correct platform
- Simpler to build (one platform at a time)

**Fat Gems:**
```
gtk3-4.3.4.gem (contains binaries for ALL platforms)
```
- All platforms in one gem
- Larger download size
- More complex to build
- Less common in modern RubyGems (platform-specific is standard now)

**Recommendation for Lich5:** Use **platform-specific gems** (industry standard, simpler build pipeline).

### Platform Targets

**Primary Platforms:**
| Platform | Ruby Platform String | Notes |
|----------|---------------------|-------|
| **Windows 64-bit** | `x64-mingw32` | Largest user base, most critical |
| **macOS Intel** | `x86_64-darwin` | Legacy Mac support |
| **macOS Apple Silicon** | `arm64-darwin` | Modern Macs (M1/M2/M3) |
| **Linux x64** | `x86_64-linux` | Most Linux users |
| **Linux ARM64** | `aarch64-linux` | Raspberry Pi, ARM servers |

**Optional/Future:**
- `x86-mingw32` (Windows 32-bit) - declining relevance
- `arm-linux` (ARM 32-bit) - embedded systems

### Native Extension Structure

Each gem with native code has an `ext/` directory:
```
gtk3/
├── lib/
│   └── gtk3.rb          # Pure Ruby interface
├── ext/
│   └── gtk3/
│       ├── extconf.rb   # Build configuration (uses mkmf)
│       ├── rbgtk*.c     # C bindings
│       └── *.h          # Headers
└── gtk3.gemspec
```

**Compilation Process:**
1. `extconf.rb` runs → generates `Makefile`
2. `make` compiles C code → produces `.so` / `.bundle` / `.dll`
3. Binary installed to `lib/gtk3/gtk3.so` (or platform-specific location)

**Binary Gem Process:**
1. Cross-compile for target platform
2. Package precompiled `.so` in gem
3. Skip `ext/` directory in binary gem (no compilation needed at install time)

---

## 3. Bundling GTK3 Runtime Libraries

### The Challenge

GTK3 gems depend on **system GTK3 libraries**:
- **Linux:** `libgtk-3.so`, `libglib-2.0.so`, etc. (usually system-installed)
- **macOS:** `libgtk-3.dylib`, `libglib-2.0.dylib` (via Homebrew or bundled)
- **Windows:** `gtk-3-0.dll`, `glib-2.0-0.dll`, etc. (must be bundled)

**Options:**

#### Option A: Require System GTK3 Libraries
```
✅ Pros: Smaller gems, uses system packages
❌ Cons: Users must install GTK3 separately (defeats purpose!)
```

#### Option B: Bundle GTK3 Libraries in Gems
```
✅ Pros: Zero dependencies, one-step install
❌ Cons: Larger gems (150-200MB for full stack)
```

**Recommendation:** **Option B (bundle libraries)** - This is the whole point!

### Bundling Strategy

**Per-Gem Approach:**
- Each gem (glib2, gtk3, etc.) bundles its own DLLs
- Pro: Gems are self-contained
- Con: Duplicate DLLs across gems (bloat)

**Shared Library Approach:**
- Create a `gtk3-runtime` gem that bundles all GTK3 DLLs
- Other gems depend on `gtk3-runtime`
- Pro: No duplication, smaller total size
- Con: Extra gem to manage

**Lich5 Bundled Approach (Recommended):**
- **Don't publish individual gems to RubyGems.org**
- Bundle **everything** in Lich5 installer:
  - Ruby interpreter
  - All GTK3 gems (precompiled)
  - All GTK3 runtime libraries
  - Lich5 code
- Pro: Complete control, zero external dependencies
- Con: Large installer (acceptable for game launcher)

### Library Bundling Locations

**Windows:**
```
lich5/
├── ruby/
│   └── lib/
│       └── ruby/
│           └── gems/
│               └── 3.3.0/
│                   └── gems/
│                       ├── gtk3-4.3.4-x64-mingw32/
│                       │   ├── lib/
│                       │   │   └── gtk3/gtk3.so
│                       │   └── vendor/
│                       │       └── bin/
│                       │           ├── libgtk-3-0.dll
│                       │           ├── libglib-2.0-0.dll
│                       │           └── ... (all GTK3 DLLs)
```

**macOS:**
```
Lich5.app/
└── Contents/
    ├── MacOS/
    │   └── lich5         # Launcher script
    ├── Resources/
    │   └── ruby/
    │       └── lib/
    │           └── ruby/
    │               └── gems/
    │                   └── 3.3.0/
    │                       └── gems/
    │                           └── gtk3-4.3.4-arm64-darwin/
    │                               ├── lib/
    │                               └── vendor/
    │                                   └── lib/
    │                                       └── libgtk-3.dylib
    └── Frameworks/       # Alternative: bundle dylibs here
        └── libgtk-3.dylib
```

**Linux (AppImage):**
```
lich5.AppImage (extracted):
├── usr/
│   ├── bin/
│   │   └── lich5
│   └── lib/
│       ├── libgtk-3.so   # GTK3 runtime
│       └── ruby/
│           └── gems/
│               └── gtk3-4.3.4-x86_64-linux/
│                   └── lib/
│                       └── gtk3/gtk3.so
```

---

## 4. Build Pipeline Architecture

### Cross-Compilation Challenges

**Native Compilation:**
- Build on Windows → Windows binary ✅
- Build on macOS → macOS binary ✅
- Build on Linux → Linux binary ✅

**Cross-Compilation:**
- Build on Linux → Windows binary (requires MinGW cross-compiler)
- Build on macOS Intel → macOS ARM binary (requires Xcode universal build)
- Build on Linux x64 → Linux ARM binary (requires ARM toolchain)

**Recommendation:** Use **native compilation on GitHub Actions** (easier, more reliable).

### GitHub Actions Matrix Build

**Strategy:** Use GitHub Actions matrix to build on native platforms.

```yaml
name: Build GTK3 Binary Gems

on:
  workflow_dispatch:
  push:
    tags:
      - 'v*'

jobs:
  build-gems:
    strategy:
      matrix:
        include:
          # Windows
          - os: windows-latest
            platform: x64-mingw32
            ruby: '3.3'

          # macOS Intel
          - os: macos-13  # Intel runner
            platform: x86_64-darwin
            ruby: '3.3'

          # macOS Apple Silicon
          - os: macos-14  # ARM runner
            platform: arm64-darwin
            ruby: '3.3'

          # Linux x64
          - os: ubuntu-latest
            platform: x86_64-linux
            ruby: '3.3'

          # Linux ARM64 (via QEMU or native runner)
          - os: ubuntu-latest
            platform: aarch64-linux
            ruby: '3.3'
            arch: aarch64

    runs-on: ${{ matrix.os }}

    steps:
      - uses: actions/checkout@v4

      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: ${{ matrix.ruby }}

      - name: Install GTK3 system libraries
        run: |
          # Platform-specific GTK3 installation
          # Windows: choco install gtk3 / vcpkg / MSYS2
          # macOS: brew install gtk+3
          # Linux: apt-get install libgtk-3-dev

      - name: Build binary gems
        run: |
          gem install rake bundler
          rake gem:build:native[${{ matrix.platform }}]

      - name: Upload binary gems
        uses: actions/upload-artifact@v4
        with:
          name: gems-${{ matrix.platform }}
          path: pkg/*.gem
```

### Build Scripts Structure

```
lich5-gtk3-gems/
├── Rakefile                  # Master build script
├── gems/
│   ├── glib2/
│   │   ├── Rakefile
│   │   ├── glib2.gemspec
│   │   └── ext/glib2/
│   ├── gobject-introspection/
│   ├── gio2/
│   ├── cairo/
│   ├── cairo-gobject/
│   ├── pango/
│   ├── gdk_pixbuf2/
│   ├── atk/
│   ├── gdk3/
│   └── gtk3/
├── vendor/
│   ├── windows/
│   │   └── gtk3-runtime/   # GTK3 DLLs for Windows
│   ├── macos/
│   │   └── gtk3-runtime/   # GTK3 dylibs for macOS
│   └── linux/
│       └── gtk3-runtime/   # GTK3 .so files for Linux (optional)
└── .github/
    └── workflows/
        └── build-gems.yml
```

### Per-Gem Build Process

**Each gem needs:**

1. **Custom `extconf.rb`** that bundles libraries:
```ruby
# gems/gtk3/ext/gtk3/extconf.rb
require 'mkmf'

# Check for GTK3 library
unless have_library('gtk-3')
  abort "GTK3 library not found!"
end

# Bundle GTK3 runtime libraries for binary gems
if RUBY_PLATFORM =~ /mingw|mswin/
  vendor_dir = File.expand_path('../../../../vendor/windows/gtk3-runtime', __FILE__)
  # Copy DLLs to gem's vendor/bin/
end

create_makefile('gtk3/gtk3')
```

2. **Custom gemspec** with platform specification:
```ruby
# gems/gtk3/gtk3.gemspec
Gem::Specification.new do |s|
  s.name        = 'gtk3'
  s.version     = '4.3.4'
  s.platform    = Gem::Platform::CURRENT  # Auto-detect or specify
  s.summary     = 'Ruby/GTK3 bindings'
  s.files       = Dir['lib/**/*', 'vendor/**/*']  # Include bundled libs

  # Runtime dependencies
  s.add_dependency 'atk', '= 4.3.4'
  s.add_dependency 'gdk3', '= 4.3.4'
end
```

3. **Rake tasks** for building:
```ruby
# gems/gtk3/Rakefile
require 'rake/extensiontask'

Rake::ExtensionTask.new('gtk3') do |ext|
  ext.lib_dir = 'lib/gtk3'
end

namespace :gem do
  task :build_native, [:platform] do |t, args|
    platform = args[:platform] || Gem::Platform::CURRENT
    system("gem build gtk3.gemspec --platform=#{platform}")
  end
end
```

---

## 5. Platform-Specific Considerations

### Windows (x64-mingw32)

**GTK3 Source:**
- **MSYS2** (recommended): `pacman -S mingw-w64-x86_64-gtk3`
- **vcpkg**: `vcpkg install gtk3:x64-windows`
- **Prebuilt binaries**: gtk.org/download/windows.html

**DLLs to Bundle (~150-200MB):**
```
libgtk-3-0.dll
libgdk-3-0.dll
libglib-2.0-0.dll
libgobject-2.0-0.dll
libgio-2.0-0.dll
libgdk_pixbuf-2.0-0.dll
libpango-1.0-0.dll
libpangocairo-1.0-0.dll
libcairo-2.dll
libcairo-gobject-2.dll
libatk-1.0-0.dll
... (plus transitive dependencies: libintl, libepoxy, libffi, etc.)
```

**Build Environment:**
- RubyInstaller DevKit (includes MinGW toolchain)
- Or native MSYS2 environment

**Challenges:**
- Path separators (backslashes vs forward slashes)
- DLL search paths (`PATH` environment variable)
- Icon/theme files bundling

---

### macOS (x86_64-darwin / arm64-darwin)

**GTK3 Source:**
- **Homebrew**: `brew install gtk+3`
- **MacPorts**: `port install gtk3`
- **Build from source**: gtk.org

**Dylibs to Bundle (~150MB):**
```
libgtk-3.dylib
libgdk-3.dylib
libglib-2.0.dylib
... (similar to Windows)
```

**Build Considerations:**
- Universal binaries (Intel + ARM in one): Possible but complex
- Separate gems for Intel vs ARM: Simpler, recommended
- Codesigning (may be needed for Gatekeeper)
- dylib search paths (`@rpath`, `install_name_tool`)

**Challenges:**
- Homebrew vs MacPorts incompatibility
- Code signing / notarization for distribution
- Universal binary complexity

---

### Linux (x86_64-linux / aarch64-linux)

**GTK3 Source:**
- **System package manager**: `apt install libgtk-3-dev`
- Usually already installed on desktop Linux

**Library Bundling:**
- **Option 1:** Don't bundle, require system GTK3 (most Linux users have it)
- **Option 2:** Bundle for AppImage (self-contained)

**AppImage Strategy:**
```bash
# Build AppImage with bundled GTK3
appimagetool lich5.AppDir lich5-x86_64.AppImage
```

**Challenges:**
- Different distros, different GTK3 versions
- ABI compatibility across distros
- AppImage bloat if bundling everything

**Recommendation:** For Linux, consider **not bundling GTK3** (rely on system), unless building AppImage.

---

## 6. Distribution Strategy: Bundled with Lich5

### Why Bundle Instead of RubyGems.org?

**Publishing to RubyGems.org:**
```
✅ Pros: Standard gem installation, reusable by others
❌ Cons: Gem naming conflicts (ruby-gnome team may resume), maintenance burden
```

**Bundling in Lich5 Installer:**
```
✅ Pros: Complete control, no external dependencies, guaranteed compatibility
✅ Pros: No naming conflicts, no ongoing gem maintenance
✅ Pros: Single unified installer
❌ Cons: Larger installer download (~200-300MB total)
```

**Decision:** **Bundle in Lich5 installer** (simpler, more reliable).

### Installer Structure

**Windows (.exe installer via Inno Setup):**
```
Lich5-Installer-Windows-x64.exe
└── Installs to C:\Program Files\Lich5\
    ├── ruby\              # Ruby 3.3 + bundled gems
    ├── lich5\             # Lich5 code
    └── lich5.exe          # Launcher
```

**macOS (.app bundle):**
```
Lich5.app
└── Contents/
    ├── MacOS/
    │   └── lich5
    ├── Resources/
    │   ├── ruby/         # Ruby + gems
    │   └── lich5/        # Lich5 code
    └── Frameworks/       # (Optional) GTK3 dylibs
```

**Linux (AppImage):**
```
Lich5-x86_64.AppImage
└── (Self-extracting, contains Ruby + GTK3 + Lich5)
```

### Installation Flow

**User perspective:**
1. Download `Lich5-Installer-[Platform].exe/.app/.AppImage`
2. Run installer (Windows) / Drag to Applications (macOS) / Make executable (Linux)
3. Launch Lich5
4. **GTK3 just works** ✅

**No user interaction required for GTK3 setup!**

---

## 7. Build Automation & CI/CD

### Workflow Overview

```
Developer Push → GitHub Actions Triggered
   ↓
Matrix Build (5 platforms in parallel)
   ↓
Compile Native Extensions + Bundle GTK3 Libs
   ↓
Package Binary Gems
   ↓
Upload Gems as Artifacts
   ↓
Separate Job: Bundle Gems into Lich5 Installers
   ↓
Release Installers (GitHub Releases)
```

### Artifact Management

**Build Artifacts:**
```
pkg/
├── glib2-4.3.4-x64-mingw32.gem
├── glib2-4.3.4-x86_64-darwin.gem
├── glib2-4.3.4-arm64-darwin.gem
├── glib2-4.3.4-x86_64-linux.gem
├── glib2-4.3.4-aarch64-linux.gem
├── ... (repeat for all 10 gems)
```

**Storage:**
- GitHub Actions Artifacts (temporary, 90 days)
- GitHub Releases (permanent, versioned)
- Private gem server (optional, overkill for bundled approach)

### Version Management

**Gem Versioning Strategy:**
- Match ruby-gnome versions: `4.3.4`, `4.4.0`, etc.
- Or fork with custom version: `4.3.4.lich5.1` (indicates Lich5 custom build)

**Dependency Locking:**
- Pin exact versions in Lich5's `Gemfile.lock`
- Rebuild all gems together when updating GTK3

---

## 8. Testing Strategy

### What to Test

1. **Gem Installation:**
   - Does `gem install gtk3-4.3.4-x64-mingw32.gem` succeed?
   - Are all files extracted correctly?

2. **Library Loading:**
   - Does `require 'gtk3'` work?
   - Are bundled DLLs/dylibs found?

3. **Functionality:**
   - Can we create a GTK3 window?
   - Does Lich5 GUI work?

4. **Across Platforms:**
   - Windows 10/11
   - macOS 12+ (Intel and ARM)
   - Ubuntu 22.04/24.04, Fedora, etc.

### Test Matrix

| Platform | Ruby Version | Test Type | Expected Result |
|----------|-------------|-----------|-----------------|
| Windows x64 | 3.3 | Gem install | Success |
| Windows x64 | 3.3 | `require 'gtk3'` | Success |
| Windows x64 | 3.3 | GTK3 window | Window appears |
| macOS Intel | 3.3 | Gem install | Success |
| macOS ARM | 3.3 | Gem install | Success |
| Linux x64 | 3.3 | Gem install | Success |

### Automated Testing (GitHub Actions)

```yaml
- name: Test binary gem
  run: |
    gem install pkg/gtk3-4.3.4-${{ matrix.platform }}.gem
    ruby -e "require 'gtk3'; puts 'GTK3 loaded successfully!'"
```

---

## 9. Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|-----------|------------|
| **GTK3 library version mismatch** | High | Medium | Bundle exact matched versions |
| **Platform-specific bugs** | Medium | High | Test on all platforms in CI/CD |
| **Large installer size** | Low | High | Accept it (200-300MB is reasonable for game launcher) |
| **Build pipeline complexity** | Medium | Medium | Invest upfront in automation, document thoroughly |
| **Ongoing maintenance burden** | High | Medium | Bundle approach minimizes this (no public gem publishing) |
| **GTK3 deprecation** | Low | Low | GTK3 stable, won't disappear for years |

---

## 10. Next Steps & Action Items

### Phase 1: Research & Proof of Concept (1-2 weeks)
- [ ] Set up test environment for building native gems
- [ ] Build single gem (e.g., `glib2`) for Windows
- [ ] Verify bundled DLLs work
- [ ] Test on clean Windows VM

### Phase 2: Build Pipeline (2-3 weeks)
- [ ] Create GitHub Actions workflow
- [ ] Build all 10 gems for Windows
- [ ] Build all 10 gems for macOS (Intel + ARM)
- [ ] Build all 10 gems for Linux

### Phase 3: Integration (1-2 weeks)
- [ ] Bundle gems into Lich5 Windows installer
- [ ] Bundle gems into Lich5 macOS .app
- [ ] Bundle gems into Lich5 Linux AppImage
- [ ] Test end-to-end installation flow

### Phase 4: Documentation & Release (1 week)
- [ ] Document build process
- [ ] Document troubleshooting
- [ ] Release Lich5 with bundled GTK3 gems
- [ ] Gather user feedback

**Total Estimated Timeline:** 5-8 weeks

---

## 11. Open Questions

1. **Ruby Version:** Which Ruby version to target? (3.3 current, but lock it?)
2. **GTK3 Version:** Use latest (4.3.4) or lock to older stable version?
3. **Windows Build Tool:** MSYS2 vs vcpkg vs prebuilt binaries?
4. **macOS Universal Binaries:** Worth the complexity vs separate gems?
5. **Linux Bundling:** Bundle GTK3 or rely on system packages?
6. **Backwards Compatibility:** Support older Windows/macOS versions?

---

## 12. References & Resources

### Ruby-GNOME Project
- GitHub: https://github.com/ruby-gnome/ruby-gnome
- RubyGems: https://rubygems.org/gems/gtk3/versions/4.3.4

### GTK3 Resources
- Official Site: https://www.gtk.org
- Downloads: https://www.gtk.org/docs/installations/

### Ruby Gem Building
- RubyGems Guides: https://guides.rubygems.org/make-your-own-gem/
- Native Extensions: https://guides.rubygems.org/gems-with-extensions/

### Cross-Platform Building
- GitHub Actions: https://docs.github.com/en/actions
- Ruby Setup Action: https://github.com/ruby/setup-ruby

---

**Status:** This document captures initial brainstorming and planning. Next step is to build a proof-of-concept binary gem for a single platform (Windows recommended as most complex).

**Contributors:** Claude & User
**Last Updated:** 2025-12-28
