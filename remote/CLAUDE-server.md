# Git & GitHub: READ-ONLY Access

Remote write operations are disabled on this machine and will fail.

Do not attempt them. This includes:

- **git**: `push`, `send-pack`, `lfs push` (all flags/variants)
- **gh**: any subcommand that creates, modifies, or deletes remote resources
- **Direct API calls**: `curl`/`wget`/scripts targeting GitHub's API with write methods

**What works**: `clone`, `pull`, `fetch`, `gh` read commands (`list`, `view`, `status`).

# DebugLogger

Use project's DebugLogger utility for debug logging.

# Internet Access

Use the full internet freely for documentation, web searches, and package installation.
