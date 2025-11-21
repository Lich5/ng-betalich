# Architecture of Collaboration: Web Claude & CLI Claude

**Established:** 2025-11-10
**Status:** Active
**Critical for:** Session initialization and role clarity

---

## Two Separate Environments, One GitHub Interface

### Web Claude (Architecture & Oversight)
- **Environment:** Browser/web interface, restricted sandbox
- **Repository Access:** Clones GitHub repo into sandbox (`git clone https://github.com/Lich5/ng-betalich.git`)
- **Local Work:** Creates work units, commits to `.claude/docs/`, pushes to GitHub
- **Code Review:** Fetches PR branches into sandbox, audits code changes locally
- **Direct Machine Access:** ❌ Cannot access Doug's macOS environment

### CLI Claude (Execution & Testing)
- **Environment:** Doug's macOS machine (`/Users/doug/dev/test/ng-betalich/`)
- **Repository Access:** Local git repository on macOS, pulls from GitHub
- **Local Work:** Executes work units, makes code changes, runs tests locally, commits, pushes
- **Direct Machine Access:** ✅ Full access to macOS filesystem and local development tools

### GitHub (The Interface)
- Central repository: `https://github.com/Lich5/ng-betalich.git`
- Pull requests, branches, commits, tags
- Single source of truth for all code and documentation changes

---

## How It Works: The Synchronization Loop

```
Web Claude (Sandbox)           GitHub                    CLI Claude (macOS)
─────────────────────────────────────────────────────────────────────────

1. Clone repo
   git clone https://...  ──→  (GitHub remote)
   (sandbox copy)

2. Work on .claude/docs/
   - Create work units
   - Document decisions
   - Commit locally
   git commit
   git push  ─────────────────→ (feat/something branch)

3. (Wait for CLI Claude)

                         ←────── git pull
                                 (CLI Claude fetches)
                                 Reads work unit from .claude/docs/
                                 Executes on macOS
                                 Runs tests locally
                                 Commits to feature branch
                                 git push ──→ (Creates PR)

4. Fetch PR branch
   git fetch origin
   git checkout feat/something
   Review code in sandbox
   Audit against spec

5. Post feedback
   (if issues found, create new work unit)
   Commit & push ───────────────→ (new work unit in .claude/docs/)

                         ←────── git pull
                                 (CLI Claude gets feedback)
                                 Makes corrections
                                 Commits & pushes

6. (Repeat until approved)

7. Merge to main (Product Owner)
   PR approved ──────────────────→ Merge via GitHub
                                   git pull origin main
                                   Local repo updated
```

---

## Web Claude's Workflow

### Phase 1: Setup & Planning
```
Web Claude (Sandbox):
  git clone https://github.com/Lich5/ng-betalich.git
  cd ng-betalich

  # Read existing documentation
  cat .claude/docs/SESSION_011C_SUMMARY.md
  cat .claude/docs/BRD_Password_Encryption.md

  # Understand current state
  git log --oneline | head -20
  git branch -r
```

### Phase 2: Create Work Unit
```
Web Claude (Sandbox):
  # Create new work unit
  vim .claude/docs/ENHANCED_CURRENT.md

  # Document architectural decisions
  vim .claude/docs/ADR_SESSION_011C_*.md

  # Commit and push
  git add .claude/docs/
  git commit -m "chore(all): create work unit for PR-Enhanced"
  git push origin claude/web-context-pr-51-setup-[sessionid]
```

### Phase 3: Code Review & Audit
```
Web Claude (Sandbox):
  # Fetch PR branch from CLI Claude
  git fetch origin feat/password-encryption-standard

  # Check out PR branch locally
  git checkout feat/password-encryption-standard

  # Review code files
  cat lib/common/gui/password_cipher.rb
  cat spec/password_cipher_spec.rb

  # Run tests in sandbox to verify
  bundle exec rspec spec/password_cipher_spec.rb

  # If issues found, create new work unit
  vim .claude/docs/FEEDBACK_PASSWORD_CIPHER.md
  git add .claude/docs/
  git commit -m "chore(all): add audit feedback for password cipher"
  git push origin claude/web-context-pr-51-setup-[sessionid]
```

### Phase 4: Post Review
```
Web Claude (via GitHub UI or comment):
  Link to feedback in .claude/docs/
  Tag CLI Claude and Product Owner
  Await corrections
```

---

## CLI Claude's Workflow

### Phase 1: Setup
```
CLI Claude (macOS):
  cd /Users/doug/dev/test/ng-betalich/

  # Pull latest from GitHub
  git pull origin main

  # Create feature branch
  git checkout -b feat/password-encryption-standard
```

### Phase 2: Read Work Unit
```
CLI Claude (macOS):
  # Pull work unit from GitHub
  git pull origin claude/web-context-pr-51-setup-[sessionid]

  # Read the work unit
  cat .claude/docs/STANDARD_EXTRACTION_CURRENT.md
```

### Phase 3: Execute
```
CLI Claude (macOS):
  # Make code changes
  vim lib/common/gui/password_cipher.rb
  vim lib/common/gui/conversion_ui.rb

  # Run tests locally (instant feedback)
  bundle exec rspec spec/password_cipher_spec.rb

  # Run linting
  bundle exec rubocop lib/common/gui/password_cipher.rb

  # Commit
  git add lib/common/gui/
  git commit -m "feat(all): add standard encryption mode"

  # Push to GitHub (creates PR)
  git push -u origin feat/password-encryption-standard
```

### Phase 4: Wait for Review & Fix
```
CLI Claude (macOS):
  # Wait for Web Claude's audit feedback

  # If corrections needed, pull feedback
  git pull origin claude/web-context-pr-51-setup-[sessionid]

  # Read feedback
  cat .claude/docs/FEEDBACK_PASSWORD_CIPHER.md

  # Make corrections
  vim lib/common/gui/password_cipher.rb

  # Test corrections
  bundle exec rspec

  # Commit & push
  git add lib/common/gui/
  git commit -m "fix(all): address audit feedback on password cipher"
  git push origin feat/password-encryption-standard
```

---

## Key Points for Web Claude

### What You Have
- ✅ GitHub repository cloned into sandbox
- ✅ Ability to create/edit `.claude/docs/` files locally
- ✅ Ability to commit and push to GitHub
- ✅ Ability to fetch PR branches and review code locally
- ✅ Ability to run tests in sandbox for verification

### What You Don't Have
- ❌ Direct access to `/Users/doug/dev/test/ng-betalich/` on macOS
- ❌ Ability to execute code on Doug's actual machine
- ❌ Ability to push code to feature branches (CLI Claude does that)
- ❌ Credentials to merge PRs to main (Product Owner does that)

### Your Responsibilities
- Read and understand requirements (BRD)
- Create architectural decisions (ADRs)
- Create and update work units (`.claude/docs/`)
- Commit work units to GitHub
- Fetch PR branches and review code for audit
- Post feedback and guidance for CLI Claude
- Verify quality gates are met

### Boundary
**You work in sandbox. CLI Claude works on macOS. GitHub synchronizes between you.**

---

## Key Points for CLI Claude

### What You Have
- ✅ Full access to `/Users/doug/dev/test/ng-betalich/`
- ✅ Ruby, RSpec, RuboCop, all development tools
- ✅ Ability to run actual Lich application
- ✅ Ability to commit and push to GitHub
- ✅ Instant feedback from local testing

### What You Don't Have
- ❌ Ability to make architectural decisions (that's Web Claude)
- ❌ Ability to change work unit scope without escalation
- ❌ Direct access to Web Claude's sandbox

### Your Responsibilities
- Read work units from `.claude/docs/` (via git pull)
- Execute work units precisely as specified
- Run tests locally and verify all pass
- Commit with conventional format
- Push to feature branches on GitHub
- Report blockers to Product Owner
- Wait for Web Claude's code review

### Boundary
**You execute on your machine. GitHub is the interface. Web Claude reviews via PR.**

---

## The Two-Environment Model

**This is NOT:**
- Filesystem synchronization
- Remote code execution
- Shared directory access
- SSH tunneling

**This IS:**
- Two independent environments
- Git as the synchronization mechanism
- Work units as documentation flowing through GitHub
- Code review through PR branches

**Data flows through:**
1. `.claude/docs/` files (work units, decisions, feedback)
2. Git commits (all changes)
3. GitHub PRs (review interface)

**NOT through:**
- Direct filesystem access
- Command execution on other machine
- Clipboard/file transfer

---

## Session Initialization Checklist for Web Claude

Before starting work, confirm:

- [ ] I am in a browser/web interface (not bash terminal)
- [ ] I have cloned the GitHub repo into my sandbox
- [ ] I can read/write `.claude/docs/` in my sandbox
- [ ] I can fetch PR branches for code review
- [ ] I understand I cannot access Doug's macOS environment directly
- [ ] I know the current state (which PR is in progress, what's being worked on)
- [ ] I understand what decision/review/guidance is being asked of me

---

## Session Initialization Checklist for CLI Claude

Before starting work, confirm:

- [ ] I am on Doug's macOS machine (bash terminal)
- [ ] I have pulled the latest from GitHub
- [ ] I can access `/Users/doug/dev/test/ng-betalich/`
- [ ] I have read the work unit from `.claude/docs/`
- [ ] I understand the acceptance criteria
- [ ] I know what tests need to pass
- [ ] I understand I cannot make architectural changes

---

## FAQ

**Q: How does Web Claude know what CLI Claude did if they can't share files?**
A: GitHub. CLI Claude pushes commits to a feature branch. Web Claude fetches that branch and reviews it.

**Q: How does CLI Claude get work units if they're in Web Claude's sandbox?**
A: Web Claude commits them to `.claude/docs/` and pushes to GitHub. CLI Claude pulls from GitHub.

**Q: Why not just give Web Claude access to macOS?**
A: Security boundary. Web Claude is in a restricted sandbox intentionally. GitHub is the safe interface.

**Q: Can Web Claude run the actual Lich application?**
A: Not on Doug's machine. In sandbox, only if tools are installed, and it would be a sandbox instance.

**Q: What if Web Claude and CLI Claude disagree on something?**
A: Escalate to Product Owner. That's what the `claude-context` hook and this social contract are for.

**Q: How are credentials managed?**
A: CLI Claude has macOS git credentials. Web Claude uses sandbox git (no credentials needed for reading public repo, credentials for pushing if needed).

---

**Principle:** GitHub is the interface. Work units flow through it. Code review happens through it. Separation is clean and secure.

