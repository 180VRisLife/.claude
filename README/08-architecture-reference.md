 # Architecture Reference

## Architecture Overview

This system uses a **Library-based architecture** where domain-specific configurations are stored in a central Library and deployed to individual workspaces:

| Location | Purpose |
|----------|---------|
| **Global Config** (`~/.claude/`) | Domain-agnostic commands (like `/git`), system hooks, and the Library |
| **Library** (`~/.claude/library/`) | Domain-specific templates for agents, commands, hooks, etc. |

## Domain-Specific Hook System

After running `/0-workspace`, your project will have domain-specific hooks that automatically enhance Claude:

| Hook | Purpose |
|------|---------|
| **workflow-orchestrator.py** | Intelligently injects workflow guides |
| **parallel.py** | Loads the parallel execution guide after planning (PostToolUse hook) |

## Guides

*Located in `./.claude/guides/` after running `/0-workspace`*

**Always loaded:**
- **foundation.md** - Professional development mode with agent delegation, parallel execution, and code standards

**Keyword-triggered:**
- **brainstorming.md** - Collaborative discovery workflow (keyword: "brainstorm")
- **deep-research.md** - Systematic investigation with evidence-based reasoning (keyword: "deep research")
- **planning.md** - Research-driven planning methodology (keywords: "plan out", "planning")
- **implementation.md** - Best practices before implementing features (keywords: "implement", "build", "code")
- **debug.md** - Debugging workflow and error investigation (keywords: "debug", "bug", "error")
- **investigation.md** - Code investigation and pattern analysis (keywords: "investigate", "research", "analyze")
- **parallel.md** - Parallel agent execution  (keywords: "parallel", "batch", "simultaneously", "concurrently")

## File Templates

Formatting guides automatically referenced by workflow commands - not executed directly.

*Located in `./.claude/file-templates/` after running `/0-workspace`*

| Template | Purpose |
|----------|---------|
| **requirements.template.md** | Template for requirements documents (user-focused, non-technical) |
| **architecture.template.md** | Template for technical architecture documentation |
| **priority.template.md** | Template for 3-tier prioritization (Tier 1: build, Tier 2: stub, Tier 3: future) |
| **parallelization.template.md** | Template for parallel execution plans with task dependencies |

## Global Hooks

These hooks remain in the global `~/.claude/hooks/` folder and work across all workspaces:

- **_system/notifications/** - System notification hooks (sounds)
