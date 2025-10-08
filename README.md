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
```
/plan-requirements
```
Creates a requirements document with user flows, functional requirements, and UI/system specifications

```
/plan-shared
```
Documents architecture overview, relevant files, patterns, and Core Data/CloudKit schemas

```
/plan-parallel
```
Creates parallelizable task breakdown with dependencies, agent assignments, and implementation phases

```
/execute-implement-plan
```
Orchestrates parallel agent execution based on plan dependencies, running batches simultaneously

### Git Command (Domain-Agnostic)
```
/git
```
Analyzes git changes and orchestrates commits - Determines if changes are small (handle directly) or large (delegate documentation to parallel agents), then stages and commits

### Parallel Development with Git Worktrees

**Use worktrees to run multiple Claude instances on different features simultaneously.**

**Complete Workflow:**

1. Create worktree and implement feature:
```
Create a worktree and implement [feature description]
```
Claude will auto-name the worktree directory and branch based on your feature description.

2. Test the feature in the worktree directory

3. Commit changes:
```
/git
```

4. Merge back to parent branch:
```
Merge back to main
```

5. Clean up worktree (REQUIRED - worktrees persist on disk after merge):
```
Remove the worktree
```

**Useful Commands:**
```bash
# List all active worktrees
git worktree list

# Manually remove a worktree
git worktree remove ../worktree-directory-name
```

**Key Points:**
- Each worktree is a separate directory on disk with its own branch checked out
- Worktrees enable multiple Claude instances to work on different features without file conflicts
- Worktrees do NOT auto-delete after merging - you must manually remove them
- Main workspace remains untouched while Claude works in the worktree

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
2. Create subfolders: agents, commands, file-templates, guides, hooks, output-styles
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
- commands/: plan-requirements.md, plan-shared.md, plan-parallel.md, execute-implement-plan.md
- hooks/: custom-reminder.py, output-style-switcher.py, parallel.py
- file-templates/: requirements.template.md, shared.template.md, parallel.template.md
- output-styles/: main.md, planning.md, brainstorming.md, business-panel.md, deep-research.md

Start by researching best practices for the specified domain's development, then systematically create each folder by:
1. Reading the library/default/ equivalent
2. Creating the exact same structure in library/[domain]/
3. For each file: Read default version → Create domain version with identical structure
4. Update init-workspace.py with detection logic

VALIDATION: After each file creation, verify that someone could do a side-by-side comparison with the library/default/ version and see the EXACT same structure with only domain-specific terms changed.
```

**After creating the domain:** Test it by running `/init-workspace` in a project of that type to verify domain detection and file copying works correctly.

## Trigger Keywords

### Thinking Keywords (Domain-Agnostic)
- **think** → Allocates 4,000 tokens for standard problem-solving (5-15 seconds)
- **megathink** → Allocates 10,000 tokens for complex refactoring and design (40% better architectural decisions)
- **ultrathink** → Allocates maximum 31,999 tokens for tackling seemingly impossible tasks (solves team-stumping bugs)

### Output Style Keywords (Domain-Specific)
- **brainstorm** → Socratic questioning with emojis, collaborative discovery mindset
- **business panel** → Channels 9 business thought leaders for multi-perspective strategic analysis
- **deep research** → Evidence-based systematic investigation with parallel research streams
- **plan out/planning** → Research-only mode with no implementation, creates strategic documentation
- **implement/build/code** → Main development mode for implementation with agent orchestration (default)

### Hook Trigger Keywords (Domain-Specific)
- **debug** → Triggers debugging reminders
- **investigate** → Triggers investigation reminders
- **improve prompt** → Triggers prompting guide
- **plan** → Triggers planning reminders
- **parallel** → Triggers parallel execution reminders

## Reference Documentation

### Architecture Overview

This system uses a **Library-based architecture** where domain-specific configurations are stored in a central Library and deployed to individual workspaces:

- **Global Config** (`~/.claude/`): Domain-agnostic commands (like `/git`), system hooks, and the Library
- **library** (`~/.claude/library/`): Domain-specific templates for agents, commands, hooks, file-templates, guides, and output-styles
- **Workspace Config** (`./.claude/`): Per-project configuration initialized from the Library for a specific domain

### System Architecture
Commands, Output Styles, and Hooks operate independently. To trigger multiple behaviors:
- Example: `/plan` alone only executes the command
- Example: `/plan out the feature` triggers both the command AND Planning output style (via "plan out" keywords)
- Keywords in your message may trigger hooks and output styles regardless of commands used

### Domain-Specific Hook System
After running `/init-workspace`, your project will have domain-specific hooks that automatically enhance Claude's behavior:
- **custom-reminder.py** - Injects contextual reminders based on keywords (debug, investigate, parallel, etc.)
- **output-style-switcher.py** - Automatically switches output styles based on keywords
- **parallel.py** - Loads the parallel execution guide after planning (PostToolUse hook)

These hooks are workspace-local and automatically use the domain-appropriate guides and styles from your `.claude/` folder.

### Agents (Domain-Specific, Auto-Selected by Claude)
None of the agents are explicitly triggered. Claude automatically recognizes based on the nature of the request.
*Note: Agents are workspace-local after running `/init-workspace` and exist in `./.claude/agents/` organized in `base/` and `specialist/` subdirectories*

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
- **parallel.md** - Triggered after ExitPlanMode; explains task independence analysis, dependency management, and parallel execution strategies
- **prompting-guide.md** - Triggered by "improve prompt" keywords; provides best practices for effective development prompts

### File Templates (Domain-Specific)
Formatting guides automatically referenced by /plan commands - not executed directly.
*Note: Templates are workspace-local after running `/init-workspace` and exist in `./.claude/file-templates/`*
- **requirements.template.md** - Template for requirements documents
- **shared.template.md** - Template for shared architecture documentation
- **parallel.template.md** - Template for parallel execution plans

### Global Hooks (Domain-Agnostic)
These hooks remain in the global `~/.claude/hooks/` folder and work across all workspaces:
- **git-hook.py** - Enhances prompt with git status/diffs when user types exactly `/git`
- **_system/notifications/** - System notification hooks (sounds, Pushover integration)
