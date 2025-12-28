# Lich5 GTK3 Binary Gems

Precompiled binary gems for the GTK3 stack with bundled runtime libraries, built specifically for Lich5.

---

## What is This?

This project provides **binary gems** for the complete ruby-gnome GTK3 stack. Each gem includes:

- Precompiled native extensions (no compilation required)
- Bundled GTK3 runtime libraries (DLLs/dylibs)
- All necessary data files (icons, themes, schemas)
- Zero external dependencies

**Result:** Install and run GTK3 Ruby applications with a single `gem install` command.

---

## Why Does This Exist?

### The Problem

Installing GTK3 Ruby applications traditionally requires:

1. Installing GTK3 system libraries
   - Windows: Complex MSYS2 setup or manual DLL hunting
   - macOS: Homebrew or MacPorts installation
   - Linux: Usually available, but version may vary

2. Installing Ruby development tools
   - Windows: RubyInstaller DevKit
   - macOS: Xcode Command Line Tools
   - Linux: Build-essential packages

3. Compiling native gem extensions
   - 10+ gems to compile
   - 10-20 minutes on slow machines
   - Frequent compilation failures

4. Troubleshooting when it breaks
   - Missing headers
   - Library version mismatches
   - PATH issues

**This is too much to ask of users who just want to run a Ruby application.**

### The Solution

Binary gems eliminate all of this:

```bash
# Traditional approach (painful):
# 1. Install GTK3 system libraries
# 2. Install build tools
# 3. gem install gtk3  # waits 10+ minutes, often fails
# 4. Debug compilation errors
# 5. Fix paths and environment variables

# Binary gem approach (simple):
gem install gtk3-4.3.4-x64-mingw32.gem  # done in seconds
```

**One step. It just works.**

---

## Features

✅ **Zero Dependencies** - All GTK3 libraries bundled in the gem
✅ **Pre-compiled** - No build tools or compilation required
✅ **Multi-Platform** - Windows, macOS (Intel & ARM), Linux
✅ **Complete Stack** - All 10 core GTK3 gems included
✅ **Tested** - Verified on clean VMs for each platform
✅ **Current** - Based on latest ruby-gnome releases

---

## Supported Platforms

| Platform | Architecture | Gem Platform String | Status |
|----------|--------------|-------------------|--------|
| Windows | x64 | `x64-mingw32` | ✅ Supported |
| macOS | Intel (x86_64) | `x86_64-darwin` | ✅ Supported |
| macOS | Apple Silicon (ARM64) | `arm64-darwin` | ✅ Supported |
| Linux | x86_64 | `x86_64-linux` | ✅ Supported |
| Linux | ARM64 | `aarch64-linux` | ✅ Supported |

---

## Gems Included

This project builds 10 core GTK3 gems:

### Foundation Layer
- **glib2** - Core GLib library (object system, main loop, utilities)
- **gobject-introspection** - Dynamic language bindings via GObject Introspection
- **gio2** - GIO (file I/O, networking, settings)

### Graphics Layer
- **cairo** - 2D graphics rendering library
- **cairo-gobject** - GObject bindings for Cairo
- **pango** - Text rendering and layout engine

### GTK Layer
- **gdk_pixbuf2** - Image loading and manipulation
- **atk** - Accessibility toolkit (screen reader support)
- **gdk3** - GTK Drawing Kit (windowing, events, display)
- **gtk3** - Main GTK+ 3.x GUI toolkit

**Total bundled size per platform:** ~150-200MB (includes all libraries and data files)

---

## Installation

### For End Users (Bundled with Lich5)

If you're using Lich5, **you don't need to do anything**. The GTK3 binary gems are pre-installed in the Lich5 distribution.

### For Developers (Manual Installation)

Download the gem for your platform and install:

```bash
# Windows
gem install gtk3-4.3.4-x64-mingw32.gem

# macOS (Intel)
gem install gtk3-4.3.4-x86_64-darwin.gem

# macOS (Apple Silicon)
gem install gtk3-4.3.4-arm64-darwin.gem

# Linux
gem install gtk3-4.3.4-x86_64-linux.gem
```

**Note:** Installing `gtk3` will automatically install all dependencies (gdk3, pango, glib2, etc.)

### From Source

See [BUILDING.md](docs/BUILDING.md) for instructions on building the gems yourself.

---

## Usage

After installation, use GTK3 in your Ruby code as normal:

```ruby
require 'gtk3'

Gtk.init

window = Gtk::Window.new("Hello World")
window.set_default_size(400, 300)

label = Gtk::Label.new("GTK3 Binary Gem is working!")
window.add(label)

window.signal_connect('destroy') { Gtk.main_quit }
window.show_all

Gtk.main
```

**No configuration needed. Libraries are automatically found.**

---

## How It Works

### Binary Gem Structure

Each platform-specific gem contains:

```
gtk3-4.3.4-x64-mingw32/
├── lib/
│   ├── gtk3.rb                    # Pure Ruby interface
│   └── gtk3/
│       ├── gtk3.so                # Precompiled native extension
│       └── vendor/                # Bundled GTK3 runtime
│           ├── bin/               # DLLs (Windows)
│           │   ├── libgtk-3-0.dll
│           │   ├── libgdk-3-0.dll
│           │   ├── libglib-2.0-0.dll
│           │   └── ... (50+ DLLs)
│           └── share/             # Data files
│               ├── icons/         # Icon themes
│               ├── themes/        # GTK themes
│               └── glib-2.0/      # GSettings schemas
```

### Library Loading

When you `require 'gtk3'`, the gem:

1. Adds `vendor/bin` to the system PATH (Windows) or LD_LIBRARY_PATH (Linux)
2. Loads the precompiled native extension (`gtk3.so`)
3. The native extension finds bundled GTK3 libraries automatically
4. GTK3 loads icon themes and data files from `vendor/share`

**Everything is self-contained and isolated.**

---

## Technical Details

### GTK3 Versions

- **GTK3:** 3.24.x (latest stable 3.x series)
- **GLib:** 2.80.x
- **Cairo:** 1.18.x
- **Pango:** 1.52.x

### Ruby Compatibility

- **Ruby 3.3.x** (locked to prevent ABI incompatibilities)
- Ruby 3.4+ support will be added as new gem builds

### Library Sources

- **Windows:** MSYS2 mingw-w64-x86_64-gtk3 packages
- **macOS:** Homebrew gtk+3 formula
- **Linux:** System GTK3 packages (or bundled for AppImage)

### Build System

- **Platform:** GitHub Actions (native compilation on each OS)
- **Automation:** Rake-based build system
- **Testing:** Automated testing on clean VMs
- **CI/CD:** Matrix builds across all platforms in parallel

---

## Versioning

Binary gem versions follow this pattern:

```
<ruby-gnome-version>.<platform>
```

**Example:** `gtk3-4.3.4-x64-mingw32.gem`
- `4.3.4` = ruby-gnome gem version
- `x64-mingw32` = Windows 64-bit platform

### Update Schedule

New builds are released:
- When ruby-gnome releases new versions
- When GTK3 security updates are needed
- When Ruby minor versions change (e.g., 3.3 → 3.4)

**Typical frequency:** 2-4 releases per year

---

## Comparison to Alternatives

### vs System GTK3 Installation

| Approach | User Experience | Pros | Cons |
|----------|----------------|------|------|
| **System GTK3** | Install GTK3 → Install Ruby → Install gems | Standard | Complex setup, version conflicts |
| **Binary Gems** | Install gem → Done | Zero dependencies | Larger download (~150MB) |

**Winner for end users:** Binary gems (simplicity beats download size)

### vs Source Gems (ruby-gnome)

| Approach | Installation Time | Failure Rate | User Complexity |
|----------|------------------|--------------|-----------------|
| **Source gems** | 10-20 minutes | High (missing headers, version mismatches) | Requires build tools |
| **Binary gems** | 10-30 seconds | Near zero | No build tools needed |

**Winner:** Binary gems (reliability and speed)

---

## License

### This Project

This project (build scripts, automation, documentation) is licensed under the **MIT License**.

### Bundled Libraries

GTK3 and related libraries are licensed under **LGPL 2.1+**.

**LGPL Compliance:**
- ✅ Libraries are dynamically linked (separate DLL/dylib files)
- ✅ Users can replace bundled libraries with their own builds
- ✅ Source code links provided below
- ✅ LGPL license text included in each gem

**Source Code:**
- GTK3: https://gitlab.gnome.org/GNOME/gtk/-/tree/gtk-3-24
- GLib: https://gitlab.gnome.org/GNOME/glib
- Cairo: https://gitlab.freedesktop.org/cairo/cairo
- Pango: https://gitlab.gnome.org/GNOME/pango
- Ruby-GNOME: https://github.com/ruby-gnome/ruby-gnome

---

## For Lich5 Users

### Where Are These Gems Used?

Lich5 uses GTK3 for its graphical user interface:
- Main window and menu system
- Login dialogs
- Settings panels
- Script UIs (e.g., Bigshot, other GUI-based scripts)

### Why Bundle Instead of Requiring Installation?

**User experience is paramount.** Lich5 users are gamers, not developers. Requiring them to:
1. Install MSYS2 on Windows
2. Set up build environments
3. Compile 10 gems
4. Debug PATH issues

...is a non-starter. Binary gems make Lich5 installation **one-click simple**.

### Can I Replace the Bundled GTK3?

Yes! The LGPL requires this freedom. To use your own GTK3 build:

1. Locate the gem installation (e.g., `C:\Lich5\ruby\lib\ruby\gems\3.3.0\gems\gtk3-4.3.4-x64-mingw32`)
2. Replace DLLs in `vendor/bin/` with your own
3. Restart Lich5

**Note:** Compatibility is not guaranteed if you use different GTK3 versions.

---

## Development

### Building the Gems

See [BUILDING.md](docs/BUILDING.md) for detailed build instructions.

**Quick start:**
```bash
# Prerequisites: Ruby 3.3, GTK3 installed on your platform

# Clone repository
git clone https://github.com/elanthia-online/lich5-gtk3-gems.git
cd lich5-gtk3-gems

# Download vendor libraries
rake vendor:download

# Build all gems for your platform
rake build:all

# Test
rake test:quick
```

### Contributing

Contributions are welcome! Areas where help is needed:

- Testing on different platforms/versions
- Build automation improvements
- Documentation
- Bug reports and fixes

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Repository Structure

```
lich5-gtk3-gems/
├── gems/                  # Ruby gem sources (10 gems)
│   ├── glib2/
│   ├── gtk3/
│   └── ...
├── vendor/                # GTK3 runtime libraries (downloaded, not in git)
│   ├── windows/x64/
│   ├── macos/arm64/
│   └── linux/x86_64/
├── scripts/               # Build automation
├── test/                  # Integration tests
├── docs/                  # Documentation
└── .github/workflows/     # CI/CD automation
```

---

## Support

### For Lich5 Users

If you're having issues with Lich5 and GTK3:
- Check Lich5 documentation first
- Report issues to Lich5 repository: https://github.com/elanthia-online/lich5

### For Developers Using These Gems

- **Bug reports:** https://github.com/elanthia-online/lich5-gtk3-gems/issues
- **Questions:** Open a discussion on GitHub
- **Ruby-GNOME issues:** https://github.com/ruby-gnome/ruby-gnome/issues

---

## Acknowledgments

This project is built on top of the excellent work by:

- **ruby-gnome team** (Kouhei Sutou and contributors) - Original GTK bindings
- **GTK/GNOME team** - GTK toolkit
- **MSYS2 team** - Windows GTK3 packages
- **Homebrew team** - macOS GTK3 packages
- **Lars Kanis** - Previous binary gem work and inspiration

Thank you to all the open-source contributors who made this possible!

---

## Project Status

**Current Phase:** Planning / Initial Development
**First Release Target:** Q1 2026
**Supported Ruby Version:** 3.3.x
**Supported GTK3 Version:** 3.24.x

---

## FAQ

### Why not just use ruby-gnome gems directly?

Ruby-gnome gems require compilation. This project provides pre-compiled versions with bundled libraries for zero-dependency installation.

### Why not publish to RubyGems.org?

These gems are built specifically for Lich5 distribution. Publishing to RubyGems.org could cause conflicts with the official ruby-gnome gems. Users get these gems bundled with Lich5 installers.

### What if I want GTK4 instead?

GTK4 support is possible but not currently planned. GTK3 is stable, well-supported, and meets Lich5's needs. A migration to GTK4 would be a separate future project.

### How large are these gems?

Each platform's full gem set is ~150-200MB compressed. This includes all libraries and data files.

### Can I use these for my own Ruby/GTK3 application?

Yes! These gems work with any Ruby/GTK3 application. However, they're optimized for Lich5's use case (bundled installer distribution). If you're publishing an app, you may want to build your own binary gems tailored to your needs.

### What about Linux?

Linux users typically have GTK3 installed already. We provide binary gems for Linux primarily for AppImage distribution or users who want a self-contained installation.

---

**Built with ❤️ for the Lich5 community**

*Making Ruby/GTK3 applications accessible to everyone, not just developers.*
