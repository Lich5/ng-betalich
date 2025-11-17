# CLI Architecture & Modernization

## Overview

Lich's startup argument parsing has been refactored from imperative regex-matching into a **declarative, modular system**. This document outlines the architectural decisions and future extensibility.

## Core Principle

**Separate concerns:** Parsing → Validation → Execution → Side Effects

## Three-Layer Architecture

### Layer 1: Parsing (`lib/util/opts.rb`)
- **Responsibility:** Pure argument parsing, type coercion, normalization
- **Input:** Raw ARGV array
- **Output:** Frozen OpenStruct (immutable)
- **Philosophy:** No side effects, no business logic
- **Scope:** Generic, reusable for any CLI work

### Layer 2: Orchestration (`lib/main/argv_options.rb`)
- **Responsibility:** Lich-specific validation, routing, environment setup
- **Input:** Frozen OpenStruct from Layer 1
- **Output:** Exit (CLI commands) or @argv_options hash (GUI flow)
- **Philosophy:** Knows about Lich startup, not about business domains
- **Uses:** `CliOptionsRegistry` for declarative option definitions

### Layer 3: Domain Handlers
- **Responsibility:** Business logic for specific operations
- **Examples:** `lib/util/cli_password_manager.rb` for password operations
- **Philosophy:** No awareness of startup orchestration, no GTK dependency
- **Scope:** Can assume Lich constants and basic infrastructure loaded

## Option Registration System

Options are declared declaratively in `CliOptionsRegistry`:

```ruby
option :gui,
  type: :boolean,
  default: true,
  deprecated: false

option :change_account_password,
  type: :boolean,
  mutually_exclusive: [:gui],
  handler: -> (opts) { execute_and_exit }

option :sal,
  type: :string,
  deprecated: true,
  deprecation_message: "Use account management UI"
```

**Benefits:**
- Self-documenting options
- Centralized dependency/exclusivity rules
- Deprecation path explicit
- Easy to add new options

## Execution Flow

```
lich.rbw
  ↓
[Early ARGV: directory overrides]
  ↓
[Load argv_options.rb]
  ↓
1. Clean ARGV (launcher.exe)
2. Parse with Lich::Util::Opts
3. Validate with CliOptionsRegistry
4. Execute CLI handlers (exit if matched)
5. Apply side effects (dark mode, etc)
6. Build @argv_options hash (backward compat)
  ↓
[Continue to GUI or exit]
```

## Backward Compatibility

- `@argv_options[:gui]` preserved exactly (main.rb contract)
- `@argv_options[:sal]` preserved (marked for deprecation walk)
- All existing ARGV flags continue to work
- Deprecation warnings logged, not errors

## Future Extensions

This architecture enables:

- **Script options registry** (`ScriptsOptionsRegistry`) — Same pattern for script arguments
- **Config file options** — Extend Opts to read from YAML/TOML
- **Plugin options** — Register plugin-specific options without modifying core
- **Option inheritance** — Subcommands inherit parent options
- **Interactive prompts** — Validators can prompt for missing required options

## Design Rationale

1. **Immutable options** — Frozen OpenStruct prevents script pollution
2. **Early exit for CLI** — Password operations don't initialize full Lich
3. **Declarative registry** — Reduces code, increases clarity, enables tooling
4. **Tight namespacing** — `Lich::Util::CLI` controls access, prevents collisions
5. **Modular handlers** — Each operation is independent, testable unit

## Key Files

- `lib/util/opts.rb` — Generic parser engine
- `lib/util/cli_options_registry.rb` — Lich startup option definitions
- `lib/util/cli_password_manager.rb` — Password operation handlers
- `lib/main/argv_options.rb` — Orchestration (refactored)

## Notes for Future Work

- `.sal` file handling and related args are marked for deprecation discussion
- Script refactor will incorporate `ScriptsOptionsRegistry` pattern
- Config/plugin options can extend this system without modifying core
