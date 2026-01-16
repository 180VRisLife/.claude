---
allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git commit:*), Bash(rm:*)
description: Create a git commit
---

## Context

- Git status: !`git status`
- Diff: !`git diff HEAD`
- Branch: !`git branch --show-current`
- Recent commits: !`git log --oneline -30`
- Last commit: !`git log -1 --format='%an <%ae> | %s'`
- Push status: !`git status -sb | head -1`
- Git root: !`git rev-parse --show-toplevel`
- CWD: !`pwd`

## Pre-Commit Checks

1. **Monorepo:** If cwd ≠ git root AND outside changes exist, ask: "This folder only" vs "Entire repo"

2. **Multi-repo:** If not in git repo but subdirs have `.git`, orchestrate across all repos

3. **⛔️ Debug code (HARD STOP):** Scan changed files for `console.log`, `print()`, `NSLog`, `debugPrint`, `DEBUG = true`, `// TEMP`, `// TODO: remove`. Exceptions: Debug UI, DebugLogger. If found: list file:line, stop, ask if exception. If not, remove first.

4. **Readiness:** Flag TODO/FIXME, commented-out blocks, credentials, junk files. Ask "Proceed anyway?" and track for cleanup reminders.

5. **Amend:** If last commit is yours + not pushed + related changes → consider amending. Ask if unsure.

## Commit Style

**Tags:** `feat`, `fix`, `refactor`, `chore`, `docs`

**Format:** `tag(scope): lowercase, no period, imperative` — add bullet list for 3+ files/complex changes

## Execution

Once checks pass, commit immediately (no confirmation needed).

- **Small:** Single commit
- **Large (3+ files):** Logical batches, multiple commits

Run `git status` to verify. Show cleanup reminders if issues were bypassed.
