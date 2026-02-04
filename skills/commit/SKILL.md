---
name: commit
description: Create a git commit, optionally with PR workflow (--pr flag)
user-invocable: true
allowed-tools: >-
  Bash(git:*), Bash(gh:*), Bash(grep:*), Bash(rm:*), Bash(find:*), Bash(cd:*)
requires-mode: edit
exit-plan-mode: auto
argument-hint: [--pr]
---

## Mode Check

If plan mode is active, call ExitPlanMode now before proceeding.

## Context

- Status: !`git status -sb 2>/dev/null || echo "Not in git repo"`
- Diff: !`git diff HEAD --stat 2>/dev/null || echo ""`
- Branch: !`git branch --show-current 2>/dev/null || echo ""`
- Recent commits: !`git log --oneline -5 2>/dev/null || echo ""`
- Git root: !`git rev-parse --show-toplevel 2>/dev/null || echo ""`

## Workflow

**Arguments:** $ARGUMENTS
- `--pr` → commit + push + PR with automerge
- No flag → commit + push

**Trivial change:** <=3 files, <20 LOC, non-core (docs/config/comments).

**Workspace mode:** If not in git repo but subdirs have `.git`, iterate each.

**Worktree branch check:** If feature branch has generic name, offer rename.

## Pre-Commit Checks

1. **Monorepo scope:** If cwd != git root with outside changes, ask scope
2. **Debug code:** Scan for `console.log`, `print()`, `debugPrint`, `DEBUG = true`, `// TEMP` - stop if found
3. **Readiness:** Flag TODO/FIXME, credentials - ask to proceed
4. **Amend:** Last commit yours + not pushed + related → offer amend

## Commit Style

`tag(scope): lowercase imperative, no period` - Example: `fix(auth): handle expired token`

Tags: `feat`, `fix`, `refactor`, `chore`, `docs`

## Execution

**Protected branches:** `develop`, `staging`, `main`

**Commit mode:** Group related changes. Push. Verify with `git status`.

**PR mode:** Branch if on protected. Push. `gh pr create`. `gh pr merge --auto --merge`.

**Trivial on protected (commit mode):** Direct push if trivial, else offer PR.

**Trivial on feature (PR mode):** Offer direct merge to base branch.

## Output

Show `git log --oneline -n` (n = commits created).
PR mode: Also show PR URL. Show cleanup reminders if issues bypassed.
