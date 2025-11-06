# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a comprehensive configuration system for Claude Code that enables domain-aware AI assistance across multiple development platforms. The system uses a **Library-based architecture** where domain-specific configurations (agents, commands, hooks, templates) are centrally maintained in `~/.claude/library/` and deployed to individual project workspaces via `/init-workspace`.

**How it works:**
1. Global configuration lives in `~/.claude/` with domain templates in `library/`
2. Run `/init-workspace` in a project to auto-detect domain and copy appropriate config to `./.claude/`
3. Domain-specific commands, agents, hooks, and styles become available in that workspace

## Core Commands

### Workspace Initialization

**Command:** `/init-workspace` or `/init-workspace <domain>`

Automatically detects your project type (visionOS, iOS, macOS, webdev, streamdeck, or default) and copies the appropriate domain configuration from the Library to your local `.claude/` folder.

**What it does:**
- Analyzes project files to detect domain (imports, dependencies, config files)
- Creates `.claude/` directory in project workspace
- Copies domain-specific agents, commands, hooks, templates, and output styles
- Merges settings and creates domain marker file

### Git Commit Orchestration

**Command:** `/git`

Analyzes git changes and orchestrates commits intelligently:
- **Small changes** (<3 files, single feature): Single commit
- **Large changes** (3+ files, multiple features): Multiple logical commits grouped by feature/type

**Git Commit Policy - CRITICAL:**
Claude NEVER creates commits autonomously. Only commit when:
1. User runs `/git` command explicitly, OR
2. User provides explicit commit instruction (e.g., "commit these changes with message X")

Do NOT commit after completing tasks unless explicitly instructed. The user controls when commits happen.

### Git Worktrees

Git worktrees enable multiple Claude instances to work on different features simultaneously:

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

**Important:** Worktrees do NOT auto-delete after merging - you must manually remove them.

## Agent Types

After running `/init-workspace`, agents become available in `./.claude/agents/`:

### Base Agents (Available in all domains)

- **@code-finder** - Quick file/function location using Haiku model (fast, cheaper)
- **@code-finder-advanced** - Deep cross-file analysis using Sonnet model (thorough, comprehensive)
- **@implementor** - Executes implementation tasks from parallel plans with strict adherence
- **@library-docs-writer** - Fetches and compresses external library documentation into reference files
- **@root-cause-analyzer** - Systematic bug diagnosis through investigation

### Specialist Agents (Domain-specific)

Specialist agents vary by domain and are automatically selected by Claude based on task context:
- **default**: backend-feature, frontend-feature, fullstack-feature
- **iOS/macOS/visionOS**: Domain-specific feature agents for Apple platforms
- **webdev**: React/Next.js feature agents
- **streamdeck**: Plugin development feature agents

See `./.claude/agents/specialist/` after running `/init-workspace` for your domain's specialists.

## Output Styles

Keywords in user prompts trigger different response formats:

- **brainstorm** → Socratic questioning with emojis, collaborative discovery mindset
- **business panel** → Multi-perspective strategic analysis from 9 business thought leaders
- **deep research** → Evidence-based systematic investigation with parallel research streams
- **plan out / planning** → Research-only mode with no implementation, creates strategic documentation
- **implement / build / code** → Main development mode for implementation (default)

## Extended Thinking

Trigger keywords allocate extended thinking tokens:

- **think** → 4,000 tokens (5-15 seconds) - standard problem-solving
- **megathink** → 10,000 tokens - complex refactoring and design decisions
- **ultrathink** → 31,999 tokens - seemingly impossible tasks and team-stumping bugs

Configured via settings.json `alwaysThinkingEnabled: true`

## File Size Guidelines

### CLAUDE.md Files (Auto-loaded)

These are always loaded into context, so keep them concise:
- **Global** (~/.claude/CLAUDE.md): 150-400 lines (~8-16KB)
- **Local** (./.claude/CLAUDE.md or ./CLAUDE.md): 200-500 lines (~12-20KB)
- **Maximum**: 600 lines before splitting into guides/
- **Optimal**: Under 50KB per file (official Anthropic guidance)

### Philosophy

Optimize for **logical coherence** and **developer experience** rather than arbitrary line counts:
- **Logical coherence**: Does this file cover one complete concept?
- **Human readability**: Can a developer scan this in 2-3 minutes?
- **Load relevance**: Auto-loaded files (CLAUDE.md) must stay tight; on-demand files can be larger
- **Search efficiency**: One searchable file often beats navigating multiple fragments

### Token Budget (1M context)

With Sonnet 4.5's 1M token context window and context awareness:
- CLAUDE.md files: ~10-20K tokens (1-2%)
- All documentation: ~50-100K tokens (5-10%)
- Active code work: ~100-500K tokens (10-50%)
- Remaining: ~400K+ tokens (40%+) for deep work

**Modern reality**: File size is less critical than logical organization and relevance. Claude tracks token budget automatically.

## Development Notes

- **Most changes don't need CLAUDE.md updates** - Use feature documentation instead
- **Preserve flat folder structure** - All files directly in top-level folders within domains
- **Template first** - Always read default template before creating domain-specific versions
- **Structure consistency** - New domains/features must match default structure exactly
- **Worktree cleanup** - Always remove worktrees after merging (they persist on disk)
