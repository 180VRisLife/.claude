---
allowed-tools: Bash(git checkout:*), Bash(git add:*), Bash(git status:*), Bash(git push:*), Bash(git commit:*), Bash(git branch:*), Bash(git merge:*), Bash(git pull:*), Bash(git diff:*), Bash(gh pr create:*), Bash(gh pr merge:*), Bash(rm:*), Bash(cd:*), Bash(wq:*)
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
- Base diff stats: !`git diff main...HEAD --stat 2>/dev/null || git diff develop...HEAD --stat 2>/dev/null || echo "N/A"`

## Branch Name Check (Worktrees Only)

**Worktree:** `[ -f .git ]` or `git rev-parse --git-common-dir` ≠ `--git-dir`. Skip if not worktree or on main/master/develop.

If on feature branch with generic name (`feature[-/]\d{8}-\d{6}`) or name mismatches diff: generate name (haiku), show `old → new`, ask "Rename? [Y/n/custom]". On rename: `git branch -m old new && git push origin :old && git push -u origin new`

## Trivial Change Shortcut (Feature Branches Only)

Skip if on main/master/develop. Check total diff: `git diff main...HEAD --stat`

**Trivial:** ≤3 files, <20 LOC, docs/config/comments or single function fix. Ask "Small change. Merge directly to main? [Y/n]"
- **Yes:** `git checkout main && git pull && git merge --no-ff <branch> && git push && git push origin --delete <branch>`. Ask "Clean up worktree? [Y/n]" → `cd .. && wq`
- **No:** Continue with PR workflow

## Pre-Commit Checks

1. **Monorepo:** cwd ≠ git root + outside changes → ask "This folder only" vs "Entire repo"
2. **Multi-repo:** Not in git but subdirs have `.git` → orchestrate across all
3. **⛔️ Debug code:** Scan for `console.log`, `print()`, `NSLog`, `debugPrint`, `DEBUG = true`, `// TEMP`. Stop + list file:line. Exception: Debug UI, DebugLogger
4. **Readiness:** Flag TODO/FIXME, commented blocks, credentials → "Proceed anyway?" + track reminders
5. **Amend:** Last commit yours + not pushed + related → consider amend, ask if unsure

## Commit Style

**Tags:** `feat`, `fix`, `refactor`, `chore`, `docs`
**Format:** `tag(scope): lowercase, no period, imperative` — bullet list for 3+ files

## Execution

Once checks pass, proceed immediately. Create branch if on main/develop/staging.
Group changes into logical commits—one or multiple as appropriate. Push to origin.
Create PR via `gh pr create`. Enable automerge: `gh pr merge <PR> --auto --merge`.
Show cleanup reminders if issues bypassed.

## Output

When complete: `git log --oneline -n` (n = commits created), then show commits list and PR URL.
