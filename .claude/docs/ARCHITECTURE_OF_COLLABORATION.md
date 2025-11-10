# Architecture of Collaboration: Web Claude & CLI Claude

**Established:** 2025-11-10
**Status:** Active
**Critical for:** Session initialization and role clarity

---

## Two Separate Entities, One GitHub Interface

### Web Claude (Architecture & Oversight)
- **Environment:** Restricted sandbox with browser/web session interface
- **GitHub Access:** ✅ Full (via git CLI in sandbox)
- **Filesystem Access:** ❌ Restricted to sandbox only (`/tmp/` or similar, not `/home/user/`)
- **Direct Execution:** ❌ Cannot execute code on Doug's machine
- **Primary Work:**
  - Read and interpret requirements
  - Audit code submissions
  - Create architecture decisions and work units
  - Review PRs and provide feedback
  - Document guidance for CLI Claude

### CLI Claude (Execution & Testing)
- **Environment:** Doug's local machine (unrestricted)
- **GitHub Access:** ✅ Full (native git on local machine)
- **Filesystem Access:** ✅ Full (Doug's `/home/user/ng-betalich/` and all system files)
- **Direct Execution:** ✅ Can run `bash`, `ruby`, `rspec`, `rubocop` directly
- **Primary Work:**
  - Execute work units created by Web Claude
  - Make code changes, run tests locally
  - Commit to git branches on Doug's machine
  - Push to GitHub for review
  - Report blockers or questions

---

## Communication Flow

```
┌──────────────────┐
│  Web Claude      │
│  (Browser)       │
└────────┬─────────┘
         │
         │ (1) Reads PRs, creates work units
         │     via .claude/docs/ files
         │
         ↓
    ┌─────────────┐
    │   GitHub    │  ← Communication Interface
    │   (Remote)  │
    └─────────────┘
         ↑
         │ (2) Fetches branch locally,
         │     reviews code changes
         │
         ↓
┌──────────────────┐
│  CLI Claude      │
│  (Bash/Local)    │
└────────┬─────────┘
         │
         │ (3) Reads work units from .claude/docs/
         │     Executes on local machine
         │     Commits & pushes to GitHub
         │
         ↓
  ┌─────────────┐
  │   feature   │  ← PR submitted to GitHub
  │   branch    │
  └─────────────┘
```

---

## The Critical Difference: Access Boundaries

### What Web Claude Can Do
```bash
# ✅ Clone the repo into sandbox
git clone https://github.com/user/ng-betalich.git

# ✅ Fetch a PR branch for review
git fetch origin feat/password-encryption-standard

# ✅ Read code files in sandbox copy
cat lib/common/gui/password_cipher.rb

# ✅ Run rspec on sandbox copy (if tools installed)
bundle exec rspec spec/password_cipher_spec.rb

# ✅ Write documentation to .claude/docs/
# (via Read/Write tools that access sandbox)
```

### What Web Claude CANNOT Do
```bash
# ❌ Access Doug's actual /home/user/ environment
ls /home/user/ng-betalich/lib/

# ❌ Modify files on Doug's machine directly
# (Write tool would fail with permission/path error)

# ❌ Execute arbitrary commands on Doug's system
# (Sandbox prevents this)

# ❌ Run the actual Lich application
ruby /home/user/ng-betalich/lich.rbw

# ❌ Directly push code to GitHub
# (That's CLI Claude's job—it has credentials)
```

### What CLI Claude Does (What Web Claude Doesn't See Until PR Review)
```bash
# CLI Claude on Doug's machine:

# ✅ Make actual code changes
vim lib/common/gui/password_cipher.rb

# ✅ Run tests locally (instant feedback)
bundle exec rspec

# ✅ Run rubocop
bundle exec rubocop

# ✅ Commit to local git
git commit -m "feat(all): add standard encryption"

# ✅ Push to GitHub
git push -u origin feat/password-encryption-standard

# ✅ Create PR on GitHub
```

---

## Why This Architecture?

### Security
- Web Claude cannot access Doug's private data
- CLI Claude has unrestricted access but is in a controlled context (Product Owner's machine)
- Separation of concerns: architecture review is independent of code execution

### Efficiency
- CLI Claude gets instant feedback (tests, linting) on Doug's machine
- Web Claude reviews via GitHub (no direct filesystem needed)
- Work units flow through `.claude/docs/` (documented, auditable)

### Clarity
- No ambiguity about who runs what
- Code review happens through standard GitHub process
- Collaboration is asynchronous and traceable

---

## Data Flow for Code Changes

### Phase 1: Web Claude Creates Work Unit
```
Web Claude reads requirements
         ↓
Web Claude writes work unit to .claude/docs/
         ↓
(Commit to github if needed)
         ↓
Work unit exists in GitHub repo
```

### Phase 2: CLI Claude Executes
```
CLI Claude reads work unit from local .claude/docs/
         ↓
CLI Claude makes code changes locally
         ↓
CLI Claude runs tests locally (instant feedback)
         ↓
CLI Claude commits with conventional format
         ↓
CLI Claude pushes to feature branch on GitHub
         ↓
PR created on GitHub
```

### Phase 3: Web Claude Audits
```
Web Claude is notified of PR on GitHub
         ↓
Web Claude fetches branch locally (into sandbox)
         ↓
Web Claude reviews code in sandbox copy
         ↓
Web Claude may create new work unit if changes needed
         ↓
Web Claude or Product Owner posts feedback to PR
         ↓
(Repeat Phase 2 if needed)
```

### Phase 4: Merge & Release
```
PR approved by Product Owner
         ↓
Product Owner merges to main (via GitHub)
         ↓
Release Please workflow processes merge
         ↓
Version bumped, release created
```

---

## The Sanity Check: How Web Claude Knows Its Role

**At the start of every Web Claude session, ask these questions:**

1. **What medium are we using?**
   - If: Multi-turn text conversation → I am Web Claude
   - If: Bash terminal with prompts → I am CLI Claude

2. **Can I access `/home/user/ng-betalich/` directly?**
   - Try: `ls /home/user/ng-betalich/lib/`
   - If: Permission denied or path not found → I am Web Claude
   - If: Lists files → I am CLI Claude

3. **Where do work units come from?**
   - If: Product Owner describes requirements in conversation → I create work units and write them to docs
   - If: Work unit file exists in my cwd → I execute it

4. **What happens when I want to review code?**
   - If: I must `git clone` or `git fetch` into sandbox → I am Web Claude
   - If: Code is already in my cwd ready to modify → I am CLI Claude

5. **What is my next action?**
   - Web Claude: Read docs, understand context, make architectural decisions, create/review work units
   - CLI Claude: Read work unit, execute it, test, commit, push

---

## Session Initialization Protocol

### For Web Claude Sessions

**BEFORE DOING ANYTHING:**

1. **Confirm environment:**
   ```
   This is a browser/web conversation interface.
   I can clone/fetch git repos but cannot access /home/user/ directly.
   Therefore: I am Web Claude.
   ```

2. **Confirm role:**
   - Architecture and oversight
   - GitHub review interface
   - Work unit creation for CLI Claude
   - NO direct execution of code

3. **Read context hierarchy:**
   - WEB_CONTEXT.md (role definition)
   - SESSION_SUMMARY.md (what happened before)
   - Relevant work units or PRs (current state)

4. **Ask clarifying questions:**
   - What is the current state (PRs in beta, code review, waiting for feedback)?
   - What is expected of Web Claude in THIS session?
   - Are there any blockers from prior sessions?

### For CLI Claude Sessions

**BEFORE DOING ANYTHING:**

1. **Confirm environment:**
   ```
   This is a bash terminal on local machine.
   I have full filesystem and git access.
   I can run ruby, rspec, rubocop directly.
   Therefore: I am CLI Claude.
   ```

2. **Confirm role:**
   - Execute work units precisely as specified
   - Run tests and verify quality gates
   - Commit with conventional format
   - Push to designated branch
   - Report when complete or blocked

3. **Read work unit:**
   - What is the specific task?
   - What are acceptance criteria?
   - What are the test expectations?

4. **Execute:**
   - Make changes
   - Run tests
   - Verify acceptance criteria
   - Commit and push

---

## Troubleshooting Session Startup Confusion

### Symptom: "I'm not sure if I'm Web Claude or CLI Claude"

**Diagnostic:**
1. What interface am I using? (browser text vs. bash prompt)
2. Can I directly access `/home/user/`? (Try `ls /home/user/ng-betalich/`)
3. Is there a work unit file waiting? (Check for CURRENT.md)

**If browser + no `/home/user/` access:** You are Web Claude
- Your job: Read context, make decisions, create/review work units
- Your interface: GitHub and .claude/docs/ files
- Your next step: What is the current status? What decision is needed?

**If bash terminal + `/home/user/` accessible:** You are CLI Claude
- Your job: Execute work unit, test, commit, push
- Your interface: Local filesystem
- Your next step: Read CURRENT.md work unit and execute it

---

## FAQ

**Q: Can Web Claude directly modify code in `/home/user/`?**
A: No. Web Claude's Write tool can only write to the sandbox. To modify production code, CLI Claude must execute the change on Doug's machine and push to GitHub.

**Q: Can CLI Claude create architectural decisions?**
A: No. CLI Claude executes architectural decisions made by Web Claude. If CLI Claude encounters an architectural question, it escalates to Product Owner or Web Claude.

**Q: Why can't Web Claude just ssh into Doug's machine?**
A: Security boundary. Web Claude operates in a restricted environment (Claude Code sandbox). Direct access to Doug's machine would require trust relationship and credentials that don't exist in this architecture.

**Q: How does Web Claude review code if it's not on local disk?**
A: Web Claude clones/fetches the GitHub repo into its sandbox when review is needed. This gives Web Claude a copy of all submitted code for audit.

**Q: What if Web Claude and CLI Claude are both active?**
A: They are asynchronous. CLI Claude makes commits, pushes to GitHub. Web Claude fetches from GitHub, reviews, creates new work units. Product Owner coordinates timing.

---

**Principle:** GitHub is the interface. Data flows through it. Separation of concerns is clear. No confusion about who does what.

