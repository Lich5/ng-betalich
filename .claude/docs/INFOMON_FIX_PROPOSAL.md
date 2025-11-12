# Infomon Test Pollution Fix - PROPOSAL FOR REVIEW

**Date:** 2025-11-09
**Status:** Proposal (Awaiting Product Owner Decision)
**Session:** 011CUwNHp9TzigghtU94X9aZ

---

## Problem Statement

**File:** `spec/infomon_spec.rb:17-21`

**Current Code:**
```ruby
class NilClass
  def method_missing(*)
    nil
  end
end
```

**Issue:**
This monkey-patch is applied **globally** at spec file load time, polluting all subsequent tests in the full suite run.

**Impact:**
- `master_password_manager_spec.rb` fails 2/16 tests when run after `infomon_spec.rb`
- Tests pass when run independently
- Error: `TypeError: wrong argument type nil (expected Process::Status)`
- Affects `system()` calls in keychain availability checks

**Root Cause:**
The `NilClass#method_missing` override causes `$?.success?` to return `nil` instead of boolean after `system()` calls, breaking conditional logic.

---

## Proposed Solution

**Isolate monkey-patch to infomon_spec.rb scope only:**

```ruby
# spec/infomon_spec.rb - UPDATED

RSpec.describe 'Infomon' do
  # Store original method_missing if it exists
  before(:all) do
    @original_method_missing = if NilClass.method_defined?(:method_missing)
                                  NilClass.instance_method(:method_missing)
                                else
                                  nil
                                end

    # Apply monkey-patch ONLY for this spec
    NilClass.class_eval do
      def method_missing(*)
        nil
      end
    end
  end

  # Restore original behavior after this spec completes
  after(:all) do
    NilClass.class_eval do
      # Remove the monkey-patch
      remove_method(:method_missing) if method_defined?(:method_missing)

      # Restore original if it existed
      if @original_method_missing
        define_method(:method_missing, @original_method_missing)
      end
    end
  end

  # ... existing infomon tests remain unchanged ...
end
```

---

## How This Works

1. **Before tests:** Capture original `NilClass#method_missing` (if exists)
2. **During tests:** Apply monkey-patch for infomon tests only
3. **After tests:** Remove monkey-patch and restore original behavior
4. **Result:** Subsequent tests see clean `NilClass` behavior

---

## Verification

**Test sequence that currently fails:**
```bash
bundle exec rspec spec/infomon_spec.rb spec/master_password_manager_spec.rb
```

**After fix, this should pass:**
```bash
bundle exec rspec spec/infomon_spec.rb spec/master_password_manager_spec.rb
# Expected: 0 failures
```

**Full suite should also pass:**
```bash
bundle exec rspec
# Expected: 380/380 passing
```

---

## Alternative Approach (If Above Doesn't Work)

**Use `around(:each)` hook for per-test isolation:**

```ruby
RSpec.describe 'Infomon' do
  around(:each) do |example|
    # Store original
    original = if NilClass.method_defined?(:method_missing)
                 NilClass.instance_method(:method_missing)
               else
                 nil
               end

    # Apply patch
    NilClass.class_eval do
      def method_missing(*)
        nil
      end
    end

    # Run test
    example.run

    # Restore
    NilClass.class_eval do
      remove_method(:method_missing) if method_defined?(:method_missing)
      define_method(:method_missing, original) if original
    end
  end

  # ... tests ...
end
```

This applies/removes the patch **per test** instead of per suite, providing even stronger isolation.

---

## Why This Matters

**For Beta Release:**
- Full test suite must pass cleanly (380/380)
- Environmental test failures are unacceptable for production
- This fix enables confident test suite execution

**For Development:**
- Developers can run full suite without random failures
- Test execution order won't matter
- Easier debugging (no pollution side effects)

---

## Recommendation

**Product Owner should:**
1. Review this proposed solution
2. Decide: Assign to original developer OR create work unit for CLI Claude
3. If assigning to original developer, provide this document as reference

**If approved for CLI Claude:**
- Work unit can be created with this fix
- Estimated effort: 30 minutes
- Can be bundled with STANDARD_EXTRACTION_CURRENT.md

---

## Context

**Original Implementation:**
- Created by senior developer
- Purpose: Allow infomon tests to call methods on nil objects without errors
- Likely emulates game server behavior (loose typing)

**Why It Needs Isolation:**
- Ruby monkey-patches are global by default
- RSpec loads all specs into single Ruby process
- Pollution is inevitable without explicit cleanup

---

**Status:** Awaiting Product Owner decision on assignment

**References:**
- `spec/infomon_spec.rb:17-21` (current implementation)
- `spec/master_password_manager_spec.rb` (affected tests)
- AUDIT_PR38_CORRECTED.md (documented issue)
