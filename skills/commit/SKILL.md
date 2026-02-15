---
name: commit
description: Create a git commit, optionally with PR workflow (--pr flag)
user-invocable: true
disable-model-invocation: true
allowed-tools: >-
  Bash(git:*), Bash(gh:*), Bash(grep:*), Bash(rm:*), Bash(find:*), Bash(cd:*)
requires-mode: edit
exit-plan-mode: auto
argument-hint: [--pr]
---

## Context

- Status: !`git status -sb 2>/dev/null || echo "Not in git repo"`
- Diff: !`git diff HEAD --stat 2>/dev/null || echo ""`
- Branch: !`git branch --show-current 2>/dev/null || echo ""`
- Recent commits: !`git log --oneline -5 2>/dev/null || echo ""`

## Arguments

$ARGUMENTS: `--pr` = commit + push + PR with automerge. No flag = commit + push.

## Pre-Commit

1. **Scope:** If cwd != git root with outside changes, ask scope
2. **Block on:** `console.log`, `print()`, `debugPrint`, `DEBUG = true`, `// TEMP`
3. **Flag:** TODO/FIXME, credentials - ask to proceed
4. **Amend:** Last commit yours + not pushed + related → offer

## Style

`tag(scope): lowercase imperative, no period` - Tags: `feat`, `fix`, `refactor`, `chore`, `docs`

## Execution

**Protected branches:** `develop`, `staging`, `main`

Split unrelated changes into separate atomic commits. Each commit = one logical change.

| Context                      | Action                                                                   |
| ---------------------------- | ------------------------------------------------------------------------ |
| Commit mode                  | Push. Verify `git status`.                                               |
| PR mode                      | Branch if protected. Push. `gh pr create`. `gh pr merge --auto --merge`. |
| Trivial on protected         | Direct push or offer PR                                                  |
| Trivial on feature + PR mode | Offer direct merge to base                                               |

## Output

Show `git log --oneline -n` (n = number of commits created this execution). 

PR mode: Include URL with all commits.
