Create a `.docs/plans/[feature-name]/parallelization.md` document breaking down web implementation into parallel tasks using `$CLAUDE_HOME/file-templates/parallelization.template.md`.

Please provide the path to the planning directory (e.g., `.docs/plans/feature-name/`):

## Process

### 1. Read Planning Documents
Read in order (abort if missing):
1. `priority.md`
2. `architecture.md`
3. `requirements.md`
4. Any other research documents

### 2. Smart Parallelization Detection
Count **Tier 1** features in `priority.md`.

**If <5 Tier 1 tasks:**
Ask: "I see [X] Tier 1 features. This is simple enough for sequential execution. Skip to `/5-execution` instead?"

If user agrees, exit and tell them to run `/5-execution`.

**If ≥5 Tier 1 tasks:**
Continue with parallel planning. If tasks have heavy dependencies or touch same files extensively, warn: "Many dependencies limit parallelization. Expect some sequential bottlenecks."

### 3. Additional Research (if needed)
If planning documents lack details, read relevant files. Quality is critical - mistakes cause implementation failures.

### 4. Create Parallel Plan
Break work into phases and tasks. Each task:
- **Brief**: Few file changes
- **Specific**: Exact file paths
- **Dependency-tracked**: [1.1, 2, none, etc]
- **Agent-assigned**: Name specialist agent

**Task structure:**
```markdown
#### Task X.X: [Title] - Depends on [none/1.1/etc]
Agent: agent-name

**READ THESE BEFORE TASK**
- /path/to/file
- /path/to/documentation

**Instructions**

Files to Create
- /path/to/new/component.tsx
- /path/to/new/api/route.ts

Files to modify
- /path/to/existing/file.ts

[Concise implementation instructions]
```

**Tier 2 (Stub) tasks:**
```markdown
#### Task X.X: [Feature Name] (STUB) - Depends on [deps]
Agent: agent-name

**Instructions**
Tier 2 stub - use strategy from priority.md:
[Copy stub strategy]

[Minimal implementation instructions for placeholder component, mock data, etc.]
```

### 5. Plan Structure
Top of document includes:
- High-level explanation (3-4 sentences)
- Critically relevant file paths
- Documentation paths

Organize phases:
- Phase 1: Foundation/core setup (API routes, data models, hooks)
- Phase 2+: Feature implementations (Components, UI - parallel)
- Final: Integration, type validation, build check

Skip individual testing EXCEPT final typecheck and build.

Upon completion: "Parallelization plan complete. Run `/5-execution` to begin."

**Important:** Be thorough - slow and informed beats fast and wrong. Mark Tier 2 tasks as stubs. Ensure correct dependency chains.
