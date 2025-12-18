# Decision Framework: Evaluating Changes

This framework helps future Claude instances evaluate proposed changes to the Claude Development Process Framework. Use this when users ask "Can I change X?" or "Should I modify Y?"

---

## The Evaluation Process

### Step 1: Classify the Change

**Is this Core or Style?**

**Core changes** affect principles that provide key benefits:
- Role separation mechanism
- Quality gate enforcement
- Evidence-based approach
- Session continuity protocol
- Handoff clarity for complex tasks

**Style changes** affect implementation details:
- File names and locations
- Specific commit formats
- Archive organization
- Documentation verbosity
- Command names

**Quick test:** If the change affects HOW you do something but not WHETHER you do it, it's likely style.

---

### Step 2: Understand the Motivation

**Ask clarifying questions:**

- "What friction are you experiencing with the current approach?"
- "What benefit are you hoping to gain?"
- "What's your team size and project complexity?"
- "What's your risk tolerance?"
- "Are there existing conventions you need to integrate with?"

**Context matters.** The right answer for a solo developer on a prototype differs from a 10-person team on a production system.

---

### Step 3: Identify What's at Risk

**For each principle potentially affected, check:**

#### Principle 1: Role Separation
- **Risk:** Mode confusion, architectural decisions during implementation, premature execution
- **Check:** Does this change maintain clear boundaries between planning, investigation, and execution?

#### Principle 2: Work Unit Handoffs
- **Risk:** Scope creep, vague requirements, lost context, poor documentation trail
- **Check:** Does this change preserve clarity in "what to build" for complex tasks?

#### Principle 3: Model Matching
- **Risk:** Wrong cognitive tool for task, unnecessary cost, insufficient capability
- **Check:** Does this change match thinking depth to task complexity?

#### Principle 4: Quality Gates
- **Risk:** Regressions, technical debt, rework, production issues
- **Check:** Does this change maintain some validation before finalization?

#### Principle 5: Evidence-Based Approach
- **Risk:** Assumptions, hallucinations, incorrect analysis, false confidence
- **Check:** Does this change preserve verification of claims?

#### Principle 6: Session Continuity
- **Risk:** Context loss, forgotten conventions, repeated mistakes, inconsistency
- **Check:** Does this change maintain some way to recover context across sessions?

#### Principle 7: Adaptability
- **Risk:** Rigid process that doesn't fit, abandoning framework entirely
- **Check:** Does this change make the framework fit their context better?

---

### Step 4: Analyze Trade-offs

**Create a clear trade-off statement:**

```
If you [proposed change]:

GAINS:
- [Benefit 1]
- [Benefit 2]
- [Benefit 3]

LOSES:
- [Cost 1]
- [Cost 2]
- [Cost 3]

MITIGATIONS:
- [How to reduce Cost 1]
- [How to reduce Cost 2]
```

**Be specific.** Don't say "might reduce quality" - say "skipping pre-push validation means regressions could reach production, requiring emergency fixes."

---

### Step 5: Provide Recommendations

**Structure your recommendation:**

1. **Direct answer:** Yes/No/It depends
2. **Context:** When this makes sense vs. doesn't
3. **Trade-offs:** What they gain and lose
4. **Alternatives:** Other ways to address their friction
5. **Implementation:** If proceeding, how to do it safely

---

## Common Change Patterns

### Pattern 1: "I want fewer modes"

**Classification:** Core (affects role separation)

**Evaluation questions:**
- How will you maintain cognitive boundaries?
- What's your plan for preventing mode confusion?
- Is the friction from too many modes or from switching?

**Typical recommendation:**
```
Merging /arch and /analyze is reasonable if:
- Your team is small (1-3 people)
- Your projects are relatively simple
- You're comfortable with instruction-based boundaries

Trade-off: You lose the clear distinction between planning (no execution)
and investigation (full toolkit). Risk of starting to implement during planning.

Alternative: Keep three modes but use them selectively - not every task needs /arch.

If proceeding: Remove tool restrictions from merged mode, add strong instructions
about when to plan vs. investigate vs. implement.
```

---

### Pattern 2: "I want to skip work units for simple tasks"

**Classification:** Style (affects when, not whether)

**Evaluation questions:**
- How will you decide what's "simple"?
- How will you handle tasks that turn out more complex?
- Do you need handoff clarity even for simple tasks?

**Typical recommendation:**
```
This is reasonable and commonly done.

Define "simple" clearly in your docs:
- Single file changes
- Under X lines of code
- No architectural decisions
- Clear requirements

Trade-off: Less consistency in process, need judgment calls.

If proceeding: Document when work units are required vs. optional.
Update CLI_PRIMER with your criteria.
```

---

### Pattern 3: "I want to remove tool restrictions"

**Classification:** Core (affects role enforcement)

**Evaluation questions:**
- What use case is blocked by restrictions?
- Can you achieve it in a different mode?
- How will you prevent accidental commits in architect mode?

**Typical recommendation:**
```
Depends on what's blocked:

If /arch can't run validation specs: Reasonable to allow RSpec/Rubocop in /arch.
If /analyze is too restricted: That mode should have full toolkit.
If /arch should execute code: Use /analyze instead, or remove restrictions and rely on instructions.

Trade-off: Technical enforcement → instruction-based enforcement.
More flexible but requires more discipline.

If proceeding: Add strong instructions about role boundaries.
Consider keeping /code as clearly separated from architecture modes.
```

---

### Pattern 4: "I want to use different models"

**Classification:** Style (affects which model, not whether you match models to tasks)

**Evaluation questions:**
- Why the different model? (Cost, capability, availability)
- Does it match cognitive demands of the task?
- Any constraints (API access, budget, performance)?

**Typical recommendation:**
```
Model selection is very customizable:

Using Opus for /arch: Great if complexity warrants it and cost isn't prohibitive.
Using Sonnet for /code: Good for complex implementations, more expensive than Haiku.
Manual model selection: Fine for experienced users who understand the trade-offs.

Principle to preserve: Match thinking depth to task complexity somehow.

If proceeding: Update model frontmatter in slash commands.
Document your reasoning so future users understand the choice.
```

---

### Pattern 5: "I want to skip quality gates"

**Classification:** Core (affects quality discipline)

**Evaluation questions:**
- Which gates and why?
- What's catching in gates that shouldn't be?
- Is the issue the gates themselves or the friction of running them?

**Typical recommendation:**
```
Be very careful here. Quality gates exist because rework is expensive.

If gates are too strict: Loosen specific checks, don't remove entirely.
If gates are too slow: Automate them, don't skip them.
If gates catch noise: Fix the checks, don't remove gates.

Prototypes/throwaway code: Skipping gates is more reasonable.
Production systems: Keep the gates, optimize the friction.

Trade-off: Faster development now, more expensive fixes later.

If proceeding: Be explicit about what quality standards remain.
Consider keeping some gates (e.g., tests) even if removing others.
```

---

### Pattern 6: "I want to eliminate work units entirely"

**Classification:** Core (affects handoff clarity)

**Evaluation questions:**
- How will you separate "what" from "how" for complex tasks?
- How will you prevent scope creep?
- How will you recover context across sessions?

**Typical recommendation:**
```
This removes a key benefit for complex tasks.

For simple projects or solo developers: Might be fine if tasks are straightforward.
For teams or complex projects: You'll miss this when tasks have unclear requirements.

Alternative: Make work units optional rather than eliminated.
Use them for complex features, skip for simple bug fixes.

Trade-off: Less overhead, but also less clarity and more scope creep risk.

If proceeding: Have some other mechanism for clarifying requirements
on complex tasks (issue templates, RFC docs, etc.).
```

---

### Pattern 7: "I want to remove documentation"

**Classification:** Core (affects session continuity)

**Evaluation questions:**
- Which docs and why?
- How will future Claude recover context?
- How will new team members learn the process?

**Typical recommendation:**
```
Documentation is how this framework survives session boundaries.

If docs are too verbose: Make them concise, don't remove them.
If docs aren't used: That's a discipline problem, not a docs problem.
If docs are outdated: Update them, don't delete them.

Minimum viable docs:
- Role definitions and boundaries
- Quality standards
- Session initialization protocol

Trade-off: Less to maintain, but process becomes tribal knowledge.

If proceeding: Keep at minimum the docs that explain your process to future Claude.
```

---

## Red Flag Patterns

**Changes that should trigger strong warnings:**

### "I want to remove all boundaries and run everything in one mode"
**Warning:** This defeats the core purpose of the framework. You'll lose the cognitive separation benefit entirely. Consider whether you need this framework at all, or if a simpler approach would serve you better.

### "Quality gates are just friction, remove them all"
**Warning:** This is how technical debt accumulates. Rework from skipped validation is expensive. If gates are causing pain, fix the gates, don't remove quality discipline.

### "Context doesn't matter, Claude can figure it out"
**Warning:** Context loss leads to repeated mistakes and inconsistent behavior. Some form of session initialization is needed for production use.

### "Just make it faster, never mind the trade-offs"
**Warning:** Every shortcut has a cost. I can help you optimize, but not if you ignore the trade-offs entirely.

---

## Decision Matrix

Use this matrix for quick evaluation:

| Change Type | Solo Dev | Small Team | Large Team | Prototype | Production |
|-------------|----------|------------|------------|-----------|------------|
| Fewer modes | Consider | Risky | No | Yes | No |
| Optional work units | Yes | Yes | Consider | Yes | Consider |
| Looser restrictions | Yes | Consider | No | Yes | Risky |
| Skip quality gates | Risky | No | No | Consider | No |
| Minimal docs | Risky | No | No | Consider | No |
| Different models | Yes | Yes | Yes | Yes | Yes |
| Different format | Yes | Yes | Yes | Yes | Yes |

**Legend:**
- Yes: Generally safe, go ahead
- Consider: Depends on context, evaluate trade-offs
- Risky: Possible but requires care and mitigation
- No: Strongly discouraged, high risk

---

## Template Response

When user asks about a change, use this template:

```
Let me evaluate this change against the framework principles.

CLASSIFICATION: [Core/Style]

WHAT YOU'RE PROPOSING:
[Summarize their request]

WHAT'S AT RISK:
[Which principles affected]

TRADE-OFFS:
Gains: [What they get]
Loses: [What they lose]
Mitigations: [How to reduce losses]

RECOMMENDATION:
[Yes/No/It depends] - [Explanation]

This makes sense if: [Context where it works]
This doesn't make sense if: [Context where it doesn't]

ALTERNATIVES:
[Other ways to address their friction]

IF PROCEEDING:
1. [Step 1]
2. [Step 2]
3. [Step 3]
[Specific implementation guidance]
```

---

## Meta-Guidance for Future Claude

**Your role:** Help users adapt thoughtfully, not enforce rigidity.

**Your goal:** Preserve core benefits while fitting their context.

**Your approach:**
1. Understand their friction and context
2. Explain trade-offs clearly
3. Recommend based on their situation
4. Provide implementation guidance
5. Trust their judgment after full information

**Remember:** The framework exists to serve them, not the other way around. If the framework doesn't fit after thoughtful adaptation, that's okay - it's not for every situation.

---

**End of Decision Framework**
