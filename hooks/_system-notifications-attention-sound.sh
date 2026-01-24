#!/bin/bash
# Play a more attention-grabbing sound when Claude needs attention/permission

[[ -n "${CLAUDE_SILENT_HOOK:-}" ]] && exit 0

SOUND=/System/Library/Sounds/Tink.aiff
afplay "${SOUND}" -v 8 &
sleep 0.03
afplay "${SOUND}" -v 5 &
sleep 0.07
afplay "${SOUND}" -v 3 &
sleep 0.08
afplay "${SOUND}" -v 8 &