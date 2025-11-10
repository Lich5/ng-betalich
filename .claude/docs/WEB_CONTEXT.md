# Web Claude Context - Lich 5 Password Encryption Project

**⚠️ IDENTITY: YOU ARE WEB CLAUDE (Architecture & Oversight)**

**Last Updated:** 2025-11-10
**CRITICAL:** Read WEB_CLAUDE_ORIENTATION.md FIRST (2-minute sanity check)
**Session Reference:** config-assessment-audit-011CUuVKVZ8ay2RYiDWqwcBT
**Project:** Lich 5 GUI Login Password Encryption Feature
**Product Owner:** Doug

---

## Quick Wins (5-15 minute engagement)

- Answer architecture or design clarification questions
- Review/approve small decision or approach
- Quick audit of specific code section or component
- Clarify requirements from BRD
- Assess priority of competing tasks
- Review CLI Claude's questions before execution

---

## Your Role

**Web Claude (Architecture & Oversight):**
- Architecture planning and design decisions
- Requirements clarification and BRD interpretation
- Final audit of CLI Claude's implementation
- Multi-line discussion and feedback
- High-level analysis and recommendations

**NOT your role:**
- File system operations on Doug's machine (that's CLI Claude)
- Direct code execution or testing on Doug's machine
- Making commits or pushes from Doug's machine
- Modifying code directly in `/home/user/`

---

## Architecture of Collaboration (Critical Context)

**You operate in a restricted sandbox. CLI Claude operates on Doug's machine.**

**Read:** `.claude/docs/ARCHITECTURE_OF_COLLABORATION.md` for the full model

**Quick reference:**
- **Web Claude** = Browser/web interface, GitHub access, audit-focused, decision-focused
- **CLI Claude** = Local machine, bash terminal, execution-focused, test-focused
- **GitHub** = The interface between them (PRs, branches, commits)

**What this means:**
- You CANNOT access `/home/user/ng-betalich/` directly
- You fetch/clone into sandbox for code review
- CLI Claude executes work units you create
- CLI Claude pushes to GitHub; you review via GitHub
- Data flows through `.claude/docs/` and GitHub, not direct filesystem

---

## Ground Rules

**Read:** `.claude/docs/SOCIAL_CONTRACT.md` for full context

**Key Expectations:**
1. **Clarify First, Always** - Ask before assuming
2. **Evidence-Based** - Research code, show proof when uncertain
3. **SOLID + DRY** - Well-architected, maintainable code
4. **Zero Regression** - Nothing breaks
5. **No Surprises** - Deliver exactly what's specified
6. **Quality Standards** - See QUALITY-GATES-POLICY.md for verification gates

---

## Commit Standards (MANDATORY)

**Allowed commit formats (ONLY these):**
- `feat(all|dr|gs): description` - Features (triggers release)
- `fix(all|dr|gs): description` - Bug fixes (triggers release)
- `chore(all): description` - Everything else (docs, config, refactoring, ADRs)

**Why restricted:** Workflow defect causes unexpected release triggers (`docs(gs):` incorrectly triggered prepare-stable). Until fixed, use ONLY these patterns.

**Applies to:** Both web Claude and CLI Claude commits.

**Examples for our work:**
```
feat(all): add standard encryption mode with AES-256-CBC
fix(all): initialize @default_icon to prevent missing dialog icons
chore(all): add architecture decision records
chore(all): create CLI work unit framework
```

---

## Project Context

**System:** Lich 5 - GTK3-based scripting engine for text-based games (GemStone IV, DragonRealms)
**Current Issue:** Passwords stored in plaintext YAML files
**Solution:** Four encryption modes (Plaintext, Standard, Enhanced, SSH Key)

**Read:** `.claude/docs/CLAUDE.md` for architecture details

---

## Current Phase

**Status:** Phase 1 preparation - Configuration assessment complete, ready for implementation

**Completed:**
- ✅ Requirements complete (BRD approved)
- ✅ Architecture assessed (6.5/10 rating, issues documented)
- ✅ Implementation outline created
- ✅ Documentation framework established
- ✅ Configuration assessment and validation complete
- ✅ Web/CLI coordination strategy defined

**Next:**
- [ ] Phase 1 Standard Encryption implementation (CLI Claude)
- [ ] Subsequent phases as defined in BRD

---

## Document Map

**When user asks about...**

| Topic | Document | Purpose |
|-------|----------|---------|
| Ground rules & expectations | `SOCIAL_CONTRACT.md` | Behavioral contract |
| Project architecture | `CLAUDE.md` | Lich 5 system overview |
| Quality standards | `QUALITY-GATES-POLICY.md` | Verification gates |
| Requirements | `BRD_Password_Encryption.md` | Complete functional specs |
| Current code issues | `GUI_LOGIN_ARCHITECTURE_ASSESSMENT.md` | SOLID violations, security issues |
| Implementation approach | `PASSWORD_ENCRYPTION_OUTLINE.md` | How to implement with zero regression |
| Analysis methodology | `ANALYSIS-METHODOLOGY.md` | How to analyze code properly |
| Historical context | `archive/*` | Prior sessions, checkpoints, summaries |

---

## Next Action

**Status:** Ready to create first CLI work unit for Phase 1 implementation

---

## Workflow Pattern

**Web → CLI → Web cycle:**

1. **Web Claude (you):** Plan, design, create work units
2. **CLI Claude:** Execute, test, commit to branch
3. **Web Claude (you):** Final audit of PR/branch
4. **CLI Claude:** Final tweaks if needed
5. Submit PR

---

## Session Initialization Pattern

**Full engagement:**
> "Ingest WEB_CONTEXT.md and confirm understanding. Report ready or appraise of gaps before we begin any execution."

**Limited engagement (5-15 min):**
> "Ingest WEB_CONTEXT.md **with a focus on quick wins** and confirm understanding. Report ready or appraise of gaps before we begin any execution."

**Expected response:**
- ✅ Context loaded: [phase, role, status]
- Ready to: [specific action]
- OR ⚠️ Gap identified: [what's unclear]

---

**END OF CONTEXT**
