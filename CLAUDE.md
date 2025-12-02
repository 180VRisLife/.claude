# CLAUDE.md

This file provides guidance to Claude Code when working with code in this repository.

## Git Policy

**ABSOLUTE RULE: Claude NEVER commits without the `/git` command.**

- **ONLY** commit when user runs `/git` explicitly
- **DO NOT** commit on verbal requests ("commit this", "make a commit", etc.)
- **ALWAYS** respond: "Please run `/git` to orchestrate commits properly"
- **NEVER** commit after completing tasks, even if user says "and commit it"

**Debug Logging:** Never commit debug logging. The `/git` command enforces this.

## Git Worktrees

Use `/wt feature-name` to create isolated worktrees for non-trivial work.

**Workflow:**
1. `/wt feature-name` - Creates worktree, saves prompt to PROMPT.md, stops
2. User navigates to `.worktrees/feature-name` and starts new Claude session
3. Work in new session, reference PROMPT.md for context
4. `/git` commits and asks about merging back

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

After `/0-workspace`, agents available in `./.claude/agents/`:

**Base Agents (universal):**
- **@code-finder** - DEFAULT for code searches (Haiku, fast/cheap)
- **@code-finder-advanced** - Deep investigation (Sonnet, thorough)
- **@root-cause-analyzer** - Bug diagnosis (investigation only)
- **@implementor** - Executes tasks from plans
- **@library-docs-writer** - Fetches/compresses library docs

**Specialist Agents (domain-specific):**
- **default**: backend-feature, frontend-feature, fullstack-feature
- **iOS/macOS/visionOS**: ui-swiftui, networking-data, architecture, etc.
- **webdev**: react-component, api-endpoint, fullstack-feature
- **streamdeck**: action-feature, integration-feature, ui-feature

See `./.claude/agents/specialist/` for your domain's complete roster.

## File Size Guidelines

### Philosophy

Optimize for **logical coherence** and **developer experience** rather than arbitrary line counts:
- **Logical coherence**: Does this file cover one complete concept?
- **Human readability**: Can a developer scan this in 2-3 minutes?
- **Load relevance**: Auto-loaded files (CLAUDE.md) must stay tight; on-demand files can be larger
- **Search efficiency**: One searchable file often beats navigating multiple fragments

**Modern reality**: File size is less critical than logical organization and relevance. Claude tracks token budget automatically.

## Development Notes

- **Most changes don't need CLAUDE.md updates** - Use feature documentation instead
- **Template first** - Always read default template before creating domain-specific versions
- **Organize logically** - Group files into folders and subfolders that reflect conceptual relationships
