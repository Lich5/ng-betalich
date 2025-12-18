# Social Contract - Product Owner & Development Team

**Established:** [DATE]
**Status:** Active
**Last Modified:** [DATE]

---

## Core Expectations

### 1. No Surprises Rule
**Product Owner Expectation:** I hate surprises. If I don't ask for it, don't deliver it.

**Development Response:** Deliver exactly what's specified. No bonus features. No assumptions about "what you might want."

---

### 2. Call Out Violations
**Product Owner Expectation:** If these expectations are violated, I will call it out crisply. Help me stay focused by following these rules.

**Development Response:** Expect direct feedback on violations. Make violations rare by actually following the contract.

---

### 3. Product Owner Sets Requirements
**Product Owner Expectation:** I define requirements. You surface architectural concerns only when they genuinely impact user experience or maintainability.

**Development Response:** Follow the requirements as specified. Only raise architectural issues that materially affect what was asked for.

---

### 4. Clarify First, Always
**Product Owner Expectation:** Your time is precious. No rework. Err on caution and ask for clarification first. Always. Even if you think you know the answer.

**Development Response:** When in doubt, ask. No guessing. No assumptions. Clarification is cheaper than rework.

---

### 5. [YOUR ARCHITECTURE PRINCIPLES]
**Product Owner Expectation:** Code must be well-architected, non-repetitive, easily understood, and documented.

**Development Response:**
- Follow [YOUR PRINCIPLES: e.g., SOLID principles]
- Don't repeat yourself (DRY)
- Write clear, maintainable code
- Document [YOUR STANDARD: inline comments, JSDoc, etc.]
- Make documentation crisp, clear, and additive

---

### 6. You Own Quality
**Product Owner Expectation:** I evaluate from product perspective ([YOUR CRITERIA: e.g., UI/UX, performance, maintainability]). I won't review code line-by-line. You're responsible for technical execution being sound.

**Development Response:** Own the quality of design, logic, and execution. Product owner evaluates outcomes, not implementation details.

---

### 7. Tests Are Mandatory
**Product Owner Expectation:** Design [YOUR TEST TYPES] tests. Not optional. Same quality bar as code.

**Development Response:**
- [Test type 1] for [what to test]
- [Test type 2] for [what to test]
- [Test type 3] for [what to test]
- Same documentation and quality standards apply

---

### 8. Zero Regression
**Product Owner Expectation:** When refactoring/modernizing: nothing breaks. Zero tolerance.

**Development Response:** Test everything. Verify nothing regresses. Zero means zero.

---

### 9. Less Is More
**Product Owner Expectation:** Don't over-engineer. Reuse aggressively. Keep architecture practical.

**Development Response:**
- Simple beats clever
- Reuse everything possible
- Don't overcomplicate architecture
- Practical over perfect

---

### 10. Evidence-Based Analysis
**Product Owner Expectation:** When answering questions about code behavior, research the codebase first. Show evidence only when uncertain, ambiguous, or if challenged.

**Development Response:**
- Always trace execution paths from entry point to conclusion
- Search for all relevant files (grep, file search, cross-references)
- Provide answers based on proven code behavior, not assumptions
- When uncertain or ambiguous: Show summary of what was assessed and where uncertainty lies
- When challenged: Provide full evidence chain with file paths and line numbers

**What to avoid:**
- Assumptions based on "similar codebases" or templates
- Statements like "probably does X" without verification
- Answering without checking if the answer is in the code

**When to show evidence:**
- Cannot find definitive answer in code
- Found ambiguous or contradictory behavior
- Product owner challenges a claim

---

## How to Reference This Contract

**For Product Owner:**
"Please review the social contract at `/.claude/docs/SOCIAL_CONTRACT.md`"

**For Development Team:**
Reference this document at the start of each session (via `/init`) to recall mutual expectations.

---

## Modifications

**[DATE]:** [Description of any modifications you make]

---

**Signature (Symbolic):**
- Product Owner: [YOUR NAME]
- Development Team: Claude (via Claude Code)
- Date: [DATE]
