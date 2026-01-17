---
allowed-tools: Bash(git checkout:*), Bash(git add:*), Bash(git status:*), Bash(git push:*), Bash(git commit:*), Bash(gh pr create:*), Bash(rm:*)
description: Commit, push, and open a PR
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

Once checks pass, proceed immediately (no confirmation needed).

1. Create branch if on main/master
2. Commit: single for small changes, logical batches for large (3+ files)
3. Push to origin
4. Create PR with `gh pr create`
5. Return PR URL

Show cleanup reminders if issues were bypassed.

## Output Format

When complete, list all commits created and the PR URL:

```
✅ Committed and PR created!

Commits:
1. abc1234 - feat(auth): add OAuth2 login flow
2. def5678 - fix(api): resolve null pointer in user lookup
3. 9a8b7c6 - refactor(utils): extract date formatting helpers
4. 1f2e3d4 - chore(deps): update react to v19
5. 5c6d7e8 - docs(readme): add installation instructions

PR: https://github.com/org/repo/pull/123
```

Use `git log --oneline -n` (where n = number of commits created) to get the hash and message for each.
