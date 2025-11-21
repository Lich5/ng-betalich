# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Lich 5** is a GTK3-based scripting engine for Simutronic's text-based games (DragonRealms and Gemstone IV). It acts as a proxy server that communicates with front-ends and allows users to write and run scripts in Ruby. The codebase is primarily Ruby with a modular architecture supporting two games with shared common functionality.

## Common Commands

### Setup & Dependencies
```bash
bundle install              # Install gem dependencies
ruby lich.rbw              # Run Lich (main entry point)
```

### Testing
```bash
bundle exec rspec          # Run all tests
bundle exec rspec spec/FILENAME_spec.rb  # Run a specific test file
bundle exec rspec -e "test name pattern"  # Run tests matching a pattern
```

### Code Quality
```bash
bundle exec rubocop        # Run style/lint checks (non-strict, many rules disabled)
bundle exec rubocop -A     # Run style checks with auto-correct
```

## Architecture & Code Structure

### Core Architecture
Lich is a **proxy-based scripting engine** with these main components:

1. **Game Abstraction Layer** (`lib/games.rb`, `lib/global_defs.rb`)
   - Defines game-specific behavior via `GameBase::Game` abstract class
   - Implements game-specific XML parsing, combat handling, atmospherics, and room display
   - Two concrete implementations: `Lich::Gemstone::Game` and `Lich::DragonRealms::Game`
   - Game-specific constants and data structures in `lib/gemstone/` and `lib/dragonrealms/` directories

2. **Script Execution Engine** (`lib/common/script.rb`, `lib/lich.rb`)
   - Manages script lifecycle and bindings
   - Runs scripts in isolated/trusted Ruby contexts
   - Implements script loading, execution, and inter-script communication
   - Handles script argument passing and variable scope isolation

3. **Data & State Management** (`lib/common/settings.rb`, `lib/stash.rb`, `lib/common/vars.rb`)
   - SQLite database for persistent storage
   - Settings system with game-specific and global scopes
   - User variables (Vars) and shared variables (UserVars)
   - Buffer management for game output

4. **Network & Communication** (`lib/common/front-end.rb`, `lib/messaging.rb`)
   - Proxy communication with game servers
   - Front-end integration for UI
   - Upstream/downstream hooks for message handling
   - XML parsing and cleanup (in `lib/common/xmlparser.rb`, `lib/games.rb`)

### Directory Organization
- `lib/lich.rb` - Main module with core API (mutex handling, db access)
- `lib/init.rb` - Initialization logic, Ruby version checks, environment setup
- `lib/common/` - Shared functionality (scripts, settings, game objects, buffers)
- `lib/gemstone/` & `lib/dragonrealms/` - Game-specific implementations
  - `infomon/` - Infomon-related data structures
  - `psms/` - PSMS (Persistent Spell Monitoring System)
  - `bounty/`, `societies/`, `critranks/`, etc. - Domain-specific modules
- `lib/util/` & `lib/attributes/` - Utility functions and attribute definitions
- `spec/` - RSpec test files with test fixtures

### Key Classes & Patterns

**Game Implementations**
- Each game implements abstract methods from `GameBase::Game`:
  - `handle_combat_tags`, `handle_atmospherics`, `process_game_specific_data`, etc.
- Game initialization happens in `Lich.seek` method
- Game-specific behavior is isolated to avoid cross-game contamination

**Script System**
- Scripts execute in restricted Ruby bindings for security
- Trusted scripts (no labels) get full access; untrusted scripts are sandboxed
- Scripts use `Script.start()` to launch other scripts
- Script-to-script communication via UserVars and hooks

**Settings & Data**
- Settings are stored in SQLite database with scoping:
  - Global settings
  - Game-specific settings
  - Character-specific settings
- Used for UI state (autosort, dark mode, layout), debug flags, and game data

### Test Structure
Tests use RSpec with a mock database adapter (`spec/mock_database_adapter.rb`) to avoid hitting the real database. Test files follow naming convention `*_spec.rb` and are located in `spec/`. Key test areas:
- Parser tests (bounty, infomon, settings, psms)
- Game behavior tests
- XML data handling tests

## Configuration & Release

### RuboCop Rules
Most metrics and style rules are disabled in `.rubocop.yml`. Only essential rules around naming and security are active (though Naming is also disabled). The project prioritizes pragmatism over strict style enforcement.

### Ruby Version
Requires Ruby 3.4+ (specified in `.ruby-version` and checked at startup in `init.rb`)

### Release Process
The project uses `release-please` for automated versioning and changelog management. PR titles must follow semantic commit format with scopes (all, dr, gs, main, pre/beta.*).

### Platforms
Lich runs on:
- Windows (native and via WINE)
- Linux
- macOS

Platform-specific code checks `RUBY_PLATFORM` for conditionals.

## Key Development Notes

- **Mutex/Thread Safety**: Core database operations use `Lich.mutex_lock/unlock` to prevent concurrent access issues (see `lib/lich.rb`)
- **Deprecated API**: Old `Lich.*` variable access is deprecated in favor of `Vars.*` (triggers warning every 5 minutes if used)
- **XML Parsing**: Game servers send XML; extensive parsing and cleansing happens in `games.rb` and `xmlparser.rb`
- **Script Bindings**: Extremely careful with script binding architecture—changes can break script isolation, variable sharing, or make defined methods inaccessible (see comment at top of `script.rb`)
- **Game-Specific Data**: Large data structures for spells, skills, abilities in respective game directories; often auto-generated from game data sources
