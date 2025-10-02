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

# Capture Claude's full message if available from stdin
# Hooks receive the message content via stdin as JSON
if [ -t 0 ]; then
    # No input from stdin
    CLAUDE_MESSAGE="No message context available"
else
    # Read from stdin
    STDIN_DATA=$(cat)

    # Debug: Log the raw JSON data
    echo "[$(date)] Raw JSON: $STDIN_DATA" >> /tmp/pushover-debug.log

    if [ -z "$STDIN_DATA" ]; then
        CLAUDE_MESSAGE="No message context available"
    else
        # Parse the JSON and extract tool details from transcript file for Notification hook only
        # For Stop hook, just show the base message
        # Use python for reliable JSON parsing
        CLAUDE_MESSAGE=$(echo "$STDIN_DATA" | python3 -c "
import sys, json

try:
    data = json.load(sys.stdin)

    # Only parse tool details for Notification hook, not Stop
    hook_event = data.get('hook_event_name', '')

    # For Stop hook, extract the last assistant message from transcript
    if hook_event == 'Stop':
        transcript_path = data.get('transcript_path')
        msg = 'Task completed'

        if transcript_path:
            try:
                import subprocess
                result = subprocess.run(
                    ['tail', '-20', transcript_path],
                    capture_output=True,
                    text=True,
                    timeout=2
                )

                if result.returncode == 0:
                    lines = result.stdout.strip().split('\n')

                    # Find the last assistant text message
                    for line in reversed(lines):
                        try:
                            entry = json.loads(line)
                            if (entry.get('type') == 'assistant' and
                                'message' in entry and
                                'content' in entry['message']):

                                content = entry['message']['content']
                                if isinstance(content, list):
                                    for item in content:
                                        if item.get('type') == 'text':
                                            text = item.get('text', '').strip()
                                            if text:
                                                # Truncate long messages
                                                if len(text) > 200:
                                                    text = text[:200] + '...'
                                                msg = text
                                                raise StopIteration
                        except (json.JSONDecodeError, StopIteration):
                            if isinstance(sys.exc_info()[1], StopIteration):
                                break
                            continue
            except Exception:
                pass
    else:
        # For Notification hook, use the message field
        msg = data.get('message', 'No message context available')
        transcript_path = data.get('transcript_path')

    if transcript_path:
        # Read the last 50 lines of the transcript to find the most recent tool_use
        try:
            import subprocess
            result = subprocess.run(
                ['tail', '-50', transcript_path],
                capture_output=True,
                text=True,
                timeout=2
            )

            if result.returncode == 0:
                lines = result.stdout.strip().split('\n')

                # Parse lines in reverse to find most recent tool_use
                for line in reversed(lines):
                    try:
                        entry = json.loads(line)

                        # Look for assistant messages with tool_use in content
                        if (entry.get('type') == 'assistant' and
                            'message' in entry and
                            'content' in entry['message']):

                            content = entry['message']['content']
                            if isinstance(content, list):
                                for item in content:
                                    if item.get('type') == 'tool_use':
                                        tool_name = item.get('name', 'Unknown')
                                        tool_input = item.get('input', {})

                                        msg += f'\n\nTool: {tool_name}'

                                        # For Bash commands
                                        if tool_name == 'Bash' and 'command' in tool_input:
                                            cmd = tool_input['command']
                                            # Truncate long commands
                                            if len(cmd) > 200:
                                                cmd = cmd[:200] + '...'
                                            msg += f'\nCommand: {cmd}'

                                        # For file operations
                                        elif tool_name in ['Write', 'Edit', 'Read']:
                                            if 'file_path' in tool_input:
                                                msg += f'\nFile: {tool_input[\"file_path\"]}'

                                            # For Write, include full content temporarily for testing
                                            if tool_name == 'Write' and 'content' in tool_input:
                                                content = tool_input['content']
                                                msg += f'\n\nContent:\n{content}'

                                            # For Edit, include old and new strings
                                            elif tool_name == 'Edit':
                                                if 'old_string' in tool_input:
                                                    old = tool_input['old_string']
                                                    msg += f'\n\nRemoving:\n{old}'
                                                if 'new_string' in tool_input:
                                                    new = tool_input['new_string']
                                                    msg += f'\n\nAdding:\n{new}'

                                        # For WebFetch
                                        elif tool_name == 'WebFetch':
                                            if 'url' in tool_input:
                                                msg += f'\nURL: {tool_input[\"url\"]}'
                                            if 'prompt' in tool_input:
                                                prompt = tool_input['prompt']
                                                if len(prompt) > 100:
                                                    prompt = prompt[:100] + '...'
                                                msg += f'\nPrompt: {prompt}'

                                        # For WebSearch
                                        elif tool_name == 'WebSearch':
                                            if 'query' in tool_input:
                                                msg += f'\nQuery: {tool_input[\"query\"]}'

                                        # For Grep
                                        elif tool_name == 'Grep':
                                            if 'pattern' in tool_input:
                                                msg += f'\nPattern: {tool_input[\"pattern\"]}'
                                            if 'path' in tool_input:
                                                msg += f'\nPath: {tool_input[\"path\"]}'
                                            if 'glob' in tool_input:
                                                msg += f'\nGlob: {tool_input[\"glob\"]}'

                                        # For Glob
                                        elif tool_name == 'Glob':
                                            if 'pattern' in tool_input:
                                                msg += f'\nPattern: {tool_input[\"pattern\"]}'
                                            if 'path' in tool_input:
                                                msg += f'\nPath: {tool_input[\"path\"]}'

                                        # For Task (subagents)
                                        elif tool_name == 'Task':
                                            if 'subagent_type' in tool_input:
                                                msg += f'\nSubagent: {tool_input[\"subagent_type\"]}'
                                            if 'description' in tool_input:
                                                msg += f'\nTask: {tool_input[\"description\"]}'
                                            if 'prompt' in tool_input:
                                                prompt = tool_input['prompt']
                                                if len(prompt) > 150:
                                                    prompt = prompt[:150] + '...'
                                                msg += f'\nPrompt: {prompt}'

                                        # For NotebookEdit
                                        elif tool_name == 'NotebookEdit':
                                            if 'notebook_path' in tool_input:
                                                msg += f'\nNotebook: {tool_input[\"notebook_path\"]}'
                                            if 'cell_id' in tool_input:
                                                msg += f'\nCell ID: {tool_input[\"cell_id\"]}'

                                        # Generic fallback for any other tools
                                        else:
                                            # Show any available input fields
                                            if tool_input:
                                                msg += '\nParameters:'
                                                for key, value in list(tool_input.items())[:3]:
                                                    val_str = str(value)
                                                    if len(val_str) > 50:
                                                        val_str = val_str[:50] + '...'
                                                    msg += f'\n  {key}: {val_str}'

                                        # Found tool, exit loop
                                        raise StopIteration
                    except (json.JSONDecodeError, StopIteration):
                        if isinstance(sys.exc_info()[1], StopIteration):
                            break
                        continue

        except Exception as e:
            # If we can't read transcript, just use base message
            pass

    print(msg)

except Exception as e:
    print('No message context available')
" 2>/dev/null)

        # Fallback if JSON parsing fails
        if [ -z "$CLAUDE_MESSAGE" ] || [ "$CLAUDE_MESSAGE" = "None" ]; then
            CLAUDE_MESSAGE="No message context available"
        fi
    fi
fi

# Set notification parameters based on hook type
case "$HOOK_TYPE" in
    "stop")
        # Claude finished a task
        TITLE="[$PROJECT_NAME] Claude has finished"
        MESSAGE="Your task in $PROJECT_NAME has been completed.

Claude's message:
$CLAUDE_MESSAGE"
        PRIORITY="0"  # Normal priority
        SOUND="cosmic"  # Pleasant completion sound
        ;;
    "subagent_stop")
        # Subagent finished a task
        TITLE="[$PROJECT_NAME] Subagent has finished"
        MESSAGE="A subagent task in $PROJECT_NAME has been completed.

Claude's message:
$CLAUDE_MESSAGE"
        PRIORITY="0"  # Normal priority
        SOUND="cosmic"  # Pleasant completion sound
        ;;
    "notification")
        # Claude needs your help/permission
        TITLE="[$PROJECT_NAME] Claude needs your help"
        MESSAGE="Input or permission required to continue in $PROJECT_NAME.

Claude's message:
$CLAUDE_MESSAGE"
        PRIORITY="1"  # High priority
        SOUND="tugboat"  # Attention-grabbing sound
        ;;
    *)
        # Default case
        TITLE="[$PROJECT_NAME] Claude Notification"
        MESSAGE="Claude has sent a notification from $PROJECT_NAME.

Claude's message:
$CLAUDE_MESSAGE"
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