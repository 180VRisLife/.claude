---
description: Review and analyze CLAUDE.md files for bloat and optimization opportunities
---

# Review Claude - Analyze CLAUDE.md for Optimization

## Context

You are reviewing CLAUDE.md files for optimization based on context window efficiency principles.

**Target file(s) to review:**
- If a path argument is provided, review that specific file
- Otherwise, review the current project's CLAUDE.md (if it exists) AND ~/.claude/CLAUDE.md

**Arguments provided:** $ARGUMENTS

## Your Task

Use the `@claude-md-reviewer` agent to analyze the CLAUDE.md file(s).

Spawn the agent with this prompt:

```
Review the following CLAUDE.md file(s) for optimization opportunities:

1. Read ~/.claude/CLAUDE.md (global instructions)
2. Read ./CLAUDE.md in the current working directory (if it exists)
3. If a specific path was provided in the arguments, read that file instead

For each file, provide:
- Metrics (lines, estimated tokens)
- Issues found (over-specification, cruft, allocation waste, missing essentials)
- Specific recommendations with line numbers
- A suggested cleaned version if the file is significantly bloated

Focus on actionable recommendations that will improve context window efficiency.
```

After the agent completes, summarize the key findings and ask if the user wants to:
1. See the full detailed report
2. Apply the suggested cleanups
3. Extract identified workflows into skills
