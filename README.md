# Claude Development Configuration

A comprehensive configuration system for Claude to build production-ready applications across any domain with parallel agent orchestration, automated workflows, and extensible templates.

## Copy-Pastable Commands & Prompts

### Getting Started

**First time in a new project:**
```
/init-workspace
```
This command automatically detects your project type (visionos, web, etc.) and copies the appropriate domain configuration from the Library to your local `.claude/` folder.

### Planning Commands (Domain-Specific)
*Execute in this order when building a new feature:*
*Clear Claude's memory and tag in .docs/plans/[FEATURENAME] directory each time you run these commands*

**Full Workflow:**
```
/1-requirements
```
Creates a requirements document with user flows, functional requirements, and UI/system specifications (non-technical, user-focused)

```
/2-architecture
```
Documents architecture overview, relevant files, patterns, and database schemas (technical design)

```
/3-priority
```
Ruthlessly prioritizes features into 3 tiers: Tier 1 (build now), Tier 2 (stub/placeholder), Tier 3 (future). Includes hybrid project detection (new project vs feature addition).

```
/4-parallelization
```
Creates parallelizable task breakdown with dependencies, agent assignments, and implementation phases. Includes smart detection to suggest sequential execution for simple projects (<5 Tier 1 tasks).

```
/5-execution
```
Orchestrates implementation with phase-by-phase review pauses. Re-runnable (tracks progress via execution-status.json), supports iterative feedback, and allows one-shot mode.

**Simplified Workflow** (for simple features):
```
/1-requirements → /2-architecture → /3-priority → /5-execution
```
Skip `/4-parallelization` for features with fewer than 5 priority tasks

### Git Command (Domain-Agnostic)
```
/git
```
Analyzes git changes and orchestrates commits - Determines if changes are small (handle directly) or large (delegate documentation to parallel agents), then stages and commits

### Parallel Development with Git Worktrees

**Use worktrees to run multiple Claude instances on different features simultaneously.**

**Primary Workflow:**

1. Create worktree for isolated development:
```
/wt [feature description]
```
Auto-generates directory and branch name (e.g., `/wt user authentication` → `.worktrees/user-authentication/`)

2. Implement and test the feature in the worktree directory

3. Commit, merge, and cleanup:
```
/git
```
Automatically handles commits, merges back to base branch, removes the worktree, and deletes the branch (local + remote).

**Managing Multiple Worktrees:**
```
/wt-mgmt
```
- Check status of all worktrees (merge readiness, conflicts, stale branches)
- Manage multiple parallel worktrees
- Clean up orphaned or abandoned worktrees
- Resolve conflicts before merging

**Key Points:**
- Each worktree is created in `.worktrees/` subdirectory within your repo
- Prevents worktrees from different projects mixing together in your workspace
- Enables multiple Claude instances on different features without conflicts
- Main workspace remains untouched while working in worktree
- `/git` handles the full workflow (commit → merge → cleanup → branch deletion)

### New Feature Prompt (Domain-Aware)
```
Add a new feature for [FEATURE_NAME] within the [DOMAIN_NAME] domain that [FEATURE_DESCRIPTION e.g., "enables users to export their data in multiple formats"].

CRITICAL STRUCTURE REQUIREMENT:
- BEFORE creating ANY file, you MUST first Read the corresponding default example from library/default/agents/specialist/
- The structure must be EXACTLY the same as the default version
- ONLY replace the specific default/base parts with the new specialist-specific content
- Keep ALL formatting, sections, subsections, and organizational patterns identical

Steps:
1. Create specialist agent in library: ~/.claude/library/[domain]/agents/specialist/[specialist-name].md
2. Research the specified feature's best practices for the domain's development thoroughly on the internet
3. For the specialist file you create:
   a. FIRST read a corresponding default specialist agent from library/default/agents/specialist/ as your exact template
   b. Maintain the EXACT same structure, headers, and organization
   c. Replace ONLY the default-specific technical content with specialist-specific content
   d. Keep the same level of detail and documentation style
4. Build comprehensive documentation that covers all aspects of implementing the specified feature while maintaining consistency with existing domain patterns
5. Review guide files to determine if this specialist agent should be mentioned:
   a. Read library/[domain]/guides/implementation.md - Consider adding to "Feature Development" section if this is a common feature type
   b. Read library/[domain]/guides/parallel.md - Consider adding to examples if this agent is commonly used in parallel
   c. Read library/[domain]/guides/always-active/foundation.md - Consider adding to "Domain specialists" if this is a primary specialist
   d. Note: Only update guide files if the agent represents a significant, frequently-used feature type. Most specialists don't require guide updates.

File structure:
- Specialist agents: agents/specialist/[specialist-name].md (e.g., agents/specialist/backend-feature.md, agents/specialist/shareplay-feature.md)

Start by researching best practices for the specified feature in the given domain, then create the feature documentation by reading a default feature template immediately before creating the domain-specific version.
```

### New Domain Prompt (Domain Creation)
```
Create a new development domain for [DOMAIN_NAME] in Claude's Library that [DOMAIN_DESCRIPTION e.g., "supports building scalable web applications with React"].

CRITICAL INSTRUCTIONS:
- Do NOT create any files unless explicitly listed below (no README, no extra documentation)
- BEFORE creating ANY file or folder, you MUST first Read the corresponding default example from library/default/
- The structure must be EXACTLY the same as the default version
- ONLY replace the specific default/core parts with the new domain equivalents
- Be EXTREMELY skeptical about making changes - when in doubt, keep it identical to default

Steps:
1. Create a new domain folder in library: ~/.claude/library/[domain]/
2. Create subfolders: agents, commands, file-templates, guides, hooks
3. For EACH file you create:
   a. FIRST read the corresponding library/default/ file to use as your EXACT template
   b. Analyze what needs changing:
      - File Templates: Need MINIMAL changes (often just domain name references)
      - Agents/Features: Need MAJOR content changes BUT exact same structure
      - Commands/Hooks: Need moderate changes, keep the same logic flow
   c. Maintain EXACTLY the same:
      - File and folder naming patterns
      - Section headers and organization
      - Documentation depth and style
      - Code structure and patterns
   d. Replace ONLY the default-specific technical content
4. Research the specified domain's development best practices thoroughly on the internet
5. Create a settings.local.template.json matching the structure in library/default/settings.local.template.json
6. Preserve flat folder structure (all files directly in their respective top-level folders)
7. Update ~/.claude/scripts/init-workspace.py to add detection logic for the new domain:
   a. Read the script to understand the detection pattern
   b. Add domain indicators (strong and medium) following the existing pattern
   c. Add detection logic in the correct priority order
   d. Ensure package.json/config file checks are domain-specific

Agent Requirements:
- Create ALL 5 base agents (code-finder, code-finder-advanced, implementor, library-docs-writer, root-cause-analyzer)
- Create EXACTLY 3 specialist agents that represent the most important/common features for this domain
- Specialist agents should cover distinct aspects of the domain (e.g., frontend/backend/fullstack or different framework capabilities)

File structure conventions:
- agents/base/: code-finder.md, code-finder-advanced.md, implementor.md, library-docs-writer.md, root-cause-analyzer.md
- agents/specialist/: [name1].md, [name2].md, [name3].md
- commands/: 1-requirements.md, 2-architecture.md, 3-priority.md, 4-parallelization.md, 5-execution.md
- hooks/: workflow-orchestrator.py, parallel.py
- file-templates/: requirements.template.md, architecture.template.md, priority.template.md, parallelization.template.md
- guides/: always-active/foundation.md, planning.md, brainstorming.md, deep-research.md, debug.md, investigation.md, implementation.md, parallel.md

Start by researching best practices for the specified domain's development, then systematically create each folder by:
1. Reading the library/default/ equivalent
2. Creating the exact same structure in library/[domain]/
3. For each file: Read default version → Create domain version with identical structure
4. Update init-workspace.py with detection logic

VALIDATION: After each file creation, verify that someone could do a side-by-side comparison with the library/default/ version and see the EXACT same structure with only domain-specific terms changed.
```

**After creating the domain:** Test it by running `/init-workspace` in a project of that type to verify domain detection and file copying works correctly.

## File Size Best Practices

Optimize for **logical coherence** and **developer experience** rather than arbitrary line counts. With Sonnet 4.5's 1M context window, focus on creating complete, searchable documentation.

### CLAUDE.md Files (Auto-loaded)
- **Global** (~/.claude/CLAUDE.md): 150-400 lines (~8-16KB)
- **Local** (./.claude/CLAUDE.md or ./CLAUDE.md): 200-500 lines (~12-20KB)
- **Maximum**: 600 lines (split into guides/ if exceeded)
- Keep under 50KB per file (official Anthropic guidance)

### Code Files (Domain-Specific)
- **iOS/macOS/visionOS (Swift)**:
  - Views: 200-400 lines; extract subviews beyond 600 lines
  - ViewModels/Managers: 300-600 lines; split beyond 1,000 lines
  - Models: 100-200 lines; use extensions beyond 400 lines
  - Utilities: 200-400 lines; split beyond 600 lines
- **Web (React/Next.js)**:
  - Components: 200-400 lines; extract sub-components beyond 600 lines
  - Pages: 250-400 lines; extract sections beyond 700 lines
  - Hooks: 100-200 lines; extract logic beyond 400 lines
  - Utilities: 200-400 lines; split beyond 600 lines
- **Stream Deck plugins**:
  - Actions: 100-200 lines; refactor beyond 400 lines
  - UI components: 100-200 lines; extract beyond 300 lines
  - Utilities: 200-300 lines; split beyond 500 lines
- **Default (General)**:
  - Components/modules: 300-500 lines; refactor beyond 800 lines
  - Utilities/helpers: 200-400 lines; split beyond 600 lines

**Key principle:** Prefer logical coherence over arbitrary limits. A cohesive 700-line module is better than three fragmented files.

## Trigger Keywords

### Thinking Keywords (Domain-Agnostic)
- **think** → Allocates 4,000 tokens for standard problem-solving (5-15 seconds)
- **megathink** → Allocates 10,000 tokens for complex refactoring and design (40% better architectural decisions)
- **ultrathink** → Allocates maximum 31,999 tokens for tackling seemingly impossible tasks (solves team-stumping bugs)

### Workflow Orchestrator Keywords (Domain-Specific)
The Workflow Orchestrator hook automatically injects contextual guides based on these keywords. Multiple guides can stack together.

**Always active:**
- **foundation.md** → Professional development mode (automatically loaded on every prompt)

**Keyword-triggered guides (stack with foundation):**

Each guide has a **primary keyword** and corresponding **slash command** for easy activation:

| Primary Keyword | Slash Command | Guide Purpose |
|----------------|---------------|---------------|
| `brainstorm` | `/brainstorm` | Socratic questioning with emojis, collaborative discovery mindset |
| `deep-research` | `/deep-research` | Evidence-based systematic investigation with parallel research streams |
| `plan` | `/plan` | Research-only mode with no implementation, creates strategic documentation |
| `implement` | `/implement` | Best practices for feature implementation (also: build, code, create) |
| `debug` | `/debug` | Debugging workflow and error investigation |
| `investigate` | `/investigate` | Code investigation and pattern analysis (also: research, analyze) |

**Two ways to activate guides:**
1. **Keywords in prompts** - Use primary keywords naturally in your message to auto-trigger guides (supports stacking)
2. **Slash commands** - Explicitly activate a specific guide with `/keyword`

**Example keyword stacking:**
- "debug this planning" → Loads: foundation + debug + planning
- "implement user auth" → Loads: foundation + implementation
- "deep research the architecture" → Loads: foundation + deep-research + investigation

## Reference Documentation

### Architecture Overview

This system uses a **Library-based architecture** where domain-specific configurations are stored in a central Library and deployed to individual workspaces:

- **Global Config** (`~/.claude/`): Domain-agnostic commands (like `/git`), system hooks, and the Library
- **library** (`~/.claude/library/`): Domain-specific templates for agents, commands, hooks, file-templates, and guides
- **Workspace Config** (`./.claude/`): Per-project configuration initialized from the Library for a specific domain

### System Architecture
Commands, Output Styles, and Hooks operate independently. To trigger multiple behaviors:
- Example: `/plan` alone only executes the command
- Example: `/plan out the feature` triggers both the command AND Planning output style (via "plan out" keywords)
- Keywords in your message may trigger hooks and output styles regardless of commands used

### Domain-Specific Hook System
After running `/init-workspace`, your project will have domain-specific hooks that automatically enhance Claude's behavior:
- **workflow-orchestrator.py** - Intelligently injects workflow guides based on keywords in your prompts (foundation.md is always active, others stack based on keywords: brainstorm, deep-research, planning, implementation, debug, investigation)
- **parallel.py** - Loads the parallel execution guide after planning (PostToolUse hook)

These hooks are workspace-local and automatically use the domain-appropriate guides from your `.claude/guides/` folder.

### Agents (Domain-Specific, Auto-Selected by Claude)
None of the agents are explicitly triggered. Claude automatically recognizes based on the nature of the request.
*Note: Agents are workspace-local after running `/init-workspace` and exist in `./.claude/agents/` organized in `base/` and `specialist/` subdirectories*

**How to Request Agents:**

Claude automatically selects appropriate agents based on your request, but you can be explicit:

**Implicit (Recommended)**:
- "Find where authentication is implemented" → Claude selects @code-finder
- "Build a new user profile feature" → Claude selects domain specialist
- "Debug why the API is failing" → Claude selects @root-cause-analyzer

**Explicit (When needed)**:
- "Use @code-finder-advanced to investigate the data flow"
- "Deploy @root-cause-analyzer to understand why this crashes"
- "Have @implementor build the service layer task from the plan"

Most users should rely on Claude's automatic agent selection. Explicit callouts are useful when you want to ensure a specific agent is used or when combining multiple agents in parallel.

**Base Agents (Available in all domains):**
Located in `./.claude/agents/base/`
- **code-finder** - Quickly locates specific code files, functions, classes, or patterns across the codebase (uses Haiku)
- **code-finder-advanced** - Deep investigation for complex relationships, cross-file analysis, and semantic understanding (uses Sonnet)
- **implementor** - Executes specific implementation tasks from parallel plans with strict adherence to requirements
- **library-docs-writer** - Fetches and compresses external library documentation into concise reference files
- **root-cause-analyzer** - Diagnoses why bugs are occurring through systematic investigation

**Specialist Agents (Domain-specific):**
Specialist agents vary by domain and exist in `./.claude/agents/specialist/`. For example:
- **Default domain**: backend-feature.md, frontend-feature.md, fullstack-feature.md
- **VisionOS domain**: openimmersive-feature.md, shareplay-feature.md, volumetric-layouts-feature.md, storekit-feature.md, expert-visionos-26-feature.md

### Guides (Domain-Specific, Auto-Triggered)
*Note: Guides are workspace-local after running `/init-workspace` and exist in `./.claude/guides/`*

**Always loaded:**
- **foundation.md** - Professional development mode with agent delegation, parallel execution, and code standards

**Keyword-triggered:**
- **brainstorming.md** - Collaborative discovery workflow (keyword: "brainstorm")
- **deep-research.md** - Systematic investigation with evidence-based reasoning (keyword: "deep research")
- **planning.md** - Research-driven planning methodology (keywords: "plan out", "planning")
- **implementation.md** - Best practices before implementing features (keywords: "implement", "build", "code")
- **debug.md** - Debugging workflow and error investigation (keywords: "debug", "bug", "error")
- **investigation.md** - Code investigation and pattern analysis (keywords: "investigate", "research", "analyze")
- **parallel.md** - Triggered after ExitPlanMode; explains task independence analysis, dependency management, and parallel execution strategies

### File Templates (Domain-Specific)
Formatting guides automatically referenced by planning commands - not executed directly.
*Note: Templates are workspace-local after running `/init-workspace` and exist in `./.claude/file-templates/`*
- **requirements.template.md** - Template for requirements documents (user-focused, non-technical)
- **architecture.template.md** - Template for technical architecture documentation
- **priority.template.md** - Template for 3-tier prioritization (Tier 1: build, Tier 2: stub, Tier 3: future)
- **parallelization.template.md** - Template for parallel execution plans with task dependencies

### Global Hooks (Domain-Agnostic)
These hooks remain in the global `~/.claude/hooks/` folder and work across all workspaces:
- **git-hook.py** - Enhances prompt with git status/diffs when user types exactly `/git`
- **_system/notifications/** - System notification hooks (sounds)
