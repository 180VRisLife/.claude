---
allowed-tools: >-
  Bash(git add:*), Bash(git status:*), Bash(git commit:*),
  Bash(git push:*), Bash(git branch:*), Bash(rm:*),
  Bash(git checkout:*), Bash(gh pr create:*), Bash(gh pr merge:*),
  Bash(git diff:*)
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

**Worktree:** `[ -f .git ]` or `git rev-parse --git-common-dir` ≠ `--git-dir`.
Skip if not worktree or on main/master/develop.

If on feature branch with generic name (`feature[-/]\d{8}-\d{6}`) or name
mismatches diff: generate name (haiku), show `old → new`,
ask "Rename? [Y/n/custom]".
On rename: `git branch -m old new && git push origin :old && git push -u origin new`

## Protected Branch Smart Defaults

**Protected:** `main`, `master`, `develop`, `staging`.
Check triviality via `git diff --stat HEAD`.

- **Trivial** (≤3 files, <20 LOC, docs/config only) → direct push
- **Not trivial** (4+ files, >50 LOC, core logic/API/deps) →
  Ask "Create PR? [y/N]". If yes: branch → commit → push → `gh pr create` →
  `gh pr merge --auto --squash` → return

## Pre-Commit Checks

1. **Monorepo:** cwd ≠ git root + outside changes → ask "This folder only"
   vs "Entire repo"
2. **Multi-repo:** Not in git but subdirs have `.git` → orchestrate across all
3. **Debug code:** Scan for `console.log`, `print()`, `NSLog`, `debugPrint`,
   `DEBUG = true`, `// TEMP`. Stop + list file:line.
   Exception: Debug UI, DebugLogger
4. **Readiness:** Flag TODO/FIXME, commented blocks, credentials →
   "Proceed anyway?" + track reminders
5. **Amend:** Last commit yours + not pushed + related → consider amend,
   ask if unsure

## Commit Style

**Tags:** `feat`, `fix`, `refactor`, `chore`, `docs`
**Format:** `tag(scope): lowercase, no period, imperative` — bullet list
for 3+ files

## Execution

Once checks pass, commit immediately. Small: single commit. Large (3+ files):
logical batches. Run `git status` to verify. Push to remote.
Show cleanup reminders if issues bypassed.

## Output

When complete: `git log --oneline -n` (n = commits created), then show
commits list.
