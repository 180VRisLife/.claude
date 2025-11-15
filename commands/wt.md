The user wants to create a new git worktree for isolated feature development.

## Phase 1: Extract and Normalize Feature Name

Parse the feature description from the user's input after `/wt`:

**Example inputs:**
- `/wt user authentication system` → `user-authentication-system`
- `/wt Fix bug in payment flow` → `fix-bug-in-payment-flow`
- `/wt SharePlay integration` → `shareplay-integration`

**Normalization rules:**
1. Convert to lowercase
2. Replace spaces with hyphens
3. Remove special characters (except hyphens)
4. Remove leading/trailing hyphens
5. Collapse multiple consecutive hyphens into one

## Phase 2: Verify Location and Check for Conflicts

Before creating the worktree, verify the environment:

```bash
# Check if we're currently in a worktree
git_dir=$(git rev-parse --git-dir)
if [[ "$git_dir" == *"/worktrees/"* ]]; then
  current_worktree=$(basename "$(git rev-parse --show-toplevel)")
  echo "ℹ️  You are currently in worktree '$current_worktree'"
  echo "Creating sibling worktree '$feature_name'"
  echo ""
fi

# Get current repo root
repo_root=$(git rev-parse --show-toplevel)

# Get parent directory (where worktree will be created)
parent_dir=$(dirname "$repo_root")

# Check if worktree already exists with this name
git worktree list | grep -q "$feature_name"
```

**If worktree already exists:**
```
⚠️  A worktree named '$feature_name' already exists.

Existing worktrees:
[output of git worktree list]

Please choose a different name or use /wt-mgmt to manage existing worktrees.
```

**If directory already exists but not a worktree:**
```
⚠️  Directory '$parent_dir/$feature_name' already exists but is not a git worktree.

Do you want to:
1. Choose a different name
2. Delete the existing directory and continue

Please specify your choice.
```

## Phase 3: Detect Base Branch

Determine which branch to base the new worktree on:

```bash
# Try common base branches in order
for branch in main master develop; do
  git show-ref --verify --quiet refs/heads/$branch && base_branch=$branch && break
done

# If none found, use current branch
if [ -z "$base_branch" ]; then
  base_branch=$(git rev-parse --abbrev-ref HEAD)
fi
```

## Phase 4: Create Worktree

Create the worktree with the normalized feature name:

```bash
# Create worktree in parent directory
git worktree add "../$feature_name" -b "$feature_name"

# Verify creation succeeded
if [ $? -eq 0 ]; then
  echo "✅ Worktree created successfully"
else
  echo "❌ Failed to create worktree"
  exit 1
fi
```

## Phase 5: Switch to Worktree Directory

Change to the newly created worktree:

```bash
cd "../$feature_name"
pwd  # Confirm location
```

## Phase 6: Confirm and Begin Implementation

```
🌳 Worktree created: $parent_dir/$feature_name
Branch: $feature_name (based on $base_branch)

Starting implementation...
```

Now immediately implement the feature described in the original `/wt` command. Work as you normally would - when done, let the user know they can review and run `/git` to merge back.

## Key Features

- **Auto-naming**: Converts your feature description to kebab-case automatically
- **Isolation**: Work independently without affecting main codebase
- **Parallel development**: Run multiple Claude instances in different worktrees
- **Automated cleanup**: `/git` handles merge and removal when you're done

## Integration with `/git`

When you run `/git` from within this worktree, it will:
1. Create all necessary commits
2. Detect the base branch automatically
3. Ask if you want to merge back and cleanup
4. Handle the merge and worktree removal

This creates a seamless workflow: `/wt` to create → work on feature → `/git` to merge and cleanup.
