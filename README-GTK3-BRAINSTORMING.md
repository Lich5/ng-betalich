# GTK3 Binary Gems Project - Brainstorming Documents

## Overview

This repository contains comprehensive planning documents for a new project: **building precompiled binary GTK3 gems for Lich5**.

### The Problem

Currently, Lich5 users must manually install GTK3 system libraries and compile native Ruby gems, which is:
- Complex and error-prone for non-technical users
- Platform-dependent (especially problematic on Windows)
- Time-consuming (compilation can take 10+ minutes)

### The Solution

Create **binary gems** (precompiled with bundled GTK3 runtime libraries) that provide:
- ✅ Zero-dependency installation
- ✅ One-click "just works" experience
- ✅ Bundled with Lich5 installers
- ✅ Support for Windows, macOS (Intel/ARM), and Linux

### Project Scope

**10 Core Gems:**
- glib2, gobject-introspection, gio2
- cairo, cairo-gobject
- pango, gdk_pixbuf2, atk
- gdk3, gtk3

**5 Platforms:**
- Windows x64 (x64-mingw32)
- macOS Intel (x86_64-darwin)
- macOS Apple Silicon (arm64-darwin)
- Linux x64 (x86_64-linux)
- Linux ARM64 (aarch64-linux)

**Distribution:**
- Bundled directly in Lich5 installers (not published to RubyGems.org)
- ~150-200MB of libraries per platform

---

## Brainstorming Documents

📦 **Package:** `gtk3-binary-gems-brainstorming-2025-12-28.tar.gz` (32KB)

### Documents Included

1. **README.md** - Overview and navigation guide
2. **INITIALIZATION_GUIDE.md** - Quick start for implementation
3. **GTK3_BINARY_GEMS_PLANNING.md** - Architecture and timeline
4. **GTK3_BINARY_GEMS_TECHNICAL_CHALLENGES.md** - Deep technical analysis
5. **GTK3_BINARY_GEMS_REPOSITORY_SCAFFOLDING.md** - Complete repo structure with code
6. **GTK3_BINARY_GEMS_VENDOR_LIBRARY_ACQUISITION.md** - Library acquisition strategy

**Total:** ~100KB of comprehensive planning documentation

### Download

**Tarball:**
```bash
# From repository root
tar -xzf gtk3-binary-gems-brainstorming-2025-12-28.tar.gz
```

**Individual Files:**
Browse the `gtk3-binary-gems-brainstorming/` directory for individual markdown files.

---

## Key Decisions

✅ **Build Approach:** Native compilation via GitHub Actions (not cross-compilation)
✅ **Cost:** $0 (free GitHub Actions for public repositories)
✅ **Build Frequency:** ~2 builds/year (Ruby updates + security patches)
✅ **Timeline:** 1-2 weeks to POC, 6-8 weeks to production

### Technologies

- **Build Platform:** GitHub Actions (matrix builds for all platforms)
- **Windows GTK3 Source:** MSYS2 (mingw-w64-x86_64-gtk3)
- **macOS GTK3 Source:** Homebrew (gtk+3)
- **Linux GTK3 Source:** System packages (or bundle for AppImage)
- **Storage:** GitHub Releases for vendor libraries

---

## Next Steps

### 1. Review Documentation
Start with `brainstorm/README.md` for navigation, then read through the planning documents.

### 2. Create New Repository
**Recommended name:** `elanthia-online/lich5-gtk3-gems` (or similar)
**Visibility:** Public (for free GitHub Actions)

### 3. Implementation
Follow the `INITIALIZATION_GUIDE.md` to set up the repository and start building.

**Quick Start Paths:**

**Option A - Fast POC** (1 day to first gem):
- Create minimal directory structure
- Import glib2 source from ruby-gnome
- Extract DLLs from MSYS2
- Build first binary gem

**Option B - Full Scaffolding** (2-3 days setup):
- Complete repository structure
- GitHub Actions workflows
- Build automation scripts
- Test framework

### 4. Cleanup
These brainstorming documents are **temporary planning artifacts**. Once you've:
- Downloaded/reviewed the documents
- Created the new `lich5-gtk3-gems` repository
- Started implementation

You can **remove these files** from ng-betalich:
```bash
git rm -r gtk3-binary-gems-brainstorming/
git rm gtk3-binary-gems-brainstorming-2025-12-28.tar.gz
git rm GTK3-BRAINSTORMING-DOWNLOAD-HERE.md
git commit -m "chore: Remove GTK3 brainstorming docs (moved to lich5-gtk3-gems)"
```

---

## Project Goals

### Short-term (POC - 1-2 weeks)
- [ ] Build single gem (glib2) for Windows with bundled DLLs
- [ ] Verify installation and loading on clean Windows VM
- [ ] Validate approach and identify blockers

### Medium-term (MVP - 4-5 weeks)
- [ ] Build all 10 gems for all platforms
- [ ] GitHub Actions CI/CD pipeline
- [ ] Basic testing framework
- [ ] Documentation

### Long-term (Production - 6-8 weeks)
- [ ] Comprehensive test suite
- [ ] Bundle in Lich5 Windows installer
- [ ] Bundle in Lich5 macOS .app
- [ ] Bundle in Lich5 Linux AppImage
- [ ] Release and user testing

---

## Technical Highlights

### Why This Approach?

**GitHub Actions Native Compilation vs Cross-Compilation:**
- GTK3 has 50-70 interdependent libraries (dependency hell for cross-compilation)
- Native compilation is simpler, more reliable, easier to debug
- Must test on target platforms anyway
- Free and parallel on GitHub Actions

**Bundling Libraries:**
- Windows: ~150MB of DLLs + data files (icons, themes, schemas)
- macOS: ~120MB of dylibs + data files
- Linux: Prefer system GTK3 (unless building AppImage)

**Build Pipeline:**
- Matrix builds run in parallel (all platforms simultaneously)
- ~100 minutes wall-clock time per full build
- Automated testing on each platform
- Artifacts uploaded to GitHub Releases

---

## Questions?

These documents provide comprehensive answers to:
- Why build binary gems? (vs requiring users to compile)
- Why GitHub Actions? (vs cross-compilation)
- How to acquire vendor libraries? (MSYS2, Homebrew, etc.)
- How to organize the repository?
- How to handle 50-70 DLL dependencies?
- What about licensing? (LGPL compliance)
- Timeline and effort estimates?

All questions are answered in the brainstorming documents. Start with `README.md` in the brainstorm package.

---

## License Note

GTK3 and related libraries are LGPL 2.1+. Binary distribution requires:
- ✅ Include license text
- ✅ Dynamic linking (not static) - libraries remain separate files
- ✅ Provide source code or offer (link to GTK3 source)
- ✅ Allow users to replace libraries

All requirements are met by our binary gem approach.

---

**Status:** Planning complete, ready for implementation
**Created:** 2025-12-28
**Session Type:** Brainstorming and architecture planning

---

## Quick Reference

| What | Where |
|------|-------|
| **All docs (tarball)** | `gtk3-binary-gems-brainstorming-2025-12-28.tar.gz` |
| **Individual docs** | `gtk3-binary-gems-brainstorming/` directory |
| **Start here** | `brainstorm/README.md` |
| **Implementation guide** | `brainstorm/INITIALIZATION_GUIDE.md` |
| **Timeline** | 1-2 weeks POC, 6-8 weeks production |
| **Cost** | $0 (free GitHub Actions) |
| **New repo** | `elanthia-online/lich5-gtk3-gems` (recommended) |

**Let's get this party started!** 🎉
