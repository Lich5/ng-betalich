# Performance Validation Approach - NFR-1

**Project:** Lich 5 Password Encryption Feature
**Requirement:** NFR-1 - Performance
**Document Purpose:** Define how to validate that performance requirements are met before beta release
**Last Updated:** 2025-11-23

---

## NFR-1: Performance Requirements

**BRD Specification:**
```
- Encryption/Decryption: < 100ms per password
- File Load: < 500ms for 100 accounts
- Mode Change: < 5 seconds for re-encrypting 100 passwords
```

**Current Status:** ⚠️ UNVALIDATED
- Theory suggests compliance (~5-10ms per password based on ADR-009)
- Requires formal benchmarking before beta release approval
- Critical for user experience validation

---

## Performance Validation Plan

### Phase 1: Benchmark Development

**Goal:** Create RSpec benchmark suite to measure actual performance

**Files to Create:**
- `spec/benchmarks/password_cipher_performance_spec.rb`
- `spec/benchmarks/yaml_state_performance_spec.rb`
- `spec/benchmarks/encryption_mode_change_performance_spec.rb`

**Dependencies:**
- Ruby's `Benchmark` module (standard library)
- RSpec with optional `benchmark_it` syntax
- Sample data: 10, 50, 100 account scenarios

**Approach:** Use RSpec examples with timing assertions

```ruby
# spec/benchmarks/password_cipher_performance_spec.rb
describe "PasswordCipher performance", type: :benchmark do
  describe "#encrypt" do
    it "encrypts a password in < 10ms (10k iterations)" do
      password = "SecurePassword123"
      account_name = "ACCOUNT"

      time = Benchmark.measure { 100.times { PasswordCipher.encrypt(password, mode: :standard) } }
      avg_time_ms = (time.real * 1000) / 100

      expect(avg_time_ms).to be < 10  # ~5ms expected
    end
  end

  describe "#decrypt" do
    it "decrypts a password in < 10ms" do
      encrypted = PasswordCipher.encrypt("password", mode: :standard)

      time = Benchmark.measure { 100.times { PasswordCipher.decrypt(encrypted, :standard) } }
      avg_time_ms = (time.real * 1000) / 100

      expect(avg_time_ms).to be < 10
    end
  end
end
```

---

### Phase 2: File-Level Performance Tests

**Goal:** Validate full workflow performance (load, save, re-encrypt)

**Benchmark Scenarios:**

#### Scenario A: File Load (< 500ms for 100 accounts)
```ruby
describe "YamlState performance" do
  it "loads 100 accounts in < 500ms" do
    # Create test YAML with 100 encrypted accounts
    test_data = create_test_yaml_with_accounts(100)

    time = Benchmark.measure do
      YamlState.load_entries(test_data)
    end

    expect(time.real * 1000).to be < 500
  end
end
```

#### Scenario B: Mode Change (< 5 seconds for 100 accounts)
```ruby
describe "Encryption mode change performance" do
  it "re-encrypts 100 accounts in < 5 seconds" do
    accounts = create_test_accounts(100)
    data_dir = create_temp_dir_with_yaml(accounts)

    time = Benchmark.measure do
      YamlState.change_encryption_mode(data_dir, :enhanced, master_password: "test")
    end

    expect(time.real).to be < 5
  end
end
```

---

### Phase 3: RSpec Integration

**Test Execution Approach:**

```bash
# Run performance benchmarks as part of full suite
bundle exec rspec spec/benchmarks/ --tag performance

# Report format (standard RSpec output + elapsed times)
# PasswordCipher performance
#   #encrypt
#     encrypts a password in < 10ms (10k iterations) (12.34 ms)
#   #decrypt
#     decrypts a password in < 10ms (10.56 ms)
```

**Pass Criteria:**
- ✅ Encryption/Decryption: All examples < 10ms per operation
- ✅ File Load: 100 accounts loaded in < 500ms
- ✅ Mode Change: 100 accounts re-encrypted in < 5 seconds
- ✅ 0 RuboCop offenses in benchmark code

---

### Phase 4: Hardware Variance Testing

**Problem:** Performance varies by machine (developer laptop vs CI server vs user machine)

**Solution: Capture Baseline & Allow Reasonable Range**

```ruby
# Adjust expectations for test environment
# Rule: Allow 2x slowdown from theoretical performance

describe "PasswordCipher performance" do
  let(:performance_multiplier) { ENV.fetch("PERF_MULTIPLIER", "1").to_f }

  it "encrypts a password efficiently" do
    avg_time_ms = benchmark_encrypt(100)
    theoretical_max = 10 * performance_multiplier

    expect(avg_time_ms).to be < theoretical_max
  end
end

# Run with:
# PERF_MULTIPLIER=2 bundle exec rspec spec/benchmarks/
```

---

### Phase 5: Continuous Integration

**CI Pipeline Configuration:**

```yaml
# .github/workflows/performance.yml (conceptual)
name: Performance Validation

on: [push, pull_request]

jobs:
  benchmark:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: ruby/setup-ruby@v1
      - run: bundle install
      - run: bundle exec rspec spec/benchmarks/ --format progress
      - name: Report Performance Results
        if: always()
        run: |
          echo "Performance Test Results:"
          bundle exec rspec spec/benchmarks/ --format json > perf-results.json
          # Compare against baseline if available
```

---

## Expected Results (Theory)

Based on ADR-009 analysis:

| Operation | Target | Expected | Multiplier | Max CI Bound |
|-----------|--------|----------|-----------|--------------|
| Encrypt (10k iter) | < 10ms | ~5ms | 2x | 10ms |
| Decrypt (10k iter) | < 10ms | ~5ms | 2x | 10ms |
| Load 100 accounts | < 500ms | ~200ms | 2x | 400ms |
| Re-encrypt 100 (10k→10k) | < 5s | ~0.5s | 2x | 1s |

---

## Acceptance Criteria

**Beta Release Gate:**
All of the following must be true:

1. ✅ **Encrypt/Decrypt:** < 10ms per password (averaged over 100 operations)
2. ✅ **File Load:** < 500ms for 100 accounts
3. ✅ **Mode Change:** < 5 seconds for 100 passwords
4. ✅ **Test Pass Rate:** 100% (all performance benchmarks green)
5. ✅ **Code Quality:** 0 RuboCop offenses in benchmark code
6. ✅ **Regression:** No performance degradation vs baseline

**If any benchmark fails:**
- Investigate bottleneck (profile code)
- Document issue in GitHub issue
- Decide: Fix or adjust expectations (with Product Owner approval)
- Re-run before beta approval

---

## Tools & Libraries

### Built-in (Already Available)
- `Benchmark` - Ruby standard library for timing
- `RSpec` - Test framework (already in use)
- `Time` - Precise timing via `Time.now`

### Optional (If Needed)
- `benchmark-ips` - Gem for iterations/second benchmarking (adds precision)
- `flamegraph` - For CPU profiling if bottleneck found
- `memory_profiler` - For memory usage analysis (optional)

**Recommendation:** Use only `Benchmark` + `RSpec` (no additional gems, keep it simple)

---

## Troubleshooting

### If Benchmarks Fail

**Common Issues & Solutions:**

| Symptom | Probable Cause | Solution |
|---------|--------------|----------|
| Encrypt/Decrypt > 10ms | CPU-heavy operation expected, increase multiplier | Use `PERF_MULTIPLIER=2` or increase assertion threshold |
| Load > 500ms | Disk I/O or YAML parsing slow | Profile with `Benchmark` blocks around individual steps |
| Mode Change > 5s | Re-encryption loop efficiency | Analyze with `flamegraph` (optional) |
| Inconsistent results | System load/thermal throttling | Run multiple times, report average |

---

## Success Criteria for "Ready for Beta"

**✅ Performance Validation Complete** when:
1. All benchmark RSpec examples run successfully
2. All timing assertions pass (or expectations adjusted with justification)
3. Results documented in commit message
4. Product Owner acknowledges performance is acceptable

**Example commit message:**
```
chore(all): Validate NFR-1 performance requirements

Performance benchmarks confirm all requirements met:
- Encrypt/Decrypt: 5-8ms (< 10ms target) ✅
- File load (100 accounts): 150-200ms (< 500ms target) ✅
- Mode change (100 accounts): 0.8-1.2s (< 5s target) ✅

All 603 tests passing, 0 RuboCop offenses.
Ready for beta release.
```

---

## References

- **BRD:** `BRD_Password_Encryption.md` (NFR-1, lines 525-529)
- **ADR-009:** Performance trade-off justification (10k vs 100k PBKDF2 iterations)
- **Test Framework:** RSpec 3.13+
- **Ruby:** 3.1+ (Benchmark module standard)

---

**Status:** Ready to implement
**Effort:** 4-6 hours (create benchmarks, run tests, document results)
**Timeline:** Can be completed in parallel with other beta prep work
**Blocker:** No - performance validation is final gate before beta release

