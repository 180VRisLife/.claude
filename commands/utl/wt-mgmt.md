The user wants a comprehensive overview of git worktrees in this repository.

## Phase 1: Gather Worktree Information

Run these commands to collect complete worktree state:

```bash
# List all worktrees with branch and commit info
git worktree list

# Get detailed info for each worktree
git worktree list --porcelain

# Show current branch and repo status
git status

# Check if we're in a worktree
git rev-parse --git-dir
```

## Phase 2: Session Analysis

Load session tracking data from `~/.claude/worktree-sessions/`:

1. **Read all session JSON files** to identify active Claude sessions
2. **Cross-reference with `git worktree list`** to find:
   - **Active worktrees** - Has session file with recent activity (<5min)
   - **Inactive worktrees** - Has session file but stale (>5min, <24h)
   - **Orphaned worktrees** - No session file, indicating abandoned work
3. **Check for stale sessions** - Session files >24h old (should be auto-cleaned)

## Phase 3: Merge Status Check

For each worktree, determine merge readiness:

```bash
# For each worktree, check if it can merge cleanly
cd <worktree-path>
git fetch origin  # Ensure we have latest

# Detect base branch (what this worktree branched from)
# Try common branches: main, master, develop
for branch in main master develop; do
  git show-ref --verify --quiet refs/heads/$branch && base_branch=$branch && break
done

# Check merge status
git merge-tree $(git merge-base $base_branch HEAD) $base_branch HEAD

# Count commits ahead
git rev-list --count $base_branch..HEAD

# Check last commit time
git log -1 --format='%ar'
```

**Merge status categories:**
- ✅ **Ready to merge** - No conflicts, commits ahead, recent activity
- ⚠️  **Has conflicts** - Would conflict with base branch, needs resolution
- 🔄 **Up to date** - No commits ahead, can be deleted
- ⏸️  **Stale** - No commits for >7 days, likely abandoned

## Phase 4: Present Status Report

Display results in clear, actionable format:

### Current Worktree (if applicable)
```
📍 You are currently in: <worktree-name>
   Branch: <branch-name>
   Base: <base-branch>
   Commits ahead: <count>
   Last commit: <time-ago>
```

### All Worktrees Overview

**Format for each worktree:**

```
🌳 <worktree-name> (<path>)
   Branch: <branch-name> | Base: <base-branch>
   Status: [Active/Inactive/Orphaned]
   Commits: <count> ahead of <base-branch>
   Last commit: <time-ago>
   Session: [Active Claude session / No active session / Stale session]
   Merge status: [Ready ✅ / Conflicts ⚠️ / Up to date 🔄 / Stale ⏸️]

   [If conflicts exist:]
   Conflicts in:
   - path/to/file1.js
   - path/to/file2.py

   Suggested action: [Merge and cleanup / Resolve conflicts / Delete / Continue working]
```

### Cleanup Suggestions

**Identify candidates for cleanup:**

1. **Safe to delete** (no commits, or fully merged):
   ```
   🗑️  Can be safely deleted:
   - <worktree-name> (up to date with <base-branch>, no commits)
   - <worktree-name> (fully merged to <base-branch>)
   ```

2. **Should merge** (ready to merge, no conflicts):
   ```
   ✅ Ready to merge and cleanup:
   - <worktree-name> (<count> commits, no conflicts)
     Run: cd <path> && /git (will auto-merge and cleanup)
   ```

3. **Needs attention** (conflicts or stale):
   ```
   ⚠️  Needs resolution:
   - <worktree-name> (conflicts with <base-branch>)
     Conflicts in: <file-list>
     Suggest: Resolve conflicts or abandon changes

   ⏸️  Stale worktrees (no commits for >7 days):
   - <worktree-name> (last commit: <time-ago>)
     Suggest: Continue work or delete if abandoned
   ```

4. **Orphaned sessions** (session file exists but no worktree):
   ```
   🧹 Orphaned session files (worktree already deleted):
   - <session-hash>.json (worktree: <path>)
     Will auto-cleanup these stale sessions.
   ```

## Phase 5: Interactive Actions

After presenting the report, offer actionable next steps:

**Ask the user:**
```
What would you like to do?

1. Merge and cleanup ready worktrees
2. Delete specific worktrees
3. Show conflicts for a specific worktree
4. Clean up all orphaned sessions
5. Nothing - just showing status
```

### Action: Merge and Cleanup
**If user chooses to merge:**
1. Confirm which worktrees to merge (or "all ready")
2. For each worktree:
   ```bash
   cd <worktree-path>
   # Verify no conflicts (already checked)
   git checkout <base-branch>
   git merge <worktree-branch> --no-ff -m "Merge <worktree-branch>"
   cd <original-path>
   git worktree remove <worktree-path>
   ```
3. Clean up session files
4. Show summary of merged work

### Action: Delete Worktrees
**If user chooses to delete:**
1. Confirm worktree names to delete
2. **Warning:** If worktree has uncommitted changes:
   ```
   ⚠️  Warning: <worktree-name> has uncommitted changes!
   Files: <list>

   Are you sure you want to delete? (yes/no)
   ```
3. Remove worktrees:
   ```bash
   git worktree remove <worktree-path>
   # If locked or has changes:
   git worktree remove --force <worktree-path>
   ```
4. Clean up session files

### Action: Show Conflicts
**If user wants to see conflicts:**
1. Show detailed conflict preview for specified worktree
2. Use `git merge-tree` output to show conflicting sections
3. Suggest resolution strategies:
   - Accept ours/theirs
   - Manual merge
   - Abandon changes

### Action: Clean Orphaned Sessions
**Automatic cleanup:**
```bash
# Remove session files for non-existent worktrees
# Remove session files >24h old
```

Show summary of cleaned files.

## Key Reminders

- **One Claude session per worktree** - Prevents conflicting changes
- **Regular cleanup** - Don't let orphaned worktrees accumulate
- **Merge early, merge often** - Don't let branches get stale
- **Check conflicts before merging** - Avoid messy merge commits
- **Use `/git` in worktrees** - It will handle merge and cleanup automatically

## Integration with `/git`

**Note:** When you run `/git` from within a worktree, it will:
1. Create all necessary commits
2. Detect the base branch automatically
3. Ask if you want to merge back and cleanup
4. Handle the merge and worktree removal

So you rarely need to manually merge worktrees - `/git` handles the full workflow!
