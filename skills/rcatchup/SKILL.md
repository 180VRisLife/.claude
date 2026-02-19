---
name: rcatchup
description: Catch up on changes made while you were away (works after rget or rpush handoff)
user-invocable: true
disable-model-invocation: true
argument-hint: "[what to continue working on]"
allowed-tools: Read, Bash(cat:*), Bash(git:*), Grep, Glob
---

**Arguments:** `$ARGUMENTS` (optional — what to focus on or continue)

## Context

- Project: !`basename "$(pwd)"`
- Changes diff: !`cat "/tmp/local-changes-$(basename "$(pwd)").diff" 2>/dev/null || echo "(no diff file found)"`
- Current state: !`git diff --stat HEAD 2>/dev/null || echo ""`

## Instructions

This is a handoff — someone else made changes while you were away. The **Changes diff** above shows exactly what was changed. This could be either direction:

- **Remote → local** (`rget`): A remote Claude session worked on the project, user pulled results down for local review or continuation
- **Local → remote** (`rpush`): The user pulled files locally, made fixes (build errors, tweaks, etc.), and pushed them back

1. Summarize the changes concisely (which files, what was done)
2. Read any modified files to fully understand current state
3. If arguments provided: use the changes as context and execute that instruction
4. If no arguments: summarize state and ask what to work on next
