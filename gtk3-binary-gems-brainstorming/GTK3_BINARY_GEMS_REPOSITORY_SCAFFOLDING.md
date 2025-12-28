# GTK3 Binary Gems: Repository Scaffolding

**Date:** 2025-12-28
**Purpose:** Define complete repository structure for building GTK3 binary gems
**Status:** Brainstorming / Planning Phase

---

## Repository Naming & Location

### Recommended Repository Name

**Option 1: `lich5-gtk3-gems`** (Recommended)
- Clear purpose: Building GTK3 gems for Lich5
- Follows pattern: `<project>-<technology>-<artifact-type>`
- Not tied to any single Lich implementation

**Option 2: `ng-gtk3-binaries`**
- Shorter
- `ng-` namespace consistency with ng-betalich

**Option 3: `ruby-gtk3-binary-gems`**
- More generic (could be used by other Ruby projects)
- Longer name

**Recommendation:** `lich5-gtk3-gems` - clear, scoped to Lich5, but reusable.

### Organization

**GitHub Organization:** `elanthia-online` (or wherever Lich5 repos live)

**Repository URL:** `https://github.com/elanthia-online/lich5-gtk3-gems`

**Visibility:** Public (for free GitHub Actions)

---

## Complete Repository Structure

```
lich5-gtk3-gems/
├── .github/
│   ├── workflows/
│   │   ├── build-gems.yml              # Main build workflow
│   │   ├── test-gems.yml               # Test workflow
│   │   └── release.yml                 # Release workflow
│   └── ISSUE_TEMPLATE/
│       └── build-failure.md            # Template for reporting build issues
│
├── gems/                               # Ruby gem sources
│   ├── glib2/
│   │   ├── ext/
│   │   │   └── glib2/
│   │   │       ├── extconf.rb
│   │   │       ├── rbglib*.c
│   │   │       └── rbglib*.h
│   │   ├── lib/
│   │   │   └── glib2.rb
│   │   ├── test/
│   │   │   └── test_glib2.rb
│   │   ├── glib2.gemspec
│   │   └── Rakefile
│   │
│   ├── gobject-introspection/
│   │   └── ... (same structure)
│   ├── gio2/
│   ├── cairo/
│   ├── cairo-gobject/
│   ├── pango/
│   ├── gdk_pixbuf2/
│   ├── atk/
│   ├── gdk3/
│   └── gtk3/
│
├── vendor/                             # Pre-compiled GTK3 libraries
│   ├── README.md                       # Where these came from
│   ├── windows/
│   │   └── x64/
│   │       ├── bin/                    # DLLs
│   │       │   ├── libgtk-3-0.dll
│   │       │   ├── libglib-2.0-0.dll
│   │       │   └── ... (50+ DLLs)
│   │       └── share/                  # Data files
│   │           ├── icons/
│   │           ├── themes/
│   │           └── glib-2.0/schemas/
│   │
│   ├── macos/
│   │   ├── x86_64/                     # Intel
│   │   │   ├── lib/                    # dylibs
│   │   │   └── share/
│   │   └── arm64/                      # Apple Silicon
│   │       ├── lib/
│   │       └── share/
│   │
│   └── linux/
│       ├── x86_64/
│       │   ├── lib/                    # .so files (optional - may rely on system)
│       │   └── share/
│       └── aarch64/
│           ├── lib/
│           └── share/
│
├── scripts/                            # Build automation scripts
│   ├── setup-build-env.sh              # Set up build environment
│   ├── download-gtk3-libs.sh           # Download GTK3 binaries
│   ├── build-gem.rb                    # Shared gem building logic
│   ├── test-gem.rb                     # Test a built gem
│   └── bundle-libs.rb                  # Bundle vendor libs into gems
│
├── test/                               # Integration tests
│   ├── test_load_all.rb                # Load all gems
│   ├── test_gtk3_window.rb             # Create GTK3 window
│   └── fixtures/
│       └── test.glade                  # Sample Glade file
│
├── docs/                               # Documentation
│   ├── BUILDING.md                     # How to build gems locally
│   ├── TESTING.md                      # How to test gems
│   ├── ARCHITECTURE.md                 # Technical architecture
│   ├── DEPENDENCIES.md                 # Dependency tree explanation
│   └── TROUBLESHOOTING.md              # Common issues
│
├── pkg/                                # Build output (gitignored)
│   └── .gitkeep
│
├── .gitignore
├── .ruby-version                       # Pin Ruby version (3.3.0)
├── Gemfile                             # Development dependencies
├── Gemfile.lock
├── Rakefile                            # Master build script
├── README.md                           # Project overview
├── LICENSE                             # LGPL 2.1+ (match ruby-gnome)
└── CHANGELOG.md                        # Version history
```

---

## Essential Files - Detailed Breakdown

### 1. `.github/workflows/build-gems.yml`

**Purpose:** Main CI/CD workflow for building binary gems

```yaml
name: Build GTK3 Binary Gems

on:
  workflow_dispatch:  # Manual trigger
  push:
    branches: [main]
  pull_request:

jobs:
  build:
    name: Build gems on ${{ matrix.os }}
    runs-on: ${{ matrix.os }}

    strategy:
      fail-fast: false
      matrix:
        include:
          # Windows
          - os: windows-latest
            platform: x64-mingw32
            ruby: '3.3'

          # macOS Intel
          - os: macos-13
            platform: x86_64-darwin
            ruby: '3.3'

          # macOS Apple Silicon
          - os: macos-14
            platform: arm64-darwin
            ruby: '3.3'

          # Linux x64
          - os: ubuntu-latest
            platform: x86_64-linux
            ruby: '3.3'

          # Linux ARM64 (via QEMU)
          - os: ubuntu-latest
            platform: aarch64-linux
            ruby: '3.3'
            setup_qemu: true

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: ${{ matrix.ruby }}
          bundler-cache: true

      - name: Install GTK3 (Windows)
        if: runner.os == 'Windows'
        run: |
          # Use MSYS2 to install GTK3
          choco install msys2 -y
          C:\tools\msys2\usr\bin\bash -lc "pacman -S --noconfirm mingw-w64-x86_64-gtk3"

      - name: Install GTK3 (macOS)
        if: runner.os == 'macOS'
        run: |
          brew install gtk+3

      - name: Install GTK3 (Linux)
        if: runner.os == 'Linux' && !matrix.setup_qemu
        run: |
          sudo apt-get update
          sudo apt-get install -y libgtk-3-dev

      - name: Build all gems
        run: |
          bundle exec rake build:all PLATFORM=${{ matrix.platform }}

      - name: Test gems
        run: |
          bundle exec rake test:quick PLATFORM=${{ matrix.platform }}

      - name: Upload gem artifacts
        uses: actions/upload-artifact@v4
        with:
          name: gems-${{ matrix.platform }}
          path: pkg/*.gem
          retention-days: 90
```

### 2. `Rakefile` (Master Build Script)

**Purpose:** Orchestrate building all gems

```ruby
# Rakefile
require 'rake/clean'

# Configuration
RUBY_GNOME_VERSION = '4.3.4'  # Target version
PLATFORMS = %w[
  x64-mingw32
  x86_64-darwin
  arm64-darwin
  x86_64-linux
  aarch64-linux
]

GEMS = %w[
  glib2
  gobject-introspection
  gio2
  cairo
  cairo-gobject
  pango
  gdk_pixbuf2
  atk
  gdk3
  gtk3
]

# Directories
PKG_DIR = 'pkg'
VENDOR_DIR = 'vendor'

# Clean tasks
CLEAN.include('pkg/**/*.gem')
CLOBBER.include('pkg')

namespace :build do
  desc 'Build all gems for current platform'
  task :all do
    platform = ENV['PLATFORM'] || Gem::Platform.local.to_s

    puts "Building all gems for platform: #{platform}"

    GEMS.each do |gem_name|
      Rake::Task["build:gem"].execute(gem_name, platform)
    end

    puts "\n✅ All gems built successfully!"
    puts "   Output: #{PKG_DIR}/"
  end

  desc 'Build a single gem'
  task :gem, [:name, :platform] do |t, args|
    name = args[:name]
    platform = args[:platform] || Gem::Platform.local.to_s

    puts "\n📦 Building #{name} for #{platform}..."

    Dir.chdir("gems/#{name}") do
      # Bundle vendor libraries
      sh "ruby ../../scripts/bundle-libs.rb #{platform}"

      # Build gem
      sh "gem build #{name}.gemspec --platform=#{platform}"

      # Move to pkg/
      FileUtils.mkdir_p("../../#{PKG_DIR}")
      FileUtils.mv(Dir.glob("*.gem"), "../../#{PKG_DIR}/")
    end

    puts "   ✅ #{name} built"
  end
end

namespace :test do
  desc 'Quick test - verify gems load'
  task :quick do
    platform = ENV['PLATFORM'] || Gem::Platform.local.to_s

    puts "Testing gems for platform: #{platform}"

    GEMS.each do |gem_name|
      gem_file = Dir.glob("#{PKG_DIR}/#{gem_name}-*-#{platform}.gem").first

      next unless gem_file

      puts "\n🧪 Testing #{gem_name}..."
      sh "ruby scripts/test-gem.rb #{gem_file}"
    end
  end

  desc 'Full integration test'
  task :integration do
    sh "ruby test/test_load_all.rb"
    sh "ruby test/test_gtk3_window.rb"
  end
end

namespace :vendor do
  desc 'Download GTK3 vendor libraries for all platforms'
  task :download do
    sh "bash scripts/download-gtk3-libs.sh"
  end
end

desc 'Show build information'
task :info do
  puts "Ruby version: #{RUBY_VERSION}"
  puts "Platform: #{Gem::Platform.local}"
  puts "Gems to build: #{GEMS.join(', ')}"
  puts "Target platforms: #{PLATFORMS.join(', ')}"
end

task default: ['build:all']
```

### 3. `scripts/bundle-libs.rb`

**Purpose:** Copy vendor libraries into gem's vendor/ directory

```ruby
#!/usr/bin/env ruby
# scripts/bundle-libs.rb

require 'fileutils'

platform = ARGV[0] || Gem::Platform.local.to_s
gem_name = File.basename(Dir.pwd)

puts "Bundling vendor libraries for #{gem_name} (#{platform})"

# Map platform to vendor directory
vendor_platform = case platform
when /mingw32/
  'windows/x64'
when /x86_64-darwin/
  'macos/x86_64'
when /arm64-darwin/
  'macos/arm64'
when /x86_64-linux/
  'linux/x86_64'
when /aarch64-linux/
  'linux/aarch64'
else
  raise "Unknown platform: #{platform}"
end

vendor_src = "../../vendor/#{vendor_platform}"
vendor_dst = "vendor"

unless Dir.exist?(vendor_src)
  puts "⚠️  No vendor libraries found at #{vendor_src}"
  puts "   Run 'rake vendor:download' first"
  exit 1
end

# Create vendor directory structure
FileUtils.mkdir_p("#{vendor_dst}/bin")   # Windows DLLs
FileUtils.mkdir_p("#{vendor_dst}/lib")   # macOS/Linux dylibs/so
FileUtils.mkdir_p("#{vendor_dst}/share") # Data files

# Copy binaries
if platform =~ /mingw32/
  # Windows: Copy DLLs
  FileUtils.cp_r(Dir.glob("#{vendor_src}/bin/*.dll"), "#{vendor_dst}/bin/")
else
  # macOS/Linux: Copy dylibs/so files
  FileUtils.cp_r(Dir.glob("#{vendor_src}/lib/*.{dylib,so,so.*}"), "#{vendor_dst}/lib/")
end

# Copy share/ data files (icons, themes, schemas)
FileUtils.cp_r("#{vendor_src}/share/", vendor_dst)

puts "✅ Vendor libraries bundled:"
puts "   Source: #{vendor_src}"
puts "   Destination: #{vendor_dst}"
```

### 4. `scripts/test-gem.rb`

**Purpose:** Test that a built gem can be installed and loaded

```ruby
#!/usr/bin/env ruby
# scripts/test-gem.rb

require 'tmpdir'
require 'fileutils'

gem_file = ARGV[0]

unless gem_file && File.exist?(gem_file)
  puts "Usage: ruby test-gem.rb <gem-file>"
  exit 1
end

gem_name = File.basename(gem_file, '.gem').split('-').first

puts "Testing gem: #{gem_file}"

Dir.mktmpdir do |tmpdir|
  ENV['GEM_HOME'] = tmpdir
  ENV['GEM_PATH'] = tmpdir

  # Install gem
  puts "  Installing gem..."
  system("gem install #{gem_file} --local --no-document") || exit(1)

  # Try to require it
  puts "  Loading gem..."
  success = system(<<~RUBY)
    ruby -I #{tmpdir}/gems/*/lib -e "
      require '#{gem_name}'
      puts '    ✅ #{gem_name} loaded successfully'
    "
  RUBY

  exit(1) unless success
end

puts "✅ Test passed: #{gem_name}"
```

### 5. `test/test_gtk3_window.rb`

**Purpose:** Integration test - create a GTK3 window

```ruby
#!/usr/bin/env ruby
# test/test_gtk3_window.rb

require 'gtk3'

puts "Testing GTK3 window creation..."
puts "  GTK version: #{Gtk::VERSION.join('.')}"
puts "  GLib version: #{GLib::VERSION.join('.')}"

Gtk.init

window = Gtk::Window.new("GTK3 Binary Gem Test")
window.set_default_size(400, 300)
window.border_width = 10

label = Gtk::Label.new("✅ GTK3 loaded successfully!")
window.add(label)

# Don't actually show the window in CI (no display)
if ENV['CI']
  puts "✅ GTK3 window object created (headless CI)"
else
  window.show_all
  puts "✅ GTK3 window displayed"

  # Auto-close after 2 seconds
  GLib::Timeout.add(2000) { Gtk.main_quit }

  Gtk.main
end
```

### 6. `README.md`

**Purpose:** Project overview and quick start

```markdown
# Lich5 GTK3 Binary Gems

Precompiled binary gems for the GTK3 stack, built for Lich5.

## What This Is

This repository builds **binary gems** for the ruby-gnome GTK3 stack, bundled with all necessary runtime libraries (DLLs/dylibs). This eliminates the need for users to:
- Install system GTK3 libraries
- Set up build toolchains
- Compile native extensions

**Just install and go!**

## Supported Platforms

- Windows x64 (`x64-mingw32`)
- macOS Intel (`x86_64-darwin`)
- macOS Apple Silicon (`arm64-darwin`)
- Linux x64 (`x86_64-linux`)
- Linux ARM64 (`aarch64-linux`)

## Quick Start

### Installing Pre-built Gems

Download the latest gems from [Releases](https://github.com/elanthia-online/lich5-gtk3-gems/releases):

```bash
gem install glib2-4.3.4-x64-mingw32.gem
gem install gobject-introspection-4.3.4-x64-mingw32.gem
# ... (install all 10 gems)
```

Or use in your `Gemfile`:

```ruby
# Gemfile
gem 'gtk3', '4.3.4', platforms: :mingw32, source: 'https://github.com/elanthia-online/lich5-gtk3-gems/releases/download/v4.3.4'
```

### Building Locally

**Prerequisites:**
- Ruby 3.3+
- GTK3 development libraries (platform-specific)

**Build all gems:**
```bash
bundle install
rake vendor:download  # Download GTK3 vendor libraries
rake build:all
```

Gems will be in `pkg/`

**Test:**
```bash
rake test:quick
```

## Gems Included

1. **glib2** - Core GLib library
2. **gobject-introspection** - Dynamic language bindings
3. **gio2** - File/network I/O
4. **cairo** - 2D graphics
5. **cairo-gobject** - GObject bindings for Cairo
6. **pango** - Text rendering
7. **gdk_pixbuf2** - Image loading
8. **atk** - Accessibility
9. **gdk3** - Graphics/display backend
10. **gtk3** - Main GUI toolkit

## Documentation

- [Building Guide](docs/BUILDING.md)
- [Testing Guide](docs/TESTING.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)

## License

LGPL 2.1+ (matching ruby-gnome)

## Credits

Based on [ruby-gnome](https://github.com/ruby-gnome/ruby-gnome) by Kouhei Sutou and contributors.
```

### 7. `docs/BUILDING.md`

**Purpose:** Detailed build instructions

```markdown
# Building GTK3 Binary Gems

## Prerequisites

### All Platforms

- Ruby 3.3+
- Bundler: `gem install bundler`
- Rake: `gem install rake`

### Windows

**Option 1: MSYS2 (Recommended)**
```bash
choco install msys2
C:\tools\msys2\usr\bin\bash -lc "pacman -S --noconfirm mingw-w64-x86_64-gtk3"
```

**Option 2: vcpkg**
```bash
vcpkg install gtk3:x64-windows
```

### macOS

```bash
brew install gtk+3
```

### Linux (Ubuntu/Debian)

```bash
sudo apt-get install libgtk-3-dev
```

### Linux (Fedora)

```bash
sudo dnf install gtk3-devel
```

## Build Process

### 1. Clone Repository

```bash
git clone https://github.com/elanthia-online/lich5-gtk3-gems.git
cd lich5-gtk3-gems
```

### 2. Install Dependencies

```bash
bundle install
```

### 3. Download Vendor Libraries

```bash
rake vendor:download
```

This downloads precompiled GTK3 libraries for bundling.

### 4. Build All Gems

```bash
rake build:all
```

Or build a single gem:

```bash
rake build:gem[glib2]
```

### 5. Test Gems

```bash
rake test:quick
```

## Output

Built gems will be in `pkg/`:
```
pkg/
├── glib2-4.3.4-x64-mingw32.gem
├── gobject-introspection-4.3.4-x64-mingw32.gem
└── ...
```

## Platform-Specific Builds

To build for a specific platform:

```bash
rake build:all PLATFORM=x64-mingw32
rake build:all PLATFORM=x86_64-darwin
rake build:all PLATFORM=arm64-darwin
rake build:all PLATFORM=x86_64-linux
```

## Troubleshooting

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
```

### 8. `.gitignore`

```gitignore
# Build output
pkg/
*.gem

# Vendor libraries (too large for git - download separately)
vendor/windows/
vendor/macos/
vendor/linux/

# Ruby
*.bundle
*.so
*.o
*.dll
*.dylib
.bundle/
vendor/bundle/

# Gem build artifacts
Gemfile.lock
.rake_tasks

# OS
.DS_Store
Thumbs.db

# IDEs
.idea/
.vscode/
*.swp
*.swo

# Testing
test/tmp/
coverage/

# CI artifacts
.github/workflows/artifacts/
```

### 9. `Gemfile`

```ruby
# Gemfile
source 'https://rubygems.org'

ruby '>= 3.3.0'

gem 'rake'
gem 'bundler'

group :development do
  gem 'rubocop'
end

group :test do
  gem 'minitest'
end
```

### 10. `.ruby-version`

```
3.3.0
```

---

## Vendor Library Acquisition Strategy

### Initial Population

**Where to get GTK3 vendor libraries:**

#### Windows
```bash
# Use MSYS2
pacman -S mingw-w64-x86_64-gtk3

# Copy from MSYS2 to vendor/
cp -r /mingw64/bin/*.dll vendor/windows/x64/bin/
cp -r /mingw64/share/{icons,themes,glib-2.0} vendor/windows/x64/share/
```

#### macOS
```bash
# Use Homebrew
brew install gtk+3

# Copy from Homebrew to vendor/
cp -r /opt/homebrew/lib/*.dylib vendor/macos/arm64/lib/
cp -r /opt/homebrew/share/{icons,themes,glib-2.0} vendor/macos/arm64/share/
```

#### Linux
**Recommendation:** Don't bundle for Linux - rely on system GTK3

Or for AppImage:
```bash
sudo apt-get install libgtk-3-0

cp -r /usr/lib/x86_64-linux-gnu/libgtk-3.so* vendor/linux/x86_64/lib/
# ... (copy all dependencies)
```

### Storage Strategy

**Problem:** Vendor libraries are 150-200MB per platform = 1GB+ total

**Options:**

**Option 1: Git LFS (Large File Storage)**
```bash
git lfs track "vendor/**/*.dll"
git lfs track "vendor/**/*.dylib"
```
- Pros: Versioned with code
- Cons: GitHub LFS costs money after 1GB storage / 1GB bandwidth

**Option 2: External Download Script**
```bash
# scripts/download-gtk3-libs.sh
# Downloads from external source (S3, archive.org, etc.)
```
- Pros: Free, doesn't bloat repo
- Cons: External dependency

**Option 3: GitHub Releases**
- Store vendor libs as release assets
- Download on-demand during build
- Pros: Free, reliable
- Cons: Manual upload on updates

**Recommendation for POC:** **Option 2** (script downloads from MSYS2/Homebrew)
**Recommendation for Production:** **Option 3** (GitHub Releases)

---

## Initial Scaffolding Tasks

### Phase 1: Repository Setup (1 day)

- [ ] Create repository: `elanthia-online/lich5-gtk3-gems`
- [ ] Set up branch protection on `main`
- [ ] Add basic README.md
- [ ] Add LICENSE (LGPL 2.1+)
- [ ] Add .gitignore
- [ ] Add .ruby-version

### Phase 2: Directory Structure (1 day)

- [ ] Create `gems/` directory structure
- [ ] Create `vendor/` directory structure
- [ ] Create `scripts/` directory
- [ ] Create `test/` directory
- [ ] Create `docs/` directory
- [ ] Add placeholder files

### Phase 3: Ruby-GNOME Source Import (2-3 days)

**Strategy:** Fork ruby-gnome code, or import selectively?

**Option A: Subtree Merge**
```bash
git subtree add --prefix gems/glib2 https://github.com/ruby-gnome/ruby-gnome.git glib2 --squash
```

**Option B: Copy & Customize**
- Copy each gem's source from ruby-gnome
- Modify gemspecs for binary bundling
- Customize extconf.rb for vendor libs

**Recommendation:** **Option B** (cleaner, more control)

Tasks:
- [ ] Copy glib2 source → `gems/glib2/`
- [ ] Copy gobject-introspection → `gems/gobject-introspection/`
- [ ] ... (repeat for all 10 gems)
- [ ] Modify each gemspec for binary platform
- [ ] Modify each extconf.rb for vendor bundling

### Phase 4: Build Scripts (2-3 days)

- [ ] Create `Rakefile` with build tasks
- [ ] Create `scripts/bundle-libs.rb`
- [ ] Create `scripts/test-gem.rb`
- [ ] Create `scripts/download-gtk3-libs.sh`
- [ ] Test local build (Windows or macOS)

### Phase 5: GitHub Actions (2-3 days)

- [ ] Create `.github/workflows/build-gems.yml`
- [ ] Test Windows build in CI
- [ ] Test macOS build in CI
- [ ] Test Linux build in CI
- [ ] Fix platform-specific issues
- [ ] Configure artifact uploads

### Phase 6: Testing (1-2 days)

- [ ] Create `test/test_load_all.rb`
- [ ] Create `test/test_gtk3_window.rb`
- [ ] Add to CI workflow
- [ ] Verify on all platforms

### Phase 7: Documentation (1-2 days)

- [ ] Write `docs/BUILDING.md`
- [ ] Write `docs/TESTING.md`
- [ ] Write `docs/ARCHITECTURE.md`
- [ ] Write `docs/TROUBLESHOOTING.md`
- [ ] Finalize README.md

**Total Estimate: 2-3 weeks to full scaffolding**

---

## Quick Start Checklist

**Absolute minimum to start experimenting:**

- [ ] Create repository
- [ ] Create `gems/glib2/` with ruby-gnome source
- [ ] Create `vendor/windows/x64/bin/` and copy GTK3 DLLs
- [ ] Create basic `Rakefile` with build task
- [ ] Build one gem locally: `rake build:gem[glib2]`
- [ ] Test: `gem install pkg/glib2-*.gem && ruby -e "require 'glib2'"`

**Time: 1 day to first successful gem build!**

---

## Next Steps After Scaffolding

1. **Proof of Concept:** Build `glib2` gem for Windows with bundled DLLs
2. **Expand:** Build all 10 gems for Windows
3. **CI Integration:** Automate with GitHub Actions
4. **Multi-Platform:** Add macOS and Linux
5. **Lich5 Integration:** Bundle gems in Lich5 installer

---

**Status:** Ready to create repository and start building!
**Estimated Time to POC:** 1-2 weeks
**Estimated Time to Production:** 6-8 weeks
