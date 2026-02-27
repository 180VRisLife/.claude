#!/bin/bash
# Play a more attention-grabbing sound when Claude needs attention/permission

[[ -n "${CLAUDE_SILENT_HOOK:-}" ]] && exit 0

# Suppress sound when user is not at the Mac (screen locked or SSH sessions)
# shellcheck source=_guard-local-sound.sh disable=SC1091
source "${HOME}/.claude/hooks/_guard-local-sound.sh"

# Remote: write event to log for local Mac to pick up
if [[ -n "${SSH_CONNECTION:-}" ]]; then
    printf 'attention\t%s\n' "$(basename "${PWD}")" >> /tmp/devkit-hook-events.log
    exit 0
fi

SOUND=/System/Library/Sounds/Tink.aiff
afplay "${SOUND}" -v 0.4 &
sleep 0.03
afplay "${SOUND}" -v 0.25 &
sleep 0.07
afplay "${SOUND}" -v 0.15 &
sleep 0.08
afplay "${SOUND}" -v 0.4 &
