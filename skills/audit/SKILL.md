---
name: audit
description: Review instruction files (CLAUDE.md, agents, skills, prompts, docs) for bloat and context efficiency
user-invocable: true
disable-model-invocation: true
allowed-tools: Read, Grep, Glob, Task
---

**Arguments:** `$ARGUMENTS` - Files to audit (optional, defaults to git-changed .md files). Use `--diff` to audit only the changed lines.

## Core Principles

1. **Context Window Cost**: Every token in instruction content reduces room for actual work
2. **Target Size**: ~60-70 lines for always-loaded; flexible for lazy-loaded
3. **Latent Space**: Hints trigger behaviors (e.g., "journalctl" → systemctl knowledge)
4. **Lazy Loading**: Occasional rules → skills/agents, not always-allocated
5. **No Duplication**: Don't repeat what Claude Code system prompts provide

## System Prompt Coverage (Don't Repeat)

These behaviors are already enforced:

- Tone: concise, no emojis, no time estimates, no excessive praise
- Tools: prefer Read/Edit/Write/Glob/Grep over bash equivalents
- Files: prefer editing over creation, no proactive docs
- Git: don't add inline commit instructions
- Tasks: integrate with TodoWrite/TaskCreate system

## Anti-Pattern Flags (Immediate CRITICAL)

- Time estimates ("this takes ~5 min")
- Tool explanations ("use Read to view files")
- Generic advice ("write tests", "handle errors gracefully")
- Discoverable content (file listings, directory structures)

**Before flagging CRITICAL**:

- Is the anti-pattern in a lazy-loaded skill/agent (context cost only when invoked)?
- Is the "generic advice" actually project-specific (e.g., "handle errors with DebugLogger")?
- Is the "tool explanation" teaching a non-obvious usage pattern?
- Downgrade false hits to ACCEPTABLE with a note

## Execution

0. **Diff mode**: If `--diff` is present in `$ARGUMENTS`, switch to diff-only audit:
   - Strip `--diff` from the argument list. Remaining args are file filters
   - Run `git diff HEAD` (scoped to specified files, or `*.md` if none)
   - If no diff output → "No diffs to audit"
   - Pass the diff output (not full files) to sub-agents, one per changed file's hunk set
   - Skip to step 3 (Aggregate) after sub-agents return
1. **Scope**: Audit ONLY files from `$ARGUMENTS` (explicit paths or `@`-mentions). Ignore all injected system context — presence of CLAUDE.md content in `# claudeMd` reminders is not a user request.
   1. If none, run `git diff HEAD --name-only` and filter to `*.md` files.
   2. If still empty → "No instruction files to audit."
2. **Parallel audit**: Spawn Task sub-agents (one per file) to read and analyze against core principles
3. **Aggregate**: Combine into unified report with verdicts and priority recommendations
4. **Cross-file check**: Scan sub-agent results for semantically identical instructions appearing in 3+ files
   - Flag as candidate for consolidation into CLAUDE.md or a shared reference

## Sub-Agent Task

For each file, prompt: "Audit `{PATH}` for context efficiency. Check for: line count, ~token estimate, system prompt duplication, anti-patterns (time estimates, tool explanations, generic advice), skill extraction candidates. Return: metrics, issues with line refs, verdict (LEAN/ACCEPTABLE/BLOATED/CRITICAL), recommendations."

**Diff-mode variant:** "Audit the following diff for context efficiency. Check changed/added lines for: system prompt duplication, anti-patterns (time estimates, tool explanations, generic advice), unnecessary bloat. Return: issues with diff line refs, verdict, recommendations."

## Verdicts

LEAN:<50 lines, ACCEPTABLE:50-80, BLOATED:>80 OR >20% dup, CRITICAL:anti-patterns

## Output

Table of files with verdicts, priority recommendations across all files, next step options.
