---
name: commit
description: Create a git commit, optionally with PR workflow (--pr flag, --promote flag)
user-invocable: true
disable-model-invocation: false
allowed-tools: >-
  Bash(git:*), Bash(gh:*), Bash(grep:*), Bash(rm:*), Bash(find:*), Bash(cd:*),
  Read, Edit, Write, Glob, Grep
argument-hint: [--pr [--promote]]
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

$ARGUMENTS:

- `--pr` = commit + push + PR with automerge. No flag = commit + push.
- `--promote` = (requires `--pr`) PR a protected branch into the next protected branch in the chain. Error if `--pr` is not also present. Error if not on a protected branch.

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

- `--pr` on protected (no `--promote`): Create feature branch, push, `gh pr create --base <current-protected>`, automerge
- `--pr` on feature: Resolve base, push, `gh pr create --base <resolved-base>`, automerge
- `--pr --promote` on protected: Stay on branch, push, `gh pr create --base <next-protected>`, automerge
- `--pr --promote` on feature: **Error.** `--promote` only works from a protected branch.
- `--promote` without `--pr`: **Error.** Requires `--pr`.

### Base-branch resolution (`--pr` only)

Determine the `--base` target for `gh pr create`. **Every `gh pr create` MUST include `--base <resolved-base>`.**

Resolution order:

1. **`--promote` flag present:** Use the next branch in the promotion chain: `develop → staging → main`. If the next branch does not exist on the remote (`git ls-remote --heads origin <branch>`), skip to the following one. If on `main`, error — nothing to promote to.
2. **Feature branch:** Detect which protected branch the feature diverged from using `git log --oneline --decorate` to find the most recent protected-branch reference in ancestry. Default to `develop` if ambiguous.
3. **Protected branch (no `--promote`):** The base is the current protected branch itself (the feature branch will PR back into it).

Store the resolved base for use in post-merge cleanup.

### CI fix loop (`--pr` only)

After creating the PR, monitor checks until they resolve:

1. Run `gh pr checks <PR_NUMBER> --watch` to wait for CI results
2. If checks **pass** → proceed to merge-completion wait
3. If checks **fail**:
   a. Read the failing check logs: `gh run view <RUN_ID> --log-failed`
   b. Identify and fix the code issues locally
   c. Stage, commit (with `fix:` tag), and push
   d. Go back to step 1 — repeat until all checks pass
4. Do NOT give up after one attempt. Keep iterating until checks are green.

### Post-merge cleanup (`--pr` only)

After checks pass, wait for automerge to complete before cleanup:

1. Poll every 10s: `gh pr view <PR_NUMBER> --json state --jq '.state'` until `MERGED` (timeout 2 min → report PR URL and stop)
2. Switch to resolved base and pull: `git checkout <resolved-base> && git pull`
3. **If `--promote`:** Skip branch deletion — both sides are protected.
4. **Otherwise:** Delete feature branch if not protected (`main`, `develop`, `staging`):
   - Local: `git branch -d <feature-branch>`
   - Remote: `git push origin --delete <feature-branch>`

## Output

Show `git log --oneline -n` (n = number of commits created this execution).

PR mode: Include URL with all commits.
