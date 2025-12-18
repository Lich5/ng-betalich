# Core Principles: The WHY Behind This Framework

This document explains the reasoning behind each design choice in the Claude Development Process Framework. Future Claude instances should read this to understand the principles well enough to guide users through thoughtful adaptations.

---

## Origin Story

This framework emerged from the Lich 5 ng-betalich project, where Product Owner (Doug) and Claude Code collaborated across web and CLI environments. Through real-world development - password encryption features, architecture analysis, quality gates - patterns emerged that balanced discipline with flexibility.

**Key insight:** The physical separation between Web Claude (architect/reviewer) and CLI Claude (executor) created natural role boundaries that improved code quality and reduced rework. This framework replicates that discipline in unified environments like VSCode.

---

## Principle 1: Role Separation Matters

### The Why

Different cognitive tasks require different approaches:
- **Planning** requires deep thinking, broad context, architectural perspective
- **Investigation** requires flexibility, experimentation, hypothesis validation
- **Implementation** requires focus, efficiency, execution discipline

When one person (or one Claude) does everything without boundaries, mode confusion happens:
- Architect starts implementing before design is solid
- Implementation makes architectural decisions without proper analysis
- Context switching wastes cognitive energy

### The How

Three modes with automatic model switching:
- **`/arch`** - Planning mode (Sonnet/Opus, restricted toolkit)
- **`/analyze`** - Investigation mode (Sonnet/Opus, full toolkit)
- **`/code`** - Implementation mode (Haiku, full toolkit)

### What's Sacred

**Some form of role separation.** Whether you use our three modes, create different ones, or enforce separation differently - maintain boundaries between planning, investigation, and execution.

### What's Adaptable

- Number of modes (2, 3, 4, or more)
- Mode names and descriptions
- Tool restrictions (tighter or looser)
- Model assignments (Opus vs Sonnet, different Haiku versions)
- How you enforce boundaries (technical restrictions vs. instructions)

### Trade-offs

**Looser boundaries:**
- Pros: More flexibility, faster for small tasks
- Cons: Mode drift, accidental architectural decisions during implementation

**Tighter boundaries:**
- Pros: Strong discipline, clear cognitive separation
- Cons: More mode switching, can feel restrictive

---

## Principle 2: Work Units Enable Handoffs

### The Why

Complex tasks benefit from separation between "what to build" and "how to build it." Work units create a contract:
- Architect defines: specifications, acceptance criteria, constraints
- Implementation executes: code, tests, validation

This handoff protocol:
- Forces clarity in requirements (can't be vague if you're writing specs)
- Prevents scope creep (acceptance criteria are explicit)
- Enables context recovery (work unit survives session boundaries)
- Creates documentation trail (archive shows project evolution)

### The How

**CURRENT.md** is the active work unit in `.claude/work-units/`:
- Single source of truth for "what I'm working on right now"
- Created by architect mode, executed by implementation mode
- Contains: specifications, acceptance criteria, context, constraints

**Archive completed work units** before creating new ones:
- Keeps CURRENT.md accurate (always shows active work)
- Prevents GitHub searches from surfacing stale/completed tasks
- Maintains clean project history

### What's Sacred

**Some form of handoff protocol** for complex tasks. You need a way to separate "what" from "how."

**Archiving principle:** Don't overwrite CURRENT.md repeatedly - move completed work somewhere before creating new work. Prevents confusion and keeps searches clean.

### What's Adaptable

- Work unit format (our structure vs. yours)
- File naming (CURRENT.md vs. active.md vs. current-task.md)
- Archive structure (date-based, feature-based, flat vs. nested)
- Archive process (manual vs. automated, naming conventions)
- When to use work units (always vs. only for complex tasks)

### Trade-offs

**Always using work units:**
- Pros: Consistent process, good documentation trail
- Cons: Overhead for simple tasks

**Selective work units:**
- Pros: Flexibility, less overhead
- Cons: Need to decide when to use them, less consistency

**No work units:**
- Pros: Fastest for small tasks
- Cons: Lose handoff clarity, harder context recovery, scope creep risk

---

## Principle 3: Model Matching Reinforces Roles

### The Why

Claude models have different cognitive characteristics:
- **Opus/Sonnet:** Deeper reasoning, better at architecture and complex analysis, more expensive
- **Haiku:** Efficient execution, cost-effective, excellent for well-defined tasks

Matching models to modes:
- Amplifies the cognitive strengths appropriate for each task
- Makes role boundaries tangible (different model = different thinking style)
- Optimizes cost (expensive model for complex thinking, efficient model for execution)

### The How

Slash command frontmatter enables automatic model switching:

```yaml
---
model: claude-sonnet-4-5-20241022
---
```

- `/arch` → Sonnet/Opus (planning)
- `/analyze` → Sonnet/Opus (investigation)
- `/code` → Haiku (implementation)

### What's Sacred

**Intentional model selection.** Use deeper thinking for complex tasks, efficient execution for well-defined tasks.

### What's Adaptable

- Specific models (Opus vs. Sonnet for architecture, Haiku 4 vs. 4.5 for implementation)
- When to switch (every mode vs. just some)
- Manual vs. automatic (frontmatter vs. user-initiated)
- Cost vs. capability trade-offs

### Trade-offs

**Always use Opus/Sonnet:**
- Pros: Maximum capability everywhere
- Cons: Expensive, overkill for simple tasks

**Always use Haiku:**
- Pros: Cost-effective, fast
- Cons: Less capable for complex architectural decisions

**Model matching (our approach):**
- Pros: Right tool for right job, cost optimization
- Cons: Need to think about which mode/model to use

---

## Principle 4: Quality Gates Prevent Rework

### The Why

"Move fast and break things" works until you break things. In production codebases, rework from skipped validation is expensive:
- Failed tests discovered after commit require fixup commits
- Style violations caught in PR review require rework
- Regression discovered in production requires emergency fixes

Quality gates at boundaries catch issues early:
- Before commit: tests pass, style clean
- Before push: all validation passed
- Before merge: review approved

### The How

Pre-push validation checklist:
- [ ] Tests written and passing
- [ ] Style/lint checks passing
- [ ] Zero regression verified
- [ ] Acceptance criteria met
- [ ] Documentation complete

Implementation mode enforces this discipline.

### What's Sacred

**Some form of validation before finalization.** The specific gates matter less than having them and enforcing them.

**Zero regression tolerance** for refactoring/modernization work. This is non-negotiable in production systems.

### What's Adaptable

- Specific checks (tests, linting, type checking, security scans)
- When to check (before commit vs. before push vs. in CI)
- How strict (blocking vs. warning)
- Automation level (manual checklist vs. git hooks vs. CI/CD)

### Trade-offs

**Strict gates:**
- Pros: High quality, catch issues early, less rework
- Cons: Slower iteration, can feel restrictive

**Loose gates:**
- Pros: Fast iteration, flexibility
- Cons: Issues caught later, more rework, quality risk

---

## Principle 5: Evidence-Based Approach

### The Why

Claude (or any AI) can hallucinate or make assumptions. In production code, assumptions cause bugs. Evidence-based approach:
- Research the codebase before answering questions
- Trace execution paths from entry to conclusion
- Verify claims with grep, file reads, cross-references
- Show evidence when uncertain or challenged

This prevents:
- "I think it works like X" (assumption) vs. "I traced the code, it works like X" (evidence)
- False positives in analysis
- Incorrect architectural assumptions

### The How

Before answering questions about code behavior:
1. Search for relevant files (Glob, Grep)
2. Read the actual code
3. Trace execution paths
4. Verify assumptions

When uncertain or challenged:
- Show what was searched
- Cite file paths and line numbers
- Explain what was found vs. not found

### What's Sacred

**Research before answering.** Don't guess about code behavior when you can read the code.

### What's Adaptable

- How much evidence to show (summary vs. detailed)
- When to show evidence (always vs. when uncertain vs. when challenged)
- Verification depth (quick check vs. thorough analysis)

### Trade-offs

**Always show full evidence:**
- Pros: Maximum transparency, verifiable
- Cons: Verbose, token-intensive

**Research but summarize:**
- Pros: Efficient, clear answers
- Cons: Less transparent, requires trust

**Trust without verification:**
- Pros: Fastest
- Cons: Risk of errors, assumptions, hallucinations

---

## Principle 6: Session Continuity Through Documentation

### The Why

Claude sessions end. Context compacts. Memory fades. Projects continue.

Without session continuity protocol:
- Lose project-specific conventions and agreements
- Re-learn architecture every session
- Forget quality standards and testing requirements
- Repeat mistakes from prior sessions

Documentation-first approach solves this:
- Core docs capture philosophy, agreements, standards
- `/init` loads context at session start
- Session checklist detects context loss
- Future Claude can recover from docs

### The How

**Core documentation:**
- Philosophy and role definitions
- Team agreements and expectations
- Workflow procedures and standards
- Session initialization checklist

**Session initialization:**
```
/init
```
Loads all core docs, establishes context, reports readiness.

**Context recovery:**
If mid-session signs of context loss appear, re-run initialization.

### What's Sacred

**Some form of session initialization.** New sessions need context.

**Documentation is law, not optional reference.** Docs must be accurate and consulted.

### What's Adaptable

- What docs to include (our set vs. yours)
- How much detail (concise vs. comprehensive)
- Initialization trigger (manual /init vs. automatic)
- Recovery protocol (re-read docs vs. summarize vs. ask user)

### Trade-offs

**Comprehensive initialization:**
- Pros: Full context, consistent behavior
- Cons: Token cost, time to initialize

**Minimal initialization:**
- Pros: Fast, efficient
- Cons: May miss critical context, inconsistent behavior

---

## Principle 7: Adaptability Through Principles

### The Why

Every team is different:
- Different languages, frameworks, tools
- Different team sizes and structures
- Different project complexities
- Different preferences and styles

Prescriptive templates fail because they can't account for this diversity. But unprincipled flexibility leads to chaos.

**Solution:** Strong principles + adaptation guidance.
- Teach the WHY behind choices
- Distinguish core from style
- Provide trade-off analysis
- Enable informed customization

### The How

This framework provides:
- **CORE_PRINCIPLES.md** (this doc) - Understanding the reasoning
- **CUSTOMIZATION_GUIDE.md** - How to adapt safely
- **DECISION_FRAMEWORK.md** - Evaluating changes

Future Claude reads these and can:
- Explain why something works the way it does
- Help users evaluate proposed changes
- Suggest adaptations that preserve core benefits
- Warn about changes that break key principles

### What's Sacred

**The meta-principle:** Understand principles before changing them.

### What's Adaptable

Everything, if you understand the trade-offs.

### Trade-offs

**Strict adherence:**
- Pros: Consistent, proven approach
- Cons: May not fit your context, feels restrictive

**Free adaptation:**
- Pros: Perfect fit for your needs
- Cons: May lose key benefits, harder to maintain

**Principled adaptation (our approach):**
- Pros: Fits your needs while preserving benefits
- Cons: Requires thinking about trade-offs

---

## Summary: What Future Claude Needs to Know

When a user asks to modify this framework, evaluate:

1. **Does this preserve role separation?** (Principle 1)
   - If no: Warn about mode confusion risk

2. **Does this maintain handoff clarity for complex tasks?** (Principle 2)
   - If no: Warn about scope creep and context loss risk

3. **Does this match cognitive task to capability?** (Principle 3)
   - If no: Discuss cost or capability trade-offs

4. **Does this maintain quality discipline?** (Principle 4)
   - If no: Warn about rework and regression risk

5. **Does this preserve evidence-based approach?** (Principle 5)
   - If no: Warn about assumption and error risk

6. **Does this maintain session continuity?** (Principle 6)
   - If no: Warn about context loss risk

7. **Is this style vs. substance?** (Principle 7)
   - Style: Safe to adapt
   - Substance: Discuss trade-offs first

**Your job as future Claude:** Help users adapt thoughtfully, preserving core benefits while fitting their context.

---

**End of Core Principles**
