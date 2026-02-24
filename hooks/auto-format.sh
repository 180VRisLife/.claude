#!/usr/bin/env bash
# PostToolUse hook: auto-format files after Write/Edit operations.
# Always exits 0 so it never blocks Claude.

set -euo pipefail

# Read JSON payload from stdin
input="$(cat)"

# Extract file_path and cwd from tool_input using jq
file_path="$(printf '%s' "${input}" | jq -r '.tool_input.file_path // empty')"
cwd="$(printf '%s' "${input}" | jq -r '.cwd // empty')"

# If no file_path, nothing to format
if [[ -z "${file_path}" ]]; then
    exit 0
fi

# Resolve to absolute path if relative
if [[ "${file_path}" != /* ]]; then
    file_path="${cwd:-.}/${file_path}"
fi

# Bail if file doesn't exist
if [[ ! -f "${file_path}" ]]; then
    exit 0
fi

# Get the file extension (lowercase)
ext="${file_path##*.}"
ext="$(printf '%s' "${ext}" | tr '[:upper:]' '[:lower:]')"

case ".${ext}" in
    .py | .pyi)
        if command -v ruff > /dev/null 2>&1; then
            ruff format --config ~/.claude/ruff.toml "${file_path}" > /dev/null 2>&1 || true
        fi
        ;;
    .ts | .tsx | .js | .jsx | .mjs | .cjs | .css | .json | .jsonc)
        if command -v biome > /dev/null 2>&1; then
            biome format --write --config-path ~/.claude "${file_path}" > /dev/null 2>&1 || true
        fi
        ;;
    .sh | .bash)
        if command -v shfmt > /dev/null 2>&1; then
            shfmt -w -i 4 -bn -ci -sr "${file_path}" > /dev/null 2>&1 || true
        fi
        ;;
    .swift)
        if command -v swiftlint > /dev/null 2>&1; then
            swiftlint fix --quiet --config ~/.claude/.swiftlint.yml --path "${file_path}" > /dev/null 2>&1 || true
        fi
        ;;
    .lua)
        if command -v stylua > /dev/null 2>&1; then
            stylua --config-path ~/.claude/stylua.toml "${file_path}" > /dev/null 2>&1 || true
        fi
        ;;
    .html | .md | .yaml | .yml)
        if command -v prettier > /dev/null 2>&1; then
            prettier --write --config ~/.claude/.prettierrc "${file_path}" > /dev/null 2>&1 || true
        fi
        ;;
    *) ;;
esac

exit 0
