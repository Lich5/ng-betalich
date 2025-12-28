# GTK3 Binary Gems - Session Initialization Guide

**Purpose:** Quick reference for starting a new implementation session
**Date:** 2025-12-28

---

## When Starting Your Next Session

### Context to Provide

When you start the new session with Claude, provide this context:

```
I'm ready to start implementing the GTK3 binary gems project we planned.

Context:
- We've completed brainstorming and have 4 planning documents
- We're building binary gems for GTK3 to bundle with Lich5
- Repository will be: elanthia-online/lich5-gtk3-gems (or similar)
- Target: 10 core gems for 5 platforms (Windows, macOS Intel/ARM, Linux)
- Distribution: Bundled with Lich5 installer (not published to RubyGems.org)
- Build: GitHub Actions with native compilation

Current status:
- [Created repository / Not created yet]
- [Initial directory structure setup / Not setup yet]
- Starting with POC: Build glib2 gem for Windows

Please help me with [specific task - see checklist below].
```

### Pre-Session Checklist

Before starting the implementation session, complete:

- [ ] Review all 4 brainstorming documents
- [ ] Make any architectural decisions we left open:
  - [ ] Repository name (recommendation: `lich5-gtk3-gems`)
  - [ ] GitHub organization
  - [ ] Ruby version to lock (recommendation: 3.3.0)
  - [ ] Linux bundling strategy (recommendation: system GTK3, unless AppImage)
- [ ] Create GitHub repository (public for free Actions)
- [ ] Clone repository locally
- [ ] Decide starting point:
  - [ ] Option A: Full scaffolding first (2-3 days setup)
  - [ ] Option B: Minimal POC first (1 day to first gem)

---

## Session Starting Points

### Option A: Full Scaffolding First (Recommended for Clean Start)

**Goal:** Set up complete repository structure before building

**First prompt:**
```
I've created the repository: elanthia-online/lich5-gtk3-gems

Please help me set up the complete directory structure and scaffolding
based on our brainstorming session. I want:

1. Directory structure (.github/workflows, gems/, vendor/, scripts/, etc.)
2. Basic Rakefile with build tasks
3. GitHub Actions workflow for Windows
4. Scripts for downloading vendor libraries

Let's start with the directory structure.
```

**Time:** 2-3 days to complete scaffolding

### Option B: Minimal POC First (Fast Experimentation)

**Goal:** Get to first working gem ASAP, add structure later

**First prompt:**
```
I've created the repository: elanthia-online/lich5-gtk3-gems

I want to build a quick POC: one gem (glib2) for Windows with bundled DLLs.

I have:
- Windows machine with Ruby 3.3 installed
- MSYS2 installed with GTK3 (C:\msys64)

Please help me:
1. Create minimal directory structure for glib2
2. Import glib2 source from ruby-gnome
3. Extract DLLs from MSYS2
4. Build the gem with bundled libraries

Let's start with step 1.
```

**Time:** 1 day to first gem

---

## Key Files to Reference

### From Repository Scaffolding Doc

Copy these from `GTK3_BINARY_GEMS_REPOSITORY_SCAFFOLDING.md`:

1. **`.github/workflows/build-gems.yml`** (lines ~150-250)
   - GitHub Actions matrix build workflow

2. **`Rakefile`** (lines ~260-360)
   - Master build script with tasks

3. **`scripts/bundle-libs.rb`** (lines ~370-420)
   - Script to copy vendor libs into gems

4. **`scripts/test-gem.rb`** (lines ~425-460)
   - Test script for built gems

5. **Directory structure** (lines ~30-100)
   - Complete file tree

### From Vendor Library Acquisition Doc

Copy these from `GTK3_BINARY_GEMS_VENDOR_LIBRARY_ACQUISITION.md`:

1. **Windows extraction script** (lines ~100-150)
   - Extract DLLs from MSYS2

2. **macOS extraction script** (lines ~250-300)
   - Extract dylibs from Homebrew

3. **Dependency discovery** (lines ~400-550)
   - ldd/otool scripts to find all dependencies

---

## Quick Reference: File Locations

After reviewing the brainstorming docs, you'll find code snippets at:

| What You Need | Document | Approximate Line Range |
|---------------|----------|----------------------|
| GitHub Actions workflow | Repository Scaffolding | 150-250 |
| Rakefile | Repository Scaffolding | 260-360 |
| Build scripts | Repository Scaffolding | 370-500 |
| Test scripts | Repository Scaffolding | 500-600 |
| Windows DLL extraction | Vendor Acquisition | 100-150 |
| macOS dylib extraction | Vendor Acquisition | 250-300 |
| Dependency discovery | Vendor Acquisition | 400-550 |

---

## Environment Setup (Before First Session)

### Windows Development

```powershell
# Install MSYS2
choco install msys2

# Install GTK3
C:\tools\msys2\usr\bin\bash -lc "pacman -Syu"
C:\tools\msys2\usr\bin\bash -lc "pacman -S --noconfirm mingw-w64-x86_64-gtk3"

# Verify
C:\tools\msys2\usr\bin\bash -lc "pacman -Ql mingw-w64-x86_64-gtk3"
```

### macOS Development

```bash
# Install Homebrew (if not already)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install GTK3
brew install gtk+3

# Verify
brew list gtk+3
```

### Linux Development

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y libgtk-3-dev

# Fedora
sudo dnf install gtk3-devel

# Verify
pkg-config --modversion gtk+-3.0
```

---

## Common First Tasks

### Task 1: Create Directory Structure

```bash
mkdir -p .github/workflows
mkdir -p gems/glib2/{ext/glib2,lib,test}
mkdir -p vendor/windows/x64/{bin,share}
mkdir -p vendor/macos/{x86_64,arm64}
mkdir -p vendor/linux/x86_64
mkdir -p scripts
mkdir -p test
mkdir -p docs
mkdir -p pkg
```

### Task 2: Import glib2 Source

```bash
# Clone ruby-gnome
git clone https://github.com/ruby-gnome/ruby-gnome.git /tmp/ruby-gnome

# Copy glib2 to gems/
cp -r /tmp/ruby-gnome/glib2/* gems/glib2/
```

### Task 3: Extract Windows DLLs

```bash
# In MSYS2 bash:
cd /mingw64/bin
ldd libglib-2.0-0.dll | grep /mingw64/bin | awk '{print $3}' > /tmp/dll-list.txt

# Copy DLLs
while read dll; do
    cp "$dll" /path/to/repo/vendor/windows/x64/bin/
done < /tmp/dll-list.txt
```

---

## Decision Log Template

Track decisions made during implementation:

```markdown
# Implementation Decisions

## 2025-12-XX: Repository Created
- Name: elanthia-online/lich5-gtk3-gems
- Visibility: Public
- Ruby version: 3.3.0

## 2025-12-XX: Build Approach
- Started with: [Full scaffolding / POC]
- Platform priority: Windows → macOS → Linux

## 2025-12-XX: Vendor Libraries
- Windows source: MSYS2 (GTK3 3.24.43)
- Storage: [GitHub Releases / Git LFS / On-demand]
```

---

## Troubleshooting First Build

### Common Issues

**Issue:** `extconf.rb` fails - can't find GTK3
```ruby
# Solution: Tell extconf.rb where to find MSYS2 GTK3
ENV['PKG_CONFIG_PATH'] = 'C:/msys64/mingw64/lib/pkgconfig'
```

**Issue:** Built gem installs but `require 'glib2'` fails - can't load DLL
```ruby
# Solution: Add vendor/bin to PATH before loading
# In glib2.rb:
ENV['PATH'] = "#{__dir__}/glib2/vendor/bin;#{ENV['PATH']}"
```

**Issue:** DLL loads but crashes with missing symbols
```bash
# Solution: Missing transitive dependencies - use ldd to find all
ldd libglib-2.0-0.dll  # Shows what's missing
```

---

## Success Criteria for POC

You know your POC succeeded when:

- [ ] Built gem: `glib2-4.3.4-x64-mingw32.gem`
- [ ] Gem size: ~150MB (includes bundled DLLs)
- [ ] Install works: `gem install glib2-*.gem`
- [ ] Load works: `ruby -e "require 'glib2'; puts GLib::VERSION.join('.')"`
- [ ] No external dependencies needed

---

## What to Bring to Next Session

For an efficient session, have ready:

1. **Repository URL** - Where the code lives
2. **Current status** - What's done, what's next
3. **Environment** - What OS you're building on
4. **Blockers** - Any issues you hit
5. **Specific question** - What you need help with

**Example:**
```
Repository: https://github.com/elanthia-online/lich5-gtk3-gems
Status: Created directory structure, imported glib2 source, extracted DLLs
Environment: Windows 11, Ruby 3.3.0, MSYS2 installed
Blocker: Not sure how to modify glib2.gemspec for binary platform
Question: How do I create a platform-specific gemspec and bundle vendor libs?
```

---

## Ready to Start!

You've got:
- ✅ 4 comprehensive brainstorming documents
- ✅ Complete architecture and decisions
- ✅ Code snippets ready to copy
- ✅ This initialization guide

**Next step:** Create the repository and dive in!

Good luck! 🚀
