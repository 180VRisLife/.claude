#!/usr/bin/env bash
# PostToolUse hook: sync lint-pipeline.yml + lint configs into git repos
# Fires after Write|Edit to ensure repos have the latest CI workflow and configs.
# Always exits 0 so it never blocks Claude.

set -euo pipefail

TEMPLATE="${HOME}/.claude/templates/lint-pipeline.yml"

# Lint config files to sync from ~/.claude/ into .github/lint-config/
CONFIG_FILES=(
    ruff.toml
    biome.json
    .swiftlint.yml
    stylua.toml
    .prettierrc
    .gitleaks.toml
    .shellcheckrc
    .yamllint.yml
    .markdownlint-cli2.jsonc
)

# Cross-platform hash function (md5sum on Linux, md5 -q on macOS)
_hash() {
    if command -v md5sum > /dev/null 2>&1; then
        md5sum | cut -d' ' -f1
    else
        md5 -q
    fi
}

# 1. Read JSON from stdin, extract file_path and cwd
input=$(cat)
file_path=$(echo "${input}" | jq -r '.tool_input.file_path // empty') 2> /dev/null
cwd=$(echo "${input}" | jq -r '.cwd // empty') 2> /dev/null

# If no file_path, nothing to do
if [[ -z "${file_path}" ]]; then
    exit 0
fi

# 2. Resolve absolute path
if [[ "${file_path}" != /* ]]; then
    file_path="${cwd:-.}/${file_path}"
fi

# 3. Determine if inside a git repo
repo_root=$(git -C "$(dirname "${file_path}")" rev-parse --show-toplevel 2> /dev/null) || exit 0

if [[ -z "${repo_root}" ]]; then
    exit 0
fi

# 4. Skip the .claude repo itself (avoid self-syncing)
repo_name=$(basename "${repo_root}")
if [[ "${repo_name}" == ".claude" ]]; then
    exit 0
fi

# 5. Support opt-out via marker file
if [[ -f "${repo_root}/.github/lint-config/.no-sync" ]]; then
    exit 0
fi

# 6. Compute content-addressed session flag
# Hash includes: repo root path + contents of all source files (template + configs)
flag_input=$(echo -n "${repo_root}")
if [[ -f "${TEMPLATE}" ]]; then
    flag_input+=$(_hash < "${TEMPLATE}")
fi
for cfg in "${CONFIG_FILES[@]}"; do
    if [[ -f "${HOME}/.claude/${cfg}" ]]; then
        flag_input+=$(_hash < "${HOME}/.claude/${cfg}")
    fi
done
flag_hash=$(echo -n "${flag_input}" | _hash)

# Encode repo root for flag filename
repo_id=$(echo -n "${repo_root}" | _hash)
flag="/tmp/claude-ci-synced-${repo_id}-${flag_hash}"

# 7. If flag exists, already synced this session with current content
if [[ -f "${flag}" ]]; then
    exit 0
fi

# 8. Clean stale flags for the same repo before syncing
rm -f /tmp/claude-ci-synced-"${repo_id}"-* 2> /dev/null

# 9. Sync workflow template
target="${repo_root}/.github/workflows/lint-pipeline.yml"
if [[ -f "${TEMPLATE}" ]]; then
    if [[ ! -f "${target}" ]]; then
        mkdir -p "$(dirname "${target}")" > /dev/null 2>&1
        cp "${TEMPLATE}" "${target}" > /dev/null 2>&1
    elif ! diff -q "${TEMPLATE}" "${target}" > /dev/null 2>&1; then
        cp "${TEMPLATE}" "${target}" > /dev/null 2>&1
    fi
fi

# 10. Sync config files
config_dir="${repo_root}/.github/lint-config"
mkdir -p "${config_dir}" > /dev/null 2>&1

for cfg in "${CONFIG_FILES[@]}"; do
    src="${HOME}/.claude/${cfg}"
    dst="${config_dir}/${cfg}"
    if [[ -f "${src}" ]]; then
        if [[ ! -f "${dst}" ]] || ! diff -q "${src}" "${dst}" > /dev/null 2>&1; then
            cp "${src}" "${dst}" > /dev/null 2>&1
        fi
    fi
done

# 11. Touch flag file
touch "${flag}" > /dev/null 2>&1

exit 0
