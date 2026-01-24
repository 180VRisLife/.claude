---
description: Resume work by understanding user's intent first, then analyzing changes through that lens
---

**Arguments:** `$ARGUMENTS` - What to focus on or accomplish (optional)

## Context

- Git status: !`git status`
- Diff: !`git diff HEAD`
- Branch: !`git branch --show-current`
- Recent commits: !`git log --oneline -10`
- Git root: !`git rev-parse --show-toplevel 2>/dev/null || echo "Not a git repo"`
- CWD: !`pwd`

## Multi-Repo Detection

**If not in a git repo:** Check for repos in subdirectories. If found, analyze all repos and present combined summary. Focus on repo with changes, or ask if multiple have changes.

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
