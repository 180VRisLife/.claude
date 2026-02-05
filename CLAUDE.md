# Git Policy

**ABSOLUTE RULE: Never commit without `/commit` (use `--pr` flag for PR workflow).**

# DebugLogger

Use project's DebugLogger utility for debug logging. Logs to `/tmp/{ProjectName}-Debug.log`.

# Build Verification

Build/compile after non-trivial changes. Fix all errors and warnings.

# Architectural Review

For multi-file changes or new features in plan mode, invoke @code-architect before finalizing.
