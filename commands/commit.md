---
allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git commit:*), Bash(git push:*), Bash(git branch:*), Bash(rm:*)
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

## Branch Name Check (Worktrees Only)

**Worktree detection:** `[ -f .git ]` or `git rev-parse --git-common-dir` ≠ `--git-dir`

If in worktree + on feature branch (not main/master/develop):

1. **Check:** Is branch generic (`feature[-/]\d{8}-\d{6}`) or mismatched with diff?

2. **If rename needed:** Generate name from diff (haiku model), show `old → new`, ask "Rename? [Y/n/custom]"

3. **On rename:** `git branch -m old new && git push origin :old && git push -u origin new`

4. **Skip if:** Not worktree, on main/master/develop, or name already fits changes

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

Push to remote after committing.

## Output Format

When complete, list all commits created:

```
✅ Committed!

1. abc1234 - feat(auth): add OAuth2 login flow
2. def5678 - fix(api): resolve null pointer in user lookup
3. 9a8b7c6 - refactor(utils): extract date formatting helpers
4. 1f2e3d4 - chore(deps): update react to v19
5. 5c6d7e8 - docs(readme): add installation instructions
```

Use `git log --oneline -n` (where n = number of commits created) to get the hash and message for each.
