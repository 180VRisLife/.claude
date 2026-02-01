# Scripts

## Automated Maintenance

Automated maintenance tasks for this repository are handled by **Hammerspoon**, not scripts in this directory.

See: `DevKit/hammerspoon/modules/claude_disk_watcher.lua`

### What it does

- **Plan archiving** - Archives plan files older than 24 hours to `plans/archive/`
- **Disk space monitoring** - Warns when disk space is low
