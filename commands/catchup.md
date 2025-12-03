# Catchup - Reload Work-in-Progress Context

Read all uncommitted git changes into this conversation and provide a summary of the work in progress.

## Steps

1. Run `git status` to see all modified, added, and untracked files
2. Run `git diff` to see unstaged changes
3. Run `git diff --cached` to see staged changes
4. Read the key modified files to understand the current state
5. Summarize:
   - What feature/fix is being worked on
   - What's been completed
   - What appears to be remaining
   - Any potential issues or blockers visible in the code

## Optional: Load GitHub Issue

If an issue number is provided as $ARGUMENTS, also fetch that GitHub issue and relate the changes to it.
