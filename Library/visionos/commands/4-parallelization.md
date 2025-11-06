Create a `.docs/plans/[feature-name]/parallelization.md` document breaking down visionOS implementation into parallel tasks using `$CLAUDE_HOME/file-templates/parallelization.template.md`.

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
Continue with parallel planning. If tasks have heavy dependencies or touch same Swift files extensively, warn: "Many dependencies limit parallelization. Expect some sequential bottlenecks."

### 3. Additional Research (if needed)
If planning documents lack details, read relevant Swift files. Quality is critical - mistakes cause implementation failures.

### 4. Create Parallel Plan
Break work into phases and tasks. Each task:
- **Brief**: Few Swift file changes
- **Specific**: Exact file paths
- **Dependency-tracked**: [1.1, 2, none, etc]
- **Agent-assigned**: Name specialist agent

**Task structure:**
```markdown
#### Task X.X: [Title] - Depends on [none/1.1/etc]
Agent: agent-name

**READ THESE BEFORE TASK**
- /path/to/SwiftFile.swift
- /path/to/documentation

**Instructions**

Files to Create
- /path/to/NewImmersiveView.swift
- /path/to/NewRealityKitComponent.swift

Files to modify
- /path/to/ExistingFile.swift

[Concise implementation instructions]
```

**Tier 2 (Stub) tasks:**
```markdown
#### Task X.X: [Feature Name] (STUB) - Depends on [deps]
Agent: agent-name

**Instructions**
Tier 2 stub - use strategy from priority.md:
[Copy stub strategy]

[Minimal implementation instructions for placeholder 3D content, basic gestures, etc.]
```

### 5. Plan Structure
Top of document includes:
- High-level explanation (3-4 sentences)
- Critically relevant Swift file paths
- Documentation paths

Organize phases:
- Phase 1: Foundation/core setup (Models, ViewModels, RealityKit components)
- Phase 2+: Feature implementations (Spatial Views, 3D content - parallel)
- Final: Integration, build validation

Skip individual testing EXCEPT final build check.

Upon completion: "Parallelization plan complete. Run `/5-execution` to begin."

**Important:** Be thorough - slow and informed beats fast and wrong. Mark Tier 2 tasks as stubs. Ensure correct dependency chains.
