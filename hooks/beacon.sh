#!/usr/bin/env bash
# beacon.sh - Phone notification + Termius session routing for Claude Code
# Mode: auto = notify only when user is away, on = always, off = never

set -euo pipefail

MODE_FILE="${HOME}/.beacon/mode"
ENV_FILE="${HOME}/.claude/hooks/.env"
TARGET_DIR="${HOME}/.beacon/targets"

# --- Mode check (presence detection) ---
mode="auto"
[[ -f "${MODE_FILE}" ]] && mode=$(<"${MODE_FILE}")
case "${mode}" in
  off) exit 0 ;;
  on)  ;;
  *)
    if [[ -z "${SSH_CONNECTION:-}" ]]; then
      # Local: skip if screen unlocked
      if ! ioreg -n Root -d1 2>/dev/null | grep -q "CGSSessionScreenIsLocked.*Yes"; then
        exit 0
      fi
      # Skip if someone SSH'd in (user on iPad/Termius)
      if who | grep -v console | grep -q .; then
        exit 0
      fi
    else
      # Remote: skip if tmux session attached
      if [[ "$(tmux display-message -p '#{session_attached}' 2>/dev/null || true)" == "1" ]]; then
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
[[ -z "${NTFY_TOPIC}" ]] && exit 0

# --- Project + session detection ---
git_root=$(git rev-parse --show-toplevel 2>/dev/null || true)
project=$(basename "${git_root:-${PWD}}")
tmux_session=$(tmux display-message -p '#{session_name}' 2>/dev/null || true)

# --- Write target file ---
if [[ -n "${tmux_session}" ]]; then
  mkdir -p "${TARGET_DIR}"
  echo "${tmux_session}" > "${TARGET_DIR}/${project}"

  # Clean stale targets (sessions that no longer exist)
  for f in "${TARGET_DIR}"/*; do
    [[ -f "${f}" ]] || continue
    stale_session=$(<"${f}")
    if ! tmux has-session -t "${stale_session}" 2>/dev/null; then
      rm -f "${f}"
    fi
  done
fi

# --- Slot allocation (local sessions only) ---
SLOT_DIR="${HOME}/.beacon/slots"
BEACON_SLOTS="${BEACON_SLOTS:-10}"
key_name="${SSH_KEY_NAME:-macbook-air}"

if [[ -z "${SSH_CONNECTION:-}" && -n "${tmux_session}" ]]; then
  mkdir -p "${SLOT_DIR}"
  session_base="${tmux_session%% - *}"

  # Clean stale slots (sessions that no longer exist in tmux)
  for f in "${SLOT_DIR}"/*; do
    [[ -f "${f}" ]] || continue
    slot_session=$(<"${f}")
    # Check if any live session starts with the stored base name
    found=false
    while IFS= read -r live; do
      if [[ "${live}" == "${slot_session}" || "${live}" == "${slot_session} - "* ]]; then
        found=true
        break
      fi
    done < <(tmux list-sessions -F '#{session_name}' 2>/dev/null || true)
    if [[ "${found}" == "false" ]]; then
      rm -f "${f}"
    fi
  done

  # Check if this session already has a slot (idempotent)
  existing_slot=""
  for f in "${SLOT_DIR}"/*; do
    [[ -f "${f}" ]] || continue
    if [[ "$(<"${f}")" == "${session_base}" ]]; then
      existing_slot=$(basename "${f}")
      break
    fi
  done

  if [[ -n "${existing_slot}" ]]; then
    key_name="beacon-${existing_slot}"
  else
    # Find next free slot
    for i in $(seq 1 "${BEACON_SLOTS}"); do
      if [[ ! -f "${SLOT_DIR}/${i}" ]]; then
        echo "${session_base}" > "${SLOT_DIR}/${i}"
        key_name="beacon-${i}"
        break
      fi
    done
    # If no free slot, key_name stays as SSH_KEY_NAME fallback
  fi
fi

# --- Determine notification content ---
INPUT=$(cat)
NOTIFICATION_TYPE=$(echo "${INPUT}" | jq -r '.notification_type // empty')

case "${NOTIFICATION_TYPE}" in
  permission_prompt|elicitation_dialog)
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

# --- Send ntfy notification (fire-and-forget) ---
curl_args=(-s -X POST "https://ntfy.sh/${NTFY_TOPIC}"
  -H "Title: ${title}"
  -H "Tags: ${tags}"
  -H "Priority: ${priority}")
if [[ -n "${SSH_TARGET_HOST}" ]]; then
  curl_args+=(-H "Click: ssh://${SSH_TARGET_HOST}?key=${key_name}&name=${key_name}&save=true&group=Beacon")
fi

curl "${curl_args[@]}" -d "${body}" >/dev/null 2>&1 &
exit 0
