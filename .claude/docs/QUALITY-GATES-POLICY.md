# Quality Gates Policy for Code Analysis

**Established:** 2025-10-29 (after Release Workflow Audit)
**Applies To:** All future code analysis, security reviews, architectural evaluations
**Authority:** This policy overrides generic best practices unless explicitly overridden by the user

---

## The Problem We're Solving

Previous analysis of release-please workflows had **~30-40% accuracy issues**:
- Wrong file names cited (cherry-pick vs prepare-stable)
- Wrong line numbers cited without verification
- False positives included in findings
- Severity overstated without evidence

**Root causes:**
1. Fragmented file reads (using `limit` parameter)
2. No verification of citations before publishing
3. Pattern analysis treated as sufficient
4. No separation between "analysis" and "verification" phases

**Solution:** Mandatory quality gates before any analysis is published.

---

## Core Quality Gates (Non-Negotiable)

### Gate 1: File Reads Must Be Complete

**Rule:** Read entire file end-to-end. Do NOT use `limit` parameter unless file >5000 lines.

**Why:** Fragmented reads cause confusion about line numbers and context.

**Verification:**
- Bash: `wc -l filename` to confirm total lines
- If file >5000 lines, use `limit: 2500` and two reads, not partial reads
- Document total file size in audit report

**Exception:** User says "best-effort only" or "speed over accuracy"

---

### Gate 2: Every Citation Must Be Verified with Grep

**Rule:** Before writing "Issue at line X in file Y", run grep to confirm.

**Why:** Line numbers drift between reads. Regex searches can fail to find the issue.

**Verification Checklist:**
```bash
# For every claimed finding:
grep -n "PATTERN" filename  # Find the exact line
sed -n 'X,Yp' filename      # Extract context (±5 lines)
# Confirm: Does the code match your description?
```

**Example (GOOD):**
```
Issue #3: Backup branch push (prepare-stable-release.yaml:150)

Verification:
$ grep -n "git push.*origin.*backup" .github/workflows/prepare-stable-release.yaml
150:          git push -u origin "$backup"

$ sed -n '148,152p' .github/workflows/prepare-stable-release.yaml
          # create new backup branch from current HEAD
          git branch -f "$backup"
          git push -u origin "$backup"

Status: CONFIRMED ✅
```

**Example (BAD):**
```
Issue #5: Error handling missing (prepare-stable-release.yaml:68)

No verification run.

Status: UNCONFIRMED ❌ [Later found to be FALSE POSITIVE]
```

---

### Gate 3: Include Code Snippets, Not Just Line Numbers

**Rule:** Every citation includes actual code from the file.

**Why:** Line numbers can be wrong; code snippet proves it

**Format:**
```
**File:** filename.yaml
**Location:** Line X
**Code:**
\`\`\`bash
actual code here
\`\`\`
```

---

### Gate 4: Confidence Rating Required

**Rule:** Every finding must have confidence: HIGH/MEDIUM/LOW

**Calibration:**

🟢 **HIGH (90-100%)**
- Code pattern verified with grep
- Line numbers confirmed with sed
- Full context checked
- No ambiguity in interpretation
- Issue reproduced/tested

🟡 **MEDIUM (60-89%)**
- Code pattern found
- Context suggests issue exists
- Some detail unverified
- Needs validation before fixing
- Likely real but details uncertain

🔴 **LOW (0-59%)**
- Pattern suspected
- But unverified
- Must be labeled "Uncertain"
- Requires explicit user confirmation before action

**Default:** MEDIUM unless you have HIGH confidence

---

### Gate 5: Severity Justified by Code Evidence

**Rule:** Don't rate severity without code evidence.

**Why:** "This could be bad in theory" ≠ "This IS bad"

**Before:**
```
🔴 CRITICAL: Git push without force-check

Risk: Could push wrong code
Severity: Critical (security issue)
```

**After:**
```
🟠 HIGH: Backup branch push without force-with-lease

Code: Line 150 `git push -u origin "$backup"`
Backup created with: `git branch -f "$backup"` (Line 149)
Issue: Non-force push on force-created branch may fail

Risk: Visible failure (not silent), backup only (not critical path)
Severity: HIGH (reliability), reduced to MEDIUM/LOW after context
```

---

### Gate 6: Check for Existing Mitigations

**Rule:** Before claiming an issue, verify no guards/mitigations exist.

**Why:** Many "issues" are actually already protected.

**Checklist:**
- [ ] Is there a guard clause that prevents this?
- [ ] Is there a concurrency lock that mitigates this?
- [ ] Is there error handling that catches this?
- [ ] Is there validation that makes this impossible?

**Example:**
```
BEFORE: "Race condition on concurrent runs"
AFTER: "Race condition exists BUT concurrency group + cancel-in-progress mitigates it. Risk: LOW"
```

---

### Gate 7: Separate "Found Code" from "Issue Exists"

**Rule:** Finding code ≠ Finding an issue.

**Why:** Just because code exists doesn't mean it's wrong.

**Pattern:**
1. **Verification:** "grep found pattern X at line Y" → FACTUAL
2. **Analysis:** "Pattern X is problematic because Z" → OPINION, needs justification
3. **Confidence:** Rate confidence of your analysis, not just grep success

---

## Verification Process (Before Publishing)

Use this checklist for EVERY analysis you publish:

### Phase 1: Setup
- [ ] List all files to analyze
- [ ] Read each file completely (no limits)
- [ ] Note file sizes and dependencies

### Phase 2: Analysis
- [ ] Create hypothesis list for potential issues
- [ ] Mark confidence (HIGH/MEDIUM/LOW) for each hypothesis
- [ ] Note any uncertainties upfront

### Phase 3: Verification (CRITICAL)
For **each** claimed issue:
- [ ] Use grep to locate exact code
- [ ] Verify line numbers with sed
- [ ] Extract code snippet
- [ ] Check ±5 context lines
- [ ] Test claim against real code
- [ ] Document verification results

### Phase 4: Severity Assessment
For **each** confirmed issue:
- [ ] Rate severity independently (before checking your initial rating)
- [ ] Consider actual impact vs. theoretical risk
- [ ] Check for existing guards/mitigations
- [ ] Update severity if different from initial

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
- [ ] Confidence ratings assigned

**If you cannot pass all gates, don't publish. Flag as incomplete.**

---

## What Counts as "Verification"

### ✅ SUFFICIENT Verification
```bash
grep -n "pattern" file         # Find exact line
sed -n 'X,Yp' file             # Show context
# Manually inspect: does code match claim?
→ CONFIRMED
```

### ❌ INSUFFICIENT Verification
```
"I read the file earlier and I think line 150 has..."
→ NOT VERIFIED

"The code should have this issue based on logic"
→ THEORY, not verification
```

---

## Exception: When to Skip Full Verification

Only skip detailed verification for:

1. **Well-known patterns** → Can validate with linter/tool
   - Example: "YAML syntax is invalid" → Run yamllint
   - Example: "Shell script has syntax error" → Run bash -n

2. **Trivial issues** → Can grep to confirm quickly
   - Example: "Typo in variable name" → grep for exact typo
   - Example: "URL is wrong" → grep for URL

3. **User-confirmed issues** → User already verified
   - Example: "You said this is broken" → Trust user, no need to verify

**NEVER skip verification for:**
- Security issues
- Data loss risks
- Architecture recommendations
- Suggested code changes
- Severity assessments

---

## Template for Citing Issues

Use this format for all future analyses:

```markdown
### Issue #X: [Short Title]

**File:** path/to/file.yaml
**Location:** Line(s) X-Y
**Confidence:** [HIGH/MEDIUM/LOW]

**Code:**
\`\`\`bash
[ACTUAL CODE FROM FILE]
\`\`\`

**Context:**
[Lines -5 to +5]

**Verification:**
- [x] Code verified with grep: `grep -n "pattern" file` → Line X
- [x] Line numbers confirmed: Line X contains "..."
- [x] Context checked: surrounding code confirms interpretation
- [x] Existing guards reviewed: [Found/Not found]

**Issue Description:**
[What the problem is]

**Risk:**
[Specific risk, with code evidence]

**Recommended Fix:**
[Concrete fix with code example]

**Effort:** [Low/Medium/High] | **Risk Reduction:** [Percentage/description]
```

---

## How This Is Used Going Forward

### When Starting New Analysis
1. **Read this file:** `.claude/QUALITY-GATES-POLICY.md`
2. **Follow methodology:** Apply Phases 1-6 from "Verification Process"
3. **Use template:** Format all findings using the template
4. **Quality gate:** Run the checklist before publishing

### When the User Says...

**"I need a quick assessment"**
→ You say: "Speed or accuracy? If speed, I'll flag uncertainty clearly"

**"I need full analysis"**
→ Apply full quality gates (Phases 1-6). No shortcuts.

**"Don't worry about accuracy, just ideas"**
→ Explicitly mark as "unverified ideas" with CONFIDENCE: LOW
→ Never present as findings

**"I need this verified"**
→ Mandatory Gates 1-7. Full template. High confidence required.

---

## Violations & Remediation

If you fail a quality gate:

1. **Acknowledge the failure:** "Gate X failed because Y"
2. **Fix the failure:** Re-verify, update findings, or remove false positives
3. **Document the fix:** Show what you corrected
4. **Retry the gate:** Confirm it passes now

**Pattern to avoid:**
```
❌ "I'll publish it anyway and the user can figure it out"
❌ "This is close enough"
❌ "I verified most of it"

✅ "Gate failed. Here's what's wrong. Here's how I'm fixing it."
```

---

## Measuring Success

After this policy is in place:

- **Accuracy rate:** 95%+ on findings (vs. 60-70% before)
- **False positives:** <1% (vs. 10-15% before)
- **Verification time:** 20-30% additional time upfront (saves rework later)
- **User confidence:** High (findings are trustworthy)

---

## Questions You Might Have

**Q: Isn't this slow?**

A: Yes, ~20-30% slower. But accuracy > speed for code analysis. A 50-line grep is cheaper than a wrong fix.

**Q: What if the file is huge (10,000 lines)?**

A: Read in 2-3 chunks with overlap. Still read completely, just split logically.

**Q: Can I skip verification for "obvious" issues?**

A: No. "Obvious" issues are often false positives. Your prior analysis was wrong on "obvious" things.

**Q: What if I'm wrong about severity?**

A: That's OK. You'll fix it during Phase 4 (Severity Assessment) when you check for mitigations.

**Q: How do I know if my confidence rating is right?**

A: If you can't check all verification boxes, it's not HIGH. Honest doubt = MEDIUM/LOW.

**Q: Can the user override this policy?**

A: YES. User can say "skip full verification" or "best-effort only". But this becomes explicit, not hidden.

---

## Historical Context

**Lesson Learned:** Release Workflow Audit (2025-10-29)

- Started with 13 "issues" based on partial reads
- After full verification audit:
  - 1 false positive (error handling)
  - 1 wrong file location (cherry-pick vs prepare-stable)
  - 2 overstated severities
  - 5-6 accuracy issues in details/line numbers

**Result:** 60-70% accuracy rate (unacceptable for code changes)

**Fix:** This policy ensures 95%+ accuracy going forward

---

**Last Updated:** 2025-10-29
**Version:** 1.0
**Status:** Active (applies to all future work unless user explicitly overrides)

