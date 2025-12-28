# Lich5 GTK3 Binary Gems

Precompiled GTK3 gems with everything bundled. Just install and run—no setup required.

---

## What Is This?

Lich5 uses GTK3 for its graphical interface (windows, menus, dialogs). Normally, installing GTK3 for Ruby is complicated and error-prone. This project solves that.

**Binary gems** = precompiled + all libraries included = zero installation hassle.

---

## Why Does This Matter?

**The Old Way (Painful):**
1. Install GTK3 system libraries (MSYS2 on Windows, Homebrew on Mac...)
2. Install build tools (compilers, headers, etc.)
3. Run `gem install gtk3` and wait 10-20 minutes while it compiles
4. Debug inevitable failures (missing libraries, version conflicts...)
5. Give up in frustration

**The New Way (Easy):**
```bash
gem install gtk3-4.3.4-x64-mingw32.gem  # Done in 10 seconds
```

**For Lich5 users:** You don't even do this—it's already bundled in the installer. Just install Lich5 and it works.

---

## What's Included?

**10 GTK3 gems**, each with bundled libraries (~150-200MB per platform):
- glib2, gobject-introspection, gio2
- cairo, cairo-gobject, pango
- gdk_pixbuf2, atk, gdk3, gtk3

**5 Platforms:**
- Windows (x64)
- macOS Intel & Apple Silicon
- Linux (x64 & ARM64)

Everything needed to run GTK3 applications is included—no external dependencies.

---

## For Lich5 Users

### Do I Need to Install This?

**No.** If you installed Lich5, you already have it. This is for developers and contributors.

### Why Bundle GTK3?

Lich5 users are gamers, not developers. Asking users to install build tools, compile gems, and debug GTK3 issues is unreasonable. Binary gems make Lich5 installation simple and reliable.

### Where Is GTK3 Used?

- Main Lich5 window and menus
- Login dialogs
- Settings panels
- Script GUIs (Bigshot, etc.)

---

## Installation

### For Lich5 Users
Already installed with Lich5. Nothing to do.

### For Developers
Download and install the gem for your platform:

```bash
gem install gtk3-4.3.4-x64-mingw32.gem      # Windows
gem install gtk3-4.3.4-x86_64-darwin.gem    # macOS Intel
gem install gtk3-4.3.4-arm64-darwin.gem     # macOS Apple Silicon
gem install gtk3-4.3.4-x86_64-linux.gem     # Linux
```

Installing `gtk3` automatically installs all dependencies.

---

## Usage

```ruby
require 'gtk3'

Gtk.init
window = Gtk::Window.new("Hello World")
window.set_default_size(400, 300)
window.show_all
Gtk.main
```

No configuration needed. Libraries load automatically.

---

## Technical Details

For developers who want to contribute or understand the internals:

- **[Architecture Overview](docs/ARCHITECTURE.md)** - How binary gems work
- **[Building Guide](docs/BUILDING.md)** - How to build gems yourself
- **[Contributing Guide](docs/CONTRIBUTING.md)** - How to help
- **[FAQ](docs/FAQ.md)** - Common questions answered

**Library sources:**
- Windows: MSYS2 mingw-w64-gtk3
- macOS: Homebrew gtk+3
- Linux: System packages

**Build system:** GitHub Actions (automatic builds for all platforms)

---

## License

- **This project:** MIT License
- **GTK3 libraries:** LGPL 2.1+ (source code: [GTK](https://gitlab.gnome.org/GNOME/gtk), [GLib](https://gitlab.gnome.org/GNOME/glib), [ruby-gnome](https://github.com/ruby-gnome/ruby-gnome))

Users can replace bundled libraries with their own builds (LGPL requirement).

---

## FAQ

**Q: Why not use system GTK3?**
A: Complex setup, version conflicts, often breaks. Binary gems just work.

**Q: Why not publish to RubyGems.org?**
A: Built specifically for Lich5 bundled distribution. Avoids conflicts with official ruby-gnome gems.

**Q: Can I use these for my own Ruby/GTK3 app?**
A: Yes, but they're optimized for bundled distribution (large size OK). For public gems, you may want a different approach.

**Q: How large are these?**
A: ~150-200MB per platform. Large, but acceptable for bundled installers.

---

## Support

**Lich5 users:** Report issues to [Lich5 repository](https://github.com/elanthia-online/lich5)
**Developers:** Open issues or discussions on [this repository](https://github.com/elanthia-online/lich5-gtk3-gems)

---

## Credits

Built on the shoulders of:
- **ruby-gnome team** (Kouhei Sutou, contributors)
- **GTK/GNOME developers**
- **MSYS2 & Homebrew maintainers**
- **Lars Kanis** (previous binary gem work)

Thank you! 🙏

---

**Built for the Lich5 community**
*Making GTK3 accessible to everyone, not just developers.*
