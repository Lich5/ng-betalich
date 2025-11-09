# ADR: Encryption Mode Terminology Alignment

**Date:** 2025-11-09
**Status:** Accepted
**Session:** 011CUwNHp9TzigghtU94X9aZ
**Decision Makers:** Product Owner (Doug), Web Claude

---

## Context

The BRD Password Encryption specification and PR #38 implementation used inconsistent terminology for encryption modes:
- **BRD:** "Enhanced Mode" (ENC-3)
- **Code Implementation:** `:master_password` symbol and "Master Password" in UI

This created confusion during code review and documentation.

---

## Decision

**Standardize on "Enhanced" terminology across all code, documentation, and UI:**

### Code Changes
- Symbol: `:master_password` → `:enhanced`
- Method names: `master_password_*` → `enhanced_*` (where appropriate)
- Comments: "master password" → "enhanced encryption"
- Test descriptions: Update to use "enhanced" terminology

### UI Changes
- Dialog labels: "Master Password Encryption" → "Enhanced Encryption"
- Tooltips and help text: Align with "enhanced" terminology
- Error messages: Use "enhanced mode" language

### Documentation Changes
- All markdown files: Update references
- YARD documentation: Use "enhanced" terminology
- Comments: Align with new terminology

### Exceptions (Keep "Master Password")
- **User-facing prompts:** "Enter Master Password" (clearer to users what they're entering)
- **Keychain service name:** May retain internal references if changing breaks compatibility
- **Variable names for password values:** `master_password` variable OK when it literally holds the password

---

## Rationale

1. **BRD Alignment:** BRD is the source of truth for requirements
2. **Avoid Confusion:** "Master Password" implies it unlocks everything (misleading - it's just one encryption mode)
3. **Future-Proofing:** "Enhanced" allows for future upgrades without terminology clash
4. **Consistency:** Single term across all artifacts reduces cognitive load

---

## Consequences

### Positive
- Clear alignment between BRD and implementation
- Easier code review (consistent terminology)
- Better user understanding (mode is "enhanced encryption", password is "master password")

### Negative
- Requires systematic rename across PR #38 code
- Existing CURRENT.md work unit needs update
- Some internal implementation details may still use "master_password" for clarity

---

## Implementation Notes

**Scope of Change:**
- All new PRs (Standard, Enhanced, SSH Key) use `:enhanced` symbol
- UI text updated in all modes
- Documentation files updated
- Test descriptions updated

**Migration from PR #38:**
- Extract code with `:master_password` symbol
- Systematically replace with `:enhanced` during extraction
- Verify with `grep -r "master_password"` after changes

**Verification:**
```bash
# Should return minimal results (only password variables, keychain internals)
grep -r "master_password" lib/

# Should return zero results in user-facing code
grep -r ":master_password" lib/
```

---

## Related Decisions
- See ADR_SESSION_011C_PR_DECOMPOSITION.md for PR structure
- See BRD_Password_Encryption.md for original requirements (unchanged, implementation aligns to it)

---

**Status:** Active - Apply to all new work starting with STANDARD_EXTRACTION_CURRENT.md
