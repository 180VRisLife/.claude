# [Feature Name] Priority Plan

## Project Type
- [ ] New Project (MVP focus - ruthless prioritization, heavy use of stubs)
- [ ] Feature Addition (Minimal change focus - complete implementations)

*Auto-detected as: [detection reasoning]. Confirmed by user: [yes/no]*

## Tier 1: Build Now
**Complete implementations required for MVP/feature to function**

### Feature: [Feature Name]
- **What**: [Brief description of what this feature does]
- **Why Tier 1**: [Why this is absolutely essential - what breaks without it?]
- **Scope**: [What specifically needs to be built]
- **Files**:
  - /path/to/relevant/file
  - /path/to/other/file

### Feature: [Another Feature Name]
- **What**: [Brief description]
- **Why Tier 1**: [Essential reasoning]
- **Scope**: [What to build]
- **Files**:
  - /path/to/file

## Tier 2: Stub/Placeholder
**Minimal implementations - just enough to make Tier 1 work**

### Feature: [Feature Name]
- **What**: [Brief description of the complete feature]
- **Why Tier 2**: [Why it can be stubbed - not critical for MVP/core feature]
- **Stub Strategy**: [Specific approach to stub this]
  - Example: "Return hardcoded mock data array"
  - Example: "Show placeholder UI with 'Coming Soon' message"
  - Example: "Basic implementation without validation or error handling"
- **Files**:
  - /path/to/file (stub only)

### Feature: [Another Feature Name]
- **What**: [Brief description]
- **Why Tier 2**: [Reasoning]
- **Stub Strategy**: [How to implement minimally]
- **Files**:
  - /path/to/file

## Tier 3: Future
**Explicitly out of scope - do not build**

### Feature: [Feature Name]
- **What**: [Brief description of what this would be]
- **Why Tier 3**: [Why this isn't needed now - e.g., edge case, optimization, polish]
- **Future Consideration**: [When this should be revisited - e.g., "After MVP validation", "v2.0", "When we have 1000+ users"]

### Feature: [Another Feature Name]
- **What**: [Brief description]
- **Why Tier 3**: [Reasoning for postponement]
- **Future Consideration**: [When to build this]

## Prioritization Rationale
[2-3 sentences explaining the overall strategy]

For new projects: Explain what the MVP achieves and why these stubs are acceptable for v0.1.

For feature additions: Explain what the core feature needs vs what can be added incrementally later.

## Tier Summary
- **Tier 1**: X features (build complete)
- **Tier 2**: Y features (stub/placeholder)
- **Tier 3**: Z features (future)

## Next Steps
1. Review and approve this prioritization
2. Run `/parallelization` to create implementation plan (if ≥5 Tier 1 features)
3. Or run `/execution` directly for simple implementations (if <5 Tier 1 features)
