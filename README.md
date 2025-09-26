# Claude visionOS Development Configuration

## System Architecture Note
Commands, Output Styles, and Hooks operate independently. To trigger multiple behaviors:
- Example: `/plan` alone only executes the command
- Example: `/plan out the feature` triggers both the command AND Planning output style (via "plan out" keywords)
- Keywords in your message may trigger hooks and output styles regardless of commands used

## Agents
None of the agents are explicitly triggered. Claude automatically recognizes based on the nature of the request.

### Available Agents
- **swift-systems-developer** - Creates/modifies backend Swift components, services, data persistence, and system integrations (ARKit, CloudKit, Core Data)
- **swiftui-spatial-developer** - Creates/modifies SwiftUI spatial interfaces, visionOS windows/volumes/spaces, and spatial interaction patterns
- **realitykit-3d-developer** - Creates/modifies RealityKit 3D content, entities, materials, animations, physics, and immersive experiences
- **code-finder** - Quickly locates specific code files, functions, classes, or patterns across the codebase (uses Haiku)
- **code-finder-advanced** - Deep investigation for complex relationships, cross-file analysis, and semantic understanding (uses Sonnet)
- **implementor** - Executes specific implementation tasks from parallel plans with strict adherence to requirements

## Commands

### Planning Commands
*Note: These commands are listed in the order they should be executed when building a new feature.*

- **/plan:requirements** - Creates a requirements document with user flows, functional requirements, and UI/system specifications for spatial features
- **/plan:shared** - Documents architecture overview, relevant files, patterns, and Core Data/CloudKit schemas
- **/plan:parallel** - Creates parallelizable task breakdown with dependencies, agent assignments, and implementation phases
- **/execute:implement-plan** - Orchestrates parallel agent execution based on plan dependencies, running batches simultaneously

### Git Commands
- **Commit all changes /git** - Reviews git status/diffs, stages files, and creates commits with project-appropriate messages

## Guides
Triggered automatically by hooks when relevant keywords are detected.

### Available Guides
- **visionos/visionos-parallel.md** - Triggered after ExitPlanMode; explains task independence analysis, dependency management, and parallel execution strategies
- **visionos/visionos-prompting-guide.md** - Triggered by "improve prompt" keywords; provides best practices for effective visionOS development prompts

## Hooks

### Automatically Triggered (every message)
- **visionos/visionos-custom-reminder.py** - Injects contextual reminders based on keywords (debug→debugging workflow, investigate→investigation guide, improve prompt→prompting guide, plan→planning workflow, parallel→parallel guide)
- **visionos/visionos-git-hook.py** - Enhances prompt with git status/diffs/commits when user types exactly `/git`
- **visionos/visionos-output-style-switcher.py** - Switches Claude's personality/behavior based on keywords (brainstorm, business panel, deep research, planning, implement)

### Conditionally Triggered
- **visionos/visionos-parallel.py** - Injects visionos-parallel.md guide after ExitPlanMode tool usage (PostToolUse hook)
- **notifications/notification-sound.sh** - Plays system sounds when Claude needs user attention (Notification hook)

## File Templates
Formatting guides automatically referenced by /plan commands - not executed directly.

## Output Styles

### Keywords → Effect
- **"brainstorm"** → Socratic questioning with emojis, collaborative discovery mindset
- **"business panel"** → Channels 9 business thought leaders for multi-perspective strategic analysis
- **"deep research"** → Evidence-based systematic investigation with parallel research streams
- **"plan out/planning"** → Research-only mode with no implementation, creates strategic documentation
- **"implement/build/code/spatial"** → Sr. Swift Developer mode for implementation with agent orchestration (default)

## Building New Development Domains & Features

### New Domain Prompt
```
Create a new development domain for [DOMAIN_NAME] in Claude's configuration.

1. Create subfolders for this domain in: agents, commands, file-templates, guides, and hooks folders
2. Use the existing visionOS domain documentation in each folder as exact templates for structure and format
3. Research the specified domain's development best practices thoroughly on the internet
4. Create all documentation files within each subfolder, adapting content for the specified domain while maintaining the exact same format as the visionOS documentation. Use them as examples.
5. Note: some subfolders, like file-templates, need minor domain-specific adjustments, while others, like agents, need major content overhauls but keep the same structural format

Start by researching best practices for the specified domain's development, then systematically create each subfolder and its documentation.

Note, some subfolders have additional subfolders as well. For example, commands/visionos/plan or /execute. And be sure to keep the naming conventions of all the folders, sub-folders, and files the same as the visionOS examples.
```

### New Feature Prompt
```
Add a new feature for [FEATURE_NAME] within the [DOMAIN_NAME].

1. Create feature documentation in /agents/ for the specified domain and feature
2. Research the specified feature's best practices for the domain's development thoroughly on the internet
3. Use the visionos features documentation structure as an exact template for format and organization
4. Build comprehensive documentation that covers all aspects of implementing the specified feature while maintaining consistency with existing domain patterns

Start by researching best practices for the specified feature in the given domain, then create the feature documentation.

Note: Be sure to follow naming conventions the same as the visionOS examples.
```
