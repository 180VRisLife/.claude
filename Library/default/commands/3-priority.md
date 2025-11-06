I need to create a `.docs/plans/[feature-name]/priority.md` document that ruthlessly prioritizes features into a 3-tier system for implementation.

Please provide the feature description or the path to the planning directory (e.g., `.docs/plans/feature-name/`):

Once you provide the path, I'll read the requirements and architecture documents, then perform hybrid project detection to determine the appropriate prioritization strategy.

## Process

### 1. Read Planning Documents
First, read all existing planning documents:
- `.docs/plans/[feature-name]/requirements.md` (required)
- `.docs/plans/[feature-name]/architecture.md` (required)

If either file is missing, abort and ask the user to run the prerequisite commands first.

### 2. Hybrid Project Detection
Automatically detect project type by analyzing:
- Does `.claude/` directory exist?
- Are there recent git commits (within last 30 days)?
- Is there substantial codebase (>10 source files)?
- Does requirements.md reference existing files?

**Auto-suggest:**
- **New Project** if: No .claude/, few commits, minimal files, requirements don't reference existing code
- **Feature Addition** if: .claude/ exists, active commits, substantial codebase, requirements reference existing files

**Then ask user:**
"I detected this is a [new project/feature addition]. Is that correct?"

If user corrects, adjust the prioritization strategy accordingly.

### 3. Prioritization Strategy

**For New Projects (MVP Focus):**
- Ask: "What's the absolute minimum users need to see value in v0.1?"
- Ask: "Which features are essential vs nice-to-have?"
- Be RUTHLESS: Most features should be Tier 2 (stub) or Tier 3 (future)
- Explain: "We're prioritizing getting a working prototype fast. Many features will be stubbed."

**For Feature Additions (Minimal Change Focus):**
- Ask: "What's the minimal change needed to achieve this feature?"
- Ask: "Which aspects are must-haves vs could be added later?"
- More lenient on completeness than new projects
- Explain: "We're prioritizing not breaking existing functionality while adding this feature."

### 4. Create 3-Tier System

Using the template at `$CLAUDE_HOME/file-templates/priority.template.md`, create a priority plan with:

**Tier 1: Build Now**
- Only absolute essentials
- Complete implementations required for the feature to work
- For new projects: MVP features only
- For feature additions: Core feature functionality

**Tier 2: Stub/Placeholder**
- Needed for structure but can be minimal
- Placeholder implementations, mock data, hardcoded values
- For new projects: Most secondary features go here
- For feature additions: Optional enhancements that can wait

**Tier 3: Future**
- Explicitly out of scope
- Features that aren't needed for v0.1 or this feature
- Edge cases, optimizations, polish

### 5. Define Stub Strategies
For each Tier 2 item, specify HOW to stub it:
- "Return hardcoded mock data"
- "UI placeholder with 'Coming soon' message"
- "Basic implementation without error handling"
- "Simplified version without edge case support"

### 6. User Sign-Off
Before finishing, present the 3-tier breakdown and ask:
"Does this prioritization make sense? Any adjustments needed?"

Allow the user to move items between tiers or adjust stub strategies.

### 7. Write priority.md
Write the final priority plan to `.docs/plans/[feature-name]/priority.md` using the template structure.

Important rules:
- Be RUTHLESS in prioritization, especially for new projects
- Default to Tier 2 (stub) over Tier 1 (build) when uncertain
- Explicitly state WHY each item is in its tier
- For Tier 2, always specify the stub strategy
- Include relevant file paths for each feature
- Keep the rationale section concise but clear (2-3 sentences)

Upon completion, inform the user:
"Priority plan complete. Run `/4-parallelization` next to create the implementation plan, or `/5-execution` if parallelization isn't needed."
