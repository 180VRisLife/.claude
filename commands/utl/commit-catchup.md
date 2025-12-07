# Commit Catchup - Resume Work by Reviewing Local Commit History

Resume work by understanding what's been committed locally but not pushed, analyzing the commit history to understand recent work.

**Arguments:** `$ARGUMENTS` - What to focus on or accomplish (optional)

## Phase 0: Parse Intent

**First, parse `$ARGUMENTS` to understand what the user wants:**

| Pattern | Interpretation |
|---------|----------------|
| Empty | Review all local commits ahead of remote |
| Repo name (e.g., `repo-a`) | Focus on specific repository |
| `repo-name instruction` | Focus on repo with specific task |
| Number (e.g., `10`) | Review last N commits regardless of remote |
| Question (e.g., `what did I change?`) | Summary request |
| Keyword (e.g., `auth`) | Filter commits by keyword |

**Extract:**
- **Target repo** (if specified) - allows skipping full workspace scan
- **Commit count** (if specified) - override default behavior
- **Keywords** - for filtering commit messages

---

## Phase 1: Workspace Detection (Multi-Repo)

**Skip this phase if:**
- User specified a repo name in `$ARGUMENTS` → go directly to that repo
- Current directory IS a git repo → proceed with single-repo workflow

**Otherwise, check if in a workspace directory containing multiple repositories:**

```bash
# If current directory is NOT a git repo...
if ! git rev-parse --git-dir &>/dev/null; then
  # Look for git repos in subdirectories (including symlinks)
  repos=$(find . -maxdepth 2 \( -type d -o -type l \) -exec test -d "{}/.git" \; -print 2>/dev/null | sort -u)
fi
```

**If workspace detected (multiple repos found):**

```
📂 Workspace detected - not a git repository, but contains:
  • repo-a -> /path/to/repo-a
  • repo-b -> /path/to/repo-b

Analyzing local commits across all repositories...
```

### Workspace Workflow

1. **Parallel Analysis** - Run Phase 2 (gather commits) on ALL repos simultaneously
2. **Combined Summary** - Present findings from all repos together:
   ```
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   📊 Workspace Local Commits Summary
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

   repo-a (5 commits ahead of origin/main):
     abc1234 feat: add retry logic to API client
     def5678 fix: handle timeout errors gracefully
     ...

   repo-b (2 commits ahead of origin/main):
     111aaaa docs: update README with new API
     222bbbb chore: bump version to 2.1.0

   repo-c (in sync with remote)
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   ```
3. **Focus determination** - Based on parsed intent or commit activity:
   - If only one repo has local commits → focus there automatically
   - If multiple repos have commits → ask which to focus on, or analyze all

**If only one repo has local commits:** Proceed directly with that repo.

**If NO repos have local commits:** Report "All repositories are in sync with remote" and ask user what they'd like to accomplish.

---

## Phase 2: Gather Local Commits

Run these to capture the commit history:

```bash
# Get the tracking branch
tracking=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null)

if [ -n "$tracking" ]; then
  # Commits ahead of remote
  git log --oneline ${tracking}..HEAD

  # Detailed view with stats
  git log --stat ${tracking}..HEAD

  # Show the actual changes in each commit
  git log -p ${tracking}..HEAD
else
  # No tracking branch - show recent commits
  git log --oneline -20
  git log --stat -10
fi

# Also check current status for context
git status --short
```

**Key information to extract:**
- Number of commits ahead of remote
- Commit messages (for understanding intent)
- Files changed per commit
- Overall scope of changes

---

## Phase 3: Commit-Focused Analysis

**Analyze commits through the lens of the user's intent (from Phase 0):**

For each commit (or group of related commits):

1. **Understand the purpose** - Parse commit message for intent
2. **Review the changes** - Read the diff for that specific commit if needed
3. **Identify patterns**:
   - Feature work (new functionality)
   - Bug fixes
   - Refactoring
   - Documentation
   - Configuration changes

**Build a narrative:**
- What work stream(s) are represented?
- Is there a logical progression?
- Are there any incomplete features (partial implementations)?
- What was the last thing worked on?

**If keywords were specified:** Filter analysis to commits matching those keywords.

---

## Phase 4: Summarize & Execute

**Present findings based on parsed intent:**

| Intent Type | Action |
|-------------|--------|
| No args | Summarize local commits, identify work streams, ask what to continue |
| Number (e.g., `10`) | Review last N commits with summary |
| "What did I change?" | Narrative summary of all local work |
| Keyword filter | Show only matching commits with context |
| Specific instruction | Use commit history as context, then execute |

**Output format:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📜 Local Commit Review
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Branch: feature/new-api (5 commits ahead of origin/main)

Work Summary:
• API retry logic implementation (3 commits)
• Error handling improvements (2 commits)

Recent Activity:
  1. abc1234 feat: add retry logic to API client
     └─ src/api/client.py (+45, -12)

  2. def5678 fix: handle timeout errors gracefully
     └─ src/api/client.py (+23, -5)
     └─ tests/test_client.py (+67, -0)

Last worked on: Error handling in API client

Ready to push? All commits appear complete.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Create a todo list if continuing work, then execute based on intent.
