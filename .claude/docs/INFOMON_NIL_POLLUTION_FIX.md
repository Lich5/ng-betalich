# Infomon NilClass Pollution Fix Proposal

**Date:** 2025-11-08
**Issue:** Global monkey-patch in infomon_spec.rb pollutes subsequent tests
**Impact:** master_password_manager_spec.rb fails 2/16 tests in full suite runs
**Priority:** MEDIUM (test reliability, not production code)

---

## PROBLEM

**File:** `spec/infomon_spec.rb:17-21`

**Current Code:**
```ruby
class NilClass
  def method_missing(*)
    nil
  end
end
```

**What it does:**
- Globally monkey-patches `NilClass` to return `nil` for any unknown method
- Intended to make infomon tests more forgiving of nil values
- Persists across all subsequent tests in the suite

**Impact:**
- When `master_password_manager_spec.rb` runs after `infomon_spec.rb`:
  - `system()` calls in keychain availability checks fail
  - `system()` normally returns `Process::Status` or `true`/`false`
  - With pollution, `system()` can return `nil` in edge cases
  - Error: `TypeError: wrong argument type nil (expected Process::Status)`
- 2/16 tests fail in full suite, but pass when run independently

**Evidence:**
```bash
# Run independently - all pass
bundle exec rspec spec/master_password_manager_spec.rb
# => 16 examples, 0 failures

# Run after infomon - failures occur
bundle exec rspec spec/infomon_spec.rb spec/master_password_manager_spec.rb
# => 2 failures with TypeError
```

---

## ROOT CAUSE ANALYSIS

**Why the monkey-patch exists:**
- Infomon tests deal with complex XML parsing and game data structures
- Many optional fields can be nil
- Monkey-patch allows code like `obj.foo.bar.baz` to return nil instead of crashing
- Similar to Rails' `try` or `&.` safe navigation

**Why it causes problems:**
- RSpec runs specs in alphabetical order by default
- `infomon_spec.rb` runs before `master_password_manager_spec.rb`
- Monkey-patch is global and permanent
- Other specs don't expect `NilClass#method_missing` behavior

**Specific failure mechanism:**
```ruby
# In master_password_manager.rb:149
system('which secret-tool >/dev/null 2>&1')

# Expected: returns true/false/Process::Status
# With pollution: can return nil in certain conditions
# Causes: TypeError when code expects boolean/status
```

---

## PROPOSED SOLUTION

**Option 1: Isolate with RSpec Hooks (Recommended)**

```ruby
# spec/infomon_spec.rb

# Store original method_missing if it exists
$_original_nil_method_missing = NilClass.instance_method(:method_missing) rescue nil

RSpec.describe Lich::Gemstone::Infomon::XMLParser, ".parse" do
  before(:all) do
    # Apply monkey-patch only for these tests
    NilClass.class_eval do
      def method_missing(*)
        nil
      end
    end
  end

  after(:all) do
    # Restore original behavior
    NilClass.class_eval do
      # Remove the method we added
      remove_method :method_missing

      # Restore original if it existed
      if $_original_nil_method_missing
        define_method :method_missing, $_original_nil_method_missing
      end
    end
  end

  # ... existing tests ...
end
```

**Pros:**
- Isolates pollution to infomon tests only
- Allows infomon tests to keep their forgiving behavior
- Fixes master_password_manager test failures
- No changes needed to other specs

**Cons:**
- Slightly more complex setup
- Requires understanding of RSpec hooks

---

**Option 2: Remove Monkey-Patch, Fix Tests (More Work)**

```ruby
# Remove lines 17-21 from spec/infomon_spec.rb
# Update infomon tests to handle nil explicitly:

# Instead of:
expect(obj.foo.bar.baz).to be_something

# Use:
expect(obj&.foo&.bar&.baz).to be_something
# OR
expect(obj.try(:foo).try(:bar).try(:baz)).to be_something
```

**Pros:**
- Cleaner, no monkey-patching
- Tests more explicit about nil handling

**Cons:**
- Requires reviewing/updating many infomon tests
- More invasive change
- May break more tests initially

---

**Option 3: Stub system() in master_password_manager_spec (Workaround)**

```ruby
# In spec/master_password_manager_spec.rb
before do
  # Ensure system() always returns boolean
  allow_any_instance_of(Object).to receive(:system).and_wrap_original do |method, *args|
    result = method.call(*args)
    result.nil? ? false : result
  end
end
```

**Pros:**
- Minimal change to master_password_manager tests
- Doesn't touch infomon tests

**Cons:**
- Treats symptom, not cause
- Other specs might have similar issues
- Doesn't prevent future pollution problems

---

## RECOMMENDATION

**Recommended Approach:** Option 1 (Isolate with RSpec Hooks)

**Rationale:**
1. Least invasive - preserves infomon test behavior
2. Fixes pollution for all subsequent tests
3. Standard RSpec pattern for test isolation
4. Senior developer's infomon implementation stays intact
5. Clear intent: "this monkey-patch is for infomon only"

**Implementation Effort:** 15-30 minutes

**Risk:** LOW
- Well-understood RSpec pattern
- Easy to verify with test runs
- Can be reverted if issues arise

---

## TESTING VERIFICATION

**After implementing fix, verify:**

```bash
# Full suite should pass
bundle exec rspec
# => 380 examples, 0 failures

# Infomon tests should still pass
bundle exec rspec spec/infomon_spec.rb
# => All examples pass

# Master password manager tests should pass
bundle exec rspec spec/master_password_manager_spec.rb
# => 16 examples, 0 failures

# Run in sequence (alphabetical) to verify no pollution
bundle exec rspec spec/infomon_spec.rb spec/master_password_manager_spec.rb
# => All examples pass, no TypeError
```

---

## DISCUSSION POINTS FOR SENIOR DEVELOPER

**Questions to clarify:**

1. **Intent:** Was the global monkey-patch intentional, or was test isolation forgotten?

2. **Infomon Needs:** Do infomon tests require this forgiving nil behavior? Could safe navigation (`&.`) be used instead?

3. **Scope:** Should the monkey-patch be:
   - A. Isolated to infomon tests only (recommended)
   - B. Removed entirely and tests updated
   - C. Left as-is with other specs working around it

4. **Alternatives:** Would using a helper method or custom matcher be cleaner?
   ```ruby
   def safe_get(obj, *methods)
     methods.reduce(obj) { |o, m| o&.send(m) }
   end

   expect(safe_get(obj, :foo, :bar, :baz)).to be_something
   ```

**Suggested Conversation Starter:**
> "We've identified that the NilClass monkey-patch in infomon_spec.rb (lines 17-21) is causing test pollution. Master password manager tests fail when run after infomon tests. We'd like to isolate this monkey-patch to infomon tests only using RSpec before/after hooks. This preserves your test behavior while preventing pollution. Thoughts?"

---

## IMPLEMENTATION CHECKLIST

If approved:

- [ ] Implement Option 1 (RSpec hook isolation)
- [ ] Test infomon_spec.rb independently
- [ ] Test master_password_manager_spec.rb independently
- [ ] Test full suite run
- [ ] Test alphabetical sequence (infomon → master_password_manager)
- [ ] Verify 380/380 tests pass
- [ ] Commit with message: `chore(all): isolate NilClass monkey-patch to infomon tests`
- [ ] Document decision in ADR if needed

**Estimated Time:** 30 minutes including testing

---

**END OF PROPOSAL**
