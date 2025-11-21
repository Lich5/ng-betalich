# Development Workflow for ng-betalich

## Philosophy

This project follows **test-before-develop** methodology with **strict branch layering**. All work must be:
- Spec-complete before code validation
- Validated (specs + rubocop) before any push
- Mindful of PR dependencies and layering order

## Branch Layering Strategy

PRs are layered sequentially - each depends on prior merges:
- **PR81**: Master password encryption feature
- **PR82**: CLI password management
- **Improvement branches**: Layer on top of appropriate PR base

### Key Principle: No Unnecessary Files

When creating an improvement branch (e.g., based on PR82):
- **DO** include code changes specific to that PR's scope
- **DO** include corresponding spec updates
- **DO NOT** merge in files from other branches unless they are direct dependencies
- **ASSUME** prior PRs will be merged in order - dependencies will be satisfied by the stack

**Example**: A CLI improvements branch based on PR82 should NOT pull in master password feature files from PR81, because PR81 will already be merged when this branch is applied.

## Testing Cross-Branch Dependencies

When your branch depends on files from another branch (e.g., yaml_state.rb from PR81):

1. **Temporarily load dependencies** to validate specs:
   ```bash
   git show other-branch:lib/path/file.rb > lib/path/file.rb
   ```

2. **Run full validation** (specs + style):
   ```bash
   rspec spec/your_spec.rb          # All specs must pass
   rubocop lib/your_file.rb         # No style violations
   ```

3. **Remove temporary files** before pushing:
   ```bash
   rm -rf lib/path/  # Clean up only the temp files
   git status        # Verify working tree is clean
   ```

4. **Push only your actual changes** - the stack will satisfy dependencies

## Pre-Push Validation Checklist

**BEFORE EVERY PUSH:**

- [ ] Specs written for all code changes
- [ ] Specs pass (use temporary deps if needed)
- [ ] Rubocop clean (no style violations)
- [ ] Only necessary files included in branch
- [ ] Commit messages are clear and reference requirements
- [ ] No temporary files left in working directory
- [ ] `git status` shows clean working tree

## Spec Requirements

Specs are **ALWAYS** required:
- One spec file per code file being modified
- Specs updated to match new function signatures
- All expectations match actual implementation
- Specs must be committed with code changes

### When Specs Can't Run in Isolation

Some branches can't run specs standalone due to cross-dependencies. This is acceptable IF:
1. You've validated specs pass with temporary deps loaded
2. You've documented the dependency (in commit message or comment)
3. The dependency will be satisfied in the actual merge stack

## Code Review & Quality Gates

Every branch must pass:
1. **RSpec** - All tests passing
2. **Rubocop** - Style compliance
3. **Logical validation** - Code follows project patterns from CLI_PRIMER and SOCIAL_CONTRACT

## Session Continuity

This document is your foundation. If you detect session compaction:
1. Re-read CLI_PRIMER (test/development philosophy)
2. Re-read SOCIAL_CONTRACT (team agreements)
3. Re-read this document (workflow procedures)
4. Reference them explicitly in decisions

**Signs of session loss:**
- Forgetting to include specs with code changes
- Pulling unnecessary files into branches
- Skipping validation before pushing
- Not consulting known project documentation

## Common Patterns

### Creating an Improvement Branch
```bash
git checkout -b fix/feature-improvements pr-base
# Make changes
# Add specs
git add lib/file.rb spec/file_spec.rb
# Test with temporary deps
# Remove temp deps
# Commit & push
```

### Testing with Dependencies
```bash
# Pull temp files
git show other-branch:lib/path/file.rb > lib/path/file.rb

# Validate
rspec spec/your_spec.rb
rubocop lib/your_file.rb

# Clean up
rm -rf lib/path/
git status  # Should be clean
```

### Commit Message Format
```
fix(component): brief description

- Detailed change 1
- Detailed change 2

Validated: specs passing, rubocop clean
```

## References

- **CLI_PRIMER** - Core development philosophy and testing strategy
- **SOCIAL_CONTRACT** - Team agreements and collaboration principles
- **Branch history** - Review recent PRs to understand layering patterns
