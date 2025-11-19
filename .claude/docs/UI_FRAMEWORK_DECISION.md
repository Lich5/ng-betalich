# Lich UI Framework Migration: Decision Framework

**Date:** 2025-11-19
**Purpose:** Provide analysis framework for selecting UI framework for Lich 5.x+
**Status:** Decision support document - no decisions made

---

## THE FIRST QUESTION: ACCESSIBILITY REQUIREMENT

**Before evaluating frameworks, you must answer:**

### What level of accessibility support does Lich require?

| Level | Definition | Example Users | Compliance |
|-------|------------|---------------|------------|
| **NONE** | No screen reader support needed | Sighted users only, visual-only interface | Not accessible |
| **SOFT** | Basic screen reader support, best effort | Some accessibility, inconsistent experience | Partial compliance |
| **HARD** | Reliable screen reader support, legal/compliance standards | Full accessibility, consistent experience | Meets ADA/508/WCAG |

**This answer determines which frameworks are viable.**

---

## DECISION TREE BY ACCESSIBILITY REQUIREMENT

### If Accessibility = NONE

**Available frameworks:**
- LibUI (native widgets, poor a11y)
- FXRuby (self-contained, poor a11y)
- GTK4 (over-engineered if a11y not needed)
- Glimmer SWT (over-engineered if a11y not needed)

**Recommendation changes:**
- **LibUI becomes attractive** (fast, native, simple)
- **FXRuby becomes viable** (self-contained, no dependencies)
- GTK4/Glimmer SWT are overkill (complexity without benefit)

**Decision criteria:**
1. Installation simplicity
2. Native look-and-feel
3. Build pipeline simplicity
4. Long-term maintenance burden

---

### If Accessibility = SOFT

**Available frameworks:**
- GTK3 (current state, stays viable longer)
- GTK4 (improvement over GTK3)
- LibUI (basic a11y, platform-dependent)

**Not recommended:**
- FXRuby (poor a11y)
- Glimmer SWT (overkill for "soft" requirement)

**Decision criteria:**
1. How much improvement over GTK3 is needed?
2. How long can you tolerate inconsistent screen reader support?
3. Risk tolerance for partial compliance

---

### If Accessibility = HARD

**Available frameworks:**
- GTK4 (meets standard, not best-in-class)
- Glimmer SWT (exceeds standard, best-in-class)

**Not viable:**
- LibUI (fails standard)
- FXRuby (fails standard)
- GTK3 (insufficient)

**Decision criteria:**
1. MRI Ruby vs JRuby (script compatibility)
2. "Good enough" vs "best in class"
3. 6-9 months vs 9-12 months timeline
4. Build pipeline complexity

---

## FRAMEWORK COMPARISON (ALL LEVELS)

| Framework | Accessibility | Native Look | Install UX | Build Complexity | Viability | Script Compat | Ruby Platform |
|-----------|--------------|-------------|------------|------------------|-----------|---------------|---------------|
| **LibUI** | ❌ NONE/SOFT | ✅ Native | One-click | Low | Questionable | 100% | MRI Ruby |
| **FXRuby** | ❌ NONE/SOFT | 🟡 FOX theme | One-click | Low | Questionable | 100% | MRI Ruby |
| **GTK4** | ✅ HARD | 🟡 Linux-best | One-click | Medium | 10+ years | 100% | MRI Ruby |
| **Glimmer SWT** | ✅✅ HARD++ | ✅ True native | One-click | Low | 15+ years | 85-90% | JRuby |
| **GTK3** (current) | ⚠️ SOFT | 🟡 Linux-best | One-click | Medium | 2-3 years | 100% | MRI Ruby |

---

## DETAILED FRAMEWORK ANALYSIS

### LibUI (Viable if Accessibility = NONE)

**What it is:** Lightweight wrapper around native OS widgets

**Technical Stack:**
- MRI Ruby
- Native Cocoa (macOS), Win32 (Windows), GTK3 (Linux)
- Glimmer DSL for LibUI (optional, cleaner syntax)

**User Experience:**

*Installation:*
- Windows: 80-100MB installer
- macOS: 60-80MB .app bundle
- Linux: 70-90MB AppImage

*Daily Use:*
- Native widgets on all platforms
- Fast, responsive
- No accessibility support (screen readers won't work)

**Pros:**
- ✅ Truly native widgets (best visual appearance)
- ✅ Fast (lightweight, no heavy dependencies)
- ✅ Small installers
- ✅ Simple build pipeline
- ✅ MRI Ruby (100% script compatibility)

**Cons:**
- ❌ Poor accessibility (fails HARD requirement)
- ❌ Limited widget set (may not cover all Lich needs)
- ❌ Small community
- ❌ Questionable long-term viability

**Timeline:** 3-4 months

**Choose if:** Accessibility = NONE, want best visual UX, accept risk

---

### FXRuby (Viable if Accessibility = NONE)

**What it is:** Ruby bindings for FOX Toolkit (C++ GUI library)

**Technical Stack:**
- MRI Ruby
- FOX Toolkit (self-contained, no GTK/Qt dependency)
- Custom rendering (not OS native)

**User Experience:**

*Installation:*
- Windows: 100-120MB installer (includes FOX libraries)
- macOS: 90-110MB .app bundle
- Linux: 80-100MB AppImage

*Daily Use:*
- FOX-themed widgets (not OS native)
- Rich widget set (covers all Lich needs)
- No accessibility support

**Pros:**
- ✅ Self-contained (no GTK/Qt dependency)
- ✅ Rich widget set (everything needed)
- ✅ MRI Ruby (100% script compatibility)
- ✅ Lars Kanis maintains Windows support

**Cons:**
- ❌ Poor accessibility (fails HARD requirement)
- ❌ Non-native look (FOX theme stands out)
- ❌ Small community
- ❌ Aging codebase (FOX development slowed)

**Timeline:** 4-5 months

**Choose if:** Accessibility = NONE, want self-contained solution, don't care about native look

---

### GTK4 (Viable if Accessibility = SOFT or HARD)

**What it is:** Modern GTK toolkit (successor to GTK3)

**Technical Stack:**
- MRI Ruby
- GTK4 C libraries + Ruby bindings
- Gtk::Builder (Glade XML support)

**User Experience:**

*Installation:*
- Windows: 150-180MB installer (with binary gems)
- macOS: 140-170MB .app bundle
- Linux: 130-160MB AppImage

*Daily Use:*
- Native GTK widgets (best on Linux, acceptable on macOS/Windows)
- Reliable screen reader support (meets HARD standard)
- Familiar GTK3 workflow

**Pros:**
- ✅ Meets HARD accessibility requirement
- ✅ MRI Ruby (100% script compatibility)
- ✅ Gtk::Builder preserved (Glade XML works)
- ✅ 10+ year viability (active development)
- ✅ Proven technology

**Cons:**
- ⚠️ Still Linux-centric UX (acceptable but not native on macOS/Windows)
- ⚠️ Medium build complexity (binary gems needed)
- ⚠️ Larger installers than LibUI
- ⚠️ Ruby bindings less mature than GTK3

**Timeline:** 6-9 months (includes binary gem work)

**Choose if:** Accessibility = HARD, want lowest risk, stay in MRI Ruby

---

### Glimmer DSL for SWT (Viable if Accessibility = HARD)

**What it is:** Ruby DSL for Eclipse SWT (Java-based GUI toolkit)

**Technical Stack:**
- JRuby (not MRI Ruby)
- Eclipse SWT (Java JARs, no native compilation)
- Glimmer DSL (clean, Ruby-idiomatic syntax)

**User Experience:**

*Installation:*
- Windows: 100-120MB installer (JRuby + SWT JARs)
- macOS: 90-110MB .app bundle
- Linux: 80-100MB AppImage

*Daily Use:*
- True native widgets (Cocoa on macOS, Win32 on Windows, GTK on Linux)
- Best-in-class screen reader support (exceeds HARD standard)
- Startup +0.5-1s slower (JVM load)

**Pros:**
- ✅✅ Best accessibility (gold standard, exceeds HARD requirement)
- ✅ True native widgets (indistinguishable from native apps)
- ✅ Smaller installers (Java JARs vs C libraries)
- ✅ Low build complexity (no native compilation)
- ✅ 15+ year viability (Eclipse Foundation)

**Cons:**
- ⚠️ JRuby required (85-90% script compatibility estimated)
- ⚠️ Startup slower (JVM load time)
- ⚠️ Script migration effort (10-15% need fixes)
- ⚠️ Longer timeline (includes JRuby migration)

**Timeline:** 9-12 months (includes JRuby migration + script updates)

**Choose if:** Accessibility = HARD, want best-in-class, can tolerate JRuby migration

---

## USER IMPACT BY FRAMEWORK

### What Users See (Installation)

| Framework | Windows | macOS | Linux |
|-----------|---------|-------|-------|
| LibUI | 80-100MB download, one-click | 60-80MB .app, drag-drop | 70-90MB AppImage |
| FXRuby | 100-120MB download, one-click | 90-110MB .app, drag-drop | 80-100MB AppImage |
| GTK4 | 150-180MB download, one-click | 140-170MB .app, drag-drop | 130-160MB AppImage |
| Glimmer SWT | 100-120MB download, one-click | 90-110MB .app, drag-drop | 80-100MB AppImage |

**All options:** Zero dependencies, one-step install

---

### What Users See (Daily Use)

**LibUI:**
- Visual: Native widgets, fastest rendering
- Accessibility: Screen readers don't work

**FXRuby:**
- Visual: FOX theme (non-native), rich features
- Accessibility: Screen readers don't work

**GTK4:**
- Visual: GTK widgets (native-ish), smooth rendering
- Accessibility: Screen readers work reliably

**Glimmer SWT:**
- Visual: True native widgets (indistinguishable from OS apps)
- Accessibility: Screen readers work perfectly

---

### What Script Authors See

**LibUI/FXRuby/GTK4:**
- Zero changes (100% MRI Ruby compatibility)
- Scripts continue working unchanged

**Glimmer SWT:**
- 85-90% of scripts work unchanged
- 10-15% need JRuby compatibility fixes
- Top complex scripts (Bigshot): 4-8 hours conversion
- Simple scripts: 0-2 hours fixes

---

## IMPLEMENTATION TIMELINE BY FRAMEWORK

### LibUI Path (3-4 months)

**Month 1:** Build `Lich::UI` abstraction (LibUI backend)
**Month 2:** Migrate core Lich to LibUI
**Month 3:** Convert top 10 scripts
**Month 4:** Beta testing, release

**User impact:** Fast migration, native widgets, no accessibility

---

### FXRuby Path (4-5 months)

**Month 1:** Build `Lich::UI` abstraction (FXRuby backend)
**Month 2:** Migrate core Lich to FXRuby
**Month 3:** Convert top 10 scripts
**Month 4-5:** Beta testing, release

**User impact:** Self-contained, FOX theme, no accessibility

---

### GTK4 Path (6-9 months)

**Month 1-2:** Build binary gems + `Lich::UI` abstraction
**Month 3-4:** Migrate core Lich to GTK4
**Month 5-6:** Convert top 10 scripts (Glade conversion tool)
**Month 7-9:** Beta testing, release

**User impact:** Reliable accessibility, familiar GTK, zero script changes

---

### Glimmer SWT Path (9-12 months)

**Month 1-2:** Build `Lich::UI` abstraction + JRuby compatibility test
**Decision gate:** If <85% compatible → switch to GTK4
**Month 3-6:** Migrate core to JRuby + Glimmer SWT
**Month 7-9:** Convert top 10 scripts + build conversion tools
**Month 10-12:** Beta testing, release

**User impact:** Best accessibility, true native widgets, some script updates

---

## DECISION CRITERIA SUMMARY

### If Accessibility = NONE

**Optimize for:**
1. Visual appearance (native widgets)
2. Installation size
3. Build simplicity
4. Speed

**Top choices:**
- **LibUI** (best visual, smallest, fastest)
- **FXRuby** (self-contained, rich features)

---

### If Accessibility = SOFT

**Optimize for:**
1. Improvement over GTK3
2. Risk tolerance (partial compliance)
3. Timeline

**Top choices:**
- **Stay on GTK3** (delay migration)
- **GTK4** (moderate improvement)
- **LibUI** (accept platform-dependent a11y)

---

### If Accessibility = HARD

**Optimize for:**
1. Compliance level (meets vs exceeds)
2. Script compatibility (MRI Ruby vs JRuby)
3. Timeline (6-9 months vs 9-12 months)
4. Build complexity

**Top choices:**
- **GTK4** (meets standard, lowest risk)
- **Glimmer SWT** (exceeds standard, best long-term)

---

## QUESTIONS TO ANSWER

**Before choosing a framework, answer these:**

1. **What accessibility level is required?**
   - NONE → LibUI/FXRuby viable
   - SOFT → GTK4/LibUI viable
   - HARD → GTK4/Glimmer SWT only

2. **What is script compatibility tolerance?**
   - 100% required → LibUI/FXRuby/GTK4
   - 85-90% acceptable → Glimmer SWT viable

3. **What timeline is acceptable?**
   - 3-4 months → LibUI
   - 4-5 months → FXRuby
   - 6-9 months → GTK4
   - 9-12 months → Glimmer SWT

4. **How important is native appearance?**
   - Critical → LibUI or Glimmer SWT
   - Acceptable → GTK4
   - Don't care → FXRuby

5. **What build complexity tolerance?**
   - Low → LibUI, FXRuby, Glimmer SWT
   - Medium → GTK4

6. **How important is long-term viability?**
   - Critical → GTK4 (10 years) or Glimmer SWT (15 years)
   - Acceptable → LibUI/FXRuby (questionable)

---

## TECHNICAL IMPLEMENTATION (ALL PATHS)

### Common Foundation: Lich::UI Abstraction

**All paths benefit from `Lich::UI` abstraction layer:**

```ruby
# Instead of direct framework calls:
Gtk::Window.new  # or LibUI::Window, etc.

# Scripts use abstraction:
Lich::UI.window("Title") do
  # Framework-agnostic DSL
end
```

**Benefits:**
- Decouples scripts from framework
- Enables future migrations
- Simplifies script development
- Consistent API

**Implementation:** Same for all paths (40-60 hours)

---

### Binary Gems Strategy (GTK4 Only)

**Purpose:** Simplify build pipeline

**Platforms:**
- macOS Intel, macOS ARM
- Linux x64, Linux ARM
- Windows x64

**Effort:** 75-120 hours (one-time)

**Not needed for:** LibUI, FXRuby, Glimmer SWT (simpler bundling)

---

### App Bundle Strategy (All Paths)

**All frameworks support app bundles:**
- macOS: `.app` bundle
- Linux: AppImage
- Windows: InnoSetup installer (simplified)

**Effort:** 60-90 hours (varies by framework)

---

## SCRIPT MIGRATION EFFORT

### Lich Core Migration

| Framework | Core Effort | Script Effort (Top 10) | Total |
|-----------|-------------|----------------------|-------|
| LibUI | 40-60h | 20-30h | 60-90h |
| FXRuby | 50-70h | 30-40h | 80-110h |
| GTK4 | 80-100h | 30-50h | 110-150h |
| Glimmer SWT | 100-140h | 50-80h | 150-220h |

**Note:** Times exclude `Lich::UI` abstraction (add 40-60h for all paths)

---

### Bigshot Script Migration (Example)

**Bigshot complexity:** 7,581 lines, 6,487 lines of Glade XML

| Framework | Conversion Approach | Effort |
|-----------|-------------------|--------|
| LibUI | Glade XML → LibUI widgets (no tool) | 30-45h manual |
| FXRuby | Glade XML → FXRuby widgets (no tool) | 30-45h manual |
| GTK4 | Glade XML → GTK4 XML (automated tool) | 4-8h with tool |
| Glimmer SWT | Glade XML → Glimmer DSL (automated tool) | 8-12h with tool |

**Conversion tool development:**
- GTK4: 8-12 hours (property renames)
- Glimmer SWT: 30-40 hours (widget mapping + DSL generation)

---

## RECOMMENDATION PROCESS

### Step 1: Answer Accessibility Question
**Required input from stakeholders**

### Step 2: Apply Decision Tree
**Filter frameworks by accessibility requirement**

### Step 3: Evaluate Remaining Criteria
**Compare viable frameworks on other dimensions**

### Step 4: Make Decision
**Choose framework based on weighted priorities**

### Step 5: Optional Validation
**For Glimmer SWT: Run 2-week JRuby compatibility test before committing**

---

## NO DECISION MADE

**This document provides analysis only.**

**Next step:** Stakeholder meeting to answer:
1. What accessibility level is required?
2. What are the priority tradeoffs?
3. Which framework aligns with priorities?

**After decision:** Web Claude will design `Lich::UI` abstraction architecture for chosen framework.

---

**Session Context:** This document created during theoretical UI framework exploration session (2025-11-19). No code changes made—analysis document only.
