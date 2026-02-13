---
name: catchup
description: Resume work by understanding user's intent first, then analyzing changes through that lens
user-invocable: true
---

**Arguments:** `$ARGUMENTS` - What to focus on or accomplish (optional)

## Context

- Git status: !`git status -sb 2>/dev/null || echo "Not in git repo"`
- Diff: !`git diff HEAD --stat 2>/dev/null || echo ""`
- Branch: !`git branch --show-current 2>/dev/null || echo ""`
- Recent commits: !`git log --oneline -10 2>/dev/null || echo ""`
- Git root: !`git rev-parse --show-toplevel 2>/dev/null || echo "Not a git repo"`
- CWD: !`pwd`

## Multi-Repo Detection

**If not in a git repo:** Find repos via `find . -maxdepth 3 -name .git -type d`. For each repo found, gather status/diff/log. Present combined summary focusing on repos with uncommitted changes. If multiple repos have changes, ask which to focus on.

## Intent-Aware Analysis

Read diffs through the lens of parsed intent:
- **Relevant**: Changes that matter for the user's request
- **Completed**: What's done that the intent cares about
- **Remaining**: What the intent needs that isn't done yet

## Execution

| Intent Type | Action |
|-------------|--------|
| No args | Summarize changes, ask what to focus on |
| "What's left?" | Summarize remaining work, ask if should continue |
| Specific instruction | Execute using current state as context |
| Issue number | Fetch issue and relate to changes |

Create a todo list aligned to intent, then execute.
