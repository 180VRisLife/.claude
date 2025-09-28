# Claude Development Configuration

A comprehensive configuration system for Claude to build production-ready applications across any domain with parallel agent orchestration, automated workflows, and extensible templates.

## Copy-Pastable Commands & Prompts

### Planning Commands (Domain-Specific)
*Execute in this order when building a new feature:*
*Clear Claude's memory and tag in .docs/plans/[FEATURENAME] directory each time you run these commands*
*Note: These commands are domain-specific and exist within each domain folder (e.g., /commands/default/plan/)*
```
/plan:requirements
```
Creates a requirements document with user flows, functional requirements, and UI/system specifications

```
/plan:shared
```
Documents architecture overview, relevant files, patterns, and Core Data/CloudKit schemas

```
/plan:parallel
```
Creates parallelizable task breakdown with dependencies, agent assignments, and implementation phases

```
/execute:implement-plan
```
Orchestrates parallel agent execution based on plan dependencies, running batches simultaneously

### Git Command (Domain-Agnostic)
```
/git
```
Analyzes git changes and orchestrates commits - Determines if changes are small (handle directly) or large (delegate documentation to parallel agents), then stages and commits
*Note: This command is domain-agnostic and works across all projects*

### New Feature Prompt (Domain-Aware)
```
Add a new feature for [FEATURE_NAME] within the [DOMAIN_NAME] that [FEATURE_DESCRIPTION e.g., "enables users to export their data in multiple formats"].

CRITICAL STRUCTURE REQUIREMENT:
- BEFORE creating ANY file, you MUST first Read the corresponding default example file
- The structure must be EXACTLY the same as the default version
- ONLY replace the specific default/core parts with the new domain equivalents
- Keep ALL formatting, sections, subsections, and organizational patterns identical

Steps:
1. Create feature documentation in /agents/ for the specified domain and feature
2. Research the specified feature's best practices for the domain's development thoroughly on the internet
3. For EACH file you create:
   a. FIRST read the corresponding default feature file as your exact template
   b. Maintain the EXACT same structure, headers, and organization
   c. Replace ONLY the default-specific technical content with domain-specific content
   d. Keep the same level of detail and documentation style
4. Build comprehensive documentation that covers all aspects of implementing the specified feature while maintaining consistency with existing domain patterns

Start by researching best practices for the specified feature in the given domain, then create the feature documentation by reading each default template file immediately before creating its domain equivalent.

Note: Follow the EXACT naming conventions used in the default examples (e.g., feature-name-feature.md pattern).
```

### New Domain Prompt (Domain Creation)
```
Create a new development domain for [DOMAIN_NAME] in Claude's configuration that [DOMAIN_DESCRIPTION e.g., "supports building scalable web applications with React"].

CRITICAL STRUCTURE REQUIREMENT:
- BEFORE creating ANY file or folder, you MUST first Read the corresponding default example
- The structure must be EXACTLY the same as the default version
- ONLY replace the specific default/core parts with the new domain equivalents
- Be EXTREMELY skeptical about making changes - when in doubt, keep it identical to default

Steps:
1. Create subfolders for this domain in: agents, commands, file-templates, guides, hooks, and output-styles folders
2. For EACH file you create:
   a. FIRST read the corresponding default file to use as your EXACT template
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
3. Research the specified domain's development best practices thoroughly on the internet
4. Create all documentation files within each subfolder, maintaining the EXACT format as default
5. Preserve ALL subfolders structure (e.g., commands/[domain]/plan/, commands/[domain]/execute/)

Start by researching best practices for the specified domain's development, then systematically create each subfolder by:
1. Reading the default equivalent folder structure
2. Creating the exact same folder hierarchy
3. For each file: Read default version → Create domain version with identical structure

VALIDATION: After each file creation, verify that someone could do a side-by-side comparison with the default version and see the EXACT same structure with only domain-specific terms changed.

Note: Keep ALL naming conventions identical to default (folder names, file names, internal structure).
```

**After running either prompt:** Review changes to verify domain-agnostic sections (like parallel execution logic) remain unchanged.

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
- **implement/build/code/spatial** → Sr. Swift Developer mode for implementation with agent orchestration (default)

### Hook Trigger Keywords (Domain-Specific)
- **debug** → Triggers debugging reminders
- **investigate** → Triggers investigation reminders
- **improve prompt** → Triggers prompting guide
- **plan** → Triggers planning reminders
- **parallel** → Triggers parallel execution reminders

## Reference Documentation

### System Architecture
Commands, Output Styles, and Hooks operate independently. To trigger multiple behaviors:
- Example: `/plan` alone only executes the command
- Example: `/plan out the feature` triggers both the command AND Planning output style (via "plan out" keywords)
- Keywords in your message may trigger hooks and output styles regardless of commands used

### Agents (Domain-Specific, Auto-Selected by Claude)
None of the agents are explicitly triggered. Claude automatically recognizes based on the nature of the request.
*Note: Agents are domain-specific and exist within each domain folder (e.g., /agents/default/)*

- **code-finder** - Quickly locates specific code files, functions, classes, or patterns across the codebase (uses Haiku)
- **code-finder-advanced** - Deep investigation for complex relationships, cross-file analysis, and semantic understanding (uses Sonnet)
- **implementor** - Executes specific implementation tasks from parallel plans with strict adherence to requirements

### Guides (Domain-Specific, Auto-Triggered)
*Note: Guides are domain-specific and exist within each domain folder (e.g., /guides/default/)*
- **default/default-parallel.md** - Triggered after ExitPlanMode; explains task independence analysis, dependency management, and parallel execution strategies
- **default/default-prompting-guide.md** - Triggered by "improve prompt" keywords; provides best practices for effective development prompts

### Hooks

#### Domain-Specific Hooks
*Note: Domain-specific hooks exist within each domain folder (e.g., /hooks/default/)*
- **default/default-custom-reminder.py** - Injects contextual reminders based on keywords
- **default/default-output-style-switcher.py** - Switches Claude's personality/behavior based on keywords

#### Domain-Agnostic Hooks
- **git-hook.py** - Enhances prompt with git status/diffs when user types exactly `/git` (simple git info hook)
- **notifications/notification-sound.sh** - Plays system sounds when Claude needs user attention (Notification hook)

#### Conditionally Triggered
- **default/default-parallel.py** - Injects default-parallel.md guide after ExitPlanMode tool usage (PostToolUse hook)

### File Templates (Domain-Specific)
Formatting guides automatically referenced by /plan commands - not executed directly.
*Note: Templates are domain-specific and exist within each domain folder (e.g., /file-templates/default/)*
