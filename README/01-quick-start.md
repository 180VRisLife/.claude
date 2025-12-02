# Quick Start

## First Time in a New Project

```
/0-workspace
```

This command automatically detects your project type (visionOS, iOS, macOS, webdev, streamdeck, or default) and copies the appropriate domain configuration from the Library to your local `.claude/` folder.

**What it does:**
- Analyzes project files to detect domain (imports, dependencies, config files)
- Creates `.claude/` directory in project workspace
- Copies domain-specific agents, commands, hooks, guides, and templates
- Merges settings and creates domain marker file

**Optional:** Specify domain explicitly:
```
/0-workspace <domain>
```

After running `/0-workspace`, you'll have access to:
- Domain-specific workflow commands (`/1-requirements` through `/5-execution`)
- Specialized agents for your platform
- Keyword-triggered workflow guides
- File templates for documentation
