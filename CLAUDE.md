# CLAUDE.md

This file provides guidance to Claude Code when working with code in this repository.

## Git Policy

**ABSOLUTE RULE: Claude NEVER commits without the `/utl:git-commit` command.**

- **ONLY** commit when user runs `/utl:git-commit` explicitly
- **DO NOT** commit on verbal requests ("commit this", "make a commit", etc.)
- **ALWAYS** respond: "Please run `/utl:git-commit` to orchestrate commits properly"
- **NEVER** commit after completing tasks, even if user says "and commit it"

**Debug Logging:** Never commit debug logging. The `/utl:git-commit` command enforces this.

## Build Verification

**After any non-trivial code change, build/compile and fix until clean.**

- Run the appropriate build command (compile, lint, type-check, etc.)
- Fix ALL errors AND warnings—not just errors
- Repeat until zero issues remain
- **Skip only for:** one-line changes, documentation-only changes, or config tweaks

## Documentation-First Policy

**Before implementing features with external libraries, ALWAYS check `.docs/` first.**

**Workflow:**
1. When a task involves external libraries (SwiftUI, React, Prisma, etc.), search `.docs/` for existing documentation
2. If docs exist → use them as the source of truth (no web search or MCP needed)
3. If docs are missing → proactively tell user: "I need documentation for [library/feature]. Should I create it?"
4. Create docs via `/utl:documentation --feature [topic]` or fetch directly with MCP tools

**Documentation Structure:**
- `.docs/` - Project-level API references grouped by cluster
- `.docs/features/` - Individual feature documentation
- `.docs/index.md` - Inventory of all documentation with gap analysis

**Why This Matters:**
- Local docs are LLM-optimized (only non-obvious info)
- Faster than external lookups
- Consistent source of truth across sessions
- Proactive gap detection prevents errors

## Agent-First Policy

**CRITICAL: Default to agents for all non-trivial tasks.**

**Use agents when:**
- Multi-step tasks or analysis required
- Code searches, pattern analysis, architecture understanding
- Debugging, root cause analysis
- Feature implementation
- Anything requiring thinking about approach

**Direct tools ONLY for:**
- Reading a specific known file
- One-off grep with exact pattern
- Simple single-file edit

**Suggest new agents:** If an appropriate agent doesn't exist for the task, proactively suggest creating one:
- "An agent for database schema analysis doesn't exist - should we create @database-schema-analyzer?"
- Provide the user with the "New Feature Prompt" from ~/.claude/README.md to create it

## Agent Types

Base agents are available globally in `~/.claude/agents/`:

- **@code-finder** - DEFAULT for code searches (Haiku, fast/cheap)
- **@code-finder-advanced** - Deep investigation (Sonnet, thorough)
- **@root-cause-analyzer** - Bug diagnosis (investigation only)
- **@implementor** - Executes tasks from plans
- **@docs-fetcher** - Fetch and compress external documentation

**Subagent Pattern:** Base agents are building blocks. When creating project-specific agents:
- **Delegate to base agents** for their specialties (use @code-finder for searches, @root-cause-analyzer for debugging)
- **Don't duplicate** base agent functionality in specialist agents
- **Compose workflows** by orchestrating multiple base agents
- Example: A `@feature-builder` agent should spawn @code-finder to understand existing patterns, then @implementor for execution

## File Size Guidelines

### Philosophy

Optimize for **logical coherence** and **developer experience** rather than arbitrary line counts:
- **Logical coherence**: Does this file cover one complete concept?
- **Human readability**: Can a developer scan this in 2-3 minutes?
- **Load relevance**: Auto-loaded files (CLAUDE.md) must stay tight; on-demand files can be larger
- **Search efficiency**: One searchable file often beats navigating multiple fragments

**Modern reality**: File size is less critical than logical organization and relevance. Claude tracks token budget automatically.

## Development Notes

- **Most changes don't need CLAUDE.md updates** - Code is the documentation; use inline comments when needed
- **Template first** - Always read default template before creating domain-specific versions
- **Organize logically** - Group files into folders and subfolders that reflect conceptual relationships

## Subdirectory Documentation

When a subdirectory has unique conventions not covered by parent CLAUDE.md, suggest: "Should I create a CLAUDE.md for [directory] documenting [specific patterns]?"
