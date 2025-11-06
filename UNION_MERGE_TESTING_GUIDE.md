# Union Merge Workflow - Testing Guide

## ⚠️ EXPERIMENTAL FEATURE

This workflow implements automatic conflict resolution using a "union merge" strategy. **This is experimental and should be thoroughly tested before production use.**

## What Was Implemented

### Core Features
1. **Union Merge Conflict Resolution** - Automatically combines both sides of conflicts
2. **Syntax Validation** - Checks Ruby, YAML, and JSON files after merge
3. **Dry-Run Mode** - Preview changes without pushing
4. **Enhanced Logging** - Detailed conflict reports in GitHub Summary
5. **Error Handling** - Proper failure modes and rollback

### Safety Mechanisms Added
- ✅ Syntax checking after conflict resolution (Ruby/YAML/JSON)
- ✅ Dry-run mode for testing (`dry_run: true`)
- ✅ Detailed conflict logging with file previews
- ✅ Warning annotations on all conflicted files
- ✅ Manual review reminders in job summary
- ✅ Proper error handling with exit codes

### Key Differences from Original Baseline

| Feature | Baseline | This Implementation |
|---------|----------|-------------------|
| Conflict strategy | `abort`, `ours`, `theirs` | + `both` (union merge) |
| Conflict resolution | Fails on conflicts | Auto-resolves with union merge |
| Validation | None | Ruby/YAML/JSON syntax checks |
| Testing | N/A | Dry-run mode available |
| Logging | Basic | Detailed with file previews |
| Error handling | Basic | Enhanced with proper cleanup |

## File Location

**New Workflow:** `.github/workflows/curate-pre-branch-union-merge.yaml`

**Baseline (unchanged):** `.github/workflows/cherry-pick-to-pre.yaml`

## How Union Merge Works

When conflicts occur, the workflow:

1. **Detects conflicts** during cherry-pick or merge operations
2. **Extracts both sides** of each conflict using Git's internal stages:
   - `:2:filename` = "ours" (current branch)
   - `:3:filename` = "theirs" (incoming changes)
3. **Concatenates both versions** into the final file
4. **Stages the result** and continues the operation
5. **Logs details** including file paths and previews
6. **Validates syntax** of Ruby/YAML/JSON files
7. **Warns reviewers** to manually inspect the results

### Example Conflict Resolution

**Original conflict:**
```ruby
<<<<<<< HEAD
API_URL = "https://prod.example.com"
=======
API_URL = "https://staging.example.com"
>>>>>>> PR #42
```

**Union merge result:**
```ruby
API_URL = "https://prod.example.com"
API_URL = "https://staging.example.com"
```

⚠️ **This may not be semantically correct!** Manual review is required.

## Testing Plan

### Phase 1: Dry-Run Testing (SAFE)

**Test 1: No Conflicts (Baseline Behavior)**
```bash
# Workflow inputs:
destination: pre/beta/test-no-conflict
base: main
prs: <PR number with no conflicts>
mode: auto
squash: true
conflict_strategy: abort
reset_destination: true
dry_run: true  # IMPORTANT: No actual push
```

**Expected result:** Workflow completes successfully, shows git log preview

---

**Test 2: Conflicts with Abort Strategy**
```bash
# Workflow inputs:
destination: pre/beta/test-abort
base: main
prs: <PR numbers that conflict>
mode: auto
squash: true
conflict_strategy: abort  # Should fail
reset_destination: true
dry_run: true
```

**Expected result:** Workflow fails with conflict error, no changes pushed

---

**Test 3: Conflicts with Union Merge (Dry-Run)**
```bash
# Workflow inputs:
destination: pre/beta/test-union-dry
base: main
prs: <PR numbers that conflict>
mode: auto
squash: true
conflict_strategy: both  # Union merge
reset_destination: true
dry_run: true  # SAFE: preview only
```

**Expected results:**
- ✅ Workflow completes (doesn't fail)
- ✅ Shows conflict resolution log in Summary
- ✅ Lists all conflicted files
- ✅ Shows syntax validation results
- ✅ Displays warning about manual review
- ✅ Git log preview shown (no push)

---

### Phase 2: Live Testing (CREATES BRANCHES)

⚠️ **These tests create real branches. Use test branches only!**

**Test 4: Simple Conflict - Union Merge (Live)**
```bash
# Workflow inputs:
destination: pre/beta/test-union-live-simple
base: main
prs: <single PR with simple conflict>
mode: auto
squash: true
conflict_strategy: both
reset_destination: true
dry_run: false  # CAUTION: Will push!
```

**Post-test validation:**
1. Check branch was created: `git fetch && git checkout pre/beta/test-union-live-simple`
2. Inspect conflicted files manually
3. Run syntax check: `ruby -c <conflicted-file.rb>`
4. Run test suite: `bundle exec rspec`
5. Review git log: `git log --oneline -10`

---

**Test 5: Multiple PRs with Conflicts**
```bash
# Workflow inputs:
destination: pre/beta/test-union-multi
base: main
prs: <PR1>,<PR2>,<PR3>  # Multiple PRs with conflicts
mode: auto
squash: true
conflict_strategy: both
reset_destination: true
dry_run: false
```

**Post-test validation:**
1. Verify all PRs were cherry-picked: `git log --oneline --grep="#<PR>"`
2. Check conflict resolution summary in GitHub Actions UI
3. Manually review each conflicted file
4. Run full test suite
5. Look for syntax errors or duplicate code

---

**Test 6: Existing Branch Update (No Reset)**
```bash
# First run: Create base branch
destination: pre/beta/test-incremental
prs: <PR1>
reset_destination: true
dry_run: false

# Second run: Add more PRs to existing branch
destination: pre/beta/test-incremental
prs: <PR2>,<PR3>
reset_destination: false  # Keep existing commits
conflict_strategy: both
dry_run: false
```

**Post-test validation:**
1. Verify branch history preserved from first run
2. Check new PRs appended correctly
3. Verify base sync merge commit exists (if needed)

---

### Phase 3: Edge Cases

**Test 7: Conflict in Gemfile**
```bash
prs: <PR that modifies Gemfile>
conflict_strategy: both
```

**Manual check:** Ensure no duplicate gem declarations

---

**Test 8: Conflict in CHANGELOG**
```bash
prs: <PR that modifies CHANGELOG>
conflict_strategy: both
```

**Manual check:** Verify both entries preserved, no broken formatting

---

**Test 9: Conflict in Ruby Source**
```bash
prs: <PR with Ruby code conflict>
conflict_strategy: both
```

**Manual check:**
- Run `ruby -c` on affected files
- Run RSpec tests
- Look for duplicate method definitions

---

## Test Scenarios to Create

If you need to create test PRs with conflicts:

### Scenario A: Gemfile Conflict
1. Create PR #1: Add `gem 'minitest'` to Gemfile
2. Create PR #2: Add `gem 'rspec-rails'` to same line/section
3. Test union merge: Should keep both gems

### Scenario B: Config Conflict
1. Create PR #1: Set `API_URL = "https://test1.com"` in config
2. Create PR #2: Set `API_URL = "https://test2.com"`
3. Test union merge: Will have duplicate assignments (needs manual fix)

### Scenario C: Method Conflict
1. Create PR #1: Add method `def process; puts "A"; end`
2. Create PR #2: Add method `def process; puts "B"; end`
3. Test union merge: Duplicate methods (syntax error)

## Interpreting Results

### Success Indicators
- ✅ Workflow completes without errors
- ✅ All syntax checks pass
- ✅ Conflict log shows reasonable resolutions
- ✅ Manual code review confirms correctness

### Failure Indicators
- ❌ Syntax validation reports errors
- ❌ Duplicate code blocks in union merge
- ❌ Test suite fails after merge
- ❌ Logical contradictions (multiple assignments to same variable)

## What to Look For

### In GitHub Actions Logs
1. **Step: "Validate syntax after conflict resolution"**
   - Should show checks for Ruby/YAML/JSON
   - Any syntax errors will appear here

2. **Step: "Report conflict resolutions"**
   - Lists all conflicted files
   - Shows preview of merged content
   - Warning about manual review

3. **Job Summary Tab**
   - Section: "⚠️ MANUAL REVIEW REQUIRED"
   - Lists each conflicted file with preview
   - Clear warnings about potential issues

### In Git History
```bash
# After workflow runs, check the branch:
git fetch origin pre/beta/<test-branch>
git checkout pre/beta/<test-branch>

# Look for union merge commits:
git log --grep="union merge"

# Inspect specific files that had conflicts:
git log --follow -- path/to/conflicted/file.rb
git diff origin/main...HEAD -- path/to/conflicted/file.rb
```

### In Code Files
Look for these patterns indicating union merge issues:

**Duplicate assignments:**
```ruby
# Bad: Union merge kept both
config.api_url = "https://prod.com"
config.api_url = "https://staging.com"
```

**Duplicate requires/imports:**
```ruby
# Bad: Both PRs added the same require
require 'json'
require 'json'
```

**Duplicate method definitions:**
```ruby
# Bad: Syntax error
def process
  # Implementation A
end
def process
  # Implementation B
end
```

**Acceptable union merges:**
```ruby
# Good: Append-only files (CHANGELOG)
## Version 1.2.0
- Feature A

## Version 1.2.0
- Feature B

# Good: Independent additions (Gemfile)
gem 'minitest'
gem 'rspec-rails'
```

## Rollback Procedure

If union merge produces broken code:

```bash
# Option 1: Delete the test branch
git push origin --delete pre/beta/test-branch-name

# Option 2: Reset to before union merge
git checkout pre/beta/test-branch-name
git reset --hard <commit-before-merge>
git push --force-with-lease origin pre/beta/test-branch-name

# Option 3: Re-run with reset_destination=true
# This will recreate the branch from scratch
```

## Recommended Testing Workflow

1. **Start with dry-run:** Always test with `dry_run: true` first
2. **Review logs:** Check conflict resolution details
3. **Test with simple conflicts:** Single PR, simple file
4. **Graduate to complex:** Multiple PRs, code conflicts
5. **Always validate:** Run tests after each live merge
6. **Document issues:** Note which conflict types work well vs. poorly

## When to Use Union Merge

### ✅ Good Use Cases
- CHANGELOG entries (append-only)
- Gemfile additions (usually safe)
- Independent configuration additions
- Documentation files with non-overlapping changes

### ❌ Bad Use Cases
- Code conflicts (method definitions, logic)
- Configuration values (URLs, keys, settings)
- Version numbers or constants
- Anything requiring semantic understanding

## Reporting Issues

If you encounter problems:

1. **Capture the workflow run URL**
2. **Note the input parameters** (PRs, strategy, etc.)
3. **Save the conflict log** from GitHub Summary
4. **Document the incorrect merge** with before/after code
5. **Include syntax errors** if validation caught them

## Next Steps After Testing

Based on test results, decide:

1. **If union merge works well:** Consider merging to baseline workflow
2. **If issues found:** Iterate on conflict resolution logic
3. **If too risky:** Use dry-run mode only, or restrict to safe file types
4. **If validation insufficient:** Add more syntax checkers (linters, etc.)

## Questions to Answer During Testing

- [ ] Does union merge correctly concatenate both sides?
- [ ] Does syntax validation catch obvious errors?
- [ ] Are conflict logs detailed enough for review?
- [ ] Does dry-run mode work correctly?
- [ ] Can the workflow recover from errors?
- [ ] Are warnings visible enough in the UI?
- [ ] Does it handle edge cases (binary files, deletions)?
- [ ] Is the performance acceptable with many PRs?
- [ ] Would you trust this in production?

---

## Implementation Notes

### What Changed from the Broken PR Submission

**Fixed:**
1. ❌ **Incomplete script** → ✅ Full implementation of `resolve_conflicts_both()`
2. ❌ **No validation** → ✅ Syntax checking for Ruby/YAML/JSON
3. ❌ **Silent failures** → ✅ Proper error handling with exit codes
4. ❌ **No testing mode** → ✅ Dry-run capability
5. ❌ **Poor logging** → ✅ Detailed conflict previews in reports
6. ❌ **Recursive source** → ✅ Proper script structure

**Added Safety Features:**
- Syntax validation step runs after all conflict resolutions
- Dry-run mode prevents accidental pushes during testing
- Enhanced error messages with file annotations
- Conflict file previews (first 20 lines) in logs
- Clear warnings in job summary
- Proper cleanup on errors

**Still Risky:**
- Union merge fundamentally cannot understand code semantics
- Manual review is ALWAYS required after using `conflict_strategy: both`
- Test suite must run before deployment
- Some conflicts will always produce broken code

---

## Support

For questions or issues with this workflow, refer to:
- Baseline workflow: `.github/workflows/cherry-pick-to-pre.yaml`
- Assessment document: (your CTO review notes)
- This guide: `UNION_MERGE_TESTING_GUIDE.md`
