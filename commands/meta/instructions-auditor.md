---
description: Review agent context files (CLAUDE.md, agents, prompts) for bloat and optimization
---

## Context

You are reviewing coding agent context files for optimization based on context
window efficiency principles.

**Target file(s) to review:**

- If a path argument is provided, review that specific file
- Otherwise, review `./CLAUDE.md` (if exists) AND `~/.claude/CLAUDE.md`

**Arguments provided:** $ARGUMENTS

## Your Task

Use the `@instructions-auditor` agent to analyze the target file(s).

After the agent completes, summarize key findings and ask if the user wants to:

1. See the full detailed report
2. Apply the suggested cleanups
3. Extract identified workflows into skills/agents
