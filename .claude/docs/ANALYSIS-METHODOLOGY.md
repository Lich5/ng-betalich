# Code Analysis Methodology & Quality Gates

**Purpose:** Ensure accurate, verifiable code analysis with traceable citations

**Created:** 2025-10-29 (after lessons learned from Release Workflow analysis)

**Scope:** All future code analysis, security reviews, architectural evaluations

---

## Core Principles

### 1. **Verification Before Publication**
Every factual claim about code must be verifiable against the actual codebase.

- ❌ PROHIBITED: "Line 150 does X" without checking that line 150 actually contains X
- ✅ REQUIRED: Grep/verify the claim exists before citing it

### 2. **No Optimization Against Accuracy**
Don't trade accuracy for speed or token savings.

- ❌ PROHIBITED: Read files in fragments (`limit` parameter) to save tokens if it causes confusion
- ✅ REQUIRED: Read full files end-to-end, even if longer

### 3. **Explicit Uncertainty**
Flag uncertain items with confidence levels rather than stating as fact.

- ❌ PROHIBITED: "Issue found at line 150" when line numbers are unclear
- ✅ REQUIRED: "Possible issue (high confidence)" or "Uncertain issue (needs verification)"

### 4. **Traceable Citations**
Every code reference must be traceable: file + line number + code snippet.

- ❌ PROHIBITED: "cherry-pick workflow has a git push issue"
- ✅ REQUIRED: "prepare-stable-release.yaml:150 - `git push -u origin "$backup"`"

---

## Audit Checklist (Use This for Every Code Analysis)

### Phase 1: Information Gathering
- [ ] List all files to be analyzed
- [ ] Read each file completely (no `limit` parameter unless absolutely necessary)
- [ ] Note file sizes and complexity
- [ ] Identify dependencies between files

### Phase 2: Initial Analysis
- [ ] Document initial observations (architecture, patterns, potential issues)
- [ ] Create hypothesis list (issues to investigate)
- [ ] Mark confidence level for each hypothesis (high/medium/low)

### Phase 3: Verification (Critical Step)
For **every** claimed issue:

- [ ] Use `grep -n` to locate the exact code
- [ ] Verify line numbers in claim match actual file
- [ ] Extract code snippet and include in citation
- [ ] Test claim against actual code (does it really exist? is severity accurate?)
- [ ] Document verification result (confirmed/false positive/needs clarification)

### Phase 4: Severity Assessment
For each confirmed issue:

- [ ] Rate severity independently (before checking my initial rating)
- [ ] Consider actual impact vs. theoretical risk
- [ ] Check if existing guards/mitigations exist
- [ ] Update severity if different from initial assessment

### Phase 5: Documentation
- [ ] Write findings with verified citations only
- [ ] Include code snippets (not just line numbers)
- [ ] Flag any remaining uncertainties
- [ ] Provide evidence for each claim

### Phase 6: Quality Gate
- [ ] All line numbers verified with grep
- [ ] All file names verified with grep
- [ ] All code snippets extracted and shown
- [ ] Severity ratings justified by code evidence
- [ ] No false positives included

---

## Specific Rules for Citation

### Rule 1: Always Include Code Snippet
❌ **Bad:** "Line 150 has a git push issue"

✅ **Good:** "Line 150: `git push -u origin "$backup"` — lacks --force-with-lease for force-created branch"

### Rule 2: Verify File Names with Grep
Before citing a file location, grep for the exact pattern:

```bash
# Example: verify Issue #1 location
grep -rn "git push.*origin.*backup" .github/workflows/
# Output: prepare-stable-release.yaml:150:...

# This proves the file name
```

### Rule 3: Verify Line Numbers Exist
After making a citation, verify:

```bash
# Check that line 150 of prepare-stable-release.yaml contains our code
sed -n '150p' .github/workflows/prepare-stable-release.yaml
# Should output: git push -u origin "$backup"
```

### Rule 4: Check Context (+/- 5 Lines)
Show surrounding context to ensure the code snippet isn't misleading:

```bash
sed -n '148,152p' .github/workflows/prepare-stable-release.yaml
```

### Rule 5: Search for All Instances
If claiming "a pattern appears in file X", grep to ensure:
- You found ALL instances
- You're not missing related code elsewhere

```bash
# If claiming "Release-As seeding not idempotent", grep for ALL Release-As mentions:
grep -rn "Release-As" .github/workflows/
# Make sure you found every place it's mentioned
```

---

## Confidence Levels

Every issue must be rated:

### 🟢 High Confidence (90-100%)
- Code pattern verified with grep
- Line numbers confirmed
- Issue reproduced/tested
- Context checked
- No ambiguity in code

### 🟡 Medium Confidence (60-89%)
- Code pattern found
- Context suggests issue
- But some detail unverified
- Needs validation before fixing

### 🔴 Low Confidence (0-59%)
- Pattern suspected
- But unverified
- Should be labeled "Uncertain"
- Requires explicit validation before action

---

## False Positive Prevention Checklist

Before publishing an issue, ask:

- [ ] Does this code pattern actually exist? (grep verified?)
- [ ] Are line numbers correct? (sed verified?)
- [ ] Is my interpretation correct? (read context?)
- [ ] Do existing guards make this a non-issue? (checked?)
- [ ] Is severity justified? (found actual risk or just theoretical?)
- [ ] Could this be a false alarm? (what would prove it wrong?)

**If you can't confidently answer all questions, mark as uncertain.**

---

## When to Skip Verification (Rare Cases)

Only skip detailed verification for:

1. **Well-known patterns** (e.g., "YAML syntax is valid" — can validate with linter)
2. **Trivial issues** (e.g., spelling errors — can grep)
3. **Already-fixed issues** (user confirmed it's been addressed)

**Never skip verification for:**
- Security issues
- Data loss risks
- Architecture recommendations
- Suggested code changes

---

## Template: How to Cite Code Issues

Use this template for all future analysis:

```
### Issue #X: [Title]

**File:** [Filename]
**Location:** Line(s) [start]-[end]
**Confidence:** [High/Medium/Low]

**Code:**
\`\`\`bash/yaml/javascript
[ACTUAL CODE FROM FILE]
\`\`\`

**Context:**
[Lines -5 to +5 from the issue]

**Claim:**
[What the issue is]

**Verification:**
- [x] Code snippet verified with grep: `grep -n "pattern" file`
- [x] Line numbers verified: line 150 contains "..."
- [x] Context confirms interpretation
- [x] Severity justified by code evidence

**Risk:**
[Specific risk with code evidence]

**Recommended Fix:**
[Concrete fix with code example]

**Effort:** [Low/Medium/High] | **Risk Reduction:** [Percentage/description]
```

---

## What Changed (Lessons Learned)

### Before (Caused Issues)
- Read files in fragments with `limit` parameter
- Didn't grep to verify citations
- Cited line numbers without checking
- Over-stated severity without evidence
- Treated pattern analysis as sufficient

### After (Quality Gates)
- Read files completely, no artificial limits
- Grep verification BEFORE writing citations
- Include actual code snippets, not just line numbers
- Justify severity with code evidence
- Require explicit verification of every claim

---

## Future Audits: Step-by-Step Process

1. **Create hypothesis list** with confidence levels
2. **Grep search** for each pattern
3. **Extract code** from actual files
4. **Verify context** (surrounding lines)
5. **Test claim** against real code
6. **Re-rate severity** based on evidence
7. **Document** with citations
8. **Quality gate check** before publishing

---

## Where This Is Used

This methodology is now:
- **Stored in:** `.claude/ANALYSIS-METHODOLOGY.md`
- **Applied to:** All future code analysis tasks
- **Enforced by:** Quality gate checklist above
- **Can be overridden by:** Explicit user instruction only

**Usage in Claude Code:**
```
Before analyzing code, reference: .claude/ANALYSIS-METHODOLOGY.md
Apply the audit checklist from Phase 1-6
Verify every citation before including in output
Use the template for all issues/findings
```

---

## Exceptions & Overrides

This methodology applies unless you explicitly say:
- "Speed over accuracy" (acknowledge the tradeoff)
- "Best-effort only" (flag uncertainty)
- "Broad assessment OK" (don't need detailed verification)

**Default:** Full methodology applies. You must explicitly override if different.

---

## Q&A for Future Reference

**Q: "Isn't verification slow?"**
A: Yes, ~10-20% slower. But accuracy > speed for code analysis.

**Q: "What if I want a quick assessment?"**
A: Say "best-effort analysis, flag uncertainty" and I'll note confidence levels clearly.

**Q: "What if the repo is huge?"**
A: Still verify key claims with grep. Sampling acceptable for "possible issues" (marked uncertain).

**Q: "Can I override this?"**
A: Yes, explicitly say "skip full verification" but I'll flag items as unverified.

**Q: "Where is this stored?"**
A: `.claude/ANALYSIS-METHODOLOGY.md` — check it before starting new analysis.

