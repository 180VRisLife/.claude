#!/bin/bash
# Sourced by sound hooks to suppress playback when user is not at the Mac.
# Exits the parent script if sounds should be suppressed.

# Only guard on local Mac — remote servers have their own SSH_CONNECTION exit path
[[ -n "${SSH_CONNECTION:-}" ]] && return 0

# Screen locked? (maintained by com.claudenotifications.lock-detector launchd agent)
if [[ -f /tmp/claude-notifications-lock-state ]] \
    && [[ "$(< /tmp/claude-notifications-lock-state)" == "locked" ]]; then
    exit 0
fi

# Active inbound SSH sessions? (user is working remotely, not at Mac)
# On macOS, `who` shows SSH sessions with remote host in parentheses.
# Exclude "(console)" to avoid false positives from local GUI login.
# shellcheck disable=SC2312
if who 2> /dev/null | grep -vF '(console)' | grep -qE '\(.+\)'; then
    exit 0
fi
