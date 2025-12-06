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

# Get current repo root (whether in main repo or worktree)
repo_root=$(git rev-parse --show-toplevel)

# If we're in a worktree, get the main repo root
if [[ "$git_dir" == *"/worktrees/"* ]]; then
  # Extract main repo path from git dir
  main_repo_git=$(echo "$git_dir" | sed 's|/.git/worktrees/.*|/.git|')
  repo_root=$(dirname "$main_repo_git")
fi

# Worktree directory within repo
worktree_dir="$repo_root/.worktrees"

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
⚠️  Directory '$worktree_dir/$feature_name' already exists but is not a git worktree.

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

## Phase 4: Create Worktree and Save Context

Create the worktree with the normalized feature name and save the user's original prompt:

**Note:** The `.worktrees/` directory and `.gitignore` configuration are set up by `/init-workspace`. If you haven't run `/init-workspace` yet, the directory will be created automatically here.

```bash
# Create .worktrees directory if it doesn't exist (fallback)
mkdir -p "$worktree_dir"

# Create worktree in .worktrees subdirectory
git worktree add "$worktree_dir/$feature_name" -b "$feature_name"

# Verify creation succeeded
if [ $? -eq 0 ]; then
  echo "✅ Worktree created successfully"
else
  echo "❌ Failed to create worktree"
  exit 1
fi

# Save user's original prompt to PROMPT.md in worktree root
cat > "$worktree_dir/$feature_name/PROMPT.md" << 'EOF'
# Original Task

[Insert the user's original prompt that triggered /wt here - everything after `/wt`]

---
*This file captures the original context for this worktree.*
*Reference it when planning/implementing in this workspace.*
*It will be auto-deleted before commits.*
EOF

echo "✅ Saved original prompt to PROMPT.md"
```

## Phase 5: Display Instructions to User (NO NAVIGATION)

**CRITICAL: Do NOT execute any navigation commands. Do NOT cd to the worktree. Do NOT change directories. ONLY display the information below to the user.**

Display this message to the user:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Worktree created: $worktree_dir/$feature_name

Branch: $feature_name (based on $base_branch)
Context: PROMPT.md saved with original task

To begin work, open a new terminal and run:

  cd $worktree_dir/$feature_name
  claude

Then reference PROMPT.md for the original task context.
The prompt file will be automatically deleted when you run /git.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**STOP HERE. DO NOT:**
- ❌ Navigate to the worktree
- ❌ Execute `cd` commands
- ❌ Change working directory
- ❌ Plan anything
- ❌ Implement anything
- ❌ Offer to do anything else

**This session's ONLY job was infrastructure setup. It is now complete. The user will manually navigate to the worktree and start a fresh Claude session.**

## Key Features

- **Auto-naming**: Converts your feature description to kebab-case automatically
- **Context preservation**: Saves your original prompt to PROMPT.md
- **Isolation**: Work independently without affecting main codebase
- **Parallel development**: Run multiple Claude sessions in different worktrees
- **Manual control**: You decide when to navigate to worktree and start working

## Workflow Integration

This creates a clean separation between setup and work:

1. **Setup** (current session): `/wt feature-name` creates infrastructure
2. **Navigate** (you): `cd .worktrees/feature-name`
3. **Work** (new session): Start `claude`, reference PROMPT.md, implement
4. **Commit** (new session): Run `/git` to commit (auto-deletes PROMPT.md)
5. **Merge** (new session): `/git` asks if you want to merge back and cleanup
