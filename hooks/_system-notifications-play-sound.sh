#!/bin/bash

# Skip sound for utility/silent Claude calls
[[ -n "$CLAUDE_SILENT_HOOK" ]] && exit 0

# Play a sound when Claude Code requests permission
afplay /System/Library/Sounds/Glass.aiff