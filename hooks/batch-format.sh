#!/usr/bin/env bash
# Stop hook: batch-format all files edited during this turn.
# Always exits 0 so it never blocks Claude.
set -euo pipefail

input="$(cat)"
session_id="$(printf '%s' "${input}" | jq -r '.session_id // empty')"
stop_hook_active="$(printf '%s' "${input}" | jq -r '.stop_hook_active // false')"

# Prevent infinite loops if Stop hook itself triggered a stop
[[ "${stop_hook_active}" == "true" ]] && exit 0
[[ -z "${session_id}" ]] && exit 0

queue="/tmp/claude-format-queue-${session_id}"
[[ ! -f "${queue}" ]] && exit 0

# Deduplicate and process
sort -u "${queue}" | while IFS= read -r file_path; do
    [[ -z "${file_path}" || ! -f "${file_path}" ]] && continue

    ext="${file_path##*.}"
    ext="$(printf '%s' "${ext}" | tr '[:upper:]' '[:lower:]')"

    case ".${ext}" in
        .py | .pyi)
            command -v ruff > /dev/null 2>&1 \
                && ruff format --config ~/.claude/ruff.toml "${file_path}" > /dev/null 2>&1 || true
            ;;
        .ts | .tsx | .js | .jsx | .mjs | .cjs | .css | .json | .jsonc)
            command -v biome > /dev/null 2>&1 \
                && biome format --write --config-path ~/.claude "${file_path}" > /dev/null 2>&1 || true
            ;;
        .sh | .bash)
            command -v shfmt > /dev/null 2>&1 \
                && shfmt -w -i 4 -bn -ci -sr "${file_path}" > /dev/null 2>&1 || true
            ;;
        .swift)
            command -v swiftlint > /dev/null 2>&1 \
                && swiftlint fix --quiet --config ~/.claude/.swiftlint.yml --path "${file_path}" > /dev/null 2>&1 || true
            ;;
        .lua)
            command -v stylua > /dev/null 2>&1 \
                && stylua --config-path ~/.claude/stylua.toml "${file_path}" > /dev/null 2>&1 || true
            ;;
        .html | .md | .yaml | .yml)
            command -v prettier > /dev/null 2>&1 \
                && prettier --write --config ~/.claude/.prettierrc "${file_path}" > /dev/null 2>&1 || true
            ;;
        *) ;;
    esac
done

# Clean up queue file
rm -f "${queue}"
exit 0
