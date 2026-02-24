#!/bin/bash
# Compact status: Model|64k 45%|main✓

INPUT=$(cat)

# Colors - muted 256-color palette (avoids Claude Code UI colors)
readonly MODEL_COLOR='\033[38;5;146m'  # Lavender - soft purple-gray
readonly FOLDER_COLOR='\033[38;5;109m' # Slate teal - muted cyan-gray
readonly GIT_COLOR='\033[38;5;67m'     # Steel blue - muted blue-gray
readonly SEP_COLOR='\033[38;5;244m'    # Medium gray - subtle separator
readonly TOKEN_LOW='\033[38;5;108m'    # Sage - muted green
readonly TOKEN_MED='\033[38;5;179m'    # Gold - muted yellow
readonly TOKEN_HIGH='\033[38;5;167m'   # Terracotta - muted red
readonly RESET='\033[0m'

# Clean up stale session files (PIDs that no longer exist)
cleanup_stale_sessions() {
    for f in /tmp/claude-session-cwd-* /tmp/claude-session-tokens-*; do
        [ -f "${f}" ] || continue
        pid="${f##*-}"
        ps -p "${pid}" > /dev/null 2>&1 || rm -f "${f}"
    done
}

# Workspaces path for multi-repo workspace detection
WORKSPACES_PATH="${HOME}/Developer/1. Workspaces"

# Get the main repository name from a worktree
get_worktree_repo_name() {
    local worktree_path="$1"
    local gitdir_line
    gitdir_line=$(cat "${worktree_path}/.git" 2> /dev/null)
    # Extract path: "gitdir: /path/to/repo/.git/worktrees/name" -> "/path/to/repo"
    local repo_path
    repo_path="${gitdir_line#gitdir: }"
    repo_path="${repo_path%%/.git/worktrees/*}"
    basename "${repo_path}"
}

# Abbreviate branch: main/master→M, develop→D, staging→S, else→F
abbreviate_branch() {
    case "$1" in
        main | master) echo "M" ;;
        develop) echo "D" ;;
        staging) echo "S" ;;
        *) echo "F" ;;
    esac
}

# Get dirty marker for a repo path
get_dirty_marker() {
    # shellcheck disable=SC2312
    [ -n "$(git -C "$1" status --porcelain 2> /dev/null)" ] && echo "*" || echo "✓"
}

# Get git info for a repo
get_repo_git_info() {
    local repo_path="$1"
    local branch
    branch=$(git -C "${repo_path}" branch --show-current 2> /dev/null)
    [ -z "${branch}" ] && return
    # shellcheck disable=SC2312
    echo "${branch}|$(get_dirty_marker "${repo_path}")"
}

# Scan workspace for git repos
scan_workspace_repos() {
    local workspace_path="$1"
    WORKSPACE_DISPLAY="" WORKSPACE_REPO_COUNT=0
    for item in "${workspace_path}"/*; do
        [ -e "${item}" ] || continue
        local real_path="${item}"
        [ -L "${item}" ] && real_path=$(readlink -f "${item}" 2> /dev/null || readlink "${item}" 2> /dev/null)
        [ -d "${real_path}" ] || continue
        if [ -d "${real_path}/.git" ] || [ -f "${real_path}/.git" ]; then
            local git_info
            git_info=$(get_repo_git_info "${real_path}")
            if [ -n "${git_info}" ]; then
                # For worktrees, use the actual repo name and [wt] icon; otherwise use folder name
                local repo_name icon
                if [ -f "${real_path}/.git" ]; then
                    repo_name=$(get_worktree_repo_name "${real_path}")
                    icon="[wt]"
                else
                    repo_name=$(basename "${item}")
                    icon=""
                fi
                local branch
                branch=$(abbreviate_branch "${git_info%%|*}")
                local dirty="${git_info##*|}"
                [ -n "${WORKSPACE_DISPLAY}" ] && WORKSPACE_DISPLAY="${WORKSPACE_DISPLAY} "
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
    if [[ "${name}" == *"Opus"* ]]; then
        echo "Opus"
    elif [[ "${name}" == *"Sonnet"* ]]; then
        echo "Sonnet"
    elif [[ "${name}" == *"Haiku"* ]]; then
        echo "Haiku"
    else
        echo "${name}" | awk '{print $NF}'
    fi
}

# Format tokens (64k, 1.2M, etc.)
format_tokens() {
    local tokens="$1"
    if [ "${tokens}" -ge 1000000 ]; then
        awk "BEGIN {printf \"%.1fM\", ${tokens} / 1000000}"
    elif [ "${tokens}" -ge 1000 ]; then
        awk "BEGIN {printf \"%.0fk\", ${tokens} / 1000}"
    else
        echo "${tokens}"
    fi
}

# Get token color based on percentage
get_token_color() {
    local percent="$1"
    if [ "${percent}" -lt 50 ]; then
        echo "${TOKEN_LOW}"
    elif [ "${percent}" -lt 80 ]; then
        echo "${TOKEN_MED}"
    else
        echo "${TOKEN_HIGH}"
    fi
}

# === Extract data (single jq call) ===
# shellcheck disable=SC2312
IFS=$'\t' read -r MODEL_NAME CWD CONTEXT_SIZE INPUT_TOKENS CACHE_CREATE CACHE_READ < <(
    echo "${INPUT}" | jq -r '[
        .model.display_name // "Claude",
        .cwd // "",
        .context_window.context_window_size // 0,
        (.context_window.current_usage.input_tokens // 0),
        (.context_window.current_usage.cache_creation_input_tokens // 0),
        (.context_window.current_usage.cache_read_input_tokens // 0)
    ] | @tsv'
)

# === Token data caching - prevent flashing during permission transitions ===
TOKEN_CACHE_FILE="/tmp/claude-session-tokens-${PPID}"
if [ "${CONTEXT_SIZE}" -gt 0 ]; then
    # Valid data - cache atomically
    TOKEN_TEMP="${TOKEN_CACHE_FILE}.$$"
    if printf '%s\t%s\t%s\t%s' "${CONTEXT_SIZE}" "${INPUT_TOKENS}" "${CACHE_CREATE}" "${CACHE_READ}" > "${TOKEN_TEMP}" 2> /dev/null; then
        mv "${TOKEN_TEMP}" "${TOKEN_CACHE_FILE}" 2> /dev/null || rm -f "${TOKEN_TEMP}"
    fi
else
    # Invalid data - restore from cache
    if [ -f "${TOKEN_CACHE_FILE}" ]; then
        IFS=$'\t' read -r CONTEXT_SIZE INPUT_TOKENS CACHE_CREATE CACHE_READ < "${TOKEN_CACHE_FILE}"
    fi
fi

# === Session path persistence - always show initial session path ===
cleanup_stale_sessions
SESSION_FILE="/tmp/claude-session-cwd-${PPID}"
if [ ! -f "${SESSION_FILE}" ]; then
    # First invocation - save initial CWD atomically
    TEMP_FILE="${SESSION_FILE}.$$"
    if echo "${CWD}" > "${TEMP_FILE}" 2> /dev/null; then
        mv "${TEMP_FILE}" "${SESSION_FILE}" 2> /dev/null || rm -f "${TEMP_FILE}"
    fi
    INITIAL_CWD="${CWD}"
else
    # Subsequent invocations - use saved path, fallback to CWD if invalid
    INITIAL_CWD=$(cat "${SESSION_FILE}" 2> /dev/null)
    [ ! -d "${INITIAL_CWD}" ] && INITIAL_CWD="${CWD}"
fi

# === Model ===
MODEL_ABBREV=$(abbreviate_model "${MODEL_NAME}")

# === Directory ===
# For worktrees, show the main repo name instead of the worktree folder name
# Use INITIAL_CWD so folder name always shows where session was opened
if [ -f "${INITIAL_CWD}/.git" ]; then
    DIR_NAME=$(get_worktree_repo_name "${INITIAL_CWD}")
else
    DIR_NAME=$(basename "${INITIAL_CWD}")
fi

# === Git info ===
GIT_BRANCH=$(git -C "${CWD}" branch --show-current 2> /dev/null || echo "")
GIT_PART=""

if [ -n "${GIT_BRANCH}" ]; then
    DIRTY=$(get_dirty_marker "${CWD}")

    # Check if in a worktree (.git is a file in worktrees, directory in main repos)
    if [ -f "${CWD}/.git" ]; then
        # Worktree: always show [wt] name:branch✓
        WORKTREE_NAME=$(basename "${CWD}")
        GIT_PART="${GIT_COLOR}[wt] ${WORKTREE_NAME}:$(abbreviate_branch "${GIT_BRANCH}")${DIRTY}${RESET}"
    else
        # Regular git repo - show repo:branch✓
        REPO_ROOT=$(git -C "${CWD}" rev-parse --show-toplevel 2> /dev/null)
        REPO_NAME=$(basename "${REPO_ROOT}")
        GIT_PART="${GIT_COLOR}${REPO_NAME}:$(abbreviate_branch "${GIT_BRANCH}")${DIRTY}${RESET}"
    fi
else
    # Only scan for workspace repos if under the Workspaces folder
    if [[ "${CWD}" == "${WORKSPACES_PATH}"* ]]; then
        scan_workspace_repos "${CWD}"
        # Workspace with multiple repos - show [ws] prefix
        [ "${WORKSPACE_REPO_COUNT}" -gt 0 ] && GIT_PART="${GIT_COLOR}[ws] ${WORKSPACE_DISPLAY}${RESET}"
    fi
fi

# === Context Window ===
CONTEXT_PART=""
if [ "${CONTEXT_SIZE}" -gt 0 ]; then
    TOTAL_TOKENS=$((INPUT_TOKENS + CACHE_CREATE + CACHE_READ))
    TOKEN_DISPLAY=$(format_tokens "${TOTAL_TOKENS}")
    PERCENT_INT=$(awk "BEGIN {printf \"%02.0f\", (${TOTAL_TOKENS} / ${CONTEXT_SIZE}) * 100}")
    TOKEN_COLOR=$(get_token_color "${PERCENT_INT}")
    WINDOW_DISPLAY=$(format_tokens "${CONTEXT_SIZE}")
    CONTEXT_PART="${TOKEN_COLOR}${TOKEN_DISPLAY}/${WINDOW_DISPLAY} · ${PERCENT_INT}%${RESET}"
fi

# === Output ===
SEP="${SEP_COLOR} | ${RESET}"

# Server prefix (shown when running over SSH)
SERVER_PREFIX=""
if [ -n "${SSH_CONNECTION}" ]; then
    SERVER_PREFIX="\033[1;38;5;167mremote${RESET}${SEP}"
else
    SERVER_PREFIX="\033[1;38;5;108mlocal${RESET}${SEP}"
fi

OUTPUT="${SERVER_PREFIX}${MODEL_COLOR}${MODEL_ABBREV}${RESET}"
[ -n "${CONTEXT_PART}" ] && OUTPUT="${OUTPUT}${SEP}${CONTEXT_PART}"
[ -n "${DIR_NAME}" ] && OUTPUT="${OUTPUT}${SEP}${FOLDER_COLOR}${DIR_NAME}${RESET}"
[ -n "${GIT_PART}" ] && OUTPUT="${OUTPUT}${SEP}${GIT_PART}"

echo -e "${OUTPUT}"
