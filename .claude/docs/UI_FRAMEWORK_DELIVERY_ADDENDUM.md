# UI Framework Migration: Application Delivery Technical Addendum

**Date:** 2025-11-19
**Purpose:** Technical guide for building and distributing Lich installers/apps
**Related:** UI_FRAMEWORK_DECISION.md, UI_FRAMEWORK_TECHNICAL_ADDENDUM.md

---

## OVERVIEW: THE DELIVERY PROBLEM

### Current State (GTK3 + Windows)

**Build process:**
1. Install GTK3 libraries via MSYS2 on build machine
2. `gem install` dependencies (triggers compilation or MSYS2 download)
3. Copy Ruby + gems + GTK3 DLLs + Lich code → staging directory
4. InnoSetup compiles installer from staging directory
5. Ship 200MB installer

**Problems:**
- ⚠️ MSYS2 dependency fragile (network issues, version conflicts)
- ⚠️ Build process manual and error-prone
- ⚠️ No macOS/Linux app bundles yet
- ⚠️ Each platform needs separate build process

---

### Desired State (Any Framework)

**Build process:**
1. Download pre-compiled platform-specific gem (or JARs for Glimmer SWT)
2. Copy Ruby + gems + Lich code → staging directory
3. Platform-specific packager creates app bundle/installer
4. Ship 80-180MB installer (varies by framework)

**Benefits:**
- ✅ Deterministic builds (no compilation, no network dependencies during build)
- ✅ CI/CD friendly (automated, repeatable)
- ✅ Cross-platform support (macOS .app, Linux AppImage, Windows installer)
- ✅ Faster builds (no compilation time)

---

## PART 1: FAT/BINARY GEMS

### What Are Fat Gems?

**Regular gem (requires compilation on user's machine):**
```bash
gem install gtk4
# Downloads source code
# Runs extconf.rb to find GTK4 libraries
# Compiles C extensions
# Links against system GTK4
# User must have: GTK4 libraries, build tools (gcc, make)
```

**Fat/binary gem (pre-compiled for specific platform):**
```bash
gem install gtk4 --platform=x86_64-darwin22
# Downloads pre-compiled gem with:
#   - Compiled C extensions (.bundle on macOS, .so on Linux, .dll on Windows)
#   - GTK4 libraries bundled inside gem (optional)
# No compilation needed
# User needs: Nothing (zero dependencies)
```

---

### Fat Gem Variants

**Variant A: Pre-compiled Extensions Only**
- Gem contains compiled C extensions
- User still needs GTK4 system libraries (`brew install gtk4`)
- **Benefit:** Faster gem install (no compilation)
- **User still needs:** System libraries

**Variant B: Pre-compiled Extensions + Bundled Libraries (True Fat Gem)**
- Gem contains compiled C extensions + GTK4 libraries
- User needs nothing
- **Benefit:** Zero dependencies
- **User needs:** Nothing

---

### When Fat Gems Are Worth It

| Framework | Need Fat Gems? | Why |
|-----------|---------------|-----|
| **LibUI** | 🟡 Optional | LibUI is small, compilation is fast (~2 min) |
| **FXRuby** | 🟡 Optional | FOX compiles quickly, Lars Kanis already provides Windows binaries |
| **GTK4** | ✅ Recommended | Simplifies your build pipeline significantly |
| **Glimmer SWT** | ❌ Not needed | Pure Java JARs, no compilation needed |

**Bottom line:** Fat gems most valuable for GTK4 path (simplifies your installer builds).

---

## BUILDING FAT GEMS (GTK4 Example)

### Architecture

**Target platforms:**
- `x86_64-darwin22` (macOS Intel, macOS 13+)
- `arm64-darwin22` (macOS ARM/M1/M2, macOS 13+)
- `x86_64-linux` (Linux x86_64, glibc 2.31+)
- `x64-mingw-ucrt` (Windows x64, Ruby 3.1+)

**Each platform needs:**
- Pre-compiled `gobject-introspection` gem
- Pre-compiled `gtk4` gem
- GTK4 libraries bundled (Variant B) or instructions to install (Variant A)

---

### Build Process (Variant B - Bundled Libraries)

#### Step 1: Set Up Cross-Compilation Environment

**Use `rake-compiler-dock`** (Docker-based cross-compilation):

```bash
# Install rake-compiler-dock
gem install rake-compiler-dock

# Build for all platforms in Docker containers
rake-compiler-dock bash # Enters Docker shell with cross-compilers
```

**Alternative: Platform-specific build machines**
- macOS: Build on macOS (both Intel + ARM via universal binary or separate builds)
- Linux: Build on Ubuntu 22.04 (glibc 2.31+ for compatibility)
- Windows: Build on Windows with RubyInstaller DevKit

---

#### Step 2: Download/Build GTK4 Libraries Per Platform

**macOS:**
```bash
# On macOS build machine
brew install gtk4

# Extract GTK4 frameworks
mkdir -p vendor/gtk4/macos-x86_64/lib
mkdir -p vendor/gtk4/macos-arm64/lib

# Copy frameworks (simplified - real process more complex)
cp -r /opt/homebrew/Cellar/gtk4/*/lib/*.dylib vendor/gtk4/macos-arm64/lib/
# ... repeat for dependencies (glib, cairo, pango, etc.)

# Rewrite install names (make libraries relocatable)
install_name_tool -id @rpath/libgtk-4.dylib vendor/gtk4/macos-arm64/lib/libgtk-4.dylib
# ... repeat for all dependencies
```

**Linux:**
```bash
# On Linux build machine
apt-get install libgtk-4-dev

# Extract libraries
mkdir -p vendor/gtk4/linux-x86_64/lib

# Copy libraries
cp /usr/lib/x86_64-linux-gnu/libgtk-4.so.* vendor/gtk4/linux-x86_64/lib/
# ... repeat for dependencies

# Set RPATH (make libraries relocatable)
patchelf --set-rpath '$ORIGIN' vendor/gtk4/linux-x86_64/lib/libgtk-4.so.1
# ... repeat for all dependencies
```

**Windows:**
```bash
# On Windows build machine with MSYS2
pacman -S mingw-w64-ucrt-x86_64-gtk4

# Extract DLLs
mkdir -p vendor/gtk4/windows-x64/bin

# Copy DLLs
cp /ucrt64/bin/libgtk-4-*.dll vendor/gtk4/windows-x64/bin/
# ... repeat for dependencies (~150 DLLs total)
```

---

#### Step 3: Build Gem with Bundled Libraries

**Gemspec (gtk4.gemspec):**

```ruby
Gem::Specification.new do |s|
  s.name        = 'gtk4'
  s.version     = '4.2.4'
  s.platform    = Gem::Platform::RUBY # Will be overridden per platform
  s.summary     = 'Ruby bindings for GTK4'
  s.files       = Dir['lib/**/*.rb', 'ext/**/*.{c,h,rb}']

  # Development dependencies
  s.add_development_dependency 'rake-compiler', '~> 1.2'
end
```

**Rakefile (build script):**

```ruby
require 'rake/extensiontask'
require 'rake_compiler_dock'

# Define extension compilation
Rake::ExtensionTask.new('gtk4') do |ext|
  ext.lib_dir = 'lib/gtk4'
  ext.cross_compile = true
  ext.cross_platform = [
    'x86_64-darwin',
    'arm64-darwin',
    'x86_64-linux',
    'x64-mingw-ucrt'
  ]
end

# Build fat gem for macOS Intel
task 'gem:darwin:x86_64' do
  platform = 'x86_64-darwin22'

  # Compile extension
  sh "rake cross native gem RUBY_CC_VERSION=3.3.0:3.2.0 PLATFORM=#{platform}"

  # Bundle GTK4 libraries into gem
  gem_file = Dir["pkg/gtk4-*-#{platform}.gem"].first
  sh "gem unpack #{gem_file}"

  # Copy GTK4 libraries into unpacked gem
  unpacked_dir = Dir["gtk4-*"].first
  mkdir_p "#{unpacked_dir}/lib/gtk4/vendor/macos-x86_64"
  cp_r 'vendor/gtk4/macos-x86_64/lib', "#{unpacked_dir}/lib/gtk4/vendor/macos-x86_64/"

  # Repack gem
  sh "gem build #{unpacked_dir}/gtk4.gemspec"

  # Clean up
  rm_rf unpacked_dir
end

# Similar tasks for other platforms...
```

---

#### Step 4: Gem Runtime Library Loading

**lib/gtk4.rb (modified to load bundled libraries):**

```ruby
# Detect platform
platform = case RUBY_PLATFORM
           when /darwin/ then 'macos'
           when /linux/ then 'linux'
           when /mingw/ then 'windows'
           end

arch = case RUBY_PLATFORM
       when /x86_64|amd64/ then 'x86_64'
       when /arm64|aarch64/ then 'arm64'
       end

# Path to bundled libraries
vendor_lib_path = File.expand_path("../gtk4/vendor/#{platform}-#{arch}/lib", __FILE__)

if File.directory?(vendor_lib_path)
  # Add bundled libraries to load path
  case platform
  when 'macos'
    ENV['DYLD_FALLBACK_LIBRARY_PATH'] = "#{vendor_lib_path}:#{ENV['DYLD_FALLBACK_LIBRARY_PATH']}"
  when 'linux'
    ENV['LD_LIBRARY_PATH'] = "#{vendor_lib_path}:#{ENV['LD_LIBRARY_PATH']}"
  when 'windows'
    # Windows DLL search path
    require 'fiddle'
    kernel32 = Fiddle.dlopen('kernel32')
    set_dll_directory = Fiddle::Function.new(
      kernel32['SetDllDirectoryW'],
      [Fiddle::TYPE_VOIDP],
      Fiddle::TYPE_INT
    )
    set_dll_directory.call(vendor_lib_path.encode('UTF-16LE'))
  end
end

# Now load GTK4 (will find bundled libraries)
require 'gobject-introspection'
require 'gtk4/loader'
```

---

#### Step 5: Publish Platform-Specific Gems

```bash
# Build all platforms
rake gem:darwin:x86_64
rake gem:darwin:arm64
rake gem:linux:x86_64
rake gem:windows:x64

# Publish to RubyGems.org (or private gem server)
gem push pkg/gtk4-4.2.4-x86_64-darwin22.gem
gem push pkg/gtk4-4.2.4-arm64-darwin22.gem
gem push pkg/gtk4-4.2.4-x86_64-linux.gem
gem push pkg/gtk4-4.2.4-x64-mingw-ucrt.gem

# Or host on private gem server
gem inabox pkg/gtk4-*.gem --host http://gems.yourserver.com
```

---

### Effort Estimate: Building Fat Gems

| Task | Effort (Hours) | Frequency |
|------|---------------|-----------|
| Initial setup (Rakefile, cross-compilation) | 20-30 | One-time |
| Extract/bundle GTK4 libraries (all platforms) | 30-40 | One-time |
| Fix library loading (RPATH, install_name_tool) | 15-25 | One-time |
| Test on all platforms | 10-15 | One-time |
| **Total initial:** | **75-110** | One-time |
| Update for new GTK4 version | 4-8 | Per GTK4 release (~2x/year) |
| Update for new Ruby version | 2-4 | Per Ruby release (~1x/year) |

**ROI Calculation:**
- Current build time: 30-60 min (with MSYS2 downloads, compilation)
- With fat gems: 5-10 min (download pre-built gem, copy files)
- **Savings per build:** 20-50 minutes

If you build 20 installers/year → save 7-17 hours/year
Break-even: ~5-10 years

**Recommendation:** Build fat gems if you plan to maintain Lich for 5+ years AND you choose GTK4 path.

---

## PART 2: APPLICATION PACKAGING

### Platform-Specific Delivery Formats

| Platform | Format | User Experience | Build Tool |
|----------|--------|----------------|------------|
| **macOS** | `.app` bundle | Drag to /Applications, double-click | Manual script or Platypus |
| **macOS** | `.dmg` disk image | Open DMG, drag .app to /Applications | `create-dmg` or `hdiutil` |
| **Linux** | AppImage | `chmod +x`, `./Lich.AppImage` | `appimagetool` |
| **Linux** | `.deb` package | `apt install lich.deb` | `dpkg-deb` or `fpm` |
| **Windows** | `.exe` installer | Next-next-finish | InnoSetup (current) or NSIS |
| **Windows** | Portable `.zip` | Extract, run `lich.exe` | Manual script |

**Recommendation by framework:**
- **All frameworks:** Focus on `.app` (macOS), AppImage (Linux), `.exe` installer (Windows)
- Skip `.deb`/`.rpm` unless you want Linux package repository distribution

---

## MACOS: .APP BUNDLE

### What is a .app Bundle?

A macOS `.app` is a directory with specific structure that macOS treats as an application:

```
Lich.app/
  Contents/
    MacOS/
      lich                    # Executable launcher script
    Resources/
      ruby/                   # Embedded Ruby
        bin/ruby
        lib/ruby/3.3.0/
        lib/ruby/gems/3.3.0/
          gems/
            gtk4-4.2.4/       # Pre-built gem (or bundled libs)
      lich/                   # Lich source code
        lib/
        scripts/
      icon.icns               # App icon
    Frameworks/               # Optional: GTK4 frameworks (if not in gem)
      Gtk.framework/
    Info.plist                # App metadata
```

---

### Building a .app Bundle

**Step 1: Create Directory Structure**

```bash
#!/bin/bash
# tools/build_macos_app.sh

VERSION="5.10.0"
APP_NAME="Lich.app"
BUILD_DIR="build/macos"

# Create structure
mkdir -p "$BUILD_DIR/$APP_NAME/Contents/MacOS"
mkdir -p "$BUILD_DIR/$APP_NAME/Contents/Resources"
mkdir -p "$BUILD_DIR/$APP_NAME/Contents/Frameworks"

# Copy launcher script
cat > "$BUILD_DIR/$APP_NAME/Contents/MacOS/lich" << 'EOF'
#!/bin/bash
# Launcher script for Lich.app

# Get bundle directory
BUNDLE_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
RESOURCES_DIR="$BUNDLE_DIR/Contents/Resources"

# Set up Ruby environment
export RUBY_BIN="$RESOURCES_DIR/ruby/bin/ruby"
export GEM_HOME="$RESOURCES_DIR/ruby/lib/ruby/gems/3.3.0"
export RUBYLIB="$RESOURCES_DIR/lich/lib"

# Set up GTK4 environment (if using bundled frameworks)
export DYLD_FALLBACK_FRAMEWORK_PATH="$BUNDLE_DIR/Contents/Frameworks"

# Launch Lich
exec "$RUBY_BIN" "$RESOURCES_DIR/lich/lich.rbw" "$@"
EOF

chmod +x "$BUILD_DIR/$APP_NAME/Contents/MacOS/lich"
```

---

**Step 2: Embed Ruby**

```bash
# Download portable Ruby or build from source
# Option A: Use ruby-install + chruby
ruby-install ruby 3.3.6 --install-dir "$BUILD_DIR/ruby-portable"

# Copy to app bundle
cp -r "$BUILD_DIR/ruby-portable" "$BUILD_DIR/$APP_NAME/Contents/Resources/ruby"

# Strip debug symbols (reduce size)
find "$BUILD_DIR/$APP_NAME/Contents/Resources/ruby" -name "*.bundle" -exec strip -x {} \;
```

---

**Step 3: Install Gems**

```bash
# Set gem environment to app bundle
export GEM_HOME="$BUILD_DIR/$APP_NAME/Contents/Resources/ruby/lib/ruby/gems/3.3.0"
export PATH="$BUILD_DIR/$APP_NAME/Contents/Resources/ruby/bin:$PATH"

# Install gems
gem install gtk4 --platform=arm64-darwin22 # Or x86_64-darwin22
gem install sqlite3
# ... other gems

# Or use Bundler
cd "$BUILD_DIR/$APP_NAME/Contents/Resources"
bundle install --deployment --path ruby/lib/ruby/gems/3.3.0
```

---

**Step 4: Copy Lich Code**

```bash
# Copy Lich source
cp -r /path/to/lich/source "$BUILD_DIR/$APP_NAME/Contents/Resources/lich"

# Create scripts directory
mkdir -p "$BUILD_DIR/$APP_NAME/Contents/Resources/lich/scripts"
```

---

**Step 5: Create Info.plist**

```bash
cat > "$BUILD_DIR/$APP_NAME/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>lich</string>
    <key>CFBundleIdentifier</key>
    <string>com.elanthia.lich</string>
    <key>CFBundleName</key>
    <string>Lich</string>
    <key>CFBundleVersion</key>
    <string>$VERSION</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleIconFile</key>
    <string>icon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
</dict>
</plist>
EOF
```

---

**Step 6: Add App Icon**

```bash
# Convert PNG to .icns (requires iconutil on macOS)
mkdir -p icon.iconset
cp lich-icon-1024.png icon.iconset/icon_512x512@2x.png
cp lich-icon-512.png icon.iconset/icon_512x512.png
# ... create other sizes (256, 128, 64, 32, 16)

iconutil -c icns icon.iconset
mv icon.icns "$BUILD_DIR/$APP_NAME/Contents/Resources/"
```

---

**Step 7: Code Sign (Optional but Recommended)**

```bash
# Requires Apple Developer account ($99/year)
codesign --deep --force --verify --verbose \
  --sign "Developer ID Application: Your Name (TEAM_ID)" \
  "$BUILD_DIR/$APP_NAME"

# Notarize (required for macOS 10.15+)
xcrun notarytool submit "$BUILD_DIR/Lich.app.zip" \
  --apple-id "you@example.com" \
  --password "app-specific-password" \
  --team-id "TEAM_ID" \
  --wait

# Staple notarization ticket
xcrun stapler staple "$BUILD_DIR/$APP_NAME"
```

**Without code signing:** Users see "Lich.app is from an unidentified developer" warning (requires right-click → Open first time).

---

**Step 8: Create DMG (Optional)**

```bash
# Install create-dmg
brew install create-dmg

# Create DMG
create-dmg \
  --volname "Lich Installer" \
  --window-pos 200 120 \
  --window-size 800 400 \
  --icon-size 100 \
  --icon "Lich.app" 200 190 \
  --hide-extension "Lich.app" \
  --app-drop-link 600 185 \
  "Lich-$VERSION.dmg" \
  "$BUILD_DIR/$APP_NAME"
```

---

### macOS App Bundle Size Estimates

| Framework | .app Size | Notes |
|-----------|-----------|-------|
| **LibUI** | 60-80 MB | Ruby (40MB) + LibUI gem (5MB) + Lich (15MB) |
| **FXRuby** | 90-110 MB | Ruby + FOX libraries (30MB) + Lich |
| **GTK4** | 140-170 MB | Ruby + GTK4 frameworks (70-90MB) + Lich |
| **Glimmer SWT** | 90-110 MB | JRuby (50MB) + SWT JARs (20MB) + Lich |

---

## LINUX: APPIMAGE

### What is an AppImage?

A single executable file containing app + dependencies that runs on any Linux distro:

```bash
# User experience:
chmod +x Lich-x86_64.AppImage
./Lich-x86_64.AppImage

# No installation, no dependencies, just works
```

---

### Building an AppImage

**Step 1: Create AppDir Structure**

```bash
#!/bin/bash
# tools/build_linux_appimage.sh

VERSION="5.10.0"
APPDIR="build/linux/Lich.AppDir"

# Create structure
mkdir -p "$APPDIR/usr/bin"
mkdir -p "$APPDIR/usr/lib"
mkdir -p "$APPDIR/usr/share/applications"
mkdir -p "$APPDIR/usr/share/icons/hicolor/256x256/apps"

# Copy Ruby
cp -r /opt/ruby-3.3.6 "$APPDIR/usr/lib/ruby"

# Copy Lich
cp -r /path/to/lich "$APPDIR/usr/lib/lich"

# Install gems
export GEM_HOME="$APPDIR/usr/lib/ruby/lib/ruby/gems/3.3.0"
gem install gtk4 --platform=x86_64-linux # Fat gem with bundled GTK4
# ... other gems
```

---

**Step 2: Create Launcher Script**

```bash
cat > "$APPDIR/usr/bin/lich" << 'EOF'
#!/bin/bash
# AppImage launcher

# Get AppImage directory
APPDIR="$(dirname "$(readlink -f "$0")")/.."

# Set up Ruby environment
export RUBY_BIN="$APPDIR/usr/lib/ruby/bin/ruby"
export GEM_HOME="$APPDIR/usr/lib/ruby/lib/ruby/gems/3.3.0"
export RUBYLIB="$APPDIR/usr/lib/lich/lib"

# Set up GTK4 environment (if using bundled libs)
export LD_LIBRARY_PATH="$APPDIR/usr/lib/gtk4:$LD_LIBRARY_PATH"
export GI_TYPELIB_PATH="$APPDIR/usr/lib/gtk4/girepository-1.0"

# Launch Lich
exec "$RUBY_BIN" "$APPDIR/usr/lib/lich/lich.rbw" "$@"
EOF

chmod +x "$APPDIR/usr/bin/lich"
```

---

**Step 3: Create Desktop Entry**

```bash
cat > "$APPDIR/usr/share/applications/lich.desktop" << EOF
[Desktop Entry]
Name=Lich
Exec=lich
Icon=lich
Type=Application
Categories=Game;
Comment=Lich scripting engine for GemStone IV and DragonRealms
EOF
```

---

**Step 4: Add AppRun and Icon**

```bash
# AppRun is the entry point
ln -s usr/bin/lich "$APPDIR/AppRun"

# Icon
cp lich-icon-256.png "$APPDIR/usr/share/icons/hicolor/256x256/apps/lich.png"
ln -s usr/share/icons/hicolor/256x256/apps/lich.png "$APPDIR/lich.png"

# .DirIcon for file managers
ln -s usr/share/icons/hicolor/256x256/apps/lich.png "$APPDIR/.DirIcon"
```

---

**Step 5: Build AppImage**

```bash
# Download appimagetool
wget https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage
chmod +x appimagetool-x86_64.AppImage

# Build AppImage
./appimagetool-x86_64.AppImage "$APPDIR" "Lich-$VERSION-x86_64.AppImage"

# Result: Lich-5.10.0-x86_64.AppImage (single file, ~120-150MB)
```

---

### Linux AppImage Size Estimates

| Framework | AppImage Size | Notes |
|-----------|---------------|-------|
| **LibUI** | 70-90 MB | Ruby + LibUI + Lich |
| **FXRuby** | 80-100 MB | Ruby + FOX libraries + Lich |
| **GTK4** | 130-160 MB | Ruby + GTK4 libraries (if bundled) + Lich |
| **Glimmer SWT** | 80-100 MB | JRuby + SWT JARs + Lich |

**Note:** If using system GTK4 (not bundled), AppImage is smaller but requires GTK4 installed.

---

## WINDOWS: INSTALLER (INNOSETUP)

### Simplifying Current InnoSetup Process

**Current process (GTK3):**
1. Manual MSYS2 setup
2. `gem install` (triggers pacman downloads)
3. Copy Ruby + gems + GTK3 DLLs (~150 files) to staging
4. InnoSetup compiles installer
5. 200MB installer

**Improved process (with fat gems):**
1. Download pre-built `gtk4` gem (contains all DLLs)
2. `gem install gtk4-4.2.4-x64-mingw-ucrt.gem` (local file, no network)
3. Copy Ruby + gems to staging (DLLs already in gem)
4. InnoSetup compiles installer
5. 150-180MB installer

---

### Simplified Build Script

```powershell
# tools/build_windows_installer.ps1

$VERSION = "5.10.0"
$STAGE_DIR = "build\windows\lich-staging"

# Step 1: Create staging directory
New-Item -ItemType Directory -Force -Path $STAGE_DIR

# Step 2: Copy Ruby (RubyInstaller portable)
# Download from: https://github.com/oneclick/rubyinstaller2/releases
Copy-Item -Recurse "C:\Ruby33-x64" "$STAGE_DIR\ruby"

# Step 3: Install pre-built gems
$env:GEM_HOME = "$STAGE_DIR\ruby\lib\ruby\gems\3.3.0"

# Install fat gem (local file, no network)
gem install vendor\gtk4-4.2.4-x64-mingw-ucrt.gem --local

# Install other gems
gem install sqlite3 --platform=x64-mingw-ucrt
# ... other gems

# Step 4: Copy Lich code
Copy-Item -Recurse "C:\dev\lich" "$STAGE_DIR\lich"

# Step 5: Create launcher script
@"
@echo off
set LICH_DIR=%~dp0
set RUBY_BIN=%LICH_DIR%ruby\bin\ruby.exe
set GEM_HOME=%LICH_DIR%ruby\lib\ruby\gems\3.3.0
"%RUBY_BIN%" "%LICH_DIR%lich\lich.rbw" %*
"@ | Out-File -Encoding ASCII "$STAGE_DIR\lich.bat"

# Step 6: Compile installer with InnoSetup
iscc tools\lich-installer.iss
```

---

### InnoSetup Script (lich-installer.iss)

```ini
; Lich Installer Script for InnoSetup

#define MyAppName "Lich"
#define MyAppVersion "5.10.0"
#define MyAppPublisher "Elanthia Online"
#define MyAppURL "https://github.com/elanthia-online/lich-5"

[Setup]
AppId={{YOUR-GUID-HERE}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
DefaultDirName={autopf}\Lich
DefaultGroupName=Lich
OutputDir=dist
OutputBaseFilename=Lich-{#MyAppVersion}-Setup
Compression=lzma2/ultra64
SolidCompression=yes
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64

[Files]
; Ruby + Gems (already includes GTK4 DLLs from fat gem)
Source: "build\windows\lich-staging\ruby\*"; DestDir: "{app}\ruby"; Flags: ignoreversion recursesubdirs

; Lich code
Source: "build\windows\lich-staging\lich\*"; DestDir: "{app}\lich"; Flags: ignoreversion recursesubdirs

; Launcher
Source: "build\windows\lich-staging\lich.bat"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\Lich"; Filename: "{app}\lich.bat"
Name: "{autodesktop}\Lich"; Filename: "{app}\lich.bat"

[Run]
Filename: "{app}\lich.bat"; Description: "Launch Lich"; Flags: postinstall nowait skipifsilent
```

---

### Windows Installer Size Estimates

| Framework | Installer Size | Notes |
|-----------|----------------|-------|
| **LibUI** | 80-100 MB | Ruby + LibUI gem + Lich |
| **FXRuby** | 100-120 MB | Ruby + FOX DLLs + Lich |
| **GTK4** | 150-180 MB | Ruby + GTK4 fat gem (includes ~150 DLLs) + Lich |
| **Glimmer SWT** | 100-120 MB | JRuby + SWT JARs + Lich |

**Current (GTK3):** 200MB
**Savings with GTK4 fat gem:** 20-50MB (DLLs better compressed in gem)

---

## CI/CD PIPELINE ARCHITECTURE

### GitHub Actions Example (All Platforms)

```yaml
# .github/workflows/build-installers.yml

name: Build Installers

on:
  push:
    tags:
      - 'v*'

jobs:
  build-macos:
    runs-on: macos-13
    steps:
      - uses: actions/checkout@v4

      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.3.6

      - name: Download fat gems
        run: |
          gem fetch gtk4 --platform=x86_64-darwin
          gem fetch gtk4 --platform=arm64-darwin

      - name: Build .app bundle
        run: ./tools/build_macos_app.sh

      - name: Create DMG
        run: ./tools/create_dmg.sh

      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: Lich-macOS.dmg
          path: dist/Lich-*.dmg

  build-linux:
    runs-on: ubuntu-22.04
    steps:
      - uses: actions/checkout@v4

      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.3.6

      - name: Download fat gems
        run: gem fetch gtk4 --platform=x86_64-linux

      - name: Build AppImage
        run: ./tools/build_linux_appimage.sh

      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: Lich-Linux-x86_64.AppImage
          path: dist/Lich-*.AppImage

  build-windows:
    runs-on: windows-2022
    steps:
      - uses: actions/checkout@v4

      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.3.6

      - name: Download fat gems
        run: gem fetch gtk4 --platform=x64-mingw-ucrt

      - name: Install InnoSetup
        run: choco install innosetup

      - name: Build installer
        run: pwsh tools/build_windows_installer.ps1

      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: Lich-Windows-Setup.exe
          path: dist/Lich-*-Setup.exe

  release:
    needs: [build-macos, build-linux, build-windows]
    runs-on: ubuntu-latest
    steps:
      - name: Download all artifacts
        uses: actions/download-artifact@v4

      - name: Create GitHub Release
        uses: softprops/action-gh-release@v1
        with:
          files: |
            Lich-macOS.dmg/*
            Lich-Linux-x86_64.AppImage/*
            Lich-Windows-Setup.exe/*
```

**Build time estimates:**
- Without fat gems: 30-60 min per platform (compilation + downloads)
- With fat gems: 5-15 min per platform (download pre-built gem + package)

---

## EFFORT SUMMARY

### One-Time Setup Effort

| Task | Fat Gems Needed? | Effort (Hours) |
|------|-----------------|---------------|
| **Fat gem creation** (GTK4 only) | Yes | 75-110 |
| **macOS .app build script** | No | 15-25 |
| **Linux AppImage build script** | No | 10-20 |
| **Windows installer simplification** | No | 10-15 |
| **CI/CD pipeline setup** | No | 10-15 |
| **Total (with fat gems):** | - | **120-185** |
| **Total (without fat gems):** | - | **45-75** |

### Ongoing Maintenance Effort

| Task | Frequency | Effort (Hours/occurrence) |
|------|-----------|-------------------------|
| **Update fat gems** (new GTK4/Ruby version) | 2-3x/year | 4-8 |
| **Update build scripts** (new dependencies) | 1-2x/year | 2-4 |
| **Build release installers** | Per release | 0.5-1 (automated via CI/CD) |

---

## DECISION MATRIX: FAT GEMS + PACKAGING STRATEGY

| Framework Path | Fat Gems Worth It? | Recommended Packaging | Setup Effort | Ongoing Effort |
|----------------|-------------------|---------------------|--------------|----------------|
| **LibUI** | 🟡 Optional (compilation fast) | .app, AppImage, InnoSetup | 45-75h | Low |
| **FXRuby** | 🟡 Optional (Lars provides binaries) | .app, AppImage, InnoSetup | 45-75h | Low |
| **GTK4** | ✅ Yes (simplifies build pipeline) | .app, AppImage, InnoSetup | 120-185h | Medium |
| **Glimmer SWT** | ❌ No (pure Java JARs, no compilation) | .app, AppImage, InnoSetup | 45-75h | Very Low |

**Recommendation:**
- **All paths:** Build app packages (.app, AppImage, installer)
- **GTK4 path only:** Build fat gems (120-185h initial, saves 20-50 min per build)
- **Other paths:** Skip fat gems (not worth effort)

---

## CONCLUSION

### For Immediate Use (Whichever Framework Chosen)

**Priority 1: Application Packaging (45-75 hours)**
- macOS: .app bundle + DMG
- Linux: AppImage
- Windows: Simplified InnoSetup installer

**Result:**
- Users get one-click install on all platforms
- Zero dependency installation
- Professional user experience

---

### For GTK4 Path Specifically

**Priority 2: Fat Gems (75-110 hours additional)**
- Pre-compiled gems with bundled GTK4 libraries
- Simplifies build pipeline significantly
- Reduces installer build time from 30-60min to 5-15min

**Result:**
- Faster, more reliable builds
- CI/CD friendly
- Long-term maintenance easier

---

### For Glimmer SWT Path

**Skip fat gems entirely** - Java JARs don't need compilation

**Focus on:**
- JRuby bundling (similar to Ruby bundling)
- SWT JAR packaging (simple file copy)
- Application packaging (same as other paths)

**Result:**
- Simplest build pipeline of all options
- Smallest installer size (100-120MB)
- Fastest build times (5-10 min)

---

**Next Steps After Framework Decision:**

1. Choose framework (use UI_FRAMEWORK_DECISION.md)
2. Decide on fat gems (GTK4 only, use this document)
3. Implement application packaging (all paths, use this document)
4. Set up CI/CD pipeline (use examples in this document)
5. Ship first beta installer

**Estimated time to first beta installer:**
- Without fat gems: 4-6 weeks (packaging only)
- With fat gems (GTK4): 8-12 weeks (gems + packaging)

---

**Session Context:** Application delivery technical addendum created 2025-11-19. Companion to UI framework decision and implementation documents.
