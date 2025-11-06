I have just finished one or more changes. It's time to commit changes.

## Phase 1: Analysis

Analyze git diffs, running any additional `git` commands necessary to understand the scope of change.

### Debugging Code Check

**ALWAYS check for debugging code in diffs:**

Look for these patterns across all changed files:
- **Console/print statements:** console.log, console.debug, print(), NSLog, println, debugPrint
- **Debug flags:** DEBUG = true, isDebug, isDevelopment
- **Breakpoint markers:** // DEBUG, // TEMP, // REMOVE
- **Verbose logging:** Excessive logging that's only useful during development
- **Test data:** Hardcoded test values, mock data generators

**If ANY debugging code is found:**
1. List each instance with file path and line number
2. Show a snippet of the debugging code
3. Ask: "I found debugging code in the changes. Should I remove it before committing, or do you want to commit it?"
4. **If user wants to remove:** Create a cleanup commit first, then proceed with main commit
5. **If user wants to keep:** Note it in commit context and continue

**Common responses:**
- "Remove it" → Clean up debugging code, stage, commit cleanup separately
- "Keep it" / "Commit it" → Proceed with debugging code included
- "Remove [specific ones]" → Selective cleanup of mentioned instances

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
3. ✅ Last commit is recent (within last hour) AND addresses same feature/fix
4. ✅ Changes are directly related to last commit's scope

**Examples when to amend:**
- Fixing typos in code just committed
- Adding forgotten files to a feature just committed
- Addressing linting/formatting issues from pre-commit hooks
- Small refinements to logic in recent commit

**Examples when NOT to amend:**
- Last commit was hours/days ago
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

### Cleanup Reminders

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
