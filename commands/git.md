I have just finished one or more changes. It's time to commit changes.

## Phase 1: Analysis

### Cleanup Temporary Files

Before analyzing changes, clean up temporary files that should never be committed:

```bash
# Remove PROMPT.md if it exists (created by /wt command)
if [ -f "PROMPT.md" ]; then
  rm PROMPT.md
  echo "🧹 Cleaned up PROMPT.md"
fi
```

### Analyze Changes

Analyze git diffs, running any additional `git` commands necessary to understand the scope of change.

### ⛔️ CRITICAL: Debugging Code Check

**ABSOLUTE RULE: DEBUG LOGGING MUST NEVER BE COMMITTED**

**ONLY exceptions:**
- ✅ Debug UI features (settings panels, diagnostic screens explicitly for users)
- ✅ Release diagnostics (production logging infrastructure like DebugLogger)

**Everything else is FORBIDDEN:**

**MANDATORY scan for these patterns across ALL changed files:**
- **Console/print statements:** console.log, console.debug, console.warn, print(), NSLog, println, debugPrint, os_log (DEBUG only)
- **Debug flags:** DEBUG = true, isDebug = true, isDevelopment = true
- **Breakpoint markers:** // DEBUG, // TEMP, // REMOVE, // FIXME (debugging context)
- **Verbose logging:** Excessive logging that's only useful during development
- **Test data:** Hardcoded test values, mock data generators, fake API responses
- **Commented debugging code:** Blocks of commented-out debugging statements

**If ANY debugging code is found:**

This is a **HARD STOP**. You MUST:

1. **List each instance** with file path and line number
2. **Show a snippet** of the debugging code
3. **STOP and declare:** "⛔️ I found debugging code in the changes. This CANNOT be committed unless it's part of a debug UI or release diagnostics."
4. **Ask explicitly:** "Is this part of a debug UI feature or release diagnostics infrastructure? If not, I need to remove it before committing."

**If user confirms it's NOT an exception:**
- **Default action:** Remove the debugging code immediately
- Create a cleanup commit first: `git add [files] && git commit -m "chore: remove debug logging"`
- Then proceed with the main commit

**If user confirms it IS an exception (debug UI or release diagnostics):**
- Verify it's properly gated or conditionally compiled for release builds
- Add a note in the commit message: "Includes debug UI/diagnostics feature"
- Proceed with commit

**NO other responses are acceptable.** Debugging code does not belong in version control unless explicitly designed for end-users or production diagnostics.

### Commit Readiness Check

After the debugging check, assess if other changes are production-ready. Look for:

- **TODO/FIXME comments:** Incomplete implementations
- **Commented-out code:** Large blocks that should be removed
- **Temporary files:** Test files, scratch files, debug outputs
- **Hardcoded values:** Credentials, API keys, or config that should be externalized
- **Incomplete error handling:** Try/catch blocks without proper handling

**If issues found:**
1. List the specific problems with file paths and line numbers
2. Ask the user: "These changes don't appear ready for commit. Should I proceed anyway?"
3. Provide your reasoning for why they're not ready
4. **If user says proceed:** Continue with commit, but add issues to a cleanup reminder list

**Check for unnecessary files:** Identify empty test files or temporary files that shouldn't be committed. Add them to the cleanup reminder list if found but user wants to proceed.

### Amend vs New Commit Decision

Before creating a new commit, check if changes should amend the last commit instead:

**Run these checks:**
```bash
# Check last commit authorship
git log -1 --format='%an %ae'

# Check if branch has been pushed
git status

# Check last commit message and timestamp
git log -1 --format='%h %s (%cr)'
```

**Amend if ALL conditions are true:**
1. ✅ Last commit author matches current git user (don't amend others' commits)
2. ✅ Branch shows "Your branch is ahead" or equivalent (not pushed to remote)
3. ✅ Changes are directly related to last commit's scope

**Examples when to amend:**
- Fixing typos in code just committed
- Adding forgotten files to a feature just committed
- Addressing linting/formatting issues from pre-commit hooks
- Small refinements to logic in recent commit

**Examples when NOT to amend:**
- Changes address different feature or bug
- Commit has been pushed (force push required)
- Author is different (collaborative work)
- Changes are substantial enough to warrant separate history entry

**If amending:**
```bash
git add [files]
git commit --amend --no-edit  # Keep same message
# OR
git commit --amend -m "updated message"  # Update message
```

**If unsure:** Ask user "These changes seem related to your last commit '[message]' from [time ago]. Should I amend that commit or create a new one?"

## Phase 2: Commit Strategy

### For Small Changes
**When:** Single feature, <3 files, or trivial changes
**Action:** Stage and commit: `git add [files] && git commit -m "type(scope): message"`

### For Large Changes
**When:** Multiple features, 3+ files with substantial changes, or complex modifications
**Action:** Group related changes and commit in logical batches

Example commit workflow for large changes:
```bash
# Feature A
git add src/feature-a.js src/feature-a-utils.js
git commit -m "feat(feature-a): implement new feature"

# Feature B
git add src/feature-b.js
git commit -m "feat(feature-b): add related feature"

## Phase 3: Final Steps

1. Stage and commit changes in logical batches
2. List all commits created with their messages
3. Run `git status` to verify all changes are committed
4. **If in worktree:** Check if in worktree and proceed to Phase 4
5. **If NOT in worktree:** Skip to Cleanup Reminders section

## Phase 4: Worktree Merge & Cleanup (Worktrees Only)

**⚠️ CRITICAL: This phase ONLY runs when you are in a git worktree AND user explicitly confirms.**

**This phase is ALWAYS opt-in. NEVER auto-merge or auto-cleanup.**

### Step 1: Detect Worktree Context

```bash
# Check if we're in a worktree
git rev-parse --git-dir
# If output contains "worktrees", we're in a worktree
```

**If NOT in worktree:** Skip this entire phase and go to Cleanup Reminders.

### Step 2: Commit Summary

Display summary of what was just committed:
```
✅ All commits complete!

Created <count> commit(s) in worktree <worktree-name>:

1. <commit-hash> - <commit-message>
2. <commit-hash> - <commit-message>
...

Current branch: <current-branch>
Working directory: Clean ✓
```

### Step 3: Detect Base Branch

Find the branch this worktree was created from:
```bash
# Try common base branches in order
for branch in main master develop; do
  git show-ref --verify --quiet refs/heads/$branch && base_branch=$branch && break
done
```

### Step 4: Pre-Merge Analysis

Before asking user, analyze the merge status:
```bash
# Check for merge conflicts
git fetch origin  # Ensure up to date

# Test merge (don't actually merge yet)
git merge-tree $(git merge-base $base_branch HEAD) $base_branch HEAD
```

**If conflicts detected:**
```
⚠️  Warning: Merging to <base-branch> will cause conflicts in:
- path/to/file1.js
- path/to/file2.py

You'll need to resolve these conflicts before merging.
```

**If clean merge:**
```
✅ Can merge cleanly to <base-branch>
```

### Step 5: **MANDATORY** User Confirmation

**🛑 STOP HERE - DO NOT PROCEED WITHOUT USER CONFIRMATION 🛑**

**Present clear choice to user:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Commit workflow complete!

Would you like to merge and cleanup this worktree now?

Your commits:
  • <commit-message-1>
  • <commit-message-2>

If you proceed, I will:
  1. Switch to <base-branch>
  2. Merge <current-branch> (--no-ff merge)
  3. Remove this worktree
  4. Delete the branch (local and remote if pushed)
  5. Clean up session tracking

Merge status: [✅ Clean merge | ⚠️  Has conflicts]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Then WAIT for user response. Do NOT proceed until user explicitly answers.**

**User responses:**
- **yes** / **proceed** / **merge** → Proceed to Step 6
- **no** / **not yet** / **later** → Skip to Cleanup Reminders (preserve worktree)
- **conflicts** / **show conflicts** → Display detailed conflict preview, then ask again
- **Any other response** → Assume "no" and skip to Cleanup Reminders

### Step 6: Execute Merge & Cleanup

**Only if user confirmed "yes":**

```bash
# Save current worktree path and branch
worktree_path=$(git rev-parse --show-toplevel)
worktree_branch=$(git rev-parse --abbrev-ref HEAD)

# Switch to base branch (in main repo)
cd <main-repo-path>
git checkout $base_branch

# Merge the worktree branch
git merge $worktree_branch --no-ff -m "Merge feature: <brief-description>"

# Verify merge succeeded
if [ $? -eq 0 ]; then
  echo "✅ Merge successful"

  # Remove the worktree
  git worktree remove $worktree_path

  # Delete the local branch (merged branches should be cleaned up)
  git branch -d $worktree_branch
  echo "✅ Local branch deleted"

  # Check if branch exists on remote and delete it
  if git show-ref --verify --quiet refs/remotes/origin/$worktree_branch; then
    git push origin --delete $worktree_branch
    echo "✅ Remote branch deleted"
  fi

  # Clean up session tracking file
  # (Hook will handle this automatically)

  echo "✅ Worktree cleaned up"
else
  echo "❌ Merge failed - worktree preserved"
  cd $worktree_path  # Return to worktree
fi
```

**If merge has conflicts:**
1. Show conflict files
2. Offer to abort merge: `git merge --abort`
3. Suggest manual resolution or abandon worktree
4. **Do NOT** remove worktree if merge failed

**On success:**
```
🎉 Successfully merged and cleaned up!

Merged commits:
- <commit-message-1>
- <commit-message-2>

✅ Worktree <worktree-name> has been removed
✅ Branch <branch-name> has been deleted (local and remote)

You are now on branch <base-branch>.

💡 If issues arise: Fix forward with new commits or create hotfix worktree via `/wt hotfix-name`
```

**On failure:**
```
❌ Merge encountered conflicts. Worktree preserved for manual resolution.

You can:
1. Resolve conflicts in the worktree
2. Run /git again after resolving
3. Delete the worktree via /wt-mgmt or `git worktree remove <path>`
```

### Cleanup Reminders

**If user declined merge/cleanup (worktree context):**
```
✅ Commits saved in worktree!

You can continue working in this worktree, or merge later via:
  • Run /git again when ready to merge
  • Use /wt-mgmt to check worktree status
  • Manually: git checkout main && git merge <branch> && git worktree remove <path>
```

**If any issues were flagged but user chose to proceed:**

Display a clear reminder section after commits are complete:

```
⚠️  Cleanup Reminders for Next Commit:

1. [Issue type] in [file:line] - [specific problem]
2. [Issue type] in [file:line] - [specific problem]

Please address these before moving forward with new features.
```

This ensures technical debt is tracked and doesn't accumulate.

### Commit Messages
- Follow Conventional Commits: `type(scope): subject`
- Types: feat, fix, docs, style, refactor, test, chore
- Group related changes in logical commits
- Keep messages concise and descriptive

## Key Reminders

- **Small changes:** Single commit with clear message
- **Large changes:** Multiple logical commits, grouped by feature/type
- **Always check for debugging code** before committing
- **Assess commit readiness** to avoid committing incomplete work
- **Consider amending** recent commits when appropriate
- **Worktree workflow:** ALWAYS ask user before merging/cleanup - commits are saved, merge is optional
- **User controls merge timing:** User may want to make more commits before merging
- **Clean merge only:** Don't remove worktree if merge has conflicts - preserve for resolution
- **Branch cleanup:** After successful merge, delete both local and remote branches (industry standard)
- **Default to no:** If user response is unclear, preserve the worktree
