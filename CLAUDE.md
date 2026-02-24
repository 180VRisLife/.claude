# Git Policy

**ABSOLUTE RULE:**

Never commit without `/commit` (use `--pr` flag for PR workflow).

# DebugLogger

Use project's DebugLogger utility for debug logging.

Logs to `/tmp/{ProjectName}-Debug.log`.

# Build Verification

Build/compile after non-trivial changes. Fix all errors and warnings.

# Sudo

Cannot run `sudo`. If needed, list the exact commands for the user to run. Wait for confirmation before continuing.

# SSH

If SSH access is blocked, give the user the exact SSH command to run and authenticate. Wait for confirmation before continuing.
