# GTK3 Binary Gems: Vendor Library Acquisition Strategy

**Date:** 2025-12-28
**Purpose:** Detailed strategy for acquiring, organizing, and managing GTK3 vendor libraries
**Status:** Brainstorming / Planning Phase

---

## Executive Summary

Building binary GTK3 gems requires bundling **50-70 shared libraries** per platform (~150-200MB). This document covers:
- Where to get these libraries
- How to identify all dependencies
- How to organize them
- How to automate acquisition
- How to store them (too large for git)
- How to keep them updated

---

## 1. Platform-by-Platform Library Sources

### Windows (x64-mingw32)

#### Source 1: MSYS2 (Recommended)

**Why MSYS2:**
- Most actively maintained GTK3 distribution for Windows
- Includes all dependencies resolved
- Easy to script
- Used by GIMP, Inkscape, and other major GTK apps
- Matches RubyInstaller's MinGW toolchain

**Installation:**
```powershell
# Install MSYS2
choco install msys2

# Or download from https://www.msys2.org/
# Install to C:\msys64

# Update MSYS2
C:\msys64\usr\bin\bash -lc "pacman -Syu"

# Install GTK3 and all dependencies
C:\msys64\usr\bin\bash -lc "pacman -S --noconfirm mingw-w64-x86_64-gtk3"
```

**Library Location:**
```
C:\msys64\mingw64\bin\         # DLLs
C:\msys64\mingw64\lib\         # Import libraries (.a files - not needed for runtime)
C:\msys64\mingw64\share\       # Data files (icons, themes, schemas)
```

**Key DLLs Installed:**
```
libgtk-3-0.dll
libgdk-3-0.dll
libgdk_pixbuf-2.0-0.dll
libglib-2.0-0.dll
libgobject-2.0-0.dll
libgio-2.0-0.dll
libpango-1.0-0.dll
libpangocairo-1.0-0.dll
libpangoft2-1.0-0.dll
libpangowin32-1.0-0.dll
libcairo-2.dll
libcairo-gobject-2.dll
libatk-1.0-0.dll

# Plus transitive dependencies:
libepoxy-0.dll
libharfbuzz-0.dll
libfontconfig-1.dll
libfreetype-6.dll
libffi-8.dll
libintl-8.dll
libpng16-16.dll
libjpeg-8.dll
libtiff-6.dll
libxml2-2.dll
libexpat-1.dll
libiconv-2.dll
zlib1.dll
libbz2-1.dll
libpixman-1-0.dll
libfribidi-0.dll
... (many more)
```

**Extraction Script:**
```bash
#!/bin/bash
# scripts/extract-windows-libs.sh

MSYS2_ROOT="C:/msys64"
VENDOR_DIR="vendor/windows/x64"

mkdir -p "$VENDOR_DIR/bin"
mkdir -p "$VENDOR_DIR/share"

# Copy all DLLs from mingw64/bin
cp -v "$MSYS2_ROOT/mingw64/bin/libgtk-3-0.dll" "$VENDOR_DIR/bin/"
cp -v "$MSYS2_ROOT/mingw64/bin/libgdk-3-0.dll" "$VENDOR_DIR/bin/"
# ... (repeat for all DLLs)

# Better: Use dependency walker to find ALL dependencies
# See "Dependency Discovery" section below

# Copy data files
cp -r "$MSYS2_ROOT/mingw64/share/icons" "$VENDOR_DIR/share/"
cp -r "$MSYS2_ROOT/mingw64/share/themes" "$VENDOR_DIR/share/"
cp -r "$MSYS2_ROOT/mingw64/share/glib-2.0" "$VENDOR_DIR/share/"
```

#### Source 2: vcpkg

**Why vcpkg:**
- Microsoft-maintained
- Integrates with Visual Studio
- Clean build environment

**Cons:**
- Slower builds (compiles from source)
- Less mature GTK3 support than MSYS2
- MSVC toolchain (RubyInstaller uses MinGW - potential ABI mismatch)

**Installation:**
```powershell
git clone https://github.com/microsoft/vcpkg.git
cd vcpkg
.\bootstrap-vcpkg.bat
.\vcpkg install gtk:x64-windows
```

**Library Location:**
```
vcpkg\installed\x64-windows\bin\       # DLLs
vcpkg\installed\x64-windows\share\     # Data files
```

**Recommendation:** Use **MSYS2** (more compatible with Ruby ecosystem)

#### Source 3: GTK.org Prebuilt Binaries

**URL:** https://github.com/tschoonj/GTK-for-Windows-Runtime-Environment-Installer

**Pros:**
- Official-ish
- Easy installer

**Cons:**
- Often outdated (GTK 3.22 vs 3.24)
- May be missing dependencies
- Less actively maintained

**Recommendation:** Only if MSYS2 unavailable

---

### macOS (x86_64-darwin / arm64-darwin)

#### Source 1: Homebrew (Recommended)

**Why Homebrew:**
- De facto standard on macOS
- Well-maintained GTK3 packages
- Handles dependencies automatically
- Supports both Intel and ARM

**Installation (Intel):**
```bash
brew install gtk+3
```

**Installation (Apple Silicon):**
```bash
# ARM Homebrew installs to /opt/homebrew
arch -arm64 brew install gtk+3
```

**Library Locations:**

**Intel (x86_64):**
```
/usr/local/Cellar/gtk+3/<version>/lib/          # dylibs
/usr/local/share/                                # Data files
```

**ARM (arm64):**
```
/opt/homebrew/Cellar/gtk+3/<version>/lib/       # dylibs
/opt/homebrew/share/                             # Data files
```

**Key dylibs:**
```
libgtk-3.dylib
libgdk-3.dylib
libgdk_pixbuf-2.0.dylib
libglib-2.0.dylib
libgobject-2.0.dylib
libgio-2.0.dylib
libpango-1.0.dylib
libpangocairo-1.0.dylib
libcairo.dylib
libcairo-gobject.dylib
libatk-1.0.dylib

# Plus dependencies:
libintl.dylib
libffi.dylib
libharfbuzz.dylib
libfreetype.dylib
libpng.dylib
libjpeg.dylib
... (40-50 total)
```

**Extraction Script:**
```bash
#!/bin/bash
# scripts/extract-macos-libs.sh

# Detect architecture
ARCH=$(uname -m)
if [ "$ARCH" = "arm64" ]; then
    BREW_PREFIX="/opt/homebrew"
    VENDOR_DIR="vendor/macos/arm64"
else
    BREW_PREFIX="/usr/local"
    VENDOR_DIR="vendor/macos/x86_64"
fi

mkdir -p "$VENDOR_DIR/lib"
mkdir -p "$VENDOR_DIR/share"

# Copy GTK3 and dependencies
cp -v "$BREW_PREFIX"/lib/libgtk-3*.dylib "$VENDOR_DIR/lib/"
cp -v "$BREW_PREFIX"/lib/libgdk-3*.dylib "$VENDOR_DIR/lib/"
# ... (use dependency walker)

# Copy data files
cp -r "$BREW_PREFIX/share/icons" "$VENDOR_DIR/share/"
cp -r "$BREW_PREFIX/share/themes" "$VENDOR_DIR/share/"
cp -r "$BREW_PREFIX/share/glib-2.0" "$VENDOR_DIR/share/"
```

**dylib Path Issue:**

macOS dylibs have **embedded paths** (install names):
```bash
$ otool -L libgtk-3.dylib
libgtk-3.dylib:
    /usr/local/lib/libgtk-3.0.dylib (compatibility version 2404.0.0)
    /usr/local/lib/libgdk-3.0.dylib (compatibility version 2404.0.0)
    ...
```

**Problem:** Paths are hardcoded to `/usr/local/lib/`

**Solution:** Rewrite paths with `install_name_tool`:
```bash
# Change absolute path to relative @rpath
install_name_tool -id @rpath/libgtk-3.dylib libgtk-3.dylib
install_name_tool -change /usr/local/lib/libgdk-3.dylib @rpath/libgdk-3.dylib libgtk-3.dylib
# ... (repeat for all dependencies)
```

**Or:** Set `DYLD_LIBRARY_PATH` at runtime (simpler, less robust)

#### Source 2: MacPorts

**Installation:**
```bash
sudo port install gtk3
```

**Library Location:**
```
/opt/local/lib/        # dylibs
/opt/local/share/      # Data files
```

**Recommendation:** Use **Homebrew** (more common, better ARM support)

---

### Linux (x86_64-linux / aarch64-linux)

#### Strategy: Rely on System Libraries (Recommended)

**Why NOT bundle for Linux:**
- Most Linux desktop environments already have GTK3
- Every distro has GTK3 packages
- ABI compatibility across distros (within GTK3 major version)
- Users expect system integration

**Gem approach:**
- Compile native extensions against **system GTK3**
- Don't bundle runtime libraries
- Document system requirements

**User installation:**
```bash
# Debian/Ubuntu
sudo apt-get install libgtk-3-0

# Fedora
sudo dnf install gtk3

# Arch
sudo pacman -S gtk3
```

**Gemspec:**
```ruby
# gtk3.gemspec (Linux platform)
Gem::Specification.new do |s|
  s.platform = 'x86_64-linux'
  # No bundled libs - rely on system
  s.requirements = ['GTK3 >= 3.22']
end
```

#### Alternative: Bundle for AppImage

**If building Lich5 as AppImage:**

Extract from system:
```bash
#!/bin/bash
# scripts/extract-linux-libs.sh

VENDOR_DIR="vendor/linux/x86_64"
mkdir -p "$VENDOR_DIR/lib"
mkdir -p "$VENDOR_DIR/share"

# Copy GTK3 libs
cp -v /usr/lib/x86_64-linux-gnu/libgtk-3.so* "$VENDOR_DIR/lib/"
cp -v /usr/lib/x86_64-linux-gnu/libgdk-3.so* "$VENDOR_DIR/lib/"
# ... (use ldd to find all dependencies)

# Copy data files
cp -r /usr/share/icons "$VENDOR_DIR/share/"
cp -r /usr/share/themes "$VENDOR_DIR/share/"
cp -r /usr/share/glib-2.0 "$VENDOR_DIR/share/"
```

**Recommendation:**
- **Development/testing:** Use system GTK3
- **AppImage distribution:** Bundle libraries

---

## 2. Automated Dependency Discovery

### The Problem

GTK3 has **transitive dependencies**:
```
gtk3.dll → gdk3.dll → pango.dll → harfbuzz.dll → freetype.dll → ...
```

**Manually listing 70+ DLLs is error-prone!**

### Tools for Dependency Analysis

#### Windows: `ldd` (MSYS2)

```bash
# In MSYS2 shell:
ldd /mingw64/bin/libgtk-3-0.dll

# Output:
libgtk-3-0.dll => /mingw64/bin/libgtk-3-0.dll
libgdk-3-0.dll => /mingw64/bin/libgdk-3-0.dll
libpango-1.0-0.dll => /mingw64/bin/libpango-1.0-0.dll
...
```

**Script to extract all:**
```bash
#!/bin/bash
# scripts/list-windows-dependencies.sh

TARGET_DLL="/mingw64/bin/libgtk-3-0.dll"
OUTPUT_DIR="vendor/windows/x64/bin"

mkdir -p "$OUTPUT_DIR"

# Get list of dependencies
DEPS=$(ldd "$TARGET_DLL" | grep /mingw64/bin | awk '{print $3}')

# Copy each dependency
for DEP in $DEPS; do
    echo "Copying $DEP"
    cp -v "$DEP" "$OUTPUT_DIR/"
done

echo "Total DLLs copied: $(ls -1 "$OUTPUT_DIR" | wc -l)"
```

#### Windows: Dependency Walker (GUI)

**Tool:** http://www.dependencywalker.com/

**Usage:**
1. Open `libgtk-3-0.dll` in Dependency Walker
2. View dependency tree (visual graph)
3. Export list of all DLLs

**Good for:** One-time analysis, understanding dependency chains

#### macOS: `otool -L`

```bash
otool -L /usr/local/lib/libgtk-3.dylib

# Output:
/usr/local/lib/libgtk-3.dylib (compatibility version 2404.0.0)
/usr/local/lib/libgdk-3.dylib (compatibility version 2404.0.0)
...
```

**Recursive script:**
```bash
#!/bin/bash
# scripts/list-macos-dependencies.sh

TARGET_DYLIB="/usr/local/lib/libgtk-3.dylib"
VENDOR_DIR="vendor/macos/x86_64/lib"

mkdir -p "$VENDOR_DIR"

# Recursive function to find all dependencies
find_deps() {
    local lib=$1

    otool -L "$lib" | grep /usr/local/lib | awk '{print $1}' | while read dep; do
        local basename=$(basename "$dep")

        if [ ! -f "$VENDOR_DIR/$basename" ]; then
            echo "Copying $basename"
            cp -v "$dep" "$VENDOR_DIR/"

            # Recurse
            find_deps "$dep"
        fi
    done
}

find_deps "$TARGET_DYLIB"
```

#### Linux: `ldd`

```bash
ldd /usr/lib/x86_64-linux-gnu/libgtk-3.so.0

# Output:
libgdk-3.so.0 => /usr/lib/x86_64-linux-gnu/libgdk-3.so.0
libpango-1.0.so.0 => /usr/lib/x86_64-linux-gnu/libpango-1.0.so.0
...
```

**Script:**
```bash
#!/bin/bash
# scripts/list-linux-dependencies.sh

TARGET_SO="/usr/lib/x86_64-linux-gnu/libgtk-3.so.0"
VENDOR_DIR="vendor/linux/x86_64/lib"

mkdir -p "$VENDOR_DIR"

DEPS=$(ldd "$TARGET_SO" | grep /usr/lib | awk '{print $3}')

for DEP in $DEPS; do
    echo "Copying $DEP"
    cp -v "$DEP" "$VENDOR_DIR/"
done
```

### Automated Master Script

**Goal:** One script to extract all vendor libs for a platform

```bash
#!/bin/bash
# scripts/download-gtk3-libs.sh

PLATFORM="${1:-$(uname -s)}"

case "$PLATFORM" in
    "Windows"|"MINGW"*)
        echo "Extracting Windows GTK3 libraries..."
        bash scripts/extract-windows-libs.sh
        ;;
    "Darwin")
        echo "Extracting macOS GTK3 libraries..."
        bash scripts/extract-macos-libs.sh
        ;;
    "Linux")
        echo "Extracting Linux GTK3 libraries..."
        bash scripts/extract-linux-libs.sh
        ;;
    *)
        echo "Unknown platform: $PLATFORM"
        exit 1
        ;;
esac

echo "✅ GTK3 libraries extracted to vendor/"
```

---

## 3. Vendor Directory Organization

### Recommended Structure

```
vendor/
├── README.md                   # Explains where libraries came from
├── VERSIONS.txt                # GTK3 versions, source, date extracted
├── windows/
│   └── x64/
│       ├── bin/                # DLLs (70+ files, ~150MB)
│       │   ├── libgtk-3-0.dll
│       │   ├── libgdk-3-0.dll
│       │   └── ...
│       └── share/              # Data files (~50MB)
│           ├── icons/
│           │   └── Adwaita/    # Default icon theme
│           ├── themes/
│           │   └── Default/
│           └── glib-2.0/
│               └── schemas/    # GSettings schemas
│
├── macos/
│   ├── x86_64/                 # Intel
│   │   ├── lib/                # dylibs (50+ files, ~120MB)
│   │   │   ├── libgtk-3.dylib
│   │   │   ├── libgdk-3.dylib
│   │   │   └── ...
│   │   └── share/
│   │
│   └── arm64/                  # Apple Silicon
│       ├── lib/
│       └── share/
│
└── linux/
    ├── x86_64/
    │   ├── lib/                # .so files (optional - prefer system)
    │   └── share/
    └── aarch64/
        ├── lib/
        └── share/
```

### `vendor/README.md`

```markdown
# GTK3 Vendor Libraries

This directory contains precompiled GTK3 runtime libraries for bundling into binary gems.

## Source

- **Windows:** MSYS2 mingw-w64-x86_64-gtk3
- **macOS (Intel):** Homebrew gtk+3
- **macOS (ARM):** Homebrew gtk+3
- **Linux:** System packages (not bundled)

## Versions

See `VERSIONS.txt` for exact versions.

## Updating

To update vendor libraries:

1. Install latest GTK3 on target platform
2. Run `scripts/download-gtk3-libs.sh`
3. Test built gems
4. Commit updated `VERSIONS.txt`

## License

All libraries are LGPL 2.1+. See each library's license in `share/licenses/`.
```

### `vendor/VERSIONS.txt`

```
GTK3 Vendor Library Versions
============================

Last Updated: 2025-12-28

Windows (x64-mingw32):
  Source: MSYS2 (C:\msys64)
  GTK3: 3.24.43
  GLib: 2.80.0
  Cairo: 1.18.0
  Pango: 1.52.1
  Extracted: 2025-12-28 by <user>

macOS (x86_64-darwin):
  Source: Homebrew (/usr/local)
  GTK3: 3.24.43
  GLib: 2.80.0
  Cairo: 1.18.0
  Pango: 1.52.1
  Extracted: 2025-12-28 by <user>

macOS (arm64-darwin):
  Source: Homebrew (/opt/homebrew)
  GTK3: 3.24.43
  GLib: 2.80.0
  Cairo: 1.18.0
  Pango: 1.52.1
  Extracted: 2025-12-28 by <user>

Linux (x86_64-linux):
  Source: Ubuntu 24.04 system packages
  GTK3: 3.24.41 (system-provided, not bundled)
```

---

## 4. Storage Strategy (Too Large for Git)

### Problem

**Total vendor library sizes:**
- Windows: ~200MB
- macOS Intel: ~150MB
- macOS ARM: ~150MB
- Linux: ~150MB (if bundled)
- **Total: ~650MB**

**Git repository limits:**
- GitHub recommends repositories < 1GB
- Cloning 650MB of binaries is slow
- Binary files don't compress well in git

### Option 1: Git LFS (Large File Storage)

**What it is:** Git extension for versioning large files separately

**Setup:**
```bash
# Install git-lfs
brew install git-lfs  # macOS
apt-get install git-lfs  # Linux
choco install git-lfs  # Windows

# Initialize in repo
git lfs install

# Track vendor binaries
git lfs track "vendor/**/*.dll"
git lfs track "vendor/**/*.dylib"
git lfs track "vendor/**/*.so"

# Commit .gitattributes
git add .gitattributes
git commit -m "Configure git-lfs for vendor binaries"
```

**Pros:**
- Libraries versioned with code
- Easy to update (just commit)
- Git workflow unchanged

**Cons:**
- **GitHub LFS pricing:** Free tier = 1GB storage, 1GB/month bandwidth
- Exceeding free tier = $5/month per 50GB pack
- **Expensive for public repo with many clones!**

**Cost estimate:**
- Storage: 650MB (within free tier)
- Bandwidth: Each CI build downloads 650MB
  - 2 builds/year × 5 platforms × 650MB = 6.5GB/year (exceeds free tier)
- **Cost: ~$5-10/month** if CI is active

**Verdict:** ❌ Too expensive for free/OSS project

### Option 2: External Hosting + Download Script

**Approach:**
- Don't commit vendor libraries to git
- Host on external service
- Download during build

**Hosting Options:**

#### Option 2a: GitHub Releases

**Strategy:**
1. Package vendor libs as archives:
   ```bash
   tar czf gtk3-vendor-windows-x64-3.24.43.tar.gz vendor/windows/x64/
   tar czf gtk3-vendor-macos-arm64-3.24.43.tar.gz vendor/macos/arm64/
   ```

2. Upload to GitHub Release as assets:
   ```
   https://github.com/elanthia-online/lich5-gtk3-gems/releases/download/v3.24.43/gtk3-vendor-windows-x64.tar.gz
   ```

3. Download script:
   ```bash
   #!/bin/bash
   # scripts/download-gtk3-libs.sh

   VERSION="3.24.43"
   PLATFORM="windows-x64"

   URL="https://github.com/elanthia-online/lich5-gtk3-gems/releases/download/v${VERSION}/gtk3-vendor-${PLATFORM}.tar.gz"

   curl -L -o vendor.tar.gz "$URL"
   tar xzf vendor.tar.gz
   ```

**Pros:**
- ✅ Free (unlimited storage/bandwidth for releases)
- ✅ Reliable (GitHub CDN)
- ✅ Versioned (tied to releases)

**Cons:**
- Manual upload process
- Not automated in CI (must download first)

#### Option 2b: Cloud Storage (S3, Backblaze B2)

**Backblaze B2:**
- Free tier: 10GB storage, 1GB/day egress
- Paid: $0.005/GB/month storage, $0.01/GB egress

**Cost estimate:**
- Storage: 650MB × $0.005 = $0.003/month (~free)
- Bandwidth: 6.5GB/year × $0.01 = $0.07/year
- **Total: ~$1/year**

**Pros:**
- Cheap
- Automated uploads
- Fast CDN

**Cons:**
- Requires setup (bucket, API keys)
- External dependency

#### Option 2c: Archive.org

**Internet Archive:**
- Free hosting for open-source artifacts
- Permanent storage

**Pros:**
- ✅ Free
- ✅ Permanent

**Cons:**
- Slower downloads
- Less control

### Option 3: Don't Pre-Extract - Download On-Demand

**Approach:**
- Don't store extracted vendor libraries
- Script downloads GTK3 directly from source during build:
  ```bash
  # In GitHub Actions:
  - name: Download GTK3
    run: |
      # Windows
      choco install msys2
      C:\tools\msys2\usr\bin\bash -lc "pacman -S mingw-w64-x86_64-gtk3"

      # Extract to vendor/
      scripts/extract-windows-libs.sh
  ```

**Pros:**
- ✅ No storage needed
- ✅ Always latest version
- ✅ Zero manual maintenance

**Cons:**
- Slower CI builds (download + extract each time)
- Dependency on MSYS2/Homebrew availability
- Version instability (MSYS2 updates may break builds)

**Mitigation:**
- Cache vendor/ directory in GitHub Actions:
  ```yaml
  - uses: actions/cache@v3
    with:
      path: vendor/
      key: gtk3-vendor-${{ runner.os }}-${{ hashFiles('VERSIONS.txt') }}
  ```

### Recommendation

**For POC/Development:**
- **Option 3** (download on-demand) - Fastest to start

**For Production:**
- **Option 2a** (GitHub Releases) - Free, reliable, versioned

**Implementation:**
1. **Development:** Download from MSYS2/Homebrew directly
2. **First Release:** Package as tarballs, upload to GitHub Release
3. **CI:** Download from GitHub Release (cached)

---

## 5. Versioning Strategy

### GTK3 Version Selection

**Current GTK3:**
- Latest: 3.24.43 (as of Dec 2024)
- Stable: 3.24.x series (ABI stable)

**Recommendation:**
- Use **latest 3.24.x** for initial build
- Lock version in `VERSIONS.txt`
- Only update for security patches or Lich5 requirements

### Ruby-GNOME Version Matching

**Ruby-GNOME releases:**
- Latest: 4.3.4 (Dec 2025)
- Tracks GTK3 3.24.x

**Strategy:**
- Match ruby-gnome gem version
- Bundle GTK3 3.24.x libraries
- Version string in gem: `gtk3-4.3.4-x64-mingw32.gem`

### Update Cadence

**When to update vendor libraries:**

1. **Ruby-GNOME releases** - Pull latest gem source
2. **Security vulnerabilities** - Update GTK3 libraries
3. **Bug fixes** - If users report issues
4. **Ruby version changes** - Rebuild for new Ruby

**Frequency:** ~2-4 times/year (low maintenance)

---

## 6. License Compliance

### GTK3 License: LGPL 2.1+

**Requirements for redistribution:**

1. **Include license text**
   - Copy `COPYING` from GTK3 source
   - Place in `vendor/share/licenses/gtk3/`

2. **Provide source code or offer**
   - Add to README:
     ```
     GTK3 source code: https://gitlab.gnome.org/GNOME/gtk/-/tree/gtk-3-24
     ```
   - Or: "Source available upon request"

3. **Allow library replacement**
   - DLLs/dylibs must be separate files (not statically linked) ✅
   - Users can replace with their own build ✅

**Compliance checklist:**
- [ ] Include GTK3 COPYING file
- [ ] Include GLib COPYING file
- [ ] Include Pango COPYING file
- [ ] Link to source code in README
- [ ] Ensure dynamic linking (not static)

**Not a problem for Lich5** - LGPL allows commercial use, just requires attribution and user freedom to replace libraries.

---

## 7. Automation Scripts

### Master Download Script

```bash
#!/bin/bash
# scripts/download-gtk3-libs.sh

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
VENDOR_DIR="$REPO_ROOT/vendor"

echo "📦 Downloading GTK3 vendor libraries..."

# Detect platform
case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*)
        PLATFORM="windows"
        ;;
    Darwin)
        PLATFORM="macos"
        ;;
    Linux)
        PLATFORM="linux"
        ;;
    *)
        echo "❌ Unsupported platform: $(uname -s)"
        exit 1
        ;;
esac

# Platform-specific extraction
case "$PLATFORM" in
    windows)
        echo "Extracting Windows GTK3 libraries from MSYS2..."
        bash "$SCRIPT_DIR/extract-windows-libs.sh"
        ;;
    macos)
        echo "Extracting macOS GTK3 libraries from Homebrew..."
        bash "$SCRIPT_DIR/extract-macos-libs.sh"
        ;;
    linux)
        echo "Linux: Using system GTK3 (not bundling)"
        # Optional: Extract for AppImage
        # bash "$SCRIPT_DIR/extract-linux-libs.sh"
        ;;
esac

echo "✅ GTK3 vendor libraries ready in $VENDOR_DIR"
echo ""
echo "Next steps:"
echo "  rake build:all        # Build all gems"
echo "  rake test:quick       # Test gems"
```

### GitHub Actions Integration

```yaml
# .github/workflows/build-gems.yml

- name: Cache vendor libraries
  uses: actions/cache@v3
  with:
    path: vendor/
    key: gtk3-vendor-${{ runner.os }}-${{ hashFiles('vendor/VERSIONS.txt') }}

- name: Download GTK3 vendor libraries
  if: steps.cache.outputs.cache-hit != 'true'
  run: |
    bash scripts/download-gtk3-libs.sh

- name: Verify vendor libraries
  run: |
    ls -lh vendor/
```

---

## 8. Testing Vendor Libraries

### Verification Script

```bash
#!/bin/bash
# scripts/verify-vendor-libs.sh

PLATFORM="${1:-windows-x64}"
VENDOR_DIR="vendor/$PLATFORM"

echo "🔍 Verifying vendor libraries for $PLATFORM..."

# Check critical libraries exist
REQUIRED_LIBS=(
    "libgtk-3"
    "libgdk-3"
    "libglib-2.0"
    "libgobject-2.0"
    "libgio-2.0"
)

MISSING=0
for LIB in "${REQUIRED_LIBS[@]}"; do
    if ! find "$VENDOR_DIR" -name "*${LIB}*" | grep -q .; then
        echo "❌ Missing: $LIB"
        MISSING=$((MISSING + 1))
    else
        echo "✅ Found: $LIB"
    fi
done

if [ $MISSING -gt 0 ]; then
    echo ""
    echo "❌ $MISSING required libraries missing!"
    exit 1
fi

echo ""
echo "✅ All required libraries present"
```

---

## Summary & Next Steps

### Recommended Approach

**Phase 1: POC (Use On-Demand Download)**
```bash
# In CI or local build:
1. Install MSYS2/Homebrew
2. Install GTK3
3. Extract to vendor/
4. Build gems
```

**Phase 2: Production (Use GitHub Releases)**
```bash
1. Package vendor/ as tarballs
2. Upload to GitHub Release
3. CI downloads from release
4. Cache vendor/ in CI
```

### Checklist

- [ ] Install GTK3 on development machine
- [ ] Run `scripts/download-gtk3-libs.sh`
- [ ] Verify libraries with `scripts/verify-vendor-libs.sh`
- [ ] Build first gem with bundled libraries
- [ ] Test gem loads and finds bundled DLLs
- [ ] Document vendor library versions in `VERSIONS.txt`
- [ ] Add license files to `vendor/share/licenses/`

**Estimated time:** 2-3 days to set up vendor library pipeline

---

**Status:** Ready to implement vendor library acquisition strategy
**Next:** Extract GTK3 libraries for first platform (Windows recommended)
