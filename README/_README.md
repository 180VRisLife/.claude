# Claude Development Configuration

A comprehensive configuration system for Claude to build production-ready applications across any domain with parallel agent orchestration, automated workflows, and extensible templates.

## Quick Reference

| Command | Purpose |
|---------|---------|
| `/0-workspace` | Initialize domain config in current project |
| `/1-5` | Workflow commands (requirements → execution) |
| `/git` | Analyze changes and orchestrate commits |
| `/wt [feature]` | Create isolated worktree for parallel development |
| `/catchup` | Reload WIP context from uncommitted changes |
| `/docs [lib]` | Force context7 MCP lookup for library docs |
| `/apple [query]` | Force apple-docs MCP lookup |

| Keyword | Purpose |
|---------|---------|
| `think` / `megathink` / `ultrathink` | Extended thinking (4K / 10K / 32K tokens) |
| `brainstorm` | Socratic discovery mode |
| `plan` | Research-only, no implementation |
| `implement` / `build` / `code` | Feature implementation guidance |
| `debug` | Debugging workflow |
| `investigate` / `research` | Code analysis |
| `parallel` | Agent delegation strategies |

## Documentation

| Doc | Contents |
|-----|----------|
| [01 - Quick Start](README/01-quick-start.md) | Initialize workspace with `/0-workspace` |
| [02 - Triggers & Guides](README/02-triggers-and-guides.md) | Thinking keywords, guide injector |
| [03 - Workflow Commands](README/03-workflow-commands.md) | `/1-requirements` through `/5-execution` |
| [04 - Git & Worktrees](README/04-git-and-worktrees.md) | `/git`, `/wt`, `/wt-mgmt` |
| [05 - Agents](README/05-agents.md) | Base agents (code-finder, implementor, etc.) |
| [06 - MCP Tools](README/06-mcp-tools.md) | MCP servers, `/docs`, `/apple` commands |
| [07 - Creation Templates](README/07-creation-templates.md) | New feature/domain prompts |
| [08 - Architecture](README/08-architecture-reference.md) | System architecture, hooks, templates |
