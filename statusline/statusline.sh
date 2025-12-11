#!/bin/bash
# Custom status line that shows accurate total context usage
# Matches /context command output (tokens used, without autocompact buffer)
# Shows "X% to compact" (green/yellow/red) when autocompact on, "X% to end" (cyan) when off
# Supports workspaces with multiple git repos
# Shows active workflow guides from guide-injector hook

set +x  # Disable xtrace in case it's inherited from environment

# Box drawing constants
BOX_TL='┌' BOX_TR='┐' BOX_BL='└' BOX_BR='┘'
BOX_H='─' BOX_V='│'

# Colors (ANSI escape codes) - defined early for helper functions
CYAN='\033[36m'
YELLOW='\033[33m'
GREEN='\033[32m'
RED='\033[31m'
BLUE='\033[34m'
MAGENTA='\033[35m'
WHITE='\033[37m'
GRAY='\033[90m'
RESET='\033[0m'

# Get display width of a string (strips ANSI, accounts for wide chars)
get_display_width() {
    local str="$1"
    local stripped=$(echo -e "$str" | sed 's/\x1b\[[0-9;]*m//g')
    # Count wide characters that display as 2 columns
    local wide_count=$(echo "$stripped" | grep -o '[📁🌳📋]' | wc -l | tr -d ' ')
    local char_len=$(echo -n "$stripped" | wc -m | tr -d ' ')
    echo $((char_len + wide_count))
}

# Build header line with model name embedded: ┌─ Claude ─────────┐
build_header_line() {
    local name="$1"
    local width="$2"
    local name_len=${#name}
    local prefix_len=$((3 + name_len + 1))  # ┌─ NAME space
    local remaining=$((width - prefix_len - 1))  # -1 for closing ┐
    [ $remaining -lt 1 ] && remaining=1
    local dashes=$(printf '%0.s─' $(seq 1 $remaining))
    echo -e "${GRAY}${BOX_TL}${BOX_H} ${RESET}${CYAN}${name}${RESET}${GRAY} ${dashes}${BOX_TR}${RESET}"
}

# Build content line with box borders: │ content          │
build_box_line() {
    local content="$1"
    local width="$2"
    local len=$(get_display_width "$content")
    local inner_width=$((width - 4))  # -2 for │ and -2 for spaces
    local padding=$((inner_width - len))
    [ $padding -lt 0 ] && padding=0
    echo -e "${GRAY}${BOX_V}${RESET} ${content}$(printf '%*s' $padding '')${GRAY} ${BOX_V}${RESET}"
}

# Build footer line: └────────────────────┘
build_footer_line() {
    local width="$1"
    local dashes=$(printf '%0.s─' $(seq 1 $((width - 2))))
    echo -e "${GRAY}${BOX_BL}${dashes}${BOX_BR}${RESET}"
}

# Output the complete status box with dynamic width
output_status() {
    local model="$1"
    local token_line="$2"
    local git_line="$3"
    local guides_line="$4"

    # Calculate widths for dynamic sizing
    local model_header_width=$((${#model} + 6))  # ┌─ NAME ─┐ minimum
    local token_width=$(($(get_display_width "$token_line") + 4))
    local git_width=0
    local guides_width=0
    [ -n "$git_line" ] && git_width=$(($(get_display_width "$git_line") + 4))
    [ -n "$guides_line" ] && guides_width=$(($(get_display_width "$guides_line") + 4))

    # Find max width (minimum 30 for aesthetics)
    local max_width=30
    [ $model_header_width -gt $max_width ] && max_width=$model_header_width
    [ $token_width -gt $max_width ] && max_width=$token_width
    [ $git_width -gt $max_width ] && max_width=$git_width
    [ $guides_width -gt $max_width ] && max_width=$guides_width

    # Output the box
    build_header_line "$model" "$max_width"
    build_box_line "$token_line" "$max_width"
    [ -n "$git_line" ] && build_box_line "$git_line" "$max_width"
    [ -n "$guides_line" ] && build_box_line "$guides_line" "$max_width"
    build_footer_line "$max_width"
    echo ""  # Blank line after box for spacing
}

INPUT=$(cat)

# Function to get active guides from session state file
# Matches the session ID calculation in guide-injector.py
get_active_guides() {
    local cwd="$1"
    local claude_pid="$PPID"  # Parent process is Claude Code

    # Calculate MD5 hash of cwd (first 12 chars) - matches Python's hashlib.md5
    local cwd_hash=$(echo -n "$cwd" | md5 | cut -c1-12 2>/dev/null || echo -n "$cwd" | md5sum | cut -c1-12)
    local session_file="/tmp/claude-workflow-${cwd_hash}-${claude_pid}.json"

    if [ -f "$session_file" ]; then
        # Read all injected guides, format as comma-separated
        local guides=$(jq -r '.injected // [] | join(", ")' "$session_file" 2>/dev/null)
        if [ -n "$guides" ] && [ "$guides" != "" ]; then
            echo "$guides"
        fi
    fi
}

# Function to abbreviate repo name (first letter of each word)
# e.g., SleepPilot -> SP, HomePi -> HP, my-cool-repo -> MCR
abbreviate_repo_name() {
    local name="$1"
    # Split on capital letters, hyphens, underscores, spaces
    # Take first letter of each part, uppercase it
    echo "$name" | sed 's/\([A-Z]\)/ \1/g; s/[-_]/ /g' | awk '{
        result=""
        for(i=1; i<=NF; i++) {
            if(length($i) > 0) {
                result = result toupper(substr($i, 1, 1))
            }
        }
        print result
    }'
}

# Function to get git info for a single repo directory
# Returns: branch|dirty|added|removed|untracked
get_repo_git_info() {
    local repo_path="$1"
    local branch added removed untracked dirty

    branch=$(cd "$repo_path" 2>/dev/null && git branch --show-current 2>/dev/null || echo "")
    if [ -z "$branch" ]; then
        echo ""
        return
    fi

    # Get staged + unstaged changes
    added=$(cd "$repo_path" && { git diff --numstat 2>/dev/null; git diff --cached --numstat 2>/dev/null; } | awk '{added+=$1} END {print added+0}')
    removed=$(cd "$repo_path" && { git diff --numstat 2>/dev/null; git diff --cached --numstat 2>/dev/null; } | awk '{removed+=$2} END {print removed+0}')
    untracked=$(cd "$repo_path" && git ls-files --others --exclude-standard 2>/dev/null | wc -l | awk '{print $1+0}')

    # Determine if dirty
    if [ "$added" -gt 0 ] || [ "$removed" -gt 0 ] || [ "$untracked" -gt 0 ]; then
        dirty="*"
    else
        dirty="✓"
    fi

    echo "${branch}|${dirty}|${added}|${removed}|${untracked}"
}

# Function to scan workspace for git repos and build display
# Sets global variables: WORKSPACE_DISPLAY, TOTAL_ADDED, TOTAL_REMOVED, TOTAL_UNTRACKED
scan_workspace_repos() {
    local workspace_path="$1"
    local repos_display=""
    TOTAL_ADDED=0
    TOTAL_REMOVED=0
    TOTAL_UNTRACKED=0
    local repo_count=0

    # Scan immediate children (including symlinks) for git repos
    for item in "$workspace_path"/*; do
        [ -e "$item" ] || continue  # Skip if doesn't exist

        # Follow symlinks and check if it's a git repo
        local real_path
        if [ -L "$item" ]; then
            real_path=$(readlink -f "$item" 2>/dev/null || readlink "$item" 2>/dev/null)
        else
            real_path="$item"
        fi

        # Skip non-directories
        [ -d "$real_path" ] || continue

        # Check if this is a git repo
        if [ -d "$real_path/.git" ] || (cd "$real_path" 2>/dev/null && git rev-parse --git-dir >/dev/null 2>&1); then
            local repo_name=$(basename "$item")
            local abbrev=$(abbreviate_repo_name "$repo_name")
            local git_info=$(get_repo_git_info "$real_path")

            if [ -n "$git_info" ]; then
                local branch=$(echo "$git_info" | cut -d'|' -f1)
                local dirty=$(echo "$git_info" | cut -d'|' -f2)
                local added=$(echo "$git_info" | cut -d'|' -f3)
                local removed=$(echo "$git_info" | cut -d'|' -f4)
                local untracked=$(echo "$git_info" | cut -d'|' -f5)

                # Aggregate totals
                TOTAL_ADDED=$((TOTAL_ADDED + added))
                TOTAL_REMOVED=$((TOTAL_REMOVED + removed))
                TOTAL_UNTRACKED=$((TOTAL_UNTRACKED + untracked))

                # Build display for this repo
                if [ -n "$repos_display" ]; then
                    repos_display="${repos_display} ${abbrev}:${branch}${dirty}"
                else
                    repos_display="${abbrev}:${branch}${dirty}"
                fi
                repo_count=$((repo_count + 1))
            fi
        fi
    done

    WORKSPACE_DISPLAY="$repos_display"
    WORKSPACE_REPO_COUNT=$repo_count
}

TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // empty')
MODEL_ID=$(echo "$INPUT" | jq -r '.model.id // ""')
MODEL_NAME=$(echo "$INPUT" | jq -r '.model.display_name // "Claude"')
CWD=$(echo "$INPUT" | jq -r '.cwd // ""')

# Determine context window based on model
# Note: [1m] suffix indicates 1M context variant for Sonnet
case "$MODEL_ID" in
    *sonnet*\[1m\]*|*sonnet*1m*)
        CONTEXT_WINDOW=1000000  # Sonnet 1M variant
        ;;
    *sonnet-4-5*|*sonnet-4*)
        CONTEXT_WINDOW=200000   # Sonnet 200k variant
        ;;
    *opus-4*|*opus-3*)
        CONTEXT_WINDOW=200000   # Opus has 200k context
        ;;
    *haiku-4*|*haiku-3*)
        CONTEXT_WINDOW=200000   # Haiku has 200k context
        ;;
    *)
        CONTEXT_WINDOW=200000   # Default to 200k for unknown models
        ;;
esac

# Check if autocompact is enabled (read from ~/.claude.json)
# Use 'if .autoCompactEnabled == false' to properly handle false values
AUTOCOMPACT_ENABLED=$(jq -r 'if .autoCompactEnabled == false then "false" else "true" end' ~/.claude.json 2>/dev/null)

# Autocompact buffer - reserved space for Claude's internal operations
AUTOCOMPACT_BUFFER=45000
USABLE_CONTEXT=$((CONTEXT_WINDOW - AUTOCOMPACT_BUFFER))

# Calculate total tokens from transcript
if [ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ]; then
    # Get the last assistant message's usage (most accurate for current context)
    LAST_USAGE=$(grep '"type":"assistant"' "$TRANSCRIPT" | tail -1 | jq -r '.message.usage // empty')

    if [ -n "$LAST_USAGE" ] && [ "$LAST_USAGE" != "null" ]; then
        INPUT_TOKENS=$(echo "$LAST_USAGE" | jq -r '.input_tokens // 0')
        CACHE_CREATE=$(echo "$LAST_USAGE" | jq -r '.cache_creation_input_tokens // 0')
        CACHE_READ=$(echo "$LAST_USAGE" | jq -r '.cache_read_input_tokens // 0')
        OUTPUT_TOKENS=$(echo "$LAST_USAGE" | jq -r '.output_tokens // 0')

        # Base tokens = input + cached tokens (actual tokens sent to model)
        BASE_TOKENS=$((INPUT_TOKENS + CACHE_CREATE + CACHE_READ))

        # Total context = base tokens (matches /context command output)
        TOTAL_TOKENS=$BASE_TOKENS

        # Calculate percentage of total context
        if [ "$CONTEXT_WINDOW" -gt 0 ]; then
            PERCENTAGE=$(awk "BEGIN {printf \"%.1f\", ($TOTAL_TOKENS / $CONTEXT_WINDOW) * 100}")
        else
            PERCENTAGE="0.0"
        fi

        # Calculate percentage remaining based on autocompact setting
        if [ "$AUTOCOMPACT_ENABLED" = "true" ]; then
            # Percentage remaining until auto-compact triggers (usable context)
            REMAINING_TOKENS=$((USABLE_CONTEXT - TOTAL_TOKENS))
            if [ "$REMAINING_TOKENS" -lt 0 ]; then
                REMAINING_TOKENS=0
            fi
            COMPACT_REMAINING=$(awk "BEGIN {printf \"%.0f\", ($REMAINING_TOKENS / $USABLE_CONTEXT) * 100}")
            COMPACT_TEXT="to compact"
            COMPACT_USE_URGENCY_COLORS="true"
        else
            # Percentage remaining until full context window
            REMAINING_TOKENS=$((CONTEXT_WINDOW - TOTAL_TOKENS))
            if [ "$REMAINING_TOKENS" -lt 0 ]; then
                REMAINING_TOKENS=0
            fi
            COMPACT_REMAINING=$(awk "BEGIN {printf \"%.0f\", ($REMAINING_TOKENS / $CONTEXT_WINDOW) * 100}")
            COMPACT_TEXT="to end"
            COMPACT_USE_URGENCY_COLORS="false"
        fi

        # Format token count (e.g., 64k or 1.2M)
        if [ "$TOTAL_TOKENS" -ge 1000000 ]; then
            TOKEN_DISPLAY=$(awk "BEGIN {printf \"%.1fM\", $TOTAL_TOKENS / 1000000}")
        elif [ "$TOTAL_TOKENS" -ge 1000 ]; then
            TOKEN_DISPLAY=$(awk "BEGIN {printf \"%.0fk\", $TOTAL_TOKENS / 1000}")
        else
            TOKEN_DISPLAY="$TOTAL_TOKENS"
        fi

        # Format context window (e.g., 200k or 1M)
        if [ "$CONTEXT_WINDOW" -ge 1000000 ]; then
            WINDOW_DISPLAY=$(awk "BEGIN {printf \"%.0fM\", $CONTEXT_WINDOW / 1000000}")
        else
            WINDOW_DISPLAY=$(awk "BEGIN {printf \"%.0fk\", $CONTEXT_WINDOW / 1000}")
        fi

        # Get git info - check for single repo or workspace
        GIT_BRANCH=$(cd "$CWD" 2>/dev/null && git branch --show-current 2>/dev/null || echo "")
        IS_WORKSPACE="false"
        ADDED=0 REMOVED=0 UNTRACKED_COUNT=0  # Initialize for non-git directories

        if [ -n "$GIT_BRANCH" ]; then
            # Single git repo
            # Check if in a worktree and get worktree name
            IS_WORKTREE=$(cd "$CWD" && git rev-parse --is-inside-work-tree 2>/dev/null && [ -f "$(git rev-parse --git-dir)/commondir" ] && echo "true" || echo "false")
            if [ "$IS_WORKTREE" = "true" ]; then
                WORKTREE_NAME=$(basename "$CWD")
                WORKTREE_SUFFIX=" 🌳 ${WORKTREE_NAME}"
            else
                WORKTREE_SUFFIX=""
            fi

            # Get git diff stats
            ADDED=$(cd "$CWD" && { git diff --numstat 2>/dev/null; git diff --cached --numstat 2>/dev/null; } | awk '{added+=$1} END {print added+0}')
            REMOVED=$(cd "$CWD" && { git diff --numstat 2>/dev/null; git diff --cached --numstat 2>/dev/null; } | awk '{removed+=$2} END {print removed+0}')
            UNTRACKED_COUNT=$(cd "$CWD" && git ls-files --others --exclude-standard 2>/dev/null | wc -l | awk '{print $1+0}')

            # Determine dirty status
            if [ "$ADDED" -gt 0 ] || [ "$REMOVED" -gt 0 ] || [ "$UNTRACKED_COUNT" -gt 0 ]; then
                DIRTY_INDICATOR="*"
            else
                DIRTY_INDICATOR="✓"
            fi
        else
            # Not a git repo - check if it's a workspace with git repos
            scan_workspace_repos "$CWD"
            if [ "$WORKSPACE_REPO_COUNT" -gt 0 ]; then
                IS_WORKSPACE="true"
                ADDED=$TOTAL_ADDED
                REMOVED=$TOTAL_REMOVED
                UNTRACKED_COUNT=$TOTAL_UNTRACKED
            fi
            WORKTREE_SUFFIX=""
        fi

        # Choose token color based on percentage thresholds
        PERCENT_INT=$(echo "$PERCENTAGE" | awk '{printf "%d", $1}')
        if [ "$PERCENT_INT" -ge 80 ]; then
            TOKEN_COLOR="$RED"
        elif [ "$PERCENT_INT" -ge 50 ]; then
            TOKEN_COLOR="$YELLOW"
        else
            TOKEN_COLOR="$GREEN"
        fi

        # Choose compact indicator color (static based on mode)
        if [ "$COMPACT_USE_URGENCY_COLORS" = "true" ]; then
            COMPACT_COLOR="$MAGENTA"
        else
            COMPACT_COLOR="$CYAN"
        fi

        # Build diff display (used for both single repo and workspace)
        if [ "$UNTRACKED_COUNT" -gt 0 ]; then
            DIFF_DISPLAY="(+${ADDED},-${REMOVED}, ${UNTRACKED_COUNT} new)"
        else
            DIFF_DISPLAY="(+${ADDED},-${REMOVED})"
        fi

        # Format git info based on single repo vs workspace (without └─ prefix for box layout)
        if [ "$IS_WORKSPACE" = "true" ]; then
            GIT_SHORT="${BLUE}📁 ${WORKSPACE_DISPLAY}${RESET} ${WHITE}${DIFF_DISPLAY}${RESET}"
        elif [ -n "$GIT_BRANCH" ]; then
            GIT_SHORT="${BLUE}⎇ ${GIT_BRANCH}${DIRTY_INDICATOR}${WORKTREE_SUFFIX}${RESET} ${WHITE}${DIFF_DISPLAY}${RESET}"
        else
            GIT_SHORT=""
        fi

        # Get active guides from session state
        ACTIVE_GUIDES=$(get_active_guides "$CWD")
        if [ -n "$ACTIVE_GUIDES" ]; then
            GUIDES_SHORT="${MAGENTA}📋 ${ACTIVE_GUIDES}${RESET}"
        else
            GUIDES_SHORT=""
        fi

        # Build token line
        TOKEN_LINE="${TOKEN_COLOR}${TOKEN_DISPLAY}/${WINDOW_DISPLAY} (${PERCENTAGE}%)${RESET}${GRAY} • ${RESET}${COMPACT_COLOR}${COMPACT_REMAINING}% ${COMPACT_TEXT}${RESET}"

        # Output with box layout (3 separate lines: tokens, git, guides)
        output_status "$MODEL_NAME" "$TOKEN_LINE" "$GIT_SHORT" "$GUIDES_SHORT"
    else
        # No assistant messages yet - show base overhead
        # System prompt (~3k) + System tools (~14.5k) + Memory files (~1k)
        BASE_OVERHEAD=18500
        TOTAL_TOKENS=$BASE_OVERHEAD
        PERCENTAGE=$(awk "BEGIN {printf \"%.1f\", ($TOTAL_TOKENS / $CONTEXT_WINDOW) * 100}")

        # Calculate compact countdown based on autocompact setting
        if [ "$AUTOCOMPACT_ENABLED" = "true" ]; then
            REMAINING_TOKENS=$((USABLE_CONTEXT - TOTAL_TOKENS))
            COMPACT_REMAINING=$(awk "BEGIN {printf \"%.0f\", ($REMAINING_TOKENS / $USABLE_CONTEXT) * 100}")
            COMPACT_TEXT="to compact"
            COMPACT_USE_URGENCY_COLORS="true"
        else
            REMAINING_TOKENS=$((CONTEXT_WINDOW - TOTAL_TOKENS))
            COMPACT_REMAINING=$(awk "BEGIN {printf \"%.0f\", ($REMAINING_TOKENS / $CONTEXT_WINDOW) * 100}")
            COMPACT_TEXT="to end"
            COMPACT_USE_URGENCY_COLORS="false"
        fi
        if [ "$TOTAL_TOKENS" -ge 1000000 ]; then
            TOKEN_DISPLAY=$(awk "BEGIN {printf \"%.1fM\", $TOTAL_TOKENS / 1000000}")
        else
            TOKEN_DISPLAY=$(awk "BEGIN {printf \"%.0fk\", $TOTAL_TOKENS / 1000}")
        fi
        if [ "$CONTEXT_WINDOW" -ge 1000000 ]; then
            WINDOW_DISPLAY=$(awk "BEGIN {printf \"%.0fM\", $CONTEXT_WINDOW / 1000000}")
        else
            WINDOW_DISPLAY=$(awk "BEGIN {printf \"%.0fk\", $CONTEXT_WINDOW / 1000}")
        fi

        # Get git info - check for single repo or workspace
        GIT_BRANCH=$(cd "$CWD" 2>/dev/null && git branch --show-current 2>/dev/null || echo "")
        IS_WORKSPACE="false"
        ADDED=0 REMOVED=0 UNTRACKED_COUNT=0  # Initialize for non-git directories

        if [ -n "$GIT_BRANCH" ]; then
            # Single git repo
            IS_WORKTREE=$(cd "$CWD" && git rev-parse --is-inside-work-tree 2>/dev/null && [ -f "$(git rev-parse --git-dir)/commondir" ] && echo "true" || echo "false")
            if [ "$IS_WORKTREE" = "true" ]; then
                WORKTREE_NAME=$(basename "$CWD")
                WORKTREE_SUFFIX=" 🌳 ${WORKTREE_NAME}"
            else
                WORKTREE_SUFFIX=""
            fi

            ADDED=$(cd "$CWD" && { git diff --numstat 2>/dev/null; git diff --cached --numstat 2>/dev/null; } | awk '{added+=$1} END {print added+0}')
            REMOVED=$(cd "$CWD" && { git diff --numstat 2>/dev/null; git diff --cached --numstat 2>/dev/null; } | awk '{removed+=$2} END {print removed+0}')
            UNTRACKED_COUNT=$(cd "$CWD" && git ls-files --others --exclude-standard 2>/dev/null | wc -l | awk '{print $1+0}')

            if [ "$ADDED" -gt 0 ] || [ "$REMOVED" -gt 0 ] || [ "$UNTRACKED_COUNT" -gt 0 ]; then
                DIRTY_INDICATOR="*"
            else
                DIRTY_INDICATOR="✓"
            fi
        else
            scan_workspace_repos "$CWD"
            if [ "$WORKSPACE_REPO_COUNT" -gt 0 ]; then
                IS_WORKSPACE="true"
                ADDED=$TOTAL_ADDED
                REMOVED=$TOTAL_REMOVED
                UNTRACKED_COUNT=$TOTAL_UNTRACKED
            fi
            WORKTREE_SUFFIX=""
        fi

        PERCENT_INT=$(echo "$PERCENTAGE" | awk '{printf "%d", $1}')
        if [ "$PERCENT_INT" -ge 80 ]; then
            TOKEN_COLOR="$RED"
        elif [ "$PERCENT_INT" -ge 50 ]; then
            TOKEN_COLOR="$YELLOW"
        else
            TOKEN_COLOR="$GREEN"
        fi

        if [ "$COMPACT_USE_URGENCY_COLORS" = "true" ]; then
            COMPACT_COLOR="$MAGENTA"
        else
            COMPACT_COLOR="$CYAN"
        fi

        # Build diff display
        if [ "$UNTRACKED_COUNT" -gt 0 ]; then
            DIFF_DISPLAY="(+${ADDED},-${REMOVED}, ${UNTRACKED_COUNT} new)"
        else
            DIFF_DISPLAY="(+${ADDED},-${REMOVED})"
        fi

        # Format git info based on single repo vs workspace (without └─ prefix for box layout)
        if [ "$IS_WORKSPACE" = "true" ]; then
            GIT_SHORT="${BLUE}📁 ${WORKSPACE_DISPLAY}${RESET} ${WHITE}${DIFF_DISPLAY}${RESET}"
        elif [ -n "$GIT_BRANCH" ]; then
            GIT_SHORT="${BLUE}⎇ ${GIT_BRANCH}${DIRTY_INDICATOR}${WORKTREE_SUFFIX}${RESET} ${WHITE}${DIFF_DISPLAY}${RESET}"
        else
            GIT_SHORT=""
        fi

        # Get active guides from session state
        ACTIVE_GUIDES=$(get_active_guides "$CWD")
        if [ -n "$ACTIVE_GUIDES" ]; then
            GUIDES_SHORT="${MAGENTA}📋 ${ACTIVE_GUIDES}${RESET}"
        else
            GUIDES_SHORT=""
        fi

        # Build token line
        TOKEN_LINE="${TOKEN_COLOR}${TOKEN_DISPLAY}/${WINDOW_DISPLAY} (${PERCENTAGE}%)${RESET}${GRAY} • ${RESET}${COMPACT_COLOR}${COMPACT_REMAINING}% ${COMPACT_TEXT}${RESET}"

        # Output with box layout (3 separate lines: tokens, git, guides)
        output_status "$MODEL_NAME" "$TOKEN_LINE" "$GIT_SHORT" "$GUIDES_SHORT"
    fi
else
    # Fallback if transcript not available - show base overhead
    BASE_OVERHEAD=18500
    TOTAL_TOKENS=$BASE_OVERHEAD
    PERCENTAGE=$(awk "BEGIN {printf \"%.1f\", ($TOTAL_TOKENS / $CONTEXT_WINDOW) * 100}")

    # Calculate compact countdown based on autocompact setting
    if [ "$AUTOCOMPACT_ENABLED" = "true" ]; then
        REMAINING_TOKENS=$((USABLE_CONTEXT - TOTAL_TOKENS))
        COMPACT_REMAINING=$(awk "BEGIN {printf \"%.0f\", ($REMAINING_TOKENS / $USABLE_CONTEXT) * 100}")
        COMPACT_TEXT="to compact"
        COMPACT_USE_URGENCY_COLORS="true"
    else
        REMAINING_TOKENS=$((CONTEXT_WINDOW - TOTAL_TOKENS))
        COMPACT_REMAINING=$(awk "BEGIN {printf \"%.0f\", ($REMAINING_TOKENS / $CONTEXT_WINDOW) * 100}")
        COMPACT_TEXT="to end"
        COMPACT_USE_URGENCY_COLORS="false"
    fi

    if [ "$TOTAL_TOKENS" -ge 1000000 ]; then
        TOKEN_DISPLAY=$(awk "BEGIN {printf \"%.1fM\", $TOTAL_TOKENS / 1000000}")
    else
        TOKEN_DISPLAY=$(awk "BEGIN {printf \"%.0fk\", $TOTAL_TOKENS / 1000}")
    fi
    if [ "$CONTEXT_WINDOW" -ge 1000000 ]; then
        WINDOW_DISPLAY=$(awk "BEGIN {printf \"%.0fM\", $CONTEXT_WINDOW / 1000000}")
    else
        WINDOW_DISPLAY=$(awk "BEGIN {printf \"%.0fk\", $CONTEXT_WINDOW / 1000}")
    fi

    # Get git info - check for single repo or workspace
    GIT_BRANCH=$(cd "$CWD" 2>/dev/null && git branch --show-current 2>/dev/null || echo "")
    IS_WORKSPACE="false"
    ADDED=0 REMOVED=0 UNTRACKED_COUNT=0  # Initialize for non-git directories

    if [ -n "$GIT_BRANCH" ]; then
        # Single git repo
        IS_WORKTREE=$(cd "$CWD" && git rev-parse --is-inside-work-tree 2>/dev/null && [ -f "$(git rev-parse --git-dir)/commondir" ] && echo "true" || echo "false")
        if [ "$IS_WORKTREE" = "true" ]; then
            WORKTREE_NAME=$(basename "$CWD")
            WORKTREE_SUFFIX=" 🌳 ${WORKTREE_NAME}"
        else
            WORKTREE_SUFFIX=""
        fi

        ADDED=$(cd "$CWD" && { git diff --numstat 2>/dev/null; git diff --cached --numstat 2>/dev/null; } | awk '{added+=$1} END {print added+0}')
        REMOVED=$(cd "$CWD" && { git diff --numstat 2>/dev/null; git diff --cached --numstat 2>/dev/null; } | awk '{removed+=$2} END {print removed+0}')
        UNTRACKED_COUNT=$(cd "$CWD" && git ls-files --others --exclude-standard 2>/dev/null | wc -l | awk '{print $1+0}')

        if [ "$ADDED" -gt 0 ] || [ "$REMOVED" -gt 0 ] || [ "$UNTRACKED_COUNT" -gt 0 ]; then
            DIRTY_INDICATOR="*"
        else
            DIRTY_INDICATOR="✓"
        fi
    else
        scan_workspace_repos "$CWD"
        if [ "$WORKSPACE_REPO_COUNT" -gt 0 ]; then
            IS_WORKSPACE="true"
            ADDED=$TOTAL_ADDED
            REMOVED=$TOTAL_REMOVED
            UNTRACKED_COUNT=$TOTAL_UNTRACKED
        fi
        WORKTREE_SUFFIX=""
    fi

    PERCENT_INT=$(echo "$PERCENTAGE" | awk '{printf "%d", $1}')
    if [ "$PERCENT_INT" -ge 80 ]; then
        TOKEN_COLOR="$RED"
    elif [ "$PERCENT_INT" -ge 50 ]; then
        TOKEN_COLOR="$YELLOW"
    else
        TOKEN_COLOR="$GREEN"
    fi

    if [ "$COMPACT_USE_URGENCY_COLORS" = "true" ]; then
        COMPACT_COLOR="$MAGENTA"
    else
        COMPACT_COLOR="$CYAN"
    fi

    # Build diff display
    if [ "$UNTRACKED_COUNT" -gt 0 ]; then
        DIFF_DISPLAY="(+${ADDED},-${REMOVED}, ${UNTRACKED_COUNT} new)"
    else
        DIFF_DISPLAY="(+${ADDED},-${REMOVED})"
    fi

    # Format git info based on single repo vs workspace (without └─ prefix for box layout)
    if [ "$IS_WORKSPACE" = "true" ]; then
        GIT_SHORT="${BLUE}📁 ${WORKSPACE_DISPLAY}${RESET} ${WHITE}${DIFF_DISPLAY}${RESET}"
    elif [ -n "$GIT_BRANCH" ]; then
        GIT_SHORT="${BLUE}⎇ ${GIT_BRANCH}${DIRTY_INDICATOR}${WORKTREE_SUFFIX}${RESET} ${WHITE}${DIFF_DISPLAY}${RESET}"
    else
        GIT_SHORT=""
    fi

    # Get active guides from session state
    ACTIVE_GUIDES=$(get_active_guides "$CWD")
    if [ -n "$ACTIVE_GUIDES" ]; then
        GUIDES_SHORT="${MAGENTA}📋 ${ACTIVE_GUIDES}${RESET}"
    else
        GUIDES_SHORT=""
    fi

    # Build token line
    TOKEN_LINE="${TOKEN_COLOR}${TOKEN_DISPLAY}/${WINDOW_DISPLAY} (${PERCENTAGE}%)${RESET}${GRAY} • ${RESET}${COMPACT_COLOR}${COMPACT_REMAINING}% ${COMPACT_TEXT}${RESET}"

    # Output with box layout (3 separate lines: tokens, git, guides)
    output_status "$MODEL_NAME" "$TOKEN_LINE" "$GIT_SHORT" "$GUIDES_SHORT"
fi
