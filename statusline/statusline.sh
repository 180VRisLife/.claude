#!/bin/bash
# Compact status: Model|64k 45%|main✓

set +x

INPUT=$(cat)

# Colors - muted 256-color palette (avoids Claude Code UI colors)
MODEL_COLOR='\033[38;5;146m'    # Lavender - soft purple-gray
FOLDER_COLOR='\033[38;5;109m'  # Slate teal - muted cyan-gray
GIT_COLOR='\033[38;5;67m'      # Steel blue - muted blue-gray
SEP_COLOR='\033[38;5;244m'     # Medium gray - subtle separator
TOKEN_LOW='\033[38;5;108m'     # Sage - muted green
TOKEN_MED='\033[38;5;179m'     # Gold - muted yellow
TOKEN_HIGH='\033[38;5;167m'    # Terracotta - muted red
RESET='\033[0m'

# Workspaces path for multi-repo workspace detection
WORKSPACES_PATH="$HOME/Developer/Workspaces"

# Abbreviate repo name (skips symbols, uses first letter of each word)
abbreviate_repo_name() {
    local name="$1"
    echo "$name" | sed 's/\([A-Z]\)/ \1/g; s/[-_.]/ /g' | awk '{
        result=""
        for(i=1; i<=NF; i++) {
            # Skip to first alphabetic character
            word = $i
            gsub(/^[^a-zA-Z]+/, "", word)
            if(length(word) > 0) { result = result toupper(substr(word, 1, 1)) }
        }
        print result
    }'
}

# Get the main repository name from a worktree
get_worktree_repo_name() {
    local worktree_path="$1"
    local gitdir_line=$(cat "$worktree_path/.git" 2>/dev/null)
    # Extract path: "gitdir: /path/to/repo/.git/worktrees/name" -> "/path/to/repo"
    local repo_path=$(echo "$gitdir_line" | sed 's/gitdir: //; s/\/\.git\/worktrees\/.*//')
    basename "$repo_path"
}

# Get git info for a repo
get_repo_git_info() {
    local repo_path="$1"
    local branch=$(cd "$repo_path" 2>/dev/null && git branch --show-current 2>/dev/null || echo "")
    [ -z "$branch" ] && return
    local dirty="✓"
    [ -n "$(cd "$repo_path" && git status --porcelain 2>/dev/null)" ] && dirty="*"
    echo "${branch}|${dirty}"
}

# Scan workspace for git repos
scan_workspace_repos() {
    local workspace_path="$1"
    WORKSPACE_DISPLAY="" WORKSPACE_REPO_COUNT=0
    for item in "$workspace_path"/*; do
        [ -e "$item" ] || continue
        local real_path="$item"
        [ -L "$item" ] && real_path=$(readlink -f "$item" 2>/dev/null || readlink "$item" 2>/dev/null)
        [ -d "$real_path" ] || continue
        if [ -d "$real_path/.git" ] || [ -f "$real_path/.git" ]; then
            local git_info=$(get_repo_git_info "$real_path")
            if [ -n "$git_info" ]; then
                # For worktrees, use the actual repo name and [w] icon; otherwise use folder name and [r]
                local repo_name icon
                if [ -f "$real_path/.git" ]; then
                    repo_name=$(get_worktree_repo_name "$real_path")
                    icon="[w]"
                else
                    repo_name=$(basename "$item")
                    icon="[r]"
                fi
                local branch=$(echo "$git_info" | cut -d'|' -f1)
                local dirty=$(echo "$git_info" | cut -d'|' -f2)
                [ -n "$WORKSPACE_DISPLAY" ] && WORKSPACE_DISPLAY="${WORKSPACE_DISPLAY} "
                WORKSPACE_DISPLAY="${WORKSPACE_DISPLAY}${icon}${repo_name}:${branch}${dirty}"
                WORKSPACE_REPO_COUNT=$((WORKSPACE_REPO_COUNT + 1))
            fi
        fi
    done
}

# Abbreviate model name (extract last word: "Claude Opus 4.5" -> "Opus")
abbreviate_model() {
    local name="$1"
    # Extract model family (Opus, Sonnet, Haiku)
    if [[ "$name" == *"Opus"* ]]; then echo "Opus"
    elif [[ "$name" == *"Sonnet"* ]]; then echo "Sonnet"
    elif [[ "$name" == *"Haiku"* ]]; then echo "Haiku"
    else echo "$name" | awk '{print $NF}'
    fi
}

# Format tokens (64k, 1.2M, etc.)
format_tokens() {
    local tokens="$1"
    if [ "$tokens" -ge 1000000 ]; then
        awk "BEGIN {printf \"%.1fM\", $tokens / 1000000}"
    elif [ "$tokens" -ge 1000 ]; then
        awk "BEGIN {printf \"%.0fk\", $tokens / 1000}"
    else
        echo "$tokens"
    fi
}

# Get token color based on percentage
get_token_color() {
    local percent="$1"
    if [ "$percent" -lt 50 ]; then echo "$TOKEN_LOW"
    elif [ "$percent" -lt 80 ]; then echo "$TOKEN_MED"
    else echo "$TOKEN_HIGH"
    fi
}

# === Extract data ===
MODEL_NAME=$(echo "$INPUT" | jq -r '.model.display_name // "Claude"')
CWD=$(echo "$INPUT" | jq -r '.cwd // ""')

# === Session path persistence - always show initial session path ===
SESSION_FILE="/tmp/claude-session-cwd-$PPID"
if [ ! -f "$SESSION_FILE" ]; then
    # First invocation - save initial CWD
    echo "$CWD" > "$SESSION_FILE"
    INITIAL_CWD="$CWD"
else
    # Subsequent invocations - use saved path
    INITIAL_CWD=$(cat "$SESSION_FILE")
fi

# === Model ===
MODEL_ABBREV=$(abbreviate_model "$MODEL_NAME")

# === Directory ===
# For worktrees, show the main repo name instead of the worktree folder name
# Use INITIAL_CWD so folder name always shows where session was opened
if [ -f "$INITIAL_CWD/.git" ]; then
    DIR_NAME=$(get_worktree_repo_name "$INITIAL_CWD")
else
    DIR_NAME=$(basename "$INITIAL_CWD")
fi

# === Git info ===
GIT_BRANCH=$(cd "$CWD" 2>/dev/null && git branch --show-current 2>/dev/null || echo "")
GIT_PART=""

if [ -n "$GIT_BRANCH" ]; then
    DIRTY="✓"
    [ -n "$(cd "$CWD" && git status --porcelain 2>/dev/null)" ] && DIRTY="*"

    # Check if in a worktree (.git is a file in worktrees, directory in main repos)
    if [ -f "$CWD/.git" ]; then
        # Worktree: always show [w] name:branch✓
        WORKTREE_NAME=$(basename "$CWD")
        GIT_PART="${GIT_COLOR}[w] ${WORKTREE_NAME}:${GIT_BRANCH}${DIRTY}${RESET}"
    else
        # Regular git repo - show [r] repo:branch✓
        REPO_ROOT=$(cd "$CWD" && git rev-parse --show-toplevel 2>/dev/null)
        REPO_NAME=$(basename "$REPO_ROOT")
        GIT_PART="${GIT_COLOR}[r] ${REPO_NAME}:${GIT_BRANCH}${DIRTY}${RESET}"
    fi
else
    # Only scan for workspace repos if under the Workspaces folder
    if [[ "$CWD" == "$WORKSPACES_PATH"* ]]; then
        scan_workspace_repos "$CWD"
        # Workspace with multiple repos - show [s] prefix
        [ "$WORKSPACE_REPO_COUNT" -gt 0 ] && GIT_PART="${GIT_COLOR}[s] ${WORKSPACE_DISPLAY}${RESET}"
    fi
fi

# === Context Window ===
CONTEXT_PART=""
CONTEXT_SIZE=$(echo "$INPUT" | jq -r '.context_window.context_window_size // 0')
CURRENT_USAGE=$(echo "$INPUT" | jq '.context_window.current_usage // null')

if [ "$CONTEXT_SIZE" -gt 0 ]; then
    # If no usage yet, default to 0 tokens
    if [ "$CURRENT_USAGE" != "null" ]; then
        INPUT_TOKENS=$(echo "$CURRENT_USAGE" | jq -r '.input_tokens // 0')
        CACHE_CREATE=$(echo "$CURRENT_USAGE" | jq -r '.cache_creation_input_tokens // 0')
        CACHE_READ=$(echo "$CURRENT_USAGE" | jq -r '.cache_read_input_tokens // 0')
        TOTAL_TOKENS=$((INPUT_TOKENS + CACHE_CREATE + CACHE_READ))
    else
        TOTAL_TOKENS=0
    fi

    TOKEN_DISPLAY=$(format_tokens "$TOTAL_TOKENS")
    PERCENT_INT=$(awk "BEGIN {printf \"%02.0f\", ($TOTAL_TOKENS / $CONTEXT_SIZE) * 100}")
    TOKEN_COLOR=$(get_token_color "$PERCENT_INT")
    WINDOW_DISPLAY=$(format_tokens "$CONTEXT_SIZE")
    CONTEXT_PART="${TOKEN_COLOR}${TOKEN_DISPLAY}/${WINDOW_DISPLAY} · ${PERCENT_INT}%${RESET}"
fi

# === Output ===
SEP="${SEP_COLOR} | ${RESET}"
OUTPUT="${MODEL_COLOR}${MODEL_ABBREV}${RESET}"
[ -n "$CONTEXT_PART" ] && OUTPUT="${OUTPUT}${SEP}${CONTEXT_PART}"
[ -n "$DIR_NAME" ] && OUTPUT="${OUTPUT}${SEP}${FOLDER_COLOR}${DIR_NAME}${RESET}"
[ -n "$GIT_PART" ] && OUTPUT="${OUTPUT}${SEP}${GIT_PART}"

echo -e "$OUTPUT"
