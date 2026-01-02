# Architecture Reference

## Directory Structure

| Location | Purpose |
|----------|---------|
| `~/.claude/agents/` | Global agents (code-finder, implementor, etc.) |
| `~/.claude/commands/` | Slash commands (/git, /worktree, /catchup) |
| `~/.claude/hooks/` | System hooks (notification sounds) |
| `~/.claude/scripts/` | Utility scripts (cleanup-claude) |
| `~/.claude/statusline/` | Custom statusline script |

## Hooks

Notification hooks in `~/.claude/hooks/`:

- `_system-notifications-attention-sound.sh` - Plays when Claude needs attention
- `_system-notifications-play-sound.sh` - Plays when Claude stops

## Scheduled Tasks

- **cleanup-claude** - Runs daily at noon, deletes cache files >7 days old (debug, todos, shell-snapshots, plans, file-history)
