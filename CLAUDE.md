# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a comprehensive configuration system for Claude Code that enables domain-aware AI assistance across multiple development platforms. The system uses a **Library-based architecture** where domain-specific configurations (agents, commands, hooks, templates) are centrally maintained and deployed to individual project workspaces.

## Architecture

### Directory Structure

```
~/.claude/                           # Global configuration
├── library/                         # Domain-specific templates
│   ├── default/                     # General-purpose development
│   ├── ios/                         # iOS app development
│   ├── macos/                       # macOS app development
│   ├── visionos/                    # Apple Vision Pro development
│   ├── webdev/                      # React/Next.js web development
│   └── streamdeck/                  # Elgato Stream Deck plugins
│       ├── agents/
│       │   ├── base/               # Common agents (all domains)
│       │   └── specialist/         # Domain-specific agents
│       ├── commands/               # Slash commands
│       ├── file-templates/         # Document templates
│       ├── guides/                 # Reference documentation
│       ├── hooks/                  # Event-driven automation
│       ├── output-styles/          # Response formatting styles
│       └── settings.local.template.json
├── commands/                        # Global slash commands
│   ├── init-workspace.md           # Initialize project workspace
│   └── git.md                      # Git commit orchestration
├── hooks/                           # Global hooks
│   ├── git-hook.py                 # Git status injection
│   └── _system/                    # System notifications
├── scripts/
│   └── init-workspace.py           # Domain detection & setup
└── settings.json                    # Global settings
```

**Workspace structure** (after running `/init-workspace`):
```
./project/.claude/                   # Project-local configuration
├── agents/                          # Copied from library/{domain}/
├── commands/                        # Copied from library/{domain}/
├── file-templates/                  # Copied from library/{domain}/
├── guides/                          # Copied from library/{domain}/
├── hooks/                           # Copied from library/{domain}/
├── output-styles/                   # Copied from library/{domain}/
├── settings.local.json              # Merged domain + user settings
└── domain.json                      # Domain marker with timestamp
```

### Component Interaction

The system operates through three independent layers:

1. **Commands** (`/init-workspace`, `/git`) - Execute specific workflows
2. **Hooks** (UserPromptSubmit, PostToolUse) - Inject context or switch behavior based on triggers
3. **Output Styles** (main, planning, brainstorming) - Format Claude's responses

Keywords in user prompts can trigger multiple layers simultaneously (e.g., "plan out" triggers both planning command AND planning output style).

## Core Workflows

### Workspace Initialization

**Command:** `/init-workspace` or `/init-workspace <domain>`

**Process:**
1. Auto-detects domain by analyzing project files (scripts/init-workspace.py:15-340)
   - visionOS: RealityKit imports, visionOS frameworks
   - macOS: AppKit/Cocoa imports, macOS SDK
   - iOS: UIKit imports, iOS SDK
   - webdev: Next.js config, React dependencies
   - streamdeck: @elgato/streamdeck dependency
   - default: Fallback for general projects
2. Creates `.claude/` directory in project workspace
3. Copies all domain-specific files from `library/{domain}/` to `./.claude/`
4. Merges `settings.local.template.json` with existing user customizations
5. Creates `domain.json` marker file
6. For macOS/visionOS: Sets up DebugLogger.swift and updates CLAUDE.md

**Key Files:**
- commands/init-workspace.md - Command documentation
- scripts/init-workspace.py - Python implementation with domain detection logic

### Git Commit Orchestration

**Command:** `/git`

**Strategy:**
- **Small changes** (<3 files, single feature): Handle directly
- **Large changes** (3+ files, multiple features): Delegate documentation to parallel agents using Task tool

**Process for large changes:**
1. Analyze git diffs and identify independent documentation tasks
2. Launch parallel documentation agents using single function_calls block
3. Wait for all agents to complete
4. Stage and commit changes in logical batches with conventional commit messages

**Key Files:**
- commands/git.md - Complete orchestration workflow

### Parallel Development

**Git worktrees** enable multiple Claude instances to work on different features simultaneously:

```bash
# Create worktree for new feature
Create a worktree and implement [feature]

# List active worktrees
git worktree list

# After testing and committing in worktree
Merge back to main

# Clean up (REQUIRED - worktrees persist after merge)
Remove the worktree
```

## Domain System

### Available Domains

- **default**: General-purpose (Python, Node.js, Go, Rust, Java)
  - Specialists: backend-feature, frontend-feature, fullstack-feature
- **ios**: iOS apps (Swift, UIKit, SwiftUI)
- **macos**: macOS apps (Swift, AppKit, SwiftUI)
  - Specialists: appkit-integration, data-architecture, swiftterm-integration, swiftui-feature
- **visionos**: Apple Vision Pro (Swift, RealityKit, SwiftUI)
  - Specialists: openimmersive-feature, shareplay-feature, volumetric-layouts-feature, storekit-feature, expert-visionos-26-feature, amplitude-feature, native-video-playback-feature
- **webdev**: React/Next.js web applications
- **streamdeck**: Elgato Stream Deck plugins

### Agent Types

**Base Agents** (available in all domains):
- **code-finder**: Quick file/function location using Haiku model
- **code-finder-advanced**: Deep cross-file analysis using Sonnet model
- **implementor**: Executes implementation tasks from parallel plans
- **library-docs-writer**: Fetches and compresses external library documentation
- **root-cause-analyzer**: Systematic bug diagnosis

**Specialist Agents** (domain-specific, automatically selected by Claude based on task context)

### Creating New Domains

Use the "New Domain Prompt" pattern from README.md (lines 114-169):

1. Research domain best practices thoroughly
2. Create `library/{domain}/` directory structure
3. For each file, read corresponding `library/default/` file first as exact template
4. Maintain identical structure, only replace domain-specific content
5. Create exactly 5 base agents + 3 specialist agents
6. Update scripts/init-workspace.py with detection logic (indicators + scoring)
7. Test with `/init-workspace` in a project of that type

**Critical:** Files must have identical structure to default versions - side-by-side comparison should show only domain-specific terminology differences.

### Creating New Features (Specialist Agents)

Use the "New Feature Prompt" pattern from README.md (lines 88-112):

1. Research feature best practices for the domain
2. Read corresponding default specialist from `library/default/agents/specialist/`
3. Create `library/{domain}/agents/specialist/{name}.md` with identical structure
4. Replace only the default-specific content with specialist-specific content

## Hooks System

### Global Hooks (~/.claude/hooks/)
- **git-hook.py**: Injects git status/diffs when user types `/git` (UserPromptSubmit)
- **_system/notifications/**: Sound and Pushover notifications (Notification, Stop events)

### Domain-Specific Hooks (./.claude/hooks/)
Copied from library during `/init-workspace`:
- **custom-reminder.py**: Injects contextual reminders for keywords (debug, investigate, parallel, plan)
- **output-style-switcher.py**: Auto-switches output styles based on keywords
- **parallel.py**: Loads parallel execution guide after ExitPlanMode tool use

## Extended Thinking

Trigger keywords allocate extended thinking tokens:
- **think**: 4,000 tokens (5-15 seconds) - standard problem-solving
- **megathink**: 10,000 tokens - complex refactoring and design
- **ultrathink**: 31,999 tokens - seemingly impossible tasks

Configured via settings.json:4 `alwaysThinkingEnabled: true`

## Key Development Patterns

### Planning Commands
Execute in sequence with clear memory between steps:
1. `/plan-requirements` - User flows, functional requirements, UI specs
2. `/plan-shared` - Architecture overview, patterns, schemas
3. `/plan-parallel` - Task breakdown with dependencies and agent assignments
4. `/execute-implement-plan` - Orchestrates parallel agent execution

### Output Styles
Keywords trigger different response formats:
- **brainstorm** → Socratic questioning with emojis
- **business panel** → Multi-perspective strategic analysis
- **deep research** → Evidence-based systematic investigation
- **plan out/planning** → Research-only mode with no implementation
- **implement/build/code** → Main development mode (default)

### File Templates
Used by plan commands for consistent documentation:
- **requirements.template.md**: Requirements documents
- **shared.template.md**: Shared architecture docs
- **parallel.template.md**: Parallel execution plans

## Settings

**Global settings** (~/.claude/settings.json):
- Model: sonnet[1m] (1M context)
- Hooks: git-hook, system notifications
- alwaysThinkingEnabled: true

**Domain settings** (./.claude/settings.local.json):
- Permissions: Allow Read/Write/Edit/Bash for workspace
- Domain-specific hooks: custom-reminder, output-style-switcher, parallel
- Default outputStyle: main

## Common Commands

```bash
# Initialize workspace (auto-detect domain)
/init-workspace

# Initialize with specific domain
/init-workspace macos

# Commit changes with orchestration
/git

# Run domain detection script directly
python3 ~/.claude/scripts/init-workspace.py <domain>
```

## Git Commit Policy

**CRITICAL:** Claude NEVER creates commits autonomously. Only commit when:
1. User runs `/git` command explicitly, OR
2. User provides explicit commit instruction (e.g., "commit these changes with message X")

Do NOT commit after completing tasks unless explicitly instructed. The user controls when commits happen.

## File Size Guidelines

### Philosophy

Optimize for **logical coherence** and **developer experience** rather than arbitrary line counts:
- **Logical coherence**: Does this file cover one complete concept?
- **Human readability**: Can a developer scan this in 2-3 minutes?
- **Load relevance**: Auto-loaded files (CLAUDE.md) must stay tight; on-demand files can be larger
- **Search efficiency**: One searchable file often beats navigating multiple fragments

### CLAUDE.md Files (Auto-loaded)

These are always loaded into context, so keep them concise:
- **Global** (~/.claude/CLAUDE.md): 150-400 lines (~8-16KB)
- **Local** (./.claude/CLAUDE.md or ./CLAUDE.md): 200-500 lines (~12-20KB)
- **Maximum**: 600 lines before splitting into guides/
- **Optimal**: Under 50KB per file (official Anthropic guidance)

### Documentation Files (On-demand)

These load only when needed, so optimize for completeness over size:
- **Planning documents** (requirements, shared, parallel): 200-600 lines each
  - **Maximum**: 1,000 lines (split when content becomes logically distinct)
  - Complex architectures need room for comprehensive documentation
- **Feature guides**: 100-400 lines per feature
  - **Maximum**: 600 lines (split when covering multiple unrelated features)
  - Complete features often need comprehensive examples
- **Reference guides**: 400-800 lines (prompting, parallel execution)
  - **Maximum**: 1,200 lines (split into topic-specific guides)
  - Reference material should be complete and searchable

### Token Budget (1M context)

With Sonnet 4.5's 1M token context window and context awareness:
- CLAUDE.md files: ~10-20K tokens (1-2%)
- All documentation: ~50-100K tokens (5-10%)
- Active code work: ~100-500K tokens (10-50%)
- Remaining: ~400K+ tokens (40%+) for deep work

**Modern reality**: File size is less critical than logical organization and relevance. Claude tracks token budget automatically.

## Development Notes

- **Most changes don't need CLAUDE.md updates** - Use feature documentation instead
- **Preserve flat folder structure** - All files directly in top-level folders
- **Template first** - Always read default template before creating domain-specific versions
- **Structure consistency** - New domains/features must match default structure exactly
- **Worktree cleanup** - Always remove worktrees after merging (they persist on disk)
