# Catchup - Resume Work with Prompt-Driven Analysis

Resume work by understanding the user's intent first, then analyzing changes through that lens.

**Arguments:** `$ARGUMENTS` - What to focus on or accomplish (optional)

## Phase 1: Establish Intent

**First, understand what the user wants:**

1. **User prompt provided:** If `$ARGUMENTS` contains instructions, that's the primary focus
2. **PROMPT.md exists:** Contains original task context (from `/utl:init-worktree`)
3. **Neither:** Ask user what they'd like to accomplish before proceeding

```bash
if [ -f "PROMPT.md" ]; then
  echo "📋 PROMPT.md context:"
  cat PROMPT.md
fi
```

**Combine both sources:** User's current prompt (`$ARGUMENTS`) may refine or redirect the original PROMPT.md intent. The user prompt takes priority for what to focus on.

## Phase 2: Gather All Changes

Run these to capture the full picture:

```bash
git status
git diff
git diff --cached
git log --oneline -5 2>/dev/null || echo "No commits yet"
```

## Phase 3: Prompt-Aware Analysis

**Read diffs through the lens of the user's intent:**

- If user said "finish the API endpoints" → focus on API-related changes
- If user said "what's left?" → identify gaps vs. original requirements
- If user said "test this" → examine testability of changes

Read modified files selectively based on relevance to the prompt.

Determine:
- **Relevant to prompt**: Changes that matter for the user's request
- **Completed**: What's done that the prompt cares about
- **Remaining**: What the prompt needs that isn't done yet
- **Unrelated**: Changes that exist but aren't the focus (note but deprioritize)

## Phase 4: Execute on Prompt

**Take action based on what the user asked for:**

| Prompt Type | Action |
|-------------|--------|
| "Continue" / no args | Resume original PROMPT.md task |
| "What's left?" | Summarize remaining work, then ask if should continue |
| Specific instruction | Execute that instruction using current state as context |
| Issue number (e.g., `123`) | Fetch `gh issue view 123` and relate to changes |

Create a todo list of work aligned to the prompt, then execute.
