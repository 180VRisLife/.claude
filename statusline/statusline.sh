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

# Abbreviate repo name
abbreviate_repo_name() {
    local name="$1"
    echo "$name" | sed 's/\([A-Z]\)/ \1/g; s/[-_]/ /g' | awk '{
        result=""
        for(i=1; i<=NF; i++) {
            if(length($i) > 0) { result = result toupper(substr($i, 1, 1)) }
        }
        print result
    }'
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
        if [ -d "$real_path/.git" ] || (cd "$real_path" 2>/dev/null && git rev-parse --git-dir >/dev/null 2>&1); then
            local git_info=$(get_repo_git_info "$real_path")
            if [ -n "$git_info" ]; then
                local abbrev=$(abbreviate_repo_name "$(basename "$item")")
                local branch=$(echo "$git_info" | cut -d'|' -f1)
                local dirty=$(echo "$git_info" | cut -d'|' -f2)
                [ -n "$WORKSPACE_DISPLAY" ] && WORKSPACE_DISPLAY="${WORKSPACE_DISPLAY} "
                WORKSPACE_DISPLAY="${WORKSPACE_DISPLAY}${abbrev}:${branch}${dirty}"
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

# === Model ===
MODEL_ABBREV=$(abbreviate_model "$MODEL_NAME")

# === Directory ===
DIR_NAME=$(basename "$CWD")

# === Git info ===
GIT_BRANCH=$(cd "$CWD" 2>/dev/null && git branch --show-current 2>/dev/null || echo "")
GIT_PART=""

if [ -n "$GIT_BRANCH" ]; then
    DIRTY="✓"
    [ -n "$(cd "$CWD" && git status --porcelain 2>/dev/null)" ] && DIRTY="*"

    # Check if in a worktree
    GIT_DIR=$(cd "$CWD" && git rev-parse --git-dir 2>/dev/null)
    if [ -f "$GIT_DIR/commondir" ]; then
        WORKTREE_NAME=$(basename "$CWD")
        if [ "$GIT_BRANCH" != "$WORKTREE_NAME" ]; then
            # Branch differs from worktree - show ⎇ ABBREV:branch✓
            WORKTREE_ABBREV=$(abbreviate_repo_name "$WORKTREE_NAME")
            GIT_PART="${GIT_COLOR}⎇ ${WORKTREE_ABBREV}:${GIT_BRANCH}${DIRTY}${RESET}"
        else
            # Branch matches worktree - show ⎇ branch✓
            GIT_PART="${GIT_COLOR}⎇ ${GIT_BRANCH}${DIRTY}${RESET}"
        fi
    else
        # Regular git repo - show ○ branch✓
        GIT_PART="${GIT_COLOR}○ ${GIT_BRANCH}${DIRTY}${RESET}"
    fi
else
    scan_workspace_repos "$CWD"
    # Workspace with multiple repos - show ◆ prefix
    [ "$WORKSPACE_REPO_COUNT" -gt 0 ] && GIT_PART="${GIT_COLOR}◆ ${WORKSPACE_DISPLAY}${RESET}"
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
    PERCENT_INT=$(awk "BEGIN {printf \"%.0f\", ($TOTAL_TOKENS / $CONTEXT_SIZE) * 100}")
    TOKEN_COLOR=$(get_token_color "$PERCENT_INT")
    WINDOW_DISPLAY=$(format_tokens "$CONTEXT_SIZE")
    CONTEXT_PART="${TOKEN_COLOR}${TOKEN_DISPLAY}/${WINDOW_DISPLAY} · ${PERCENT_INT}%${RESET}"
fi

# === Output ===
SEP="${SEP_COLOR} | ${RESET}"
OUTPUT="${MODEL_COLOR}${MODEL_ABBREV}${RESET}"
[ -n "$DIR_NAME" ] && OUTPUT="${OUTPUT}${SEP}${FOLDER_COLOR}${DIR_NAME}${RESET}"
[ -n "$CONTEXT_PART" ] && OUTPUT="${OUTPUT}${SEP}${CONTEXT_PART}"
[ -n "$GIT_PART" ] && OUTPUT="${OUTPUT}${SEP}${GIT_PART}"

echo -e "$OUTPUT"
