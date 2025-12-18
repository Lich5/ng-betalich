# Customization Guide: How to Adapt Safely

This guide helps you adapt the Claude Development Process Framework to fit your team's style while preserving core benefits.

---

## Philosophy: Core vs. Style

**Core = Principles that provide key benefits**
- Changing these has trade-offs you should understand
- Not forbidden, but consider carefully

**Style = Implementation details that fit your preferences**
- Change freely to match your workflow
- Minimal trade-offs

---

## Common Customizations

### 1. Mode Structure

**What we provide:**
- `/arch` - Planning mode (Sonnet, restricted)
- `/analyze` - Investigation mode (Sonnet, full toolkit)
- `/code` - Implementation mode (Haiku, full toolkit)

**Common adaptations:**

#### Two Modes Instead of Three

**Approach:** Merge `/arch` and `/analyze` into single architect mode

**How:**
```yaml
---
description: Architecture mode for planning and analysis
model: claude-sonnet-4-5-20241022
---
```

Remove tool restrictions, trust instructions.

**Trade-offs:**
- Pros: Simpler, fewer modes to remember, less switching
- Cons: Lose distinction between planning and investigation, risk of mode confusion

**When this makes sense:** Small teams, simple projects, low risk tolerance for restriction

---

#### Four or More Modes

**Approach:** Add specialized modes (e.g., `/debug`, `/security`, `/perf`)

**How:** Create new command files with appropriate model and tool configs

**Trade-offs:**
- Pros: Specialized focus, clearer cognitive boundaries
- Cons: More modes to learn, more switching, potentially over-engineered

**When this makes sense:** Large teams, complex projects, specialized skill domains

---

### 2. Model Selection

**What we provide:**
- Architect/Analysis: Sonnet 4.5
- Implementation: Haiku 4.5

**Common adaptations:**

#### Use Opus for Architecture

```yaml
model: claude-opus-4-5-20251101
```

**Trade-offs:**
- Pros: Deepest reasoning available, best for complex decisions
- Cons: Most expensive, may be overkill for straightforward architecture

**When this makes sense:** Critical architectural decisions, complex systems, cost less important than capability

---

#### Use Sonnet for Implementation

```yaml
model: claude-sonnet-4-5-20241022
```

**Trade-offs:**
- Pros: More capable than Haiku, handles complex implementation better
- Cons: More expensive than Haiku, may be slower

**When this makes sense:** Complex implementations, less clear specifications, learning new codebases

---

#### Manual Model Selection

Remove `model:` from frontmatter, let users choose via `/model`

**Trade-offs:**
- Pros: Maximum flexibility, user controls cost vs. capability
- Cons: Requires more decisions, may use wrong model for task, less automatic

**When this makes sense:** Experienced users, variable project complexity, tight budget control

---

### 3. Tool Restrictions

**What we provide:**
- `/arch` - Restricted (no code execution except validation)
- `/analyze` - Full toolkit
- `/code` - Full toolkit

**Common adaptations:**

#### Looser Restrictions

Remove `allowed-tools` from `/arch`, rely on instructions

**Trade-offs:**
- Pros: More flexibility, faster when boundaries blur
- Cons: Risk of architect mode implementing, less enforcement

**When this makes sense:** Solo developers, high trust in discipline, simple projects

---

#### Tighter Restrictions

Add restrictions to `/analyze` or `/code`

**Trade-offs:**
- Pros: Stronger guarantees, prevent accidents
- Cons: May block legitimate use cases, frustration

**When this makes sense:** Learning teams, high-risk projects, strict process compliance needed

---

#### No Restrictions

Trust instructions completely, no technical enforcement

**Trade-offs:**
- Pros: Maximum flexibility, no blocked use cases
- Cons: No safety net, relies entirely on model following instructions

**When this makes sense:** Experienced users, low-risk projects, prototyping

---

### 4. Work Units

**What we provide:**
- CURRENT.md for active work
- Archive completed before creating new

**Common adaptations:**

#### Skip Work Units for Simple Tasks

Only create work units for complex features

**How:** Add to your docs:
```
Work units required for:
- Multi-file changes
- New features with specifications
- Complex refactoring

Skip work units for:
- Bug fixes under 20 lines
- Documentation updates
- Style/lint fixes
```

**Trade-offs:**
- Pros: Less overhead for simple tasks
- Cons: Need to decide when to use them, less consistent

**When this makes sense:** Mix of simple and complex tasks, want flexibility

---

#### Different File Structure

**Options:**
- `WIP.md` instead of `CURRENT.md`
- `tasks/active/` directory with multiple files
- Issue tracker instead of files

**Trade-offs:**
- Pros: Fits your existing workflow
- Cons: May need tooling changes, team adjustment

**When this makes sense:** Existing workflow to integrate with

---

#### Different Archive Approach

**Options:**
- Date-based: `archive/2025-01-15-feature.md`
- Feature-based: `archive/login-system/`
- Git-based: Just commit/delete, rely on git history

**Trade-offs:**
- Date: Easy to find by time, harder by topic
- Feature: Easy to find by topic, requires organization
- Git: No files to manage, harder to browse

**When this makes sense:** Whatever matches your project organization style

---

### 5. Commit Conventions

**What we provide:**
- Conventional commits format
- Specific prefixes required

**Common adaptations:**

#### Different Convention

Use your existing convention (e.g., Jira ticket numbers, different format)

**How:** Update `CLI_PRIMER.md` with your convention

**Trade-offs:**
- Pros: Matches existing workflow, team already knows it
- Cons: May not integrate with release tools the same way

**When this makes sense:** Established projects with existing conventions

---

#### Looser Requirements

No specific format required

**Trade-offs:**
- Pros: Flexibility, less friction
- Cons: Inconsistent history, harder to automate releases

**When this makes sense:** Small projects, internal tools, prototypes

---

### 6. Testing Requirements

**What we provide:**
- Tests mandatory before commit
- Zero regression tolerance

**Common adaptations:**

#### Test Coverage Thresholds

Add specific coverage requirements (e.g., 80% line coverage)

**Trade-offs:**
- Pros: Measurable quality gate
- Cons: May encourage gaming metrics, false sense of quality

**When this makes sense:** Teams learning testing, quality improvement focus

---

#### Flexible Testing

Tests strongly encouraged but not blocking

**Trade-offs:**
- Pros: Faster iteration, less friction
- Cons: Technical debt accumulates, regressions more likely

**When this makes sense:** Prototyping, proofs of concept, throwaway code

---

### 7. Quality Gates

**What we provide:**
- Pre-push validation checklist
- Multiple checks required

**Common adaptations:**

#### Add Gates

Security scanning, type checking, performance benchmarks

**Trade-offs:**
- Pros: Higher quality, catch more issues
- Cons: Slower, more to maintain

**When this makes sense:** Production systems, high-risk code, compliance requirements

---

#### Remove Gates

Fewer or no gates, rely on CI/CD or manual review

**Trade-offs:**
- Pros: Faster local development
- Cons: Issues caught later, more expensive to fix

**When this makes sense:** Mature teams with strong CI/CD, prototyping

---

### 8. Session Initialization

**What we provide:**
- `/init` command loads core docs
- Required at session start

**Common adaptations:**

#### Automatic Initialization

Use VSCode extension or shell profile to auto-run `/init`

**Trade-offs:**
- Pros: Never forget, always consistent
- Cons: Token cost every session, may not need full init every time

**When this makes sense:** Frequent short sessions, critical to maintain context

---

#### Minimal Initialization

Shorter doc set, faster loading

**Trade-offs:**
- Pros: Lower token cost, faster start
- Cons: May miss critical context

**When this makes sense:** Very frequent sessions, well-established patterns

---

#### Manual Initialization

No automatic loading, read docs when needed

**Trade-offs:**
- Pros: Maximum flexibility, no automatic cost
- Cons: Easy to forget, inconsistent context

**When this makes sense:** Infrequent Claude use, experienced users

---

## Language/Framework Specific Adaptations

### Python Projects

- Change `bundle exec rspec` to `pytest`
- Change `rubocop` to `black`, `flake8`, `mypy`
- Update quality gates for Python tooling

### JavaScript/TypeScript Projects

- Change testing commands to `npm test` or `jest`
- Change linting to `eslint`, `prettier`
- Add `tsc` for type checking
- Update quality gates for JS ecosystem

### Go Projects

- Change testing to `go test`
- Add `go vet`, `golint`
- Update quality gates for Go tooling

### Generic (Non-Ruby) Projects

The template docs reference Ruby/RSpec heavily. Update:
- Remove Ruby-specific commands
- Replace with your language's testing framework
- Update code examples in docs
- Keep the principles, change the tooling

---

## How to Customize: Process

### 1. Start with Template As-Is

Use the framework unchanged for at least one feature or sprint. Understand how it works before changing it.

### 2. Identify Friction Points

Note where the process:
- Blocks legitimate use cases
- Feels unnecessarily restrictive
- Doesn't fit your workflow
- Creates overhead without benefit

### 3. Consult Core Principles

Read `CORE_PRINCIPLES.md` to understand:
- Why this choice was made
- What benefit it provides
- What's core vs. style

### 4. Ask Claude for Guidance

```
I want to modify [X] in the Claude development framework.
Please review CORE_PRINCIPLES.md and DECISION_FRAMEWORK.md
and help me evaluate this change.
```

### 5. Make Incremental Changes

Change one thing at a time. See how it affects your workflow before changing more.

### 6. Document Your Adaptations

Update your docs to reflect your changes. Future Claude and future team members need to know your process.

---

## Red Lines: Changes That Break Key Benefits

### Don't Do These Without Understanding Consequences

**Remove all role boundaries:**
- Loses cognitive separation benefit
- Mode confusion likely
- Consider: Looser boundaries instead of none

**Skip quality gates entirely:**
- Technical debt accumulates quickly
- Regressions become common
- Consider: Fewer gates instead of none

**Abandon evidence-based approach:**
- Assumptions and errors increase
- Code quality suffers
- Consider: Show evidence only when uncertain

**Eliminate session initialization:**
- Context loss across sessions
- Inconsistent behavior
- Consider: Minimal initialization instead of none

**No documentation:**
- Process becomes tribal knowledge
- New team members lost
- Future Claude can't help
- Consider: Concise docs instead of none

---

## Getting Help with Customization

Ask Claude (after it reads CORE_PRINCIPLES and DECISION_FRAMEWORK):

**Good questions:**
- "What's the trade-off if I merge /arch and /analyze?"
- "How should I adapt the testing requirements for Python?"
- "What's the risk of removing tool restrictions?"
- "Can I use work units only for complex features?"

**What Claude needs from you:**
- Your context (team size, project type, risk tolerance)
- What friction you're experiencing
- What benefit you're trying to preserve or add

---

## Summary

**The meta-principle:** Understand why before changing what.

This framework is a starting point, not a prison. Adapt it to fit your needs - just do so thoughtfully, preserving the core benefits that make it valuable.

---

**End of Customization Guide**
