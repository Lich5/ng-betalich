# Lich::UI Work Units Index

**Created:** 2025-11-19
**Status:** Ready for execution
**Related Documents:** See `.claude/docs/UI_FRAMEWORK_*.md` for theoretical analysis

---

## Overview

This index tracks the work units for implementing the `Lich::UI` abstraction layer, enabling Lich to migrate from GTK3 to future UI frameworks (GTK4, Glimmer SWT, etc.) without breaking 1000+ existing scripts.

---

## Work Unit Tracks

### GTK3 Track (Serialized Execution)

Migrate Lich to use `Lich::UI` abstraction with GTK3 as the default backend.

**Branch:** `feat/lich-ui-abstraction`

| Phase | Work Unit | Status | Dependencies | Effort |
|-------|-----------|--------|--------------|--------|
| 1 | [LICH_UI_PHASE_1_GTK3_BACKEND.md](LICH_UI_PHASE_1_GTK3_BACKEND.md) | Ready | None | 8-12h |
| 2 | [LICH_UI_PHASE_2_SCRIPT_API.md](LICH_UI_PHASE_2_SCRIPT_API.md) | Blocked | Phase 1 | 6-8h |
| 3 | [LICH_UI_PHASE_3_LOGIN_GUI.md](LICH_UI_PHASE_3_LOGIN_GUI.md) | Blocked | Phases 1+2, Top 10 scripts passing | 12-16h |
| 4 | [LICH_UI_PHASE_4_CORE_MIGRATION.md](LICH_UI_PHASE_4_CORE_MIGRATION.md) | Blocked | Phase 3 approved | 20-30h |

**Total Effort:** 46-66 hours

**Execution Order:** Sequential (1 → 2 → 3 → GATE → 4)

---

### JRuby/SWT Track (Parallel POC)

Proof-of-concept for JRuby + Glimmer DSL for SWT as alternative framework.

**Branch:** `poc/jruby-glimmer-swt`

| Work Unit | Status | Dependencies | Effort |
|-----------|--------|--------------|--------|
| [POC_JRUBY_GLIMMER_SWT.md](POC_JRUBY_GLIMMER_SWT.md) | Ready | Phase 1 recommended | 16-24h |

**Execution:** Can run in parallel with GTK3 Phases 2-4

---

## Execution Strategy

### Sequential GTK3 Track

```
Phase 1: Lich::UI + GTK3 Backend
    ↓
Phase 2: Script API Modernization
    ↓
Phase 3: Login GUI Migration → Test top 10 scripts
    ↓
  GATE: Approve/Reject Phase 4
    ↓
Phase 4: Core Lich Migration → Test 50-60 scripts
    ↓
  COMPLETE: Ready for framework migration
```

### Parallel JRuby POC

```
POC: JRuby + Glimmer SWT
  ↓
Report: PROCEED / REVISE / ABANDON
  ↓
If PROCEED: Full Glimmer implementation
If ABANDON: Fallback to GTK4
```

---

## Testing Gates

### Gate 1: Phase 2 → Phase 3
- **Criteria:** Top 10 scripts run without errors
- **Scripts:** bigshot, go2, repository, waggle, loot, buff, sloot, afk, autostart, xptrack
- **Pass:** Proceed to Phase 3
- **Fail:** Fix issues, re-test

### Gate 2: Phase 3 → Phase 4
- **Criteria:** Login GUI fully functional, top 10 scripts still passing
- **Testing:** Manual + automated
- **Decision:** APPROVE / HOLD / REJECT Phase 4
- **Pass:** Proceed to Phase 4
- **Fail:** Fix issues or revise approach

### Gate 3: Phase 4 → Production
- **Criteria:** 50-60 scripts pass, all core features work
- **Testing:** Extended script suite
- **Decision:** Ready for framework migration OR need revisions

### Gate 4: JRuby POC → Full Implementation
- **Criteria:** > 85% core functionality works
- **Performance:** < 10s startup, < 500MB memory
- **Decision:** PROCEED / REVISE / ABANDON

---

## Success Metrics

### GTK3 Track

| Metric | Target | Measured At |
|--------|--------|-------------|
| Unit test coverage | 90%+ | Each phase |
| RuboCop offenses | 0 | Each phase |
| Top 10 script pass rate | 100% | Phases 2, 3, 4 |
| Extended script pass rate | 95%+ | Phase 4 |
| Performance regression | 0% | Phase 4 |

### JRuby POC

| Metric | Target |
|--------|--------|
| Startup time | < 10s |
| Memory usage | < 500MB |
| Core functionality | > 85% |
| Script compatibility | > 85% |

---

## Deliverables by Phase

### Phase 1 (GTK3 Backend)
- ✅ `lib/common/ui.rb`
- ✅ `lib/common/ui/base_backend.rb`
- ✅ `lib/common/ui/gtk3_backend.rb`
- ✅ Unit tests
- ✅ Architecture decision record

### Phase 2 (Script API)
- ✅ Modified `lib/common/script.rb`
- ✅ UI injection mechanism
- ✅ Unit tests
- ✅ Integration tests (top 10 scripts)
- ✅ Migration guide for script authors

### Phase 3 (Login GUI)
- ✅ Migrated `gui-login.rb`
- ✅ Migrated `gui-manual-login.rb`
- ✅ Extended `Lich::UI` methods (as needed)
- ✅ Unit + integration tests
- ✅ **GATE DECISION:** Approve Phase 4?

### Phase 4 (Core Migration)
- ✅ All GTK3 calls migrated or documented
- ✅ Extended `Lich::UI` methods
- ✅ GTK3 migration inventory
- ✅ Extended test suite (50-60 scripts)
- ✅ Performance tests
- ✅ Complete documentation

### JRuby POC
- ✅ `Lich::UI::GlimmerSWTBackend`
- ✅ Minimal login window
- ✅ JRuby compatibility fixes
- ✅ POC report
- ✅ **DECISION:** Proceed/Revise/Abandon

---

## Risk Management

### High Risks

| Risk | Phase | Mitigation |
|------|-------|-----------|
| Script compatibility breaks | 2, 3, 4 | Maintain backward compat, test extensively |
| Performance regression | 4 | Benchmark, optimize delegation |
| Complex widgets hard to abstract | 3, 4 | Defer complex widgets, keep GTK3 backend |
| JRuby incompatibilities | POC | Early testing, identify blockers |

### Medium Risks

| Risk | Phase | Mitigation |
|------|-------|-----------|
| Incomplete abstraction | 1 | Iterative design, extend as needed |
| Testing time (60 scripts) | 4 | Automate tests, parallelize |
| POC reveals blockers | POC | Have fallback plan (GTK4) |

---

## Documentation

### For Developers
- `.claude/docs/ADR_LICH_UI_ABSTRACTION.md` - Architecture decision
- `.claude/docs/LICH_UI_DEVELOPER_GUIDE.md` - Implementation guide
- `.claude/docs/SCRIPT_UI_MIGRATION_GUIDE.md` - Script author guide

### For Stakeholders
- `.claude/docs/UI_FRAMEWORK_DECISION.md` - Decision framework (completed)
- `.claude/docs/UI_FRAMEWORK_TECHNICAL_ADDENDUM.md` - Implementation details (completed)
- `.claude/docs/UI_FRAMEWORK_DELIVERY_ADDENDUM.md` - Delivery strategy (completed)

### POC Reports
- `.claude/docs/POC_JRUBY_GLIMMER_SWT_REPORT.md` - JRuby POC findings

---

## Next Actions

### For Product Owner
1. Review work units
2. Approve execution start
3. Decide on parallel vs sequential execution (GTK3 + JRuby POC)

### For CLI Claude
1. **Ready to start:** Phase 1 on branch `feat/lich-ui-abstraction`
2. **Can start parallel:** JRuby POC on branch `poc/jruby-glimmer-swt`
3. Follow work units sequentially within GTK3 track

---

## Completion Status

- [ ] Phase 1: GTK3 Backend
- [ ] Phase 2: Script API
- [ ] Phase 3: Login GUI (+ Gate approval)
- [ ] Phase 4: Core Migration
- [ ] JRuby POC (+ Decision)

**Overall Progress:** 0% (Ready to start)

---

**Last Updated:** 2025-11-19
**Status:** All work units created, ready for execution
