I need to create a `.docs/plans/[feature-name]/priority.md` document that ruthlessly prioritizes visionOS features into a 3-tier system.

Please provide the path to the planning directory (e.g., `.docs/plans/feature-name/`):

## Process

### 1. Read Planning Documents
Read both required documents (abort if missing):
- `.docs/plans/[feature-name]/requirements.md`
- `.docs/plans/[feature-name]/architecture.md`

### 2. Detect Project Type
Analyze: `.claude/` exists? Recent commits? Substantial codebase (>10 Swift files)? Requirements reference existing spatial Views?

**Auto-suggest then confirm:**
- **New visionOS App**: No .claude/, few commits, minimal files → MVP focus, ruthless stubbing
- **Feature Addition**: Established app → Core feature focus, minimal changes to existing spatial experiences

Ask: "I detected this is a [new visionOS app/feature addition]. Correct?"

### 3. Prioritization Strategy

**New visionOS Apps (MVP Focus):**
- Ask: "What's the absolute minimum for v0.1 to deliver value in spatial computing?"
- Most features → Tier 2 (stub) or Tier 3 (future)

**Feature Additions (Minimal Change):**
- Ask: "What's the minimal change needed for this visionOS feature?"
- Focus on core feature without breaking existing spatial Views or RealityKit components

### 4. Create 3-Tier System

Using `$CLAUDE_HOME/file-templates/priority.template.md`:

**Tier 1: Build Now** - Only absolute essentials for visionOS feature to function
**Tier 2: Stub/Placeholder** - Needed for structure but minimal (specify stub strategy for each)
**Tier 3: Future** - Out of scope, edge cases, polish

### 5. User Sign-Off
Present 3-tier breakdown: "Does this prioritization make sense? Adjustments needed?"

### 6. Write priority.md
Create `.docs/plans/[feature-name]/priority.md` following template.

**Rules:**
- Be RUTHLESS, especially for new visionOS apps
- Default to Tier 2 over Tier 1 when uncertain
- State WHY each item is in its tier
- Specify stub strategy for all Tier 2 items (e.g., "Placeholder 3D model", "Basic spatial gesture")
- Include relevant Swift file paths

Upon completion: "Priority plan complete. Run `/4-parallelization` next, or `/5-execution` if parallelization isn't needed."
