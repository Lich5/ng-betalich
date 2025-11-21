# Pre-Branch Curation Scripts

Modular, testable, and extensible scripts for curating prerelease branches with PR cherry-picking.

## Architecture

### Design Principles

- **SOLID**: Single responsibility, open/closed, dependency inversion
- **DRY**: No code duplication, single source of truth
- **Testable**: Each module can be tested independently
- **Extensible**: Add new strategies without modifying existing code
- **Maintainable**: Clear separation of concerns, well-documented

### Directory Structure

```
.github/scripts/
├── lib/                         # Reusable libraries
│   ├── core.sh                  # Logging, env exports, GitHub Actions utils
│   ├── git-helpers.sh           # Git operations (fetch, merge, cherry-pick)
│   ├── github-api.sh            # GitHub API client
│   └── validation.sh            # Input validation and normalization
├── strategies/
│   ├── conflict/                # Pluggable conflict resolution strategies
│   │   ├── abort.sh             # Default: fail on conflicts
│   │   ├── ours.sh              # Prefer current branch
│   │   ├── theirs.sh            # Prefer incoming changes
│   │   └── union.sh             # Concatenate both sides (experimental)
│   └── syntax/                  # Pluggable syntax validators
│       ├── ruby.sh              # Ruby syntax checking
│       ├── yaml.sh              # YAML syntax checking
│       └── json.sh              # JSON syntax checking
└── curate-pre-branch.sh         # Main orchestration script
```

## Usage

### From Workflow

See `.github/workflows/curate-pre-branch.yaml` for workflow integration.

### Direct Execution

```bash
export DESTINATION="pre/beta/my-feature"
export BASE="main"
export PRS="12,27,43"
export MODE="auto"
export SQUASH="true"
export CONFLICT_STRATEGY="abort"
export RESET_DESTINATION="false"
export DRY_RUN="false"
export GITHUB_TOKEN="<token>"
export GITHUB_REPOSITORY="owner/repo"

.github/scripts/curate-pre-branch.sh
```

## Conflict Strategies

### abort (default)
Fails immediately on conflicts. Safest option, requires manual resolution.

### ours
Auto-resolves conflicts favoring current branch. Use when preserving existing code.

### theirs
Auto-resolves conflicts favoring incoming PR. Use when accepting all PR changes.

### union (experimental)
Concatenates both sides of conflicts. **Dangerous** - may create broken code.

**Works well for:**
- CHANGELOG entries
- Independent configuration additions
- Documentation with non-overlapping changes

**Breaks for:**
- Method definitions (duplicate methods = syntax error)
- Configuration values (last assignment wins = silent bug)
- Code logic (both branches kept = nonsense)

## Extending the System

### Add New Conflict Strategy

1. Create `.github/scripts/strategies/conflict/my-strategy.sh`:
```bash
#!/usr/bin/env bash
get_strategy_flag_my_strategy() {
  echo "-X my-strategy"
}
```

2. Update `setup_conflict_strategy()` in `curate-pre-branch.sh`:
```bash
my-strategy)
  source "${SCRIPT_DIR}/strategies/conflict/my-strategy.sh"
  GIT_STRATEGY_FLAG="$(get_strategy_flag_my_strategy)"
  USE_UNION=false
  ;;
```

3. Update workflow input choices in `.github/workflows/curate-pre-branch.yaml`

### Add New Syntax Validator

1. Create `.github/scripts/strategies/syntax/python.sh`:
```bash
#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/core.sh"

validate_python_syntax() {
  log_info "Validating Python syntax..."
  # Implementation here
}
```

2. Call from `validate_syntax()` in `curate-pre-branch.sh`:
```bash
source "${SCRIPT_DIR}/strategies/syntax/python.sh"
validate_python_syntax || exit_code=$?
```

## Testing

Run all tests:
```bash
bash .github/tests/run-tests.sh
```

Run specific test suite:
```bash
bash .github/tests/lib/test-validation.sh
```

## Comparison to Previous Implementation

| Aspect | Old (Monolithic) | New (Modular) |
|--------|------------------|---------------|
| Lines in workflow | 1,123 | 108 (90% reduction) |
| Testability | 0% (inline bash) | 100% (all functions testable) |
| Code duplication | High (3+ workflows) | Zero (shared lib/) |
| Extensibility | Hard (modify core) | Easy (add strategy file) |
| SOLID compliance | Low | High |
| Maintainability | Medium (docs only) | High (structure + docs) |

## Benefits

### For Developers
- **Clear structure**: Find code quickly by responsibility
- **Easy testing**: Mock functions, test edge cases
- **Safe modifications**: Change one module without breaking others

### For Reviewers
- **Small, focused changes**: Each PR touches specific modules
- **Easy to verify**: Test individual functions
- **Clear impact**: Module boundaries show affected areas

### For Operations
- **Reusable**: Same scripts work across workflows
- **Debuggable**: Run scripts locally with `bash -x`
- **Versionable**: Pin to specific script versions

## Migration Path

### From Old Workflow
The new workflow is a drop-in replacement:
1. Same inputs
2. Same outputs
3. Same behavior
4. Just rename the old workflow to keep as backup

### Gradual Adoption
Other workflows can migrate incrementally:
1. Extract common code to `lib/`
2. Reuse `validation.sh` functions
3. Share `git-helpers.sh` operations
4. Use same conflict strategies

## Troubleshooting

### Script not executable
```bash
chmod +x .github/scripts/curate-pre-branch.sh
```

### Import errors
Ensure all scripts use absolute paths from `$SCRIPT_DIR`

### Test failures
Check environment variables are set correctly

## License

Follows repository license.
