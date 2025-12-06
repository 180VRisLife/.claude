# Quick Start

## First Time in a New Project

```
/0-workspace
```

This command automatically detects your project type (visionOS, iOS, macOS, webdev, streamdeck, or default) and sets up domain-specific infrastructure.

**What it does:**
- Analyzes project files to detect domain (imports, dependencies, config files)
- Creates `.claude/` directory with domain marker
- Installs domain-specific templates (debug logger, git info, overlays)
- Sets up `.gitignore` with domain patterns
- Creates `.worktrees/` directory for worktree support

**Optional:** Specify domain explicitly:
```
/0-workspace <domain>
```

After running `/0-workspace`, you'll have:
- **Installed locally:** Domain-specific templates in your project
- **Available globally:** Base agents, workflow commands, and guides from `~/.claude/`
