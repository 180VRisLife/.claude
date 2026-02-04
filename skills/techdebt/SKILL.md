---
name: techdebt
description: Eliminate duplicate/dead code and simplify recently modified files
user-invocable: true
allowed-tools: Bash(git:*), Bash(npm:*), Read, Glob, Grep, Edit, Task
---

## Mode-Aware Execution

**Plan Mode:** Analyze and propose changes. Show file targets, agent orchestration plan, and validation decisions. 

Exit with plan for approval.

**Edit Mode:** Execute immediately - spawn agents, make changes, validate, report.

## Context

- Git status: !`git status`
- Diff: !`git diff HEAD`
- Branch: !`git branch --show-current`
- Recent commits: !`git log --oneline -10`
- Git root: !`git rev-parse --show-toplevel 2>/dev/null || echo "Not a git repo"`
- CWD: !`pwd`

## Multi-Repo Detection

If not in a git repo, check subdirectories for repos. Analyze all found, focus on those with changes.

## Complexity Analysis & Agent Orchestration

**code-simplifier (1-5 agents):** Scale based on diff size, file count, module diversity. 

Group files by directory or related functionality.

**build-validator:** Run if source or package files changed, or simplifications made. 

Skip for docs/config-only changes.

**verify-app:** Run if tests exist and critical paths modified. 

Skip for superficial or non-critical changes.

**instructions-auditor:** Run only if diff includes CLAUDE.md, agents/, skills/, prompts/, or .claude/.

## Execution Phases

1. **Code Simplification:** Spawn code-simplifier agents in parallel with file lists. 
	1. Focus: duplicates, dead code, unnecessary abstractions.
2. **Validation:** Spawn build-validator and verify-app in parallel as needed.
3. **Instructions Audit:** If instruction files modified, run instructions-auditor.

## Output

Report files processed, agents used, lines removed, consolidations made. Include validation results (+ outcome).
