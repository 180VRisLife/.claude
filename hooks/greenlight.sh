#!/usr/bin/env bash
# greenlight.sh - Wrapper for Greenlight hook with mode gating and project detection
# Forwards Claude Code hooks to iPhone via Greenlight relay.
# Mode: auto (default) = notify only when user is away
#         Local: screen locked + no SSH sessions (iPad detection)
#         Remote: tmux session detached
#       on = always notify, off = never notify

set -euo pipefail

MODE_FILE="${HOME}/.claude/hooks/.greenlight-mode"
ENV_FILE="${HOME}/.claude/hooks/.env"
HOOK_SCRIPT="${HOME}/.claude/hooks/greenlight-hook.sh"

# --- Mode check ---
mode="auto"
[[ -f "${MODE_FILE}" ]] && mode=$(<"${MODE_FILE}")

case "${mode}" in
  off) exit 0 ;;
  on)  ;; # always proceed
  *)   # auto: check presence
    if [[ -z "${SSH_CONNECTION:-}" ]]; then
      # Local: check macOS lock state
      if ! ioreg -n Root -d1 2>/dev/null | grep -q "CGSSessionScreenIsLocked.*Yes"; then
        exit 0  # screen unlocked, user is present
      fi
      # Screen locked — check for active SSH sessions (iPad via Termius)
      if who | grep -v console | grep -q .; then
        exit 0  # someone SSH'd in, user is on iPad
      fi
    else
      # Remote: check if tmux session is attached
      if [[ "$(tmux display-message -p '#{session_attached}' 2>/dev/null)" == "1" ]]; then
        exit 0  # session attached, user is present
      fi
    fi
    ;;
esac

# --- Device ID ---
if [[ -f "${ENV_FILE}" ]]; then
  # shellcheck source=/dev/null
  source "${ENV_FILE}"
fi
GREENLIGHT_DEVICE_ID="${GREENLIGHT_DEVICE_ID:-}"
[[ -z "${GREENLIGHT_DEVICE_ID}" ]] && exit 0

# --- Project detection ---
git_root=$(git rev-parse --show-toplevel 2>/dev/null || true)
project=$(basename "${git_root:-${PWD}}")

# --- Forward to official hook ---
exec bash "${HOOK_SCRIPT}" --device-id "${GREENLIGHT_DEVICE_ID}" --project "${project}" "$@"
