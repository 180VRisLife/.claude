---
allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git commit:*)
description: Create a git commit
---

## Context

- Current git status: !`git status`
- Current git diff (staged and unstaged changes): !`git diff HEAD`
- Current branch: !`git branch --show-current`
- Recent commits: !`git log --oneline -10`

## Your task

Based on the above changes, create git commit(s).

**Small changes:** Create a single commit.

**Large changes (multiple features, 3+ files):** Group related changes into logical batches and create multiple commits.

You have the capability to call multiple tools in a single response. Stage and create the commit(s) using appropriate messages. Do not use any other tools or do anything else. Do not send any other text or messages besides these tool calls.
