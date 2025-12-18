# Claude Development Process Framework

A structured, adaptable framework for disciplined software development with Claude Code in VSCode, CLI, or Web environments.

## What This Is

This is not a rigid prescription - it's a **teaching framework** that provides:
- Clear role separation between planning, analysis, and implementation
- Model-appropriate cognitive modes (deeper thinking vs. efficient execution)
- Work unit handoff protocol for complex tasks
- Quality gates and testing discipline
- Customization guidance for adapting to your team's style

**Philosophy:** Strong opinions, loosely held. We provide the principles and reasoning so you can adapt thoughtfully.

---

## Quick Start

### 1. Copy the Template

Copy the `template/.claude/` directory into your repository root:

```bash
cp -r template/.claude /path/to/your/repo/
```

### 2. Initialize Your Session

In Claude Code (VSCode, CLI, or Web), run:

```
/init
```

This loads core documentation and establishes your development context.

### 3. Understand the Modes

This framework provides three cognitive modes:

- **`/arch`** - Architecture/Planning Mode (Sonnet/Opus)
  - Design systems, plan features, create work units
  - Restricted toolkit: no code execution

- **`/analyze`** - Investigation Mode (Sonnet/Opus)
  - Troubleshoot, validate hypotheses, experiment
  - Full toolkit: run code, execute tests, investigate

- **`/code`** - Implementation Mode (Haiku)
  - Execute work units, write tests, implement features
  - Full toolkit: efficient execution

### 4. Start Working

**For planning:**
```
/arch
```
Plan your feature, create a work unit in `.claude/work-units/CURRENT.md`

**For troubleshooting:**
```
/analyze
```
Investigate issues, validate assumptions, experiment

**For implementation:**
```
/code
```
Execute the work unit, write tests, implement the feature

---

## Core Concepts

### Role Separation

Different cognitive tasks require different approaches:
- **Planning** needs deep thinking, architectural perspective
- **Investigation** needs flexibility, experimentation, validation
- **Implementation** needs efficiency, focus, execution discipline

Modes enforce this separation even in a single environment.

### Work Units

**CURRENT.md** is the active work unit - the handoff between modes:
- Architect mode creates it (specifications, acceptance criteria)
- Implementation mode executes it (code, tests, commits)

**Archive completed work units** before creating new ones:
- Keeps CURRENT.md accurate (always the active task)
- Prevents GitHub searches from surfacing stale content
- Maintains clean project history

**How you archive is up to you** - the principle matters, not the structure.

### Model Matching

Different modes use different models automatically:
- Architecture/Analysis: Sonnet or Opus (deeper reasoning)
- Implementation: Haiku (efficient, cost-effective)

Slash commands switch models automatically via frontmatter configuration.

### Quality Gates

Test-before-develop, validation before push, zero regression tolerance - these aren't optional. The framework enforces quality discipline at boundaries.

---

## What's Included

### Template Files (`template/.claude/`)

**Slash Commands** (`commands/`):
- `init.md` - Session initialization
- `arch.md` - Architecture/planning mode
- `analyze.md` - Investigation mode
- `code.md` - Implementation mode
- `test.md` - Testing mode
- `review.md` - Code review mode

**Core Documentation** (`docs/`):
- `CLI_PRIMER.md` - Role definitions, testing philosophy
- `SOCIAL_CONTRACT.md` - Team agreements (10 core expectations)
- `DEVELOPMENT_WORKFLOW.md` - Branch strategy, validation checklist
- `SESSION_INIT_CHECKLIST.md` - Context recovery protocol

### Guides (`guides/`)

- **`CORE_PRINCIPLES.md`** - The WHY behind each choice (for future Claude)
- **`CUSTOMIZATION_GUIDE.md`** - How to adapt safely (what's core vs. style)
- **`DECISION_FRAMEWORK.md`** - Evaluating proposed changes

---

## Customization

**This framework is meant to be adapted.**

The guides explain:
- What's sacred (role separation, quality gates, evidence-based approach)
- What's adaptable (mode structure, tool restrictions, commit conventions)
- How to evaluate changes (trade-offs, risks, benefits)
- Common adaptations and their implications

**Future Claude can help you customize** - the CORE_PRINCIPLES and DECISION_FRAMEWORK give Claude the context to guide thoughtful adaptations.

---

## Who This Is For

- **Teams** wanting disciplined development with Claude
- **Solo developers** wanting structure and quality discipline
- **Organizations** establishing Claude development standards
- **Anyone** who wants a starting point they can adapt

---

## Getting Help

When customizing, ask Claude:

```
I want to modify [X] in the Claude development framework.
Please review CORE_PRINCIPLES.md and DECISION_FRAMEWORK.md
and help me evaluate this change.
```

Future Claude will understand the principles and guide you through the trade-offs.

---

## License

This framework is provided as-is for adaptation and use. Modify freely to fit your team's needs.

---

## Credits

Developed through the Lich 5 ng-betalich project, this framework emerged from real-world collaboration between Product Owner and Claude Code across web and CLI environments.

**Learn more:** See `guides/CORE_PRINCIPLES.md` for the full story and philosophy.
