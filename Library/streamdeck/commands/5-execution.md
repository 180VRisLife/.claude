Execute a Stream Deck plugin implementation plan with support for resuming, iterative feedback, and phase-by-phase review.

Please provide the path to the planning directory (e.g., `.docs/plans/feature-name/`):

## Process

### 1. Read Planning Documents
Read in order:
1. `parallelization.md` OR `priority.md` (if parallelization skipped)
2. `architecture.md`
3. `requirements.md`
4. Relevant plugin files mentioned at top of plan

### 2. Check Execution Status
Look for `.docs/plans/[feature-name]/execution-status.json`.

**If exists:**
Present summary:
```
Previous execution:
✅ Completed: Phase 1 (Tasks: 1.1, 1.2, 1.3)
🚧 In-progress: Phase 2 (Task: 2.1)
❌ Failed: Task 2.2 (manifest validation errors)
⏸️ Pending: Phase 3, Phase 4
```
Ask: "Continue from Phase 2? Or start fresh?"

**If doesn't exist:**
Create new status file:
```json
{
  "feature": "feature-name",
  "created": "2025-11-06T10:00:00Z",
  "lastUpdated": "2025-11-06T10:00:00Z",
  "mode": "phase-by-phase",
  "phases": {}
}
```

### 3. Determine Mode
- User says "one-shot", "run all", "don't pause" → **One-shot mode** (auto-continue, pause only on errors)
- Otherwise → **Phase-by-phase mode** (pause after each phase for review)

### 4. Create Todo List
Make todo for each task in plan:
- Note dependencies
- Mark status from execution-status.json
- Skip individual testing EXCEPT final plugin validation

### 5. Execute Phases

**For each phase:**

**5a. Execute Tasks**
- Identify runnable tasks (dependencies satisfied)
- **CRITICAL**: Run independent tasks in parallel (single function call)
- Delegate to specialist agents with:
  - Links to planning docs
  - Task instructions
  - Plugin file paths and documentation
  - Validation requirement before returning

**Agent Orchestration:**
Ensure compatible contracts (e.g., Action event handlers, Property Inspector communication). Coordinate to prevent conflicts.

**5b. Verify Completion**
- Run plugin validation on manifest and modified files
- Update execution-status.json:
```json
"phases": {
  "1": {"status": "completed", "tasks": ["1.1", "1.2"], "completedAt": "..."}
}
```

**5c. Handle Failures**
If task fails:
1. Mark failed in status file with reason
2. **ALWAYS PAUSE** (even one-shot mode)
3. Output: "⚠️ Task X.X failed: [reason]. Review error."
4. Wait for user guidance

**5d. Pause for Review (Phase-by-phase only)**
```
✅ Phase X complete

Tasks: Task X.1, Task X.2
Files: /path/to/action.js, /path/to/propertyInspector.html

📋 Review changes. Type 'continue' for Phase Y, or provide feedback.
```
**WAIT** for user input.

**5e. User Feedback**
- **"continue"**: Next phase
- **Feedback**: Update task, mark in-progress, re-execute, continue
- **"stop"/"pause"**: Save status, exit

### 6. Final Validation
After all phases:
1. Mark all tasks completed in status file
2. Run full plugin validation
3. Output:
```
✅ All phases complete!

Summary: X tasks, Y phases, Z files created, W modified

Next steps:
1. Load plugin in Stream Deck and test feature
2. Review changes
3. Commit: /git
```

## Rules

**DO:**
- Update status file after every phase
- Run plugin validation before/after phases
- Parallelize independent tasks (single function call)
- Coordinate agent contracts
- Enable easy resume

**DON'T:**
- Auto-run `/git` (user decides)
- Skip review (unless one-shot)
- Proceed past failures without input
- Assume fixes (wait for user)

**Stub Tasks:**
If marked "(STUB)":
- Minimal implementation per priority.md strategy
- Comment: `// TODO: Stub implementation - expand later`
- Skip edge cases/error handling

**Feedback Patterns:**
```
"Task 2.1 isn't right, use X pattern" → Update, re-execute, continue
"Phase 2 looks good, continue" → Proceed to Phase 3
"Stop here, I need to test" → Save status, exit
```

You orchestrate, agents implement. Coordinate work, ensure quality via validation and review.
