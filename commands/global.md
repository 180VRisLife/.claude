# Global Developer Scan

Scan the Developer folder for repositories needing git commits and/or CLAUDE.md attention, then generate a single Ghostty command to open Claude Code sessions for all locations needing work.

**Arguments:** `$ARGUMENTS` - Mode: `git`, `init`, or `both` (default)

## Phase 0: Parse Mode

Parse `$ARGUMENTS` to determine scan mode:

| Input | Mode | Description |
|-------|------|-------------|
| Empty / `both` | Both | Scan for git AND CLAUDE.md needs |
| `git` | Git only | Only scan for uncommitted changes |
| `init` | Init only | Only scan for CLAUDE.md needs |

---

## Phase 1: Discover Repositories & Validate Symlinks

Scan `/Users/chrisjamesbliss/Developer` for git repositories:

```bash
# Find all git repos in Developer folder
find /Users/chrisjamesbliss/Developer -type d -name ".git" 2>/dev/null | \
  while read gitdir; do
    dirname "$gitdir"
  done | sort -u

# Check symlinks in Unversioned and Workspaces
for link in /Users/chrisjamesbliss/Developer/Unversioned/* /Users/chrisjamesbliss/Developer/Workspaces/*; do
  if [ -L "$link" ]; then
    target=$(readlink "$link")
    if [ ! -e "$target" ]; then
      echo "BROKEN: $link -> $target"
    elif [[ "$target" == /Volumes/* ]] && [ ! -d "$target" ]; then
      echo "UNAVAILABLE: $link -> $target (external drive)"
    else
      echo "VALID: $link -> $target"
    fi
  fi
done
```

### Symlink Health Report

Display symlink status:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔗 SYMLINK HEALTH
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Valid: <list of working symlinks>
⚠️  Unavailable: <external drive symlinks not mounted>
❌ Broken: <symlinks pointing to non-existent targets>
```

**If broken symlinks found:** Note them but continue with scan.

---

## Phase 2: Git Analysis (if mode includes git)

For each discovered repository, check for uncommitted changes:

```bash
cd "$repo_path"
branch=$(git branch --show-current 2>/dev/null || echo "unknown")
status=$(git status --porcelain 2>/dev/null)
ahead=$(git rev-list --count @{u}..HEAD 2>/dev/null || echo "0")
```

### Categorize Results

**Needs /git:** Repos with any of:
- Uncommitted changes (staged or unstaged)
- Untracked files
- Ahead of remote

**Clean:** Repos with no changes

**Output format:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 GIT STATUS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚠️  Needs /git (N repos):

RepoName (branch, X files)
   M  path/to/modified.swift
   A  path/to/added.py
   ?? path/to/untracked.js
   ... (N more files)

AnotherRepo (main, 3 ahead, 2 files)
   M  file1.ts
   M  file2.ts

✅ Clean (N repos):
   • repo1
   • repo2
   • repo3

❌ Unavailable (N repos):
   • external-repo (drive not mounted)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Truncation:** If a repo has >5 file changes, show first 5 and "... (N more files)".

---

## Phase 3: CLAUDE.md Analysis (if mode includes init)

For each repository, check CLAUDE.md status:

```bash
claude_file="$repo_path/CLAUDE.md"

if [ ! -f "$claude_file" ]; then
  echo "MISSING"
else
  # Check freshness: compare CLAUDE.md mtime vs last git commit
  claude_mtime=$(stat -f %m "$claude_file" 2>/dev/null || echo "0")
  last_commit=$(git -C "$repo_path" log -1 --format=%ct 2>/dev/null || echo "0")

  if [ "$last_commit" -gt "$claude_mtime" ]; then
    days_old=$(( (last_commit - claude_mtime) / 86400 ))
    echo "STALE:$days_old"
  fi

  # Check size
  size=$(wc -c < "$claude_file" | tr -d ' ')
  if [ "$size" -lt 500 ]; then
    echo "INCOMPLETE:$size"
  fi
fi
```

### Staleness Criteria

| Signal | Status |
|--------|--------|
| File missing | ❌ Missing |
| File older than last commit | ⚠️ Stale (X days behind) |
| Size < 500 bytes | ⚠️ Incomplete |
| Up to date & complete | ✅ OK |

### Also Check for Sub-directory CLAUDE.md Files

Look for CLAUDE.md files in subdirectories:
```bash
find "$repo_path" -name "CLAUDE.md" -not -path "$repo_path/CLAUDE.md" 2>/dev/null
```

Note these as "has subdirectory docs" in the report.

**Output format:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📝 CLAUDE.md STATUS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚠️  Needs /init (N repos):

RepoName/
   ⚠️  CLAUDE.md is 14 days older than latest commit
   └── Has subdirectory: Views/CLAUDE.md

AnotherRepo/
   ⚠️  CLAUDE.md appears incomplete (423 bytes)

✅ Up to Date (N repos):
   • HomePi/CLAUDE.md (324 lines)
   • SleepPilot/CLAUDE.md (68 lines)

❌ Missing (N locations):
   • hammerspoon - no CLAUDE.md
   • DropboxDirect - no CLAUDE.md
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Phase 4: Non-Git Detection

Identify directories that contain code but aren't git repositories:

```bash
# Look for directories with code files but no .git
for dir in /Users/chrisjamesbliss/Developer/Unversioned/*; do
  if [ -d "$dir" ] && [ ! -d "$dir/.git" ]; then
    # Check if it has code files
    if ls "$dir"/*.py "$dir"/*.swift "$dir"/*.ts "$dir"/*.js "$dir"/*.lua 2>/dev/null | head -1 > /dev/null; then
      echo "SHOULD_INIT: $dir"
    fi
  fi
done
```

**Output (if any found):**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔍 DIRECTORIES WITHOUT GIT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

These contain code but aren't git repositories:

• ~/.hammerspoon (Lua files)
  └── Consider: git init

• ~/Desktop/Playground/DropboxDirect (Python files)
  └── Consider: git init
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Phase 5: Generate Single Combined Ghostty Script

Collect all repos needing attention and generate ONE copyable script:

### Determine What Each Repo Needs

For each repo:
- If needs git: tag with `/git`
- If needs init: tag with `/init`
- If needs both: tag with `/git, /init`

### Generate Script Block

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🖥️  COPY & RUN
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Copy this entire block and paste into terminal:
open -na Ghostty --args --working-directory="/Users/chrisjamesbliss/Developer/Versioned/FrontRow" -e "claude" &      # /git
open -na Ghostty --args --working-directory="/Users/chrisjamesbliss/Developer/Versioned/HomePi" -e "claude" &       # /git
open -na Ghostty --args --working-directory="/Users/chrisjamesbliss/Developer/Versioned/Interface" -e "claude" &    # /git, /init
open -na Ghostty --args --working-directory="/Users/chrisjamesbliss/Developer/Versioned/SleepPilot" -e "claude" &   # /git
wait

💡 In each Claude session, run /git or /init as indicated in the comments.

📊 Summary: 4 repos need attention (4 git, 2 init)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Format rules:**
- Use `&` after each command for parallel execution
- Add `wait` at the end so script doesn't exit immediately
- Comment each line with what action is needed
- Align comments for readability
- Include summary count at end

---

## Phase 6: Handle Edge Cases

### If Nothing Needs Attention

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ ALL CLEAR
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

All repositories are clean and CLAUDE.md files are up to date!

📊 Scanned: 5 repos, 5 CLAUDE.md files, 3 symlinks
   All symlinks valid ✓
   No uncommitted changes ✓
   All documentation current ✓
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### If Only Symlinks Are Broken

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️  SYMLINK ISSUES ONLY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

All repos are clean, but some symlinks need attention:

❌ Broken:
   • OldProject → /path/that/no/longer/exists

To fix: Remove broken symlink or update target path.
No Ghostty script needed - repos are clean.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Execution Policy

**IMPORTANT: Run all analysis phases before outputting anything.**

1. Complete all scanning in parallel where possible
2. Aggregate results
3. Then output combined report with Ghostty script at the end

This ensures the user gets a complete picture before taking action.
