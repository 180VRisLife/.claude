# Architecture Reference

## Architecture Overview

| Location | Purpose |
|----------|---------|
| **Global Config** (`~/.claude/`) | Commands, agents, system hooks, and file templates |

## File Templates

Formatting guides automatically referenced by workflow commands - not executed directly.

*Located in `~/.claude/file-templates/`*

| Template | Purpose |
|----------|---------|
| **requirements.template.md** | Template for requirements documents (user-focused, non-technical) |
| **architecture.template.md** | Template for technical architecture documentation |
| **priority.template.md** | Template for 3-tier prioritization (Tier 1: build, Tier 2: stub, Tier 3: future) |
| **parallelization.template.md** | Template for parallel execution plans with task dependencies |

## Global Hooks

These hooks remain in the global `~/.claude/hooks/` folder and work across all workspaces:

- **_system/notifications/** - System notification hooks (sounds)
