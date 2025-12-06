# Catchup - Resume Work with Prompt-Driven Analysis

Resume work by understanding the user's intent first, then analyzing changes through that lens.

**Arguments:** `$ARGUMENTS` - What to focus on or accomplish (optional)

## Phase 0: Parse Intent

**First, parse `$ARGUMENTS` to understand what the user wants:**

| Pattern | Interpretation |
|---------|----------------|
| Empty | No specific focus - will need to discover or ask |
| Repo name (e.g., `repo-a`) | Focus on specific repository |
| `repo-name instruction` | Focus on repo with specific task |
| Question (e.g., `what's left?`) | Status/summary request |
| Instruction (e.g., `fix the bug`) | Specific task to execute |
| Issue number (e.g., `123`) | GitHub issue context |

**Extract:**
- **Target repo** (if specified) - allows skipping full workspace scan
- **Task type** - status check, specific instruction, or open-ended
- **Keywords** - for focusing analysis later

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

Analyzing changes across all repositories...
```

### Workspace Workflow

1. **Parallel Analysis** - Run Phase 2 (gather changes) on ALL repos simultaneously
2. **Combined Summary** - Present findings from all repos together:
   ```
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   📊 Workspace Changes Summary
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

   repo-a (3 files changed, 2 commits ahead):
     M  src/core/handler.py
     M  src/api/client.py
     A  src/utils/retry.py

   repo-b (1 file changed):
     M  README.md

   repo-c (no changes)
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   ```
3. **Focus determination** - Based on parsed intent or changes:
   - If only one repo has changes → focus there automatically
   - If multiple repos have changes → ask which to focus on, or analyze all

**If only one repo has changes:** Proceed directly with that repo (skip multi-repo summary).

**If NO repos have changes:** Report "No changes in any repository" and ask user what they'd like to accomplish.

---

## Phase 2: Gather Changes

Run these to capture the full picture (scoped to target repo if specified):

```bash
git status
git diff
git diff --cached
git log --oneline -5 2>/dev/null || echo "No commits yet"
```

---

## Phase 3: Intent-Aware Analysis

**Read diffs through the lens of the user's intent (from Phase 0):**

- If user said "finish the API endpoints" → focus on API-related changes
- If user said "what's left?" → identify gaps vs. requirements
- If user said "test this" → examine testability of changes

Read modified files selectively based on relevance to the parsed intent.

Determine:
- **Relevant to intent**: Changes that matter for the user's request
- **Completed**: What's done that the intent cares about
- **Remaining**: What the intent needs that isn't done yet
- **Unrelated**: Changes that exist but aren't the focus (note but deprioritize)

---

## Phase 4: Execute

**Take action based on parsed intent:**

| Intent Type | Action |
|-------------|--------|
| No args | Summarize changes and ask what to focus on |
| "What's left?" | Summarize remaining work, then ask if should continue |
| Specific instruction | Execute that instruction using current state as context |
| Issue number (e.g., `123`) | Fetch `gh issue view 123` and relate to changes |

Create a todo list of work aligned to the intent, then execute.
