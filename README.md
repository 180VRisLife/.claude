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
- **/git commit all changes** - Reviews git status/diffs, stages files, and creates commits with project-appropriate messages

## Guides
Triggered automatically by hooks when relevant keywords are detected.

### Available Guides
- **parallel.md** - Triggered after ExitPlanMode; explains task independence analysis, dependency management, and parallel execution strategies
- **prompting-guide.md** - Triggered by "improve prompt" keywords; provides best practices for effective visionOS development prompts

## Hooks

### Automatically Triggered (every message)
- **custom-reminder.py** - Injects contextual reminders based on keywords (debug→debugging workflow, investigate→investigation guide, improve prompt→prompting guide, plan→planning workflow, parallel→parallel guide)
- **git-hook.py** - Enhances prompt with git status/diffs/commits when user types exactly `/git`
- **output-style-switcher.py** - Switches Claude's personality/behavior based on keywords (brainstorm, business panel, deep research, planning, implement)

### Conditionally Triggered
- **parallel.py** - Injects parallel.md guide after ExitPlanMode tool usage (PostToolUse hook)
- **notification-sound.sh** - Plays system sounds when Claude needs user attention (Notification hook)

## File Templates
Formatting guides automatically referenced by /plan commands - not executed directly.

## Output Styles

### Keywords → Effect
- **"brainstorm"** → Socratic questioning with emojis, collaborative discovery mindset
- **"business panel"** → Channels 9 business thought leaders for multi-perspective strategic analysis
- **"deep research"** → Evidence-based systematic investigation with parallel research streams
- **"plan out/planning"** → Research-only mode with no implementation, creates strategic documentation
- **"implement/build/code/spatial"** → Sr. Swift Developer mode for implementation with agent orchestration (default)
