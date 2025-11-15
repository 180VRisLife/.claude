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

**ABSOLUTE RULE: Claude NEVER commits without the `/git` command.**

- **ONLY** commit when user runs `/git` explicitly
- **DO NOT** commit on verbal requests ("commit this", "make a commit", etc.)
- **ALWAYS** respond: "Please run `/git` to orchestrate commits properly"
- **NEVER** commit after completing tasks, even if user says "and commit it"

The `/git` command analyzes changes and creates logical, well-structured commits. Bypassing it defeats the orchestration system.

### Debug Logging Policy

**⛔️ ABSOLUTE RULE: DEBUG LOGGING MUST NEVER BE COMMITTED**

**ONLY exceptions:** Debug UI features or release diagnostics infrastructure (properly gated for production).

The `/git` command enforces this automatically.

### Git Worktrees

**Git worktrees enable isolated parallel development for non-trivial work.**

**Why use worktrees:**
- **Isolation** - Changes don't affect main codebase
- **Parallel sessions** - Run multiple Claude instances simultaneously
- **Easy abandonment** - Delete worktree if approach doesn't work
- **Clean history** - Each feature gets its own branch and merge

**Workflow:**
- Create: `git worktree add ../feature-name feature-name`
- Work in isolation on feature branch
- When done: `/git` handles commits → merge → cleanup automatically

**Key points:**
- **Use `/worktree`** - Check status, find conflicts, cleanup suggestions
- **Auto-cleanup** - `/git` removes worktree after successful merge
- **Always cleanup** - Worktrees persist on disk after merge

## Agent-First Policy

**CRITICAL: Default to agents for all non-trivial tasks.**

**Use agents when:**
- Multi-step tasks or analysis required
- Code searches, pattern analysis, architecture understanding
- Debugging, root cause analysis
- Feature implementation
- Anything requiring thinking about approach

**Direct tools ONLY for:**
- Reading a specific known file
- One-off grep with exact pattern
- Simple single-file edit

**Suggest new agents:** If an appropriate agent doesn't exist for the task, proactively suggest creating one:
- "An agent for database schema analysis doesn't exist - should we create @database-schema-analyzer?"
- Provide the user with the "New Feature Prompt" from ~/.claude/README.md to create it

## Agent Types

After `/init-workspace`, agents available in `./.claude/agents/`:

**Base Agents (universal):**
- **@code-finder** - DEFAULT for code searches (Haiku, fast/cheap)
- **@code-finder-advanced** - Deep investigation (Sonnet, thorough)
- **@root-cause-analyzer** - Bug diagnosis (investigation only)
- **@implementor** - Executes tasks from plans
- **@library-docs-writer** - Fetches/compresses library docs

**Specialist Agents (domain-specific):**
- **default**: backend-feature, frontend-feature, fullstack-feature
- **iOS/macOS/visionOS**: ui-swiftui, networking-data, architecture, etc.
- **webdev**: react-component, api-endpoint, fullstack-feature
- **streamdeck**: action-feature, integration-feature, ui-feature

See `./.claude/agents/specialist/` for your domain's complete roster.

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
