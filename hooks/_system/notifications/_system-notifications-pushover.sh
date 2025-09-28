#!/bin/bash

# Pushover notification script for Claude Code hooks
# Sends push notifications when Claude needs attention or completes a task
# Only sends notifications when the Mac screen is locked (user is away)

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Check if screen is locked
# Exit silently if screen is unlocked (user is at their desk)
if python3 "$SCRIPT_DIR/check-screen-lock.py"; then
    # Screen is locked, proceed with notification
    echo "[$(date)] Screen is locked, sending Pushover notification" >> /tmp/pushover-debug.log
else
    # Screen is unlocked, skip notification
    echo "[$(date)] Screen is unlocked, skipping Pushover notification" >> /tmp/pushover-debug.log
    exit 0
fi

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

# Get the project name from the current working directory
# Extract the last directory name from PWD (project folder name)
PROJECT_NAME=$(basename "$PWD")

# Debug: Log when script is called
echo "[$(date)] Pushover script called with argument: '$HOOK_TYPE' from project: '$PROJECT_NAME'" >> /tmp/pushover-debug.log

# Set notification parameters based on hook type
case "$HOOK_TYPE" in
    "stop")
        # Claude finished a task
        TITLE="[$PROJECT_NAME] Claude has finished"
        MESSAGE="Your task in $PROJECT_NAME has been completed."
        PRIORITY="0"  # Normal priority
        SOUND="cosmic"  # Pleasant completion sound
        ;;
    "notification")
        # Claude needs your help/permission
        TITLE="[$PROJECT_NAME] Claude needs your help"
        MESSAGE="Input or permission required to continue in $PROJECT_NAME."
        PRIORITY="1"  # High priority
        SOUND="tugboat"  # Attention-grabbing sound
        ;;
    *)
        # Default case
        TITLE="[$PROJECT_NAME] Claude Notification"
        MESSAGE="Claude has sent a notification from $PROJECT_NAME."
        PRIORITY="0"
        SOUND="pushover"
        ;;
esac

# Debug: Log what we're sending
echo "[$(date)] Sending notification - Title: '$TITLE', Type: '$HOOK_TYPE'" >> /tmp/pushover-debug.log

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