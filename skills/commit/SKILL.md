---
name: commit
description: Create a git commit, optionally with PR workflow (--pr flag)
user-invocable: true
disable-model-invocation: true
allowed-tools: >-
  Bash(git:*), Bash(gh:*), Bash(grep:*), Bash(rm:*), Bash(find:*), Bash(cd:*)
argument-hint: [--pr]
---

## CRITICAL RULE — NO PRs WITHOUT `--pr` FLAG

DO NOT CREATE A PULL REQUEST. DO NOT OFFER TO CREATE A PULL REQUEST. DO NOT SUGGEST CREATING A PULL REQUEST. DO NOT RUN `gh pr create`. DO NOT RUN ANY `gh pr` COMMAND.

THE ONLY EXCEPTION: the user passed `--pr` in $ARGUMENTS. If `--pr` is not present, PR behavior is **FORBIDDEN**.

This applies regardless of branch, context, or how "helpful" a PR might seem. No exceptions. No suggestions. No "would you like me to…?" offers. Commit. Push. Stop.

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

### Default flow (no `--pr`)

Stage changes → commit → push → verify with `git status` → stop.

**FORBIDDEN** (see CRITICAL RULE above): No `gh pr` commands, no PR creation, no PR offers or suggestions. Even on protected branches — push directly.

### PR flow (`--pr` passed)

Only when `$ARGUMENTS` contains `--pr`:

| Context                      | Action                                                                   |
| ---------------------------- | ------------------------------------------------------------------------ |
| On protected branch          | Create feature branch. Push. `gh pr create`. `gh pr merge --auto --merge`. |
| On feature branch            | Push. `gh pr create`. `gh pr merge --auto --merge`.                      |
| Trivial on feature branch    | Offer direct merge to base                                               |

## Output

Show `git log --oneline -n` (n = number of commits created this execution). 

PR mode: Include URL with all commits.
