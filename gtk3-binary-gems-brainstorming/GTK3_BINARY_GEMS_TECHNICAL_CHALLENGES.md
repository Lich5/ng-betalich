# GTK3 Binary Gems: Technical Challenges & Strategies

**Date:** 2025-12-28
**Purpose:** Deep dive into technical challenges of building binary GTK3 gems
**Status:** Brainstorming / Planning Phase

---

## 1. The Core Challenge: Why Did ruby-gnome Stop Providing Binary Gems?

### Historical Context

**The Old Way (2015-2018):**
- ruby-gnome team (Lars Kanis, Kouhei Sutou, et al.) provided **fat binary gems**
- Windows users: `gem install gtk3` → instantly worked ✅
- Gems included precompiled `.dll` files and GTK3 runtime
- Installation was trivial

**The Transition (~2019+):**
- Team stopped producing binary gems
- Shifted to **source-only gems** requiring compilation
- Users must: Install GTK3 → Install DevKit → Compile → Debug ❌

**Why They Stopped:**
Likely reasons (not officially documented):
1. **Maintenance burden** - Cross-compiling for multiple platforms is complex
2. **CI/CD complexity** - Building, testing, and publishing across platforms
3. **Gem size** - Fat gems with bundled libraries are 150-200MB+
4. **Volunteer project** - Limited resources, core team moved on
5. **GObject Introspection** - Modern approach uses dynamic bindings, less need for handcrafted bindings

### Why This Matters for Lich5

- **Lich5's user base is non-technical** (gamers, not developers)
- Compiling gems is a dealbreaker for 90%+ of users
- Current state: "Just use system GTK3" doesn't work on Windows (most users)
- **Binary gems are essential** for Lich5 distribution

---

## 2. Cross-Platform Native Extension Challenges

### The Fundamental Problem

Ruby gems with **native extensions** (C code) must be compiled for each platform:
- Ruby's C API varies slightly between versions (3.2 vs 3.3)
- Operating systems have different ABIs (Windows PE vs Linux ELF vs Mach-O)
- CPU architectures differ (x86_64 vs ARM64)

**Example: `gtk3` gem's native extension**
```c
// ext/gtk3/rbgtk-application.c
#include <gtk/gtk.h>
#include <ruby.h>

VALUE rb_gtk_application_new(VALUE self, VALUE id, VALUE flags) {
    GtkApplication *app = gtk_application_new(
        RSTRING_PTR(id),
        NUM2INT(flags)
    );
    return GOBJ2RVAL(app);
}
```

This C code must be compiled to:
- `gtk3.so` on Linux
- `gtk3.bundle` on macOS
- `gtk3.dll` on Windows

Each has different calling conventions, symbol mangling, etc.

### The Build Matrix

| Ruby Version | Platform | Architecture | Output Binary |
|--------------|----------|--------------|---------------|
| 3.3 | Windows | x64 | `gtk3.dll` (PE32+) |
| 3.3 | macOS | x86_64 | `gtk3.bundle` (Mach-O 64-bit) |
| 3.3 | macOS | ARM64 | `gtk3.bundle` (Mach-O ARM64) |
| 3.3 | Linux | x86_64 | `gtk3.so` (ELF 64-bit) |
| 3.3 | Linux | ARM64 | `gtk3.so` (ELF ARM64) |
| 3.2 | ... | ... | (Repeat for each Ruby version) |

**For 10 gems × 5 platforms × N Ruby versions = 50+ binaries to build!**

### Cross-Compilation vs Native Compilation

**Cross-Compilation:**
```
Build on Linux → Compile for Windows (using MinGW cross-compiler)
```
- **Pros:** Single build machine can target all platforms
- **Cons:** Complex toolchain setup, hard to debug, ABI mismatches

**Native Compilation:**
```
Build on Windows → Compile for Windows
Build on macOS → Compile for macOS
Build on Linux → Compile for Linux
```
- **Pros:** Simpler, more reliable, easier debugging
- **Cons:** Need build environments for each platform

**Recommendation:** **Native compilation via GitHub Actions** (free, reliable, well-documented)

---

## 3. GTK3 Runtime Library Bundling

### The Dependency Hell

GTK3 is not a single library - it's a **stack of ~50+ shared libraries**:

**Core GTK3:**
- `libgtk-3`
- `libgdk-3`
- `libgdk-pixbuf-2.0`
- `libpango-1.0`
- `libcairo`
- `libglib-2.0`
- `libgobject-2.0`
- `libgio-2.0`

**Transitive Dependencies:**
- `libffi` (foreign function interface)
- `libintl` (internationalization)
- `libepoxy` (OpenGL dispatch)
- `libharfbuzz` (text shaping)
- `libfontconfig` (font configuration)
- `libfreetype` (font rendering)
- `libpng`, `libjpeg`, `libtiff` (image formats)
- `libxml2`, `libexpat` (XML parsing)
- `libiconv` (character encoding)
- `zlib`, `bzip2` (compression)
- `pixman` (low-level pixel manipulation)
- And more...

**Total:** 50-70 DLLs on Windows, 40-60 dylibs on macOS!

### Where to Get These Libraries?

#### Windows Options:

**1. MSYS2 (Recommended)**
```bash
pacman -S mingw-w64-x86_64-gtk3
```
- Pros: Active maintenance, easy updates, includes all dependencies
- Cons: Large ecosystem (2GB+ for full MSYS2), must extract DLLs

**2. vcpkg**
```bash
vcpkg install gtk3:x64-windows
```
- Pros: Clean, Windows-native, good for C++ projects
- Cons: Slower builds, less mature GTK3 support than MSYS2

**3. gtk.org Prebuilt Binaries**
- Pros: Official, curated
- Cons: Often outdated, may be missing dependencies

**4. Build from Source**
- Pros: Maximum control
- Cons: Insanely complex (GTK3 build system is brutal)

#### macOS Options:

**1. Homebrew (Recommended)**
```bash
brew install gtk+3
```
- Pros: De facto standard on macOS, well-maintained
- Cons: x86_64 vs ARM64 bottle compatibility

**2. MacPorts**
```bash
port install gtk3
```
- Pros: Alternative to Homebrew
- Cons: Smaller community, slower updates

**3. Build from Source**
- Cons: Complex build, requires Xcode tools

#### Linux Options:

**1. System Package Manager (Recommended for Development)**
```bash
apt install libgtk-3-dev    # Debian/Ubuntu
dnf install gtk3-devel      # Fedora
```
- Pros: Easy, standard
- Cons: Version varies by distro

**2. Build from Source**
- Cons: Dependency nightmare on Linux

### Bundling Strategy: Copy All DLLs

**Windows Example:**
1. Install GTK3 via MSYS2: `C:\msys64\mingw64\bin\`
2. Identify all required DLLs (use `ldd` or Dependency Walker)
3. Copy to gem's `vendor/bin/` directory:
   ```
   gtk3-4.3.4-x64-mingw32/
   └── vendor/
       └── bin/
           ├── libgtk-3-0.dll
           ├── libgdk-3-0.dll
           ├── libglib-2.0-0.dll
           └── ... (50+ DLLs)
   ```
4. Modify gem's `extconf.rb` to add `vendor/bin` to PATH at load time

**macOS Example:**
1. Install GTK3 via Homebrew: `/opt/homebrew/lib/` (ARM) or `/usr/local/lib/` (Intel)
2. Copy dylibs to `vendor/lib/`
3. Use `install_name_tool` to rewrite dylib paths to `@rpath`

**Challenge:** Each DLL/dylib can be 1-5MB → Total bundle: **150-200MB**

---

## 4. Dynamic Library Loading & Path Resolution

### How Ruby Loads Native Extensions

**On `require 'gtk3'`:**
1. Ruby searches for `gtk3.rb` in load path
2. `gtk3.rb` calls `require 'gtk3.so'` (or `.bundle`, `.dll`)
3. OS dynamic linker loads the native extension
4. **Problem:** `gtk3.so` depends on `libgtk-3.so`, which depends on `libglib-2.0.so`, etc.

**OS Linker Search Paths:**
- **Linux:** `LD_LIBRARY_PATH`, `/lib`, `/usr/lib`, etc.
- **macOS:** `DYLD_LIBRARY_PATH`, `@rpath`, `/usr/lib`, etc.
- **Windows:** `PATH`, current directory, system directories

**If bundled DLLs are in `vendor/bin/`, how does the linker find them?**

### Solution 1: Modify PATH/LD_LIBRARY_PATH Before Loading

**In `gtk3.rb` (before `require 'gtk3.so'`):**
```ruby
# gtk3.rb
module Gtk3
  vendor_bin = File.join(__dir__, 'gtk3', 'vendor', 'bin')
  if Gem.win_platform?
    ENV['PATH'] = "#{vendor_bin};#{ENV['PATH']}"
  else
    ENV['LD_LIBRARY_PATH'] = "#{vendor_bin}:#{ENV['LD_LIBRARY_PATH']}"
  end
end

require 'gtk3/gtk3'  # Load native extension
```

**Pros:** Simple, works across platforms
**Cons:** Modifies global environment (may affect other gems)

### Solution 2: Use rpath (Linux/macOS)

**At compile time, embed library search path in `.so`:**
```bash
gcc -o gtk3.so ... -Wl,-rpath,'$ORIGIN/../vendor/lib'
```

**`$ORIGIN`** = directory containing `gtk3.so`

**Pros:** No runtime environment manipulation
**Cons:** Only works on Linux/macOS, requires build-time configuration

### Solution 3: Delayed Binding (Windows)

**Use `LoadLibraryEx` with `LOAD_WITH_ALTERED_SEARCH_PATH`:**
```c
// In native extension init
HMODULE gtk_dll = LoadLibraryEx(
    "vendor\\bin\\libgtk-3-0.dll",
    NULL,
    LOAD_WITH_ALTERED_SEARCH_PATH
);
```

**Pros:** Full control over load order
**Cons:** Complex, Windows-specific, fragile

### Recommendation

**Use Solution 1 (PATH modification) for simplicity**, especially for bundled Lich5 installer (isolated environment).

---

## 5. Icon Themes, Glade Files, and Data Files

### GTK3 Runtime Data

GTK3 doesn't just need **code** (DLLs) - it also needs **data files**:

**Icon Themes:**
```
share/icons/Adwaita/
├── index.theme
├── 16x16/
├── 22x22/
└── ...
```

**GSettings Schemas:**
```
share/glib-2.0/schemas/
└── org.gtk.Settings.FileChooser.gschema.xml
```

**Glade UI Files (for Lich5 scripts like Bigshot):**
```
data/
└── bigshot.glade
```

**Themes:**
```
share/themes/Adwaita/
```

**Without these:**
- Icons won't display (default to missing icon)
- File chooser dialogs may crash
- UI may look broken

### Bundling Data Files

**Windows:**
```
gtk3-4.3.4-x64-mingw32/
├── vendor/
│   ├── bin/          # DLLs
│   └── share/        # Data files
│       ├── icons/
│       ├── themes/
│       └── glib-2.0/
```

**Set environment variables in `gtk3.rb`:**
```ruby
vendor_share = File.join(__dir__, 'gtk3', 'vendor', 'share')
ENV['XDG_DATA_DIRS'] = "#{vendor_share};#{ENV['XDG_DATA_DIRS']}"
```

**macOS/Linux:** Similar approach using `XDG_DATA_DIRS`

**Challenge:** Data files add another 50-100MB to bundle!

---

## 6. Version Compatibility & ABI Stability

### GTK3 ABI Stability

**Good News:** GTK3 has **stable ABI** within major version:
- GTK 3.0 → GTK 3.24: Binary compatible
- Apps compiled against GTK 3.0 work with GTK 3.24 runtime

**Implication:** We can bundle latest GTK3 3.x and support older Lich5 versions.

### Ruby ABI Stability

**Bad News:** Ruby's C API changes between **minor versions**:
- Gem compiled for Ruby 3.3 may not work with Ruby 3.4
- Must rebuild for each Ruby version

**Implication:** Lock Lich5 to a specific Ruby version (e.g., 3.3).

### GLib ABI Versions

**GLib uses "soname versioning":**
- `libglib-2.0.so.0` (Linux)
- `libglib-2.0-0.dll` (Windows)

**The `.0` suffix indicates ABI version** (not release version).

**GLib 2.56, 2.58, 2.80 all provide `libglib-2.0.so.0`** → ABI compatible!

**Implication:** Bundled GLib works across wide range of GTK3 versions.

---

## 7. Debugging & Troubleshooting Strategies

### Common Failure Modes

**1. "Cannot load library: libgtk-3-0.dll"**
- Cause: DLL not found in PATH
- Fix: Verify DLL bundled in `vendor/bin/`, check PATH modification

**2. "Undefined symbol: g_object_unref"**
- Cause: ABI mismatch between compiled gem and runtime GTK3
- Fix: Rebuild gem against same GTK3 version as bundled runtime

**3. Segmentation fault on `Gtk::Window.new`**
- Cause: Multiple GTK3 versions loaded (system + bundled)
- Fix: Ensure bundled DLLs take precedence in PATH

**4. Icons don't display**
- Cause: Icon theme data files missing
- Fix: Bundle `share/icons/` and set `XDG_DATA_DIRS`

### Debugging Tools

**Windows:**
- **Dependency Walker** (`depends.exe`): Show DLL dependencies
- **Process Monitor**: Trace DLL load attempts
- **Dr. Memory**: Detect memory corruption

**macOS:**
- **otool -L**: Show dylib dependencies
- **DYLD_PRINT_LIBRARIES=1**: Trace dylib loading
- **lldb**: Debugger

**Linux:**
- **ldd**: Show `.so` dependencies
- **LD_DEBUG=libs**: Trace library loading
- **strace**: System call tracing
- **gdb**: Debugger

### Test Suite

**Minimal test for each gem:**
```ruby
# test_gtk3_load.rb
require 'gtk3'

Gtk.init
window = Gtk::Window.new("Test")
window.set_default_size(400, 300)
window.show_all

puts "✅ GTK3 loaded successfully!"
puts "   GTK version: #{Gtk::VERSION.join('.')}"
puts "   GLib version: #{GLib::VERSION.join('.')}"

Gtk.main_quit
```

**Run on each platform in CI:**
```bash
ruby test_gtk3_load.rb
# Exit code 0 = success
```

---

## 8. Performance Considerations

### Gem Size vs Install Speed

**Fat Gems with Bundled Libraries:**
- Size: 150-200MB per gem (or 200-300MB total if shared)
- Install time: 5-10 seconds (just extracting files)

**Source Gems Requiring Compilation:**
- Size: 5-10MB per gem
- Install time: 5-10 **minutes** (compiling + linking)

**For Lich5 users: 200MB download >> 10 minutes compiling!**

### Load Time Impact

**Bundled DLLs:**
- Extra overhead: ~100ms on first `require 'gtk3'` (loading 50+ DLLs)
- Negligible for Lich5 (GUI app, not latency-sensitive)

**Optimizations:**
- Lazy-load non-essential libraries
- Strip debug symbols from DLLs (saves 30-50% size)

---

## 9. Build System Design Patterns

### Pattern 1: Monorepo with Subgems

```
lich5-gtk3-gems/
├── gems/
│   ├── glib2/
│   │   ├── ext/
│   │   ├── lib/
│   │   ├── glib2.gemspec
│   │   └── Rakefile
│   ├── gtk3/
│   └── ...
├── vendor/
│   ├── windows-x64/
│   ├── macos-arm64/
│   └── linux-x64/
├── Rakefile (master build script)
└── .github/workflows/
```

**Build process:**
1. `rake build:all` → Builds all 10 gems for all platforms
2. Each gem's Rakefile copies DLLs from `vendor/`
3. Output: `pkg/*.gem` (50+ gem files)

**Pros:** Centralized control, shared vendor libraries
**Cons:** Complex Rakefile orchestration

### Pattern 2: Separate Repos per Gem

```
lich5-glib2/
├── ext/
├── lib/
├── glib2.gemspec
└── .github/workflows/

lich5-gtk3/
├── ext/
├── lib/
├── gtk3.gemspec
└── .github/workflows/
```

**Pros:** Simpler per-gem build, independent versioning
**Cons:** Duplicated vendor libraries, harder to coordinate

### Recommendation: **Pattern 1 (Monorepo)** for easier bundling into Lich5 installer.

---

## 10. Licensing Considerations

### GTK3 License: LGPL 2.1+

**LGPL Requirements for Distribution:**
1. **Dynamically link** to LGPL libraries (vs static linking) ✅ (We are!)
2. **Provide source code** for LGPL libraries (or offer to provide)
3. **Allow users to modify** LGPL libraries (provide .dll/.so files separately)

**For Lich5:**
- ✅ GTK3 DLLs are separate files (users can replace them)
- ✅ Provide download link to GTK3 source code
- ✅ Include LGPL license text in installer

**Not a problem for Lich5** (game launcher, not proprietary library).

### Ruby License: 2-clause BSD / Ruby License

**Permissive:** No restrictions on bundling Ruby with commercial software.

### Ruby-GNOME License: LGPL 2.1+

Same as GTK3 - must allow users to replace gems.

---

## 11. Long-Term Maintenance Strategy

### What Happens When GTK3/Ruby Updates?

**GTK3 Update (3.24.x → 3.24.y):**
1. Download new GTK3 binaries
2. Update `vendor/` libraries
3. Rebuild all gems (may not need C code changes)
4. Test thoroughly
5. Release new Lich5 installer

**Ruby Update (3.3 → 3.4):**
1. Rebuild all gems for Ruby 3.4
2. Test for C API changes (unlikely to break)
3. Release new gems

**Ruby-GNOME Update (4.3.4 → 4.4.0):**
1. Pull latest ruby-gnome source
2. Rebuild with bundled libraries
3. Test (may have breaking changes)
4. Update Lich5 as needed

### Minimizing Maintenance Burden

**Strategy:**
- **Freeze versions** for each Lich5 major release
- Only update for security patches or critical bugs
- Bundle approach means **no need to publish gems** → No ongoing gem server maintenance

---

## 12. Alternative Approaches (Considered & Rejected)

### Alternative 1: Ship System Installer for GTK3

**Idea:** Lich5 installer runs `choco install gtk3` (Windows) or prompts user to install GTK3.

**Pros:** Smaller Lich5 installer
**Cons:**
- Extra step for users (friction!)
- Requires admin privileges
- GTK3 version mismatch issues
- Doesn't work offline

**Verdict:** ❌ Rejected (too user-hostile)

### Alternative 2: Use libui Instead of GTK3

**Idea:** Migrate Lich5 to [libui](https://github.com/andlabs/libui) (lightweight native GUI library).

**Pros:** Smaller binaries, truly native widgets
**Cons:**
- Complete Lich5 rewrite (months of work)
- Glade files (Bigshot, etc.) unusable
- Limited widget set
- Poor accessibility
- Questionable long-term viability

**Verdict:** ❌ Rejected (too much migration effort, see UI_FRAMEWORK_DECISION.md)

### Alternative 3: Ship Pre-Installed Ruby + Gems

**Idea:** Lich5 installer includes full Ruby + all gems pre-installed (not as gems, just extracted files).

**Pros:** Simplest for users
**Cons:**
- Non-standard Ruby installation
- Harder to update individual gems
- Breaks `gem` command expectations

**Verdict:** 🤔 Possible, but binary gems are more standard

---

## 13. Key Success Criteria

### For POC (Proof of Concept):
- [ ] Build single gem (`glib2`) for Windows with bundled DLLs
- [ ] `require 'glib2'` works on clean Windows 10/11 VM
- [ ] No external dependencies (no system GTK3 needed)

### For MVP (Minimum Viable Product):
- [ ] All 10 core gems built for Windows, macOS, Linux
- [ ] GitHub Actions CI builds gems automatically
- [ ] Gems bundled in Lich5 installer
- [ ] Lich5 GUI loads successfully on all platforms

### For Production:
- [ ] Comprehensive test suite (automated + manual)
- [ ] Documentation for build process
- [ ] Version update process documented
- [ ] User-facing troubleshooting guide

---

## 14. Timeline Estimates

**Phase 1: Research & POC (2 weeks)**
- Set up build environment
- Build single gem for Windows
- Validate DLL bundling works

**Phase 2: Full Windows Build (2 weeks)**
- Build all 10 gems for Windows
- Automated CI pipeline
- Integration testing

**Phase 3: macOS & Linux (2 weeks)**
- Build for macOS (Intel + ARM)
- Build for Linux
- Cross-platform testing

**Phase 4: Lich5 Integration (1 week)**
- Bundle gems in installers
- End-to-end testing
- Release

**Total: 7-8 weeks** (assuming no major blockers)

---

## 15. Next Actions

1. **Set up build environment** on local machine (Windows or macOS)
2. **Download GTK3 binaries** (MSYS2 for Windows, Homebrew for macOS)
3. **Clone ruby-gnome/ruby-gnome** repository
4. **Build `glib2` gem** manually with bundled DLLs
5. **Test on clean VM** (no GTK3 installed)
6. **Document build steps** for automation

---

**Status:** Planning complete. Ready to move to proof-of-concept implementation.

**Contributors:** Claude & User
**Last Updated:** 2025-12-28
