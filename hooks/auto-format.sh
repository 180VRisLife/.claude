#!/usr/bin/env bash
# PostToolUse hook: track edited files for batch formatting on Stop.
# Always exits 0 so it never blocks Claude.
set -euo pipefail

input="$(cat)"
file_path="$(printf '%s' "${input}" | jq -r '.tool_input.file_path // empty')"
session_id="$(printf '%s' "${input}" | jq -r '.session_id // empty')"
cwd="$(printf '%s' "${input}" | jq -r '.cwd // empty')"

[[ -z "${file_path}" || -z "${session_id}" ]] && exit 0

# Resolve to absolute path
if [[ "${file_path}" != /* ]]; then
    file_path="${cwd:-.}/${file_path}"
fi

# Append to session-scoped queue (one path per line)
echo "${file_path}" >> "/tmp/claude-format-queue-${session_id}"
exit 0
