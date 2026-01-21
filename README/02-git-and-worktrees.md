# Git and Worktrees

## Catchup Command

```text
/catchup [issue#]
```

Reloads work-in-progress context when resuming a session:

- Reads all uncommitted changes (staged and unstaged)
- Summarizes what's being worked on and what remains
- Optionally fetches a GitHub issue to relate changes to it

## Git Commit Command

```text
/git
```

Analyzes git changes and orchestrates commits:

- **Small changes** (<3 files, single feature): Single commit
- **Large changes** (3+ files, multiple features): Groups into logical batches, multiple commits

## Parallel Development with Git Worktrees

Use worktrees to run multiple Claude instances on different features simultaneously.

### Primary Workflow

**1. Initialize worktree for isolated development:**

```text
/worktree [feature description]
```

Auto-generates directory and branch name (e.g., `.worktrees/user-authentication/`)

**2.** Start a new Claude Code session in the worktree directory to implement the feature

**3. Commit, merge, and cleanup:**

```text
/git
```

Automatically handles commits, merges back to base branch, removes the worktree, and deletes the branch.

### Key Points

- Each worktree is created in `.worktrees/` subdirectory within your repo
- Prevents worktrees from different projects mixing together in your workspace
- Enables multiple Claude instances on different features without conflicts
- Main workspace remains untouched while working in worktree
- `/git` handles the full workflow (commit → merge → cleanup → branch deletion)
