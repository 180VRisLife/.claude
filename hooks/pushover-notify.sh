#!/bin/bash

# Pushover notification script for Claude Code hooks
# Sends push notifications when Claude needs attention or completes a task

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Load environment variables from .env file
if [ -f "$SCRIPT_DIR/.env" ]; then
    export $(grep -v '^#' "$SCRIPT_DIR/.env" | xargs)
else
    echo "Error: .env file not found at $SCRIPT_DIR/.env" >&2
    echo "Please create it with your Pushover credentials" >&2
    exit 1
fi

# Verify credentials are set
if [ -z "$PUSHOVER_USER_KEY" ] || [ -z "$PUSHOVER_APP_TOKEN" ]; then
    echo "Error: PUSHOVER_USER_KEY or PUSHOVER_APP_TOKEN not set in .env file" >&2
    exit 1
fi

# Read the hook type from the first argument
HOOK_TYPE="$1"

# Set notification parameters based on hook type
case "$HOOK_TYPE" in
    "stop")
        # Claude finished a task
        TITLE="Claude Task Complete"
        MESSAGE="Claude has finished the current task."
        PRIORITY="0"  # Normal priority
        SOUND="cosmic"  # Pleasant completion sound
        ;;
    "notification")
        # Claude needs your help/permission
        TITLE="Claude Needs Your Help"
        MESSAGE="Claude is requesting your permission or input to continue."
        PRIORITY="1"  # High priority
        SOUND="tugboat"  # Attention-grabbing sound
        ;;
    *)
        # Default case
        TITLE="Claude Notification"
        MESSAGE="Claude has sent a notification."
        PRIORITY="0"
        SOUND="pushover"
        ;;
esac

# Send the Pushover notification
curl -s \
    --form-string "token=${PUSHOVER_APP_TOKEN}" \
    --form-string "user=${PUSHOVER_USER_KEY}" \
    --form-string "title=${TITLE}" \
    --form-string "message=${MESSAGE}" \
    --form-string "priority=${PRIORITY}" \
    --form-string "sound=${SOUND}" \
    https://api.pushover.net/1/messages.json > /dev/null 2>&1

# Exit successfully
exit 0