#!/bin/bash

# Skip sound for utility/silent Claude calls
[[ -n "$CLAUDE_SILENT_HOOK" ]] && exit 0

# Only play sound for main agent stops (not subagents)
# SubagentStop events include agent_id field, Stop events don't
if grep -q '"agent_id"'; then
    exit 0
fi

# Remote: write event to log for local Mac to pick up
if [[ -n "${SSH_CONNECTION:-}" ]]; then
    printf 'stop\t%s\n' "$(basename "$PWD")" >> /tmp/devkit-hook-events.log
    exit 0
fi

# Play a sound when main Claude Code session stops
afplay /System/Library/Sounds/Glass.aiff
