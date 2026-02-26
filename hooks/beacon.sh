#!/usr/bin/env bash
# beacon.sh - Phone notification via ntfy with Termius deep link
# Mode: auto = notify only when user is away, on = always, off = never
#
# === DEEP LINK STRATEGY (Termius Pro) ===
#
# Previous approach (Blink Shell) failed — blinkshell://run?cmd= is broken
# in current versions, and ssh:// can't pass a remote command.
#
# New approach: Termius ssh:// deep link + startup snippet
#
# How it works:
#   1. beacon.sh writes a per-session helper script to /tmp/beacon-{key}.sh
#      (cd to project dir, attach tmux session, fallback to $SHELL)
#   2. beacon.sh symlinks /tmp/beacon-latest.sh → the per-session script
#   3. ntfy "Click" action uses ssh://user@host (Termius handles this)
#   4. User taps notification → Termius opens → connects to saved host
#   5. Termius startup snippet runs: [[ -x /tmp/beacon-latest.sh ]] && exec /tmp/beacon-latest.sh
#   6. Helper script cd's to project, attaches tmux, done
#
# Termius setup required:
#   - Host "local":  chrisjamesbliss@100.97.43.63, key: macbook-air
#   - Host "remote": claude-dev@100.119.234.5, key: claude-sandbox
#   - Startup snippet on BOTH hosts:
#       [[ -x /tmp/beacon-latest.sh ]] && exec /tmp/beacon-latest.sh
#
# TODO: Test whether ssh://user@host matches a saved Termius host config
#       (triggering the startup snippet) or creates an ad-hoc connection.
#       If ad-hoc, we may need ssh://local instead — test both.
#
# TODO: Snippet variables are iOS-pending. If they ship, we could pass
#       the session key through the deep link and skip the symlink.
#       For now, /tmp/beacon-latest.sh (most-recent-wins) is the approach.
#
# TODO: Clean up unused blink_key / SSH_KEY_NAME config once Termius is
#       confirmed working. Those were for blinkshell://run?key= which is dead.
# ===

set -euo pipefail

MODE_FILE="${HOME}/.beacon/mode"
ENV_FILE="${HOME}/.claude/hooks/.env"
DEDUP_DIR="${HOME}/.beacon/dedup"

# --- Read stdin early (needed for dedup) ---
INPUT=$(cat)
NOTIFICATION_TYPE=$(echo "${INPUT}" | jq -r '.notification_type // empty')

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
SSH_KEY_NAME="${SSH_KEY_NAME:-macbook-air}"
REMOTE_SSH_TARGET_HOST="${REMOTE_SSH_TARGET_HOST:-}"
REMOTE_SSH_KEY_NAME="${REMOTE_SSH_KEY_NAME:-}"
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

# Write per-session helper script to /tmp.
# Termius startup snippet will exec this on connect.
# Per-session key ensures multiple Claude sessions get distinct scripts.
safe_key="${session_key//[^a-zA-Z0-9_-]/_}"
helper="/tmp/beacon-${safe_key}.sh"
if [[ -n "${tmux_session}" ]]; then
    session_base="${tmux_session%% - *}"
    cat > "${helper}" << BEACON
#!/bin/bash
rm -f /tmp/beacon-latest.sh  # one-shot: disarm after use
cd '${PWD}'
t=\$(tmux ls -F '#{session_name}' | grep -m1 -F '${session_base} - ') && exec tmux attach -t "\$t"
exec \$SHELL
BEACON
else
    cat > "${helper}" << BEACON
#!/bin/bash
rm -f /tmp/beacon-latest.sh  # one-shot: disarm after use
cd '${PWD}'
exec \$SHELL
BEACON
fi
chmod +x "${helper}"

# Symlink latest — Termius startup snippet always runs beacon-latest.sh.
# Most-recent-wins: if multiple sessions notify, tapping any notification
# lands you in whichever session fired last. Once on the Mac you can
# tmux ls and switch if needed.
ln -sf "${helper}" /tmp/beacon-latest.sh

# Deep link: ssh://user@host — Termius opens + connects to saved host.
# The startup snippet on the Termius host config handles the rest.
# TODO: Test if ssh://user@host matches saved config or goes ad-hoc.
#       If ad-hoc, try Termius host label: may need a different URL format.
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
