# Git and Worktrees

## Git Command

```
/git
```

Analyzes git changes and orchestrates commits:
- **Small changes** (<3 files, single feature): Single commit
- **Large changes** (3+ files, multiple features): Groups into logical batches, multiple commits

## Parallel Development with Git Worktrees

Use worktrees to run multiple Claude instances on different features simultaneously.

### Primary Workflow

**1. Create worktree for isolated development:**
```
/wt [feature description]
```
Auto-generates directory and branch name (e.g., `.worktrees/user-authentication/`)

**2. Start a new Claude Code session in the worktree directory to implement the feature**

**3. Commit, merge, and cleanup:**
```
/git
```
Automatically handles commits, merges back to base branch, removes the worktree, and deletes the branch.

### Managing Multiple Worktrees

```
/wt-mgmt
```

- Check status of all worktrees (merge readiness, conflicts, stale branches)
- Manage multiple parallel worktrees
- Clean up orphaned or abandoned worktrees
- Resolve conflicts before merging

### Key Points

- Each worktree is created in `.worktrees/` subdirectory within your repo
- Prevents worktrees from different projects mixing together in your workspace
- Enables multiple Claude instances on different features without conflicts
- Main workspace remains untouched while working in worktree
- `/git` handles the full workflow (commit → merge → cleanup → branch deletion)
