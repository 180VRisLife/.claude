#!/bin/bash
# Single-line status
# Format: 🤖 Model • 🌿 main✓ • 📋 SWI, FEA

set +x

INPUT=$(cat)

# Colors
CYAN='\033[36m'
BLUE='\033[34m'
MAGENTA='\033[35m'
GRAY='\033[90m'
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

# Abbreviate guide name (lookup table)
abbreviate_guide() {
    local name=$(echo "$1" | tr '[:upper:]' '[:lower:]')
    case "$name" in
        foundation)     echo "FND" ;;
        brainstorming)  echo "BST" ;;
        debug)          echo "DBG" ;;
        deep-research)  echo "RSH" ;;
        implementation) echo "IMP" ;;
        investigation)  echo "INV" ;;
        parallel)       echo "PAR" ;;
        planning)       echo "PLN" ;;
        *)              echo "$name" | sed 's/-//g' | cut -c1-3 | tr '[:lower:]' '[:upper:]' ;;
    esac
}

# Get active guides (abbreviated)
get_active_guides() {
    local cwd="$1"
    local cwd_hash=$(echo -n "$cwd" | md5 | cut -c1-12 2>/dev/null || echo -n "$cwd" | md5sum | cut -c1-12)
    local session_file="/tmp/claude-workflow-${cwd_hash}-${PPID}.json"
    if [ -f "$session_file" ]; then
        local guides=$(jq -r '.injected // [] | .[]' "$session_file" 2>/dev/null)
        local abbrevs=""
        while IFS= read -r guide; do
            [ -z "$guide" ] && continue
            local abbr=$(abbreviate_guide "$guide")
            [ -n "$abbrevs" ] && abbrevs="${abbrevs}, "
            abbrevs="${abbrevs}${abbr}"
        done <<< "$guides"
        echo "$abbrevs"
    fi
}

# === Extract data ===
MODEL_ID=$(echo "$INPUT" | jq -r '.model.id // ""')
MODEL_NAME=$(echo "$INPUT" | jq -r '.model.display_name // "Claude"')
CWD=$(echo "$INPUT" | jq -r '.cwd // ""')
TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // empty')

# === Git info ===
GIT_BRANCH=$(cd "$CWD" 2>/dev/null && git branch --show-current 2>/dev/null || echo "")
GIT_PART=""

if [ -n "$GIT_BRANCH" ]; then
    DIRTY="✓"
    [ -n "$(cd "$CWD" && git status --porcelain 2>/dev/null)" ] && DIRTY="*"

    WORKTREE=""
    [ -f "$(cd "$CWD" && git rev-parse --git-dir 2>/dev/null)/commondir" ] && WORKTREE=" 🌳 $(basename "$CWD")"

    GIT_PART="${BLUE}🌿 ${GIT_BRANCH}${DIRTY}${WORKTREE}${RESET}"
else
    scan_workspace_repos "$CWD"
    [ "$WORKSPACE_REPO_COUNT" -gt 0 ] && GIT_PART="${BLUE}📁 ${WORKSPACE_DISPLAY}${RESET}"
fi

# === Guides ===
GUIDES_PART=""
ACTIVE_GUIDES=$(get_active_guides "$CWD")
[ -n "$ACTIVE_GUIDES" ] && GUIDES_PART="${MAGENTA}📋 ${ACTIVE_GUIDES}${RESET}"

# === Context Window (from transcript) ===
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'

# Determine context window based on model
case "$MODEL_ID" in
    *sonnet*\[1m\]*|*sonnet*1m*)  CONTEXT_WINDOW=1000000 ;;
    *)                            CONTEXT_WINDOW=200000 ;;
esac

# Check autocompact setting
AUTOCOMPACT_ENABLED=$(jq -r 'if .autoCompactEnabled == false then "false" else "true" end' ~/.claude.json 2>/dev/null)
AUTOCOMPACT_BUFFER=45000
USABLE_CONTEXT=$((CONTEXT_WINDOW - AUTOCOMPACT_BUFFER))

# Calculate tokens from transcript
CONTEXT_PART=""
if [ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ]; then
    LAST_USAGE=$(grep '"type":"assistant"' "$TRANSCRIPT" | tail -1 | jq -r '.message.usage // empty')

    if [ -n "$LAST_USAGE" ] && [ "$LAST_USAGE" != "null" ]; then
        INPUT_TOKENS=$(echo "$LAST_USAGE" | jq -r '.input_tokens // 0')
        CACHE_CREATE=$(echo "$LAST_USAGE" | jq -r '.cache_creation_input_tokens // 0')
        CACHE_READ=$(echo "$LAST_USAGE" | jq -r '.cache_read_input_tokens // 0')

        TOTAL_TOKENS=$((INPUT_TOKENS + CACHE_CREATE + CACHE_READ))

        # Format token display (e.g., 64k or 1.2M)
        if [ "$TOTAL_TOKENS" -ge 1000000 ]; then
            TOKEN_DISPLAY=$(awk "BEGIN {printf \"%.1fM\", $TOTAL_TOKENS / 1000000}")
        elif [ "$TOTAL_TOKENS" -ge 1000 ]; then
            TOKEN_DISPLAY=$(awk "BEGIN {printf \"%.0fk\", $TOTAL_TOKENS / 1000}")
        else
            TOKEN_DISPLAY="$TOTAL_TOKENS"
        fi

        # Format window display (e.g., 200k or 1M)
        if [ "$CONTEXT_WINDOW" -ge 1000000 ]; then
            WINDOW_DISPLAY=$(awk "BEGIN {printf \"%.0fM\", $CONTEXT_WINDOW / 1000000}")
        else
            WINDOW_DISPLAY=$(awk "BEGIN {printf \"%.0fk\", $CONTEXT_WINDOW / 1000}")
        fi

        # Percentage of context used
        PERCENTAGE=$(awk "BEGIN {printf \"%.1f\", ($TOTAL_TOKENS / $CONTEXT_WINDOW) * 100}")
        PERCENT_INT=$(echo "$PERCENTAGE" | awk '{printf "%d", $1}')

        # Color for token count based on usage
        if [ "$PERCENT_INT" -lt 50 ]; then
            TOKEN_COLOR="$GREEN"
        elif [ "$PERCENT_INT" -lt 80 ]; then
            TOKEN_COLOR="$YELLOW"
        else
            TOKEN_COLOR="$RED"
        fi

        # Remaining percentage and label
        if [ "$AUTOCOMPACT_ENABLED" = "true" ]; then
            REMAINING=$((USABLE_CONTEXT - TOTAL_TOKENS))
            [ "$REMAINING" -lt 0 ] && REMAINING=0
            PERCENT_REMAINING=$(awk "BEGIN {printf \"%.0f\", ($REMAINING / $USABLE_CONTEXT) * 100}")
            LABEL="to compact"
            # Color: green if >50%, yellow if >20%, red if <=20%
            if [ "$PERCENT_REMAINING" -gt 50 ]; then
                COMPACT_COLOR="$GREEN"
            elif [ "$PERCENT_REMAINING" -gt 20 ]; then
                COMPACT_COLOR="$YELLOW"
            else
                COMPACT_COLOR="$RED"
            fi
        else
            REMAINING=$((CONTEXT_WINDOW - TOTAL_TOKENS))
            [ "$REMAINING" -lt 0 ] && REMAINING=0
            PERCENT_REMAINING=$(awk "BEGIN {printf \"%.0f\", ($REMAINING / $CONTEXT_WINDOW) * 100}")
            LABEL="to end"
            COMPACT_COLOR="$CYAN"
        fi

        CONTEXT_PART="${TOKEN_COLOR}${TOKEN_DISPLAY}/${WINDOW_DISPLAY} (${PERCENTAGE}%)${RESET}${GRAY} • ${COMPACT_COLOR}${PERCENT_REMAINING}% ${LABEL}${RESET}"
    fi
fi

# === Output single status line ===
# Build parts array and join with separators (no trailing separator)
SEP="${GRAY} • ${RESET}"
OUTPUT="${CYAN}🤖 ${MODEL_NAME}${RESET}"

[ -n "$CONTEXT_PART" ] && OUTPUT="${OUTPUT}${SEP}${CONTEXT_PART}"
[ -n "$GIT_PART" ] && OUTPUT="${OUTPUT}${SEP}${GIT_PART}"
[ -n "$GUIDES_PART" ] && OUTPUT="${OUTPUT}${SEP}${GUIDES_PART}"

echo -e "$OUTPUT"
