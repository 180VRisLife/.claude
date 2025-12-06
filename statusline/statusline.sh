#!/bin/bash
# Custom status line that shows accurate total context usage
# Matches /context command output (tokens used, without autocompact buffer)
# Shows "X% to compact" (green/yellow/red) when autocompact on, "X% to end" (cyan) when off

INPUT=$(cat)
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

        # Get git info
        GIT_BRANCH=$(cd "$CWD" 2>/dev/null && git branch --show-current 2>/dev/null || echo "")
        if [ -n "$GIT_BRANCH" ]; then
            # Check if in a worktree and get worktree name
            IS_WORKTREE=$(cd "$CWD" && git rev-parse --is-inside-work-tree 2>/dev/null && [ -f "$(git rev-parse --git-dir)/commondir" ] && echo "true" || echo "false")
            if [ "$IS_WORKTREE" = "true" ]; then
                WORKTREE_NAME=$(basename "$CWD")
                WORKTREE_SUFFIX=" 🌳 ${WORKTREE_NAME}"
            else
                WORKTREE_SUFFIX=""
            fi

            # Get git diff stats
            # Get staged + unstaged changes to tracked files
            ADDED=$(cd "$CWD" && { git diff --numstat 2>/dev/null; git diff --cached --numstat 2>/dev/null; } | awk '{added+=$1} END {print added+0}')
            REMOVED=$(cd "$CWD" && { git diff --numstat 2>/dev/null; git diff --cached --numstat 2>/dev/null; } | awk '{removed+=$2} END {print removed+0}')

            # Count untracked files
            UNTRACKED_COUNT=$(cd "$CWD" && git ls-files --others --exclude-standard 2>/dev/null | wc -l | awk '{print $1+0}')
        else
            WORKTREE_SUFFIX=""
        fi

        # Get shortened directory path
        DIR_NAME=$(basename "$CWD")

        # Colors (ANSI escape codes)
        # Token status colors (reserved): GREEN (<50%), YELLOW (50-80%), RED (>80%)
        CYAN='\033[36m'
        YELLOW='\033[33m'
        GREEN='\033[32m'
        RED='\033[31m'
        BLUE='\033[34m'
        MAGENTA='\033[35m'
        WHITE='\033[37m'
        GRAY='\033[90m'
        RESET='\033[0m'

        # Choose token color based on percentage thresholds
        # Green: <50%, Yellow: 50-80%, Red: >80%
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
            # Magenta for autocompact mode
            COMPACT_COLOR="$MAGENTA"
        else
            # Cyan for manual mode (autocompact off)
            COMPACT_COLOR="$CYAN"
        fi

        # Format git info with separate colors
        if [ -n "$GIT_BRANCH" ]; then
            # Build diff display
            if [ "$UNTRACKED_COUNT" -gt 0 ]; then
                DIFF_DISPLAY="(+${ADDED},-${REMOVED}, ${UNTRACKED_COUNT} new)"
            else
                DIFF_DISPLAY="(+${ADDED},-${REMOVED})"
            fi
            GIT_DISPLAY="${GRAY} | ${RESET}${BLUE}⎇ ${GIT_BRANCH}${WORKTREE_SUFFIX}${RESET}${GRAY} | ${RESET}${WHITE}${DIFF_DISPLAY}${RESET}"
        else
            GIT_DISPLAY=""
        fi

        # Output status line with colors (includes compact countdown)
        echo -e "${CYAN}${MODEL_NAME}${RESET}${GRAY} | ${RESET}${TOKEN_COLOR}${TOKEN_DISPLAY}/${WINDOW_DISPLAY} (${PERCENTAGE}%)${RESET}${GRAY} - ${RESET}${COMPACT_COLOR}${COMPACT_REMAINING}% ${COMPACT_TEXT}${RESET}${GIT_DISPLAY}${GRAY} | ${RESET}${MAGENTA}${DIR_NAME}${RESET}"
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

        # Get git info
        GIT_BRANCH=$(cd "$CWD" 2>/dev/null && git branch --show-current 2>/dev/null || echo "")
        if [ -n "$GIT_BRANCH" ]; then
            # Check if in a worktree and get worktree name
            IS_WORKTREE=$(cd "$CWD" && git rev-parse --is-inside-work-tree 2>/dev/null && [ -f "$(git rev-parse --git-dir)/commondir" ] && echo "true" || echo "false")
            if [ "$IS_WORKTREE" = "true" ]; then
                WORKTREE_NAME=$(basename "$CWD")
                WORKTREE_SUFFIX=" 🌳 ${WORKTREE_NAME}"
            else
                WORKTREE_SUFFIX=""
            fi

            # Get staged + unstaged changes to tracked files
            ADDED=$(cd "$CWD" && { git diff --numstat 2>/dev/null; git diff --cached --numstat 2>/dev/null; } | awk '{added+=$1} END {print added+0}')
            REMOVED=$(cd "$CWD" && { git diff --numstat 2>/dev/null; git diff --cached --numstat 2>/dev/null; } | awk '{removed+=$2} END {print removed+0}')

            # Count untracked files
            UNTRACKED_COUNT=$(cd "$CWD" && git ls-files --others --exclude-standard 2>/dev/null | wc -l | awk '{print $1+0}')
        else
            WORKTREE_SUFFIX=""
        fi

        # Get shortened directory path
        DIR_NAME=$(basename "$CWD")

        # Colors (ANSI escape codes)
        # Token status colors (reserved): GREEN (<50%), YELLOW (50-80%), RED (>80%)
        CYAN='\033[36m'
        YELLOW='\033[33m'
        GREEN='\033[32m'
        RED='\033[31m'
        BLUE='\033[34m'
        MAGENTA='\033[35m'
        WHITE='\033[37m'
        GRAY='\033[90m'
        RESET='\033[0m'

        # Choose token color based on percentage thresholds
        # Green: <50%, Yellow: 50-80%, Red: >80%
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

        # Format git info with separate colors
        if [ -n "$GIT_BRANCH" ]; then
            # Build diff display
            if [ "$UNTRACKED_COUNT" -gt 0 ]; then
                DIFF_DISPLAY="(+${ADDED},-${REMOVED}, ${UNTRACKED_COUNT} new)"
            else
                DIFF_DISPLAY="(+${ADDED},-${REMOVED})"
            fi
            GIT_DISPLAY="${GRAY} | ${RESET}${BLUE}⎇ ${GIT_BRANCH}${WORKTREE_SUFFIX}${RESET}${GRAY} | ${RESET}${WHITE}${DIFF_DISPLAY}${RESET}"
        else
            GIT_DISPLAY=""
        fi

        echo -e "${CYAN}${MODEL_NAME}${RESET}${GRAY} | ${RESET}${TOKEN_COLOR}${TOKEN_DISPLAY}/${WINDOW_DISPLAY} (${PERCENTAGE}%)${RESET}${GRAY} - ${RESET}${COMPACT_COLOR}${COMPACT_REMAINING}% ${COMPACT_TEXT}${RESET}${GIT_DISPLAY}${GRAY} | ${RESET}${MAGENTA}${DIR_NAME}${RESET}"
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

    # Get git info
    GIT_BRANCH=$(cd "$CWD" 2>/dev/null && git branch --show-current 2>/dev/null || echo "")
    if [ -n "$GIT_BRANCH" ]; then
        # Check if in a worktree
        IS_WORKTREE=$(cd "$CWD" && git rev-parse --is-inside-work-tree 2>/dev/null && [ -f "$(git rev-parse --git-dir)/commondir" ] && echo "true" || echo "false")
        if [ "$IS_WORKTREE" = "true" ]; then
            WORKTREE_INDICATOR="🌳 "
        else
            WORKTREE_INDICATOR=""
        fi

        ADDED=$(cd "$CWD" && git diff --numstat 2>/dev/null | awk '{added+=$1} END {print added+0}')
        REMOVED=$(cd "$CWD" && git diff --numstat 2>/dev/null | awk '{removed+=$2} END {print removed+0}')
        GIT_INFO=" | ${WORKTREE_INDICATOR}⎇ $GIT_BRANCH | (+$ADDED,-$REMOVED)"
    else
        GIT_INFO=""
    fi

    # Get shortened directory path
    DIR_NAME=$(basename "$CWD")

    # Colors (ANSI escape codes)
    # Token status colors (reserved): GREEN (<50%), YELLOW (50-80%), RED (>80%)
    CYAN='\033[36m'
    YELLOW='\033[33m'
    GREEN='\033[32m'
    RED='\033[31m'
    BLUE='\033[34m'
    MAGENTA='\033[35m'
    WHITE='\033[37m'
    GRAY='\033[90m'
    RESET='\033[0m'

    # Choose token color based on percentage thresholds
    # Green: <50%, Yellow: 50-80%, Red: >80%
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

    # Format git info with separate colors
    if [ -n "$GIT_BRANCH" ]; then
        GIT_DISPLAY="${GRAY} | ${RESET}${WORKTREE_INDICATOR}${BLUE}⎇ ${GIT_BRANCH}${RESET}${GRAY} | ${RESET}${WHITE}(+${ADDED},-${REMOVED})${RESET}"
    else
        GIT_DISPLAY=""
    fi

    echo -e "${CYAN}${MODEL_NAME}${RESET}${GRAY} | ${RESET}${TOKEN_COLOR}${TOKEN_DISPLAY}/${WINDOW_DISPLAY} (${PERCENTAGE}%)${RESET}${GRAY} - ${RESET}${COMPACT_COLOR}${COMPACT_REMAINING}% ${COMPACT_TEXT}${RESET}${GIT_DISPLAY}${GRAY} | ${RESET}${MAGENTA}${DIR_NAME}${RESET}"
fi
