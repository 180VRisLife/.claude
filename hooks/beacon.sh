#!/usr/bin/env bash
# beacon.sh - Phone notification via ntfy with Termius deep link
# Mode: auto = notify only when user is away, on = always, off = never
#
# === DEEP LINK STRATEGY (ba command) ===
#
# How it works:
#   1. beacon.sh writes a per-session helper script to ~/.beacon/scripts/
#      with metadata comment: # beacon: session | project | type
#   2. ntfy "Click" action uses ssh://user@host (Termius handles this)
#   3. User taps notification → Termius opens → connects to saved host
#   4. User types 'ba' → scans ~/.beacon/scripts/ → auto-attaches or shows menu
#   5. Helper script cd's to project, attaches tmux, self-destructs
#
# No Termius Pro or startup snippets required.
# ===

set -euo pipefail

MODE_FILE="${HOME}/.beacon/mode"
ENV_FILE="${HOME}/.claude/hooks/.env"
DEDUP_DIR="${HOME}/.beacon/dedup"

# --- Read stdin early (needed for dedup) ---
INPUT=$(cat)
NOTIFICATION_TYPE=$(echo "${INPUT}" | jq -r '.notification_type // empty')
claude_session_id=$(echo "${INPUT}" | jq -r '.session_id // empty')

# --- Session identity (for per-session dedup) ---
tmux_session=$(tmux display-message -p '#{session_name}' 2> /dev/null || true)
session_key="${tmux_session:-$$}"

# --- Dedup (one notification per waiting state, per session) ---
mkdir -p "${DEDUP_DIR}"
DEDUP_FILE="${DEDUP_DIR}/${session_key}"
if [[ -f "${DEDUP_FILE}" ]] && [[ "$(< "${DEDUP_FILE}")" == "${NOTIFICATION_TYPE}" ]]; then
    exit 0
fi

# --- Clean stale dedup files (sessions that no longer exist) ---
for f in "${DEDUP_DIR}"/*; do
    [[ -f "${f}" ]] || continue
    if ! tmux has-session -t "$(basename "${f}")" 2> /dev/null; then
        rm -f "${f}"
    fi
done

# --- Mode check (presence detection) ---
mode="auto"
[[ -f "${MODE_FILE}" ]] && mode=$(< "${MODE_FILE}")
case "${mode}" in
    off) exit 0 ;;
    on) ;;
    *)
        if [[ -z "${SSH_CONNECTION:-}" ]]; then
            # Local: skip if screen unlocked
            if ! ioreg -n Root -d1 2> /dev/null | grep -q '"IOConsoleLocked" = Yes'; then
                exit 0
            fi
            # Skip if someone SSH'd in (user on iPad/Termius)
            if who | grep -v console | grep -qE '\(.+\)$'; then
                exit 0
            fi
        else
            # Remote: skip if tmux session attached
            if [[ "$(tmux display-message -p '#{session_attached}' 2> /dev/null || true)" == "1" ]]; then
                exit 0
            fi
        fi
        ;;
esac

# --- Config ---
# shellcheck source=/dev/null
[[ -f "${ENV_FILE}" ]] && source "${ENV_FILE}"
NTFY_TOPIC="${NTFY_TOPIC:-}"
SSH_TARGET_HOST="${SSH_TARGET_HOST:-}"
REMOTE_SSH_TARGET_HOST="${REMOTE_SSH_TARGET_HOST:-}"
[[ -z "${NTFY_TOPIC}" ]] && exit 0

# --- Project detection ---
git_root=$(git rev-parse --show-toplevel 2> /dev/null || true)
project=$(basename "${git_root:-${PWD}}")

# --- Determine notification content ---
case "${NOTIFICATION_TYPE}" in
    permission_prompt | elicitation_dialog)
        title="${project}: Permission needed"
        body=$(echo "${INPUT}" | jq -r '.message // "Claude is waiting for approval"')
        tags="warning"
        priority="high"
        ;;
    idle_prompt)
        title="${project}: Waiting for input"
        body="Claude is idle and waiting for your response"
        tags="hourglass"
        priority="default"
        ;;
    *)
        title="${project}: Task complete"
        body=$(echo "${INPUT}" | jq -r '.message // "Claude has finished"')
        tags="white_check_mark"
        priority="default"
        ;;
esac

body="${body} — type 'ba' to attach"

[[ -n "${SSH_CONNECTION:-}" ]] && title="${title} (remote)"
if [[ -n "${tmux_session}" ]]; then
    title="${title} [T]"
else
    title="${title} [NT]"
fi

# --- Build deep link (Termius via ssh://) ---
# Determine target host — local Mac or remote server depending on where
# this hook is running. These map to Termius saved host configs.
if [[ -n "${SSH_CONNECTION:-}" ]]; then
    # Running on remote server — deep link should SSH to the server
    termius_host="${REMOTE_SSH_TARGET_HOST:-${SSH_TARGET_HOST}}"
else
    # Running on local Mac — deep link should SSH to the Mac
    termius_host="${SSH_TARGET_HOST}"
fi

# Write per-session helper script to ~/.beacon/scripts/.
# The 'ba' shell function scans these to attach to waiting sessions.
# Per-session key ensures multiple Claude sessions get distinct scripts.
BEACON_SCRIPTS="${HOME}/.beacon/scripts"
mkdir -p "${BEACON_SCRIPTS}"
chmod 700 "${BEACON_SCRIPTS}"
safe_key="${session_key//[^a-zA-Z0-9_-]/_}"
helper="${BEACON_SCRIPTS}/beacon-${safe_key}.sh"
safe_pwd=$(printf '%q' "${PWD}")
if [[ -n "${tmux_session}" ]]; then
    session_base="${tmux_session%% - *}"
    cat > "${helper}" << BEACON
#!/bin/bash
# beacon: ${tmux_session} | ${project} | ${NOTIFICATION_TYPE}
rm -f "${helper}"
cd ${safe_pwd}
t=\$(tmux ls -F '#{session_name}' | grep -m1 -F '${session_base} - ') && exec tmux attach -t "\$t"
exec claude --resume '${claude_session_id}'
BEACON
else
    cat > "${helper}" << BEACON
#!/bin/bash
# beacon: ${tmux_session:-no-tmux} | ${project} | ${NOTIFICATION_TYPE}
rm -f "${helper}"
cd ${safe_pwd}
exec claude --resume '${claude_session_id}'
BEACON
fi
chmod 700 "${helper}"

# Symlink latest for quick single-session access.
ln -sf "${helper}" "${BEACON_SCRIPTS}/beacon-latest.sh"

# Deep link: ssh://user@host — Termius opens + connects to saved host.
# User then types 'ba' to attach to the waiting session.
deep_link="ssh://${termius_host}"

# --- Send ntfy notification (fire-and-forget) ---
curl_args=(-s -X POST "https://ntfy.sh/${NTFY_TOPIC}"
    -H "Title: ${title}"
    -H "Tags: ${tags}"
    -H "Priority: ${priority}")
if [[ -n "${termius_host}" ]]; then
    curl_args+=(-H "Click: ${deep_link}")
fi

echo "${NOTIFICATION_TYPE}" > "${DEDUP_FILE}"
curl "${curl_args[@]}" -d "${body}" > /dev/null 2>&1 &
exit 0
