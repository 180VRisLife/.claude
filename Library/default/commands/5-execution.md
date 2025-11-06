I need to execute an implementation plan for your project. This command supports re-running from where you left off, iterative feedback, and phase-by-phase review.

Please provide the path to the planning documentation directory (e.g., `.docs/plans/feature-name/`):

## Process

### 1. Read Planning Documents
Once you provide the path, read the planning documents in order:
1. `parallelization.md` OR `priority.md` (if parallelization was skipped)
2. `architecture.md`
3. `requirements.md`

Also read the list of relevant files mentioned at the top of the parallelization/priority document.

### 2. Check for Existing Execution Status
Look for `.docs/plans/[feature-name]/execution-status.json`.

**If it exists:**
1. Read the status file to see what's been completed
2. Compare plan vs current codebase state
3. Present a summary:
   ```
   Previous execution found:
   ✅ Completed: Phase 1 (Tasks: 1.1, 1.2, 1.3)
   🚧 In-progress: Phase 2 (Tasks: 2.1)
   ❌ Failed: Task 2.2 (reason: typecheck errors)
   ⏸️ Pending: Phase 3, Phase 4
   ```
4. Ask: "Continue from Phase 2? Or start fresh?"

**If user says start fresh:** Reset the status file and begin from Phase 1.
**If user says continue:** Resume from the in-progress or failed task.

**If status file doesn't exist:**
Create a new one with structure:
```json
{
  "feature": "feature-name",
  "created": "2025-11-06T10:00:00Z",
  "lastUpdated": "2025-11-06T10:00:00Z",
  "mode": "phase-by-phase",
  "phases": {}
}
```

### 3. Determine Execution Mode
Check if the user specified a mode in their message:
- If they said "one-shot", "run all phases", "don't pause", or similar → **One-shot mode**
- Otherwise → **Phase-by-phase mode** (default)

Inform the user:
- **Phase-by-phase**: "I'll pause after each phase for your review. You can provide feedback or type 'continue' to proceed."
- **One-shot**: "Running all phases without pausing (except on errors). You can interrupt anytime with feedback."

### 4. Create Comprehensive Todo List
Make a todo item for each task in the plan. For each todo:
- Name the tasks it depends on
- Mark current status based on execution-status.json (completed/pending/failed)
- Don't include individual testing steps EXCEPT the final typecheck step

### 5. Execute in Phases

For each phase in the plan:

#### 5a. Execute Phase Tasks
- Identify all tasks in this phase that can run (dependencies satisfied)
- Delegate work to specified agents in batches
- **CRITICAL**: Tasks without dependencies or with satisfied dependencies MUST run in parallel in a single function call
- Provide each agent with:
  - Links to parallelization.md, architecture.md, requirements.md
  - Specific task instructions from the plan
  - Relevant file paths and documentation
  - Instruction to run typecheck on files they edit before returning

**Agent Orchestration:**
You are responsible for ensuring agents have compatible contracts. For example:
- If one agent creates an API endpoint, later agents need the contract
- If one agent creates types, other agents should use them (no duplication)
- Coordinate to prevent conflicts

#### 5b. Verify Phase Completion
After all tasks in a phase complete:
1. Run typecheck on all modified files
2. Update execution-status.json:
   ```json
   "phases": {
     "1": {
       "status": "completed",
       "tasks": ["1.1", "1.2"],
       "completedAt": "2025-11-06T10:30:00Z"
     }
   }
   ```

#### 5c. Handle Failures
If any task fails (typecheck errors, build failures, etc.):
1. Mark task as failed in execution-status.json with reason
2. **ALWAYS PAUSE**, even in one-shot mode
3. Output: "⚠️ Task X.X failed: [reason]. Please review the error."
4. Wait for user feedback to fix and retry

#### 5d. Pause for Review (Phase-by-phase mode only)
If NOT in one-shot mode:
1. Output summary:
   ```
   ✅ Phase X complete

   Tasks completed:
   - Task X.1: [Title]
   - Task X.2: [Title]

   Files modified:
   - /path/to/file
   - /path/to/other/file

   📋 Please review the changes above.

   Type 'continue' to proceed to Phase Y, or provide feedback to refine.
   ```
2. **WAIT** for user input - do NOT proceed automatically

#### 5e. Handle User Feedback
User can respond with:
- **"continue"**: Proceed to next phase
- **Feedback** (e.g., "Make X change to Task Y"):
  1. Update the task based on feedback
  2. Mark task as in-progress in status file
  3. Re-execute that specific task
  4. Continue from there
- **"stop" or "pause"**: Save status and exit gracefully

#### 5f. One-shot Mode Behavior
In one-shot mode:
- Skip pause steps (5d)
- Continue through all phases automatically
- ONLY pause on failures or errors
- User can still interrupt with feedback anytime

### 6. Final Validation
After all phases complete:
1. Mark all tasks completed in execution-status.json
2. Run full typecheck across entire codebase
3. Output:
   ```
   ✅ All phases complete!

   Summary:
   - X tasks completed across Y phases
   - Z files created
   - W files modified

   Next steps:
   1. Run your tests: [suggest test command if known]
   2. Review all changes carefully
   3. Commit when ready: /git
   ```

### 7. Important Notes

**Do NOT:**
- Run `/git` automatically - user decides when to commit
- Skip user review points (unless one-shot mode explicitly chosen)
- Proceed past failures without user input
- Make assumptions about fixes - wait for user guidance on failures

**DO:**
- Update execution-status.json after every phase
- Provide clear summaries of what was done
- Run typechecks before and after phases
- Parallelize independent tasks in single function calls
- Coordinate agent work to prevent conflicts
- Make it easy to resume from any point

**Stub Tasks:**
If tasks are marked "(STUB)" in the parallelization plan:
- Implement minimally according to stub strategy from priority.md
- Mark clearly in code with comments: `// TODO: Stub implementation - expand later`
- Don't spend time on edge cases or error handling

### 8. Feedback Loop Support
This command is designed for iteration. Common patterns:
```
User: "That implementation of Task 2.1 isn't quite right, make it use X pattern instead"
→ Update Task 2.1, re-execute, continue

User: "Phase 2 looks good, continue"
→ Proceed to Phase 3

User: "Stop here, I need to test this"
→ Save status, exit gracefully
```

Remember: You are orchestrating implementation, not doing it yourself. Delegate to specialist agents, coordinate their work, and ensure quality through typechecks and user review.
