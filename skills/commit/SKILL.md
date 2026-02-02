---
name: commit
description: Create a git commit
user-invocable: true
allowed-tools: >-
  Bash(git:*), Bash(gh:*), Bash(grep:*), Bash(rm:*), Bash(find:*)
requires-mode: edit
exit-plan-mode: auto
---

## Mode Check

If plan mode is active, call ExitPlanMode now before proceeding.

## Context

- Git status: !`git status 2>/dev/null || echo "Not in git repo"`
- Diff: !`git diff HEAD 2>/dev/null || echo ""`
- Branch: !`git branch --show-current 2>/dev/null || echo ""`
- Recent commits: !`git log --oneline -30 2>/dev/null || echo ""`
- Last commit: !`git log -1 --format='%an <%ae> | %s' 2>/dev/null || echo ""`
- Push status: !`git status -sb 2>/dev/null | head -1 || echo ""`
- Git root: !`git rev-parse --show-toplevel 2>/dev/null || echo "Not in git repo"`
- CWD: !`pwd`
- Workspace repos: !`find . -maxdepth 2 -name ".git" -type d 2>/dev/null | sed 's|/\.git$||;s|^\./||'`

## Workspace Mode

**Detection:** Git root = "Not in git repo" + workspace repos found.

1. **Check repos:** `git -C <repo> status --porcelain` for each
2. **No changes** → "No uncommitted changes in workspace"
3. **Has changes** → commit all sequentially: "→ RepoName" + workflow + result
4. **Summary:** list all commits made across repos

## Branch Name Check (Worktrees Only)

**Worktree:** `[ -f .git ]` or `git rev-parse --git-common-dir` ≠ `--git-dir`.
Skip if not worktree or on develop/staging/main.

If on feature branch with generic name (`feature[-/]\d{8}-\d{6}`) or name mismatches diff: generate name (haiku), show `old → new`, ask "Rename? [Y/n/custom]".
On rename: `git branch -m old new && git push origin :old && git push -u origin new`

## Protected Branch Smart Defaults

**Protected:** `develop`, `staging`, `main`.
Check triviality via `git diff --stat HEAD`.

- **Trivial** (≤3 files, <20 LOC, docs/config only) → direct push
- **Not trivial** (4+ files, >50 LOC, core logic/API/deps) → Ask "Create PR? [y/N]". If yes: branch → commit → push → `gh pr create` → `gh pr merge --auto --squash` → return

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

Once checks pass, commit immediately. Group changes into logical commits—one
commit for tightly coupled changes, multiple commits when changes are distinct.
Run `git status` to verify. Push to remote.
Show cleanup reminders if issues bypassed.

## Output

When complete: `git log --oneline -n` (n = commits created), then show commits list.
