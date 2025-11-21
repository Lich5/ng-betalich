# Claude Code Configuration & Policies

This directory contains configuration and operational guidelines for Claude Code when working in this repository.

## Files

### 1. `ANALYSIS-METHODOLOGY.md`
**Purpose:** How to conduct thorough code analysis

**Use When:**
- Analyzing codebase architecture
- Reviewing code for issues
- Performing security assessments
- Documenting system behavior

**Contents:**
- 6-phase audit checklist (Information Gathering → Quality Gate)
- Verification rules and procedures
- Confidence level definitions
- When to skip verification (rare cases)
- Citation template

**Key Point:** Emphasizes systematic verification before publishing findings.

---

### 2. `QUALITY-GATES-POLICY.md`
**Purpose:** Standards for acceptable analysis quality

**Use When:**
- Before publishing any code analysis
- Planning a new analysis task
- Reviewing analysis from prior session
- Deciding if findings are ready for action

**Contents:**
- 7 mandatory quality gates
- Verification process checklist (6 phases)
- Template for citing issues
- When to skip verification (rare exceptions)
- How violations are handled

**Key Point:** Mandatory gates that must pass before analysis is published.

---

## Quick Start

### For a New Analysis Task

1. **Open `ANALYSIS-METHODOLOGY.md`**
   → Review Phase 1-3 (setup and analysis)

2. **Open `QUALITY-GATES-POLICY.md`**
   → Review the 7 quality gates
   → Use the verification checklist (Phases 1-6)

3. **Conduct analysis** following both documents

4. **Before publishing:**
   → Run through Gates 1-7
   → Confirm verification checklist passes
   → Use the issue template

5. **Publish** findings with confidence they're accurate

---

## How These Documents Work Together

```
ANALYSIS-METHODOLOGY.md          QUALITY-GATES-POLICY.md
(HOW to analyze)                 (WHEN to publish)
        ↓                              ↓
    6 Phases                      7 Gates + Checklist
        ↓                              ↓
   Systematic                     Quality
   Investigation            Assurance
        ↓                              ↓
    Findings               Pass/Fail Decision
        ↓                              ↓
   Ready for              YES → Publish
   Quality Gate           NO → Fix & Retry
```

---

## Key Rules You Must Follow

### Rule 1: Read Files Completely
- No `limit` parameter unless file >5000 lines
- Read end-to-end, not fragments
- Document total file size

### Rule 2: Verify Every Citation
- Use `grep -n` to find exact line
- Use `sed` to show context
- Extract code snippet
- Document verification

### Rule 3: Confidence Ratings Required
- HIGH (90-100%): Code verified, context checked, no ambiguity
- MEDIUM (60-89%): Found but some details unverified
- LOW (0-59%): Suspected but unverified (must be labeled "Uncertain")

### Rule 4: Check for Mitigations
- Don't claim issue if guards/locks/error-handling already exist
- Document mitigations found
- Adjust severity accordingly

### Rule 5: Severity Justified by Code
- Don't rate critical without evidence
- Show code that proves risk
- Explain actual impact vs. theoretical

### Rule 6: Use the Template
- All findings use standard format
- File, Location, Code, Verification, Issue, Risk, Fix
- Consistent format = easier review

### Rule 7: Pass All Gates
- Verify checklist before publishing
- Don't publish incomplete analysis
- Flag as incomplete if you can't pass gates

---

## What Changed Since Last Analysis

**Before (Release Workflow Audit v0):**
- Partial file reads using `limit` parameter
- No systematic verification
- 60-70% accuracy rate
- Wrong file names and line numbers
- False positives included
- Severities overstated

**After (Release Workflow Audit v1 + New Policies):**
- Complete file reads
- Mandatory grep verification
- 95%+ accuracy target
- All citations checked
- Confidence ratings on everything
- Severity justified by code evidence

---

## Exception: User Override

You can explicitly override these policies. Say:

**"Best-effort analysis, flag uncertainty"**
→ I'll do phases 1-2, flag confidence levels clearly, won't do full verification

**"Speed over accuracy"**
→ I'll note trade-off, mark findings as unverified, you review before action

**"Skip verification for X"**
→ I'll explicitly label as unverified, you acknowledge risk

**Default:** Full methodology + all gates apply unless you override.

---

## How to Reference These Files

When starting analysis work:

```
I'm going to analyze the release-please workflows.

Before I begin, I'm reading:
- .claude/ANALYSIS-METHODOLOGY.md (the process)
- .claude/QUALITY-GATES-POLICY.md (the standards)

I'll follow the 6-phase checklist and pass all 7 gates before publishing.
```

---

## Storage & Availability

These files are stored in `.claude/` directory:
- Preserved across Claude Code sessions
- Available for reference by future instances
- Can be updated if policies evolve

**Check them before every analysis.**

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2025-10-29 | Initial creation after Release Workflow Audit findings |

---

## Questions?

**Q: Where do I find these files when I start work?**
A: In `.claude/` directory. Read them before starting analysis.

**Q: Can I modify these policies?**
A: Only if you have good reason. They were created to fix real accuracy problems.

**Q: What if I disagree with a gate?**
A: Raise it. These are learnings, not dogma. But they exist because prior analysis had issues.

**Q: What if a policy doesn't fit my use case?**
A: Ask user to override explicitly. Don't skip silently.

---

**Created:** 2025-10-29
**Reason:** Accuracy issues in prior Release Workflow Analysis
**Status:** Active - Applies to all future code analysis in this repository
