# .claude/docs Inventory Matrix

**Purpose:** Determine which documents are essential, need updating, or should be removed

---

## Document Classification

### TIER 1: Essential (Keep As-Is)

| Document | Purpose | Status | Keep? |
|----------|---------|--------|-------|
| **WEB_CONTEXT.md** | Web Claude session initialization | Current, accurate | ✅ YES |
| **WEB_CLAUDE_ORIENTATION.md** | Sanity check for Web Claude | Current, accurate | ✅ YES |
| **SOCIAL_CONTRACT.md** | Product Owner expectations | Current, accurate | ✅ YES |
| **BRD_Password_Encryption.md** | Requirements source of truth | Current, comprehensive | ✅ YES |
| **ARCHITECTURE_OF_COLLABORATION.md** | Web/CLI separation model | Current, accurate | ✅ YES |
| **CLI_PRIMER.md** | Ground rules for CLI Claude | Current, accurate | ✅ YES |
| **QUALITY-GATES-POLICY.md** | Quality standards & verification | Current, applicable | ✅ YES |
| **README.md** | Directory overview & navigation | Current, minimal | ✅ YES |

---

### TIER 2: Supporting (Keep But May Need Update)

| Document | Purpose | Status | Notes | Keep? |
|----------|---------|--------|-------|-------|
| **CLAUDE.md** | Architecture & system overview | Potentially outdated | Refers to old file structure; review before next session | ⚠️ REVIEW |
| **PASSWORD_ENCRYPTION_OUTLINE.md** | Implementation approach | Still valid | Describes Standard + Enhanced, matches current approach | ✅ YES |
| **TRACEABILITY_MATRIX.md** | BRD → Code requirements mapping | Outdated | References old 5-PR strategy; should be updated to reflect "1 PR Standard+Enhanced" approach | ⚠️ UPDATE |
| **ANALYSIS-METHODOLOGY.md** | How to analyze code properly | Valid reference | General guidance, applicable to future work | ✅ YES |
| **SESSION_011C_SUMMARY.md** | Planning session notes | Historical reference | Documents decision-making process; useful for context but describes old strategy | ⚠️ ARCHIVE |

---

### TIER 3: Historical (Archive or Remove)

| Document | Purpose | Status | Reason | Action |
|----------|---------|--------|--------|--------|
| **ADR_SESSION_011C_PR_DECOMPOSITION.md** | Approved 5-PR decomposition strategy | **SUPERSEDED** | We abandoned the 5-PR approach; using 1 unified PR instead | 🗑️ DELETE |
| **ADR_SESSION_011C_TERMINOLOGY.md** | Decision on `:enhanced` vs `:master_password` | Valid but minor | Still applicable; could archive to reduce clutter | ⚠️ ARCHIVE |
| **STEP2_Decomposition_Strategy_DRAFT.md** | Draft decomposition plan | **SUPERSEDED** | Describes 5-PR strategy we abandoned | 🗑️ DELETE |
| **STANDARD_EXTRACTION_CURRENT.md** | Work unit for Standard mode extraction | **OBSOLETE** | Old strategy; we're copying files, not extracting | 🗑️ DELETE |
| **ENHANCED_CURRENT.md** | Work unit for Enhanced mode extraction | **OBSOLETE** | Old strategy; we're copying files, not extracting | 🗑️ DELETE |
| **SSH_KEY_CURRENT.md** | Work unit for SSH Key mode (Phase 2) | **NOT STARTED** | Future phase; will create when needed | 🗑️ DELETE |
| **MASTER_PASSWORD_CHANGE_CURRENT.md** | Work unit for master password change UI (Phase 3) | **NOT STARTED** | Future phase; will create when needed | 🗑️ DELETE |
| **SSH_KEY_CHANGE_CURRENT.md** | Work unit for SSH key change UI (Phase 3) | **NOT STARTED** | Future phase; will create when needed | 🗑️ DELETE |
| **INFOMON_FIX_PROPOSAL.md** | Fix for test pollution issue | **OUT OF SCOPE** | Unrelated to current password encryption work | 🗑️ DELETE |
| **INFOMON_NIL_POLLUTION_FIX.md** | Implementation of infomon fix | **OUT OF SCOPE** | Unrelated to current password encryption work | 🗑️ DELETE |
| **SESSION_011C_PR51_REVIEW.md** | Review of PR 51 | Historical reference | Useful for context but describes old decomposition | ⚠️ ARCHIVE |

---

### TIER 4: Audit/Reference (Keep for History or Remove)

| Document | Purpose | Status | Use Case | Action |
|----------|---------|--------|----------|--------|
| **AUDIT_PR38_CORRECTED.md** | Detailed audit of PR 38 | Reference only | We're now copying PR 38 as-is, not decomposing it; less useful | ⚠️ ARCHIVE |
| **AUDIT_PR38_Implementation_Status.md** | Status of PR 38 implementation | Reference only | Historical; documents completion of PR 38 | ⚠️ ARCHIVE |
| **AUDIT_PR51_STANDARD_MODE.md** | Audit of PR 51 (Standard mode) | Reference only | Historical analysis; may inform future reviews | ⚠️ ARCHIVE |
| **AUDIT_PR55_ENHANCED_MODE.md** | Audit of PR 55 (Enhanced mode) | Reference only | Historical analysis; may inform future reviews | ⚠️ ARCHIVE |
| **GUI_LOGIN_ARCHITECTURE_ASSESSMENT.md** | Assessment of existing code quality issues | Reference only | Identifies problems in codebase; useful for future refactoring | ✅ KEEP |
| **DECISIONS.md** | Decision log | Reference only | Documents past decisions; useful for understanding rationale | ⚠️ ARCHIVE |
| **TRACEABILITY_MATRIX.md** | Requirements → code mapping | **NEEDS UPDATE** | Should reflect current 1-PR strategy instead of 5-PR | ⚠️ UPDATE |

---

### TIER 5: Configuration

| Document | Status | Action |
|----------|--------|--------|
| **settings.local.json** | Configuration file | ✅ KEEP |

---

### TIER 6: Archive (Already Segregated)

| Document | Purpose | Action |
|----------|---------|--------|
| Archive files | Historical session notes | ✅ KEEP (already in archive/) |

---

## Recommended Actions

### IMMEDIATE (Before Next CLI Claude Session)

**Delete (5 files):**
```
ADR_SESSION_011C_PR_DECOMPOSITION.md  → describes 5-PR strategy we abandoned
STEP2_Decomposition_Strategy_DRAFT.md → describes 5-PR strategy we abandoned
STANDARD_EXTRACTION_CURRENT.md        → work unit for abandoned strategy
ENHANCED_CURRENT.md                   → work unit for abandoned strategy
INFOMON_FIX_PROPOSAL.md              → out of scope, test pollution fix
```

**Archive (5 files):**
```
ADR_SESSION_011C_TERMINOLOGY.md       → minor ADR, valid but not essential
SESSION_011C_SUMMARY.md               → session notes, useful history
SESSION_011C_PR51_REVIEW.md           → historical review
AUDIT_PR38_CORRECTED.md               → we're copying PR 38, not decomposing
DECISIONS.md                          → decision log, useful for context
```

**Update (1 file):**
```
TRACEABILITY_MATRIX.md                → update to reflect 1-PR (Standard+Enhanced) instead of 5-PR
```

**Delete (Future Phases - Not Started):**
```
SSH_KEY_CURRENT.md                    → will create when Phase 2 starts
MASTER_PASSWORD_CHANGE_CURRENT.md     → will create when Phase 3 starts
SSH_KEY_CHANGE_CURRENT.md             → will create when Phase 3 starts
INFOMON_NIL_POLLUTION_FIX.md          → out of scope
```

### KEEP AS-IS

```
✅ WEB_CONTEXT.md
✅ WEB_CLAUDE_ORIENTATION.md
✅ SOCIAL_CONTRACT.md
✅ BRD_Password_Encryption.md
✅ ARCHITECTURE_OF_COLLABORATION.md
✅ CLI_PRIMER.md
✅ QUALITY-GATES-POLICY.md
✅ README.md
✅ PASSWORD_ENCRYPTION_OUTLINE.md
✅ ANALYSIS-METHODOLOGY.md
✅ GUI_LOGIN_ARCHITECTURE_ASSESSMENT.md
✅ settings.local.json
✅ archive/* (all files)
```

---

## Summary

**Current State:** 35 files total (31 in root, 4 in archive)

**Recommended Cleanup:**
- 🗑️ Delete: 8 files (old strategy work units, obsolete docs)
- 📦 Archive: 5 files (historical reference, useful for context)
- ⚠️ Update: 1 file (TRACEABILITY_MATRIX.md)
- ✅ Keep: 13 files (essential + supporting + reference)
- ⚠️ Review: 1 file (CLAUDE.md for accuracy)
- ⏸️ Future: 3 files (create when starting Phase 2/3)

**Result After Cleanup:** ~20 active docs (13 keep + 5 archived + 2 in progress)

---

## Questions for You

1. **Approval to delete old work units?** (STANDARD_EXTRACTION_CURRENT, ENHANCED_CURRENT, SSH_KEY_CURRENT, etc.)
2. **Approval to archive historical docs?** (SESSION_011C_*, AUDIT_*, DECISIONS.md)
3. **Should I update TRACEABILITY_MATRIX.md now?** (to reflect 1-PR approach)
4. **Review CLAUDE.md for accuracy?** (before next Web Claude session)

