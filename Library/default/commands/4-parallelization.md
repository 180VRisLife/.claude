For this task, make a `.docs/plans/[feature-name]/parallelization.md` document, outlining what needs to get done, following the format at `$CLAUDE_HOME/file-templates/parallelization.template.md`. You are the senior developer for this project, and you need to break down the problem into actionable tasks, optimized for parallel building.

Please provide the path to the planning documentation directory (e.g., `.docs/plans/feature-name/`):

## Process

### 1. Read Planning Documents
Once you provide the path, read all existing planning documents in order:
1. `priority.md` (required - abort if missing, ask user to run `/3-priority` first)
2. `architecture.md` (required - abort if missing, ask user to run `/2-architecture` first)
3. `requirements.md` (required - abort if missing, ask user to run `/1-requirements` first)
4. Any other research documents in the directory

### 2. Smart Parallelization Detection
After reading `priority.md`, count the number of **Tier 1** features.

**If fewer than 5 Tier 1 tasks:**
Ask the user:
"I see [X] Tier 1 features to build. This is a relatively simple implementation.

I recommend **sequential execution** rather than creating a parallel plan, as the overhead of parallelization may not be worth it for this scope.

Would you like to:
1. Skip to `/5-execution` for sequential implementation
2. Continue with parallel planning anyway"

If user chooses option 1, exit and tell them to run `/5-execution`.

**If 5 or more Tier 1 tasks:**
Continue with parallel planning as normal.

### 3. Assess Parallelization Opportunities
Even with ≥5 tasks, some work may be inherently sequential. Check if:
- Tasks have heavy dependencies (each requires previous completion)
- Tasks touch the same files extensively
- The implementation naturally flows in stages

If work appears mostly sequential, inform the user:
"While there are [X] tasks, many have dependencies that limit parallelization. Parallel execution may still help, but expect some sequential bottlenecks."

### 4. Additional Research (if needed)
After reading the planning documents, if you don't have enough information to create a comprehensive plan, read additional files from the codebase that would be relevant.

Remember: Quality and completeness are CRITICAL. If there's not enough information, more research is required. It's disastrous for developers if the plan has mistakes.

### 5. Create Parallel Implementation Plan
Break down the work into phases and tasks. Each task should be:

- **Brief**: A few file changes at most
- **Complete**: Fully specified with purpose and gotchas
- **Specific**: Include exact file paths
- **Linked**: Reference relevant documentation files
- **Dependency-tracked**: List prerequisite tasks in brackets [1.1, 2, none, etc]
- **Agent-assigned**: Name the specialist agent for this task

**Task structure:**
```markdown
#### Task X.X: [Title] - Depends on [none/1.1/etc]
Agent: agent-name

**READ THESE BEFORE TASK**
- /path/to/file
- /path/to/documentation

**Instructions**

Files to Create
- /path/to/new/file

Files to modify
- /path/to/existing/file

[Concise instructions on what needs to be implemented]
```

### 6. Handle Tier 2 (Stub) Tasks
For Tier 2 features from `priority.md`, include them in the plan but mark clearly:

```markdown
#### Task X.X: [Feature Name] (STUB) - Depends on [deps]
Agent: agent-name

**Instructions**
This is a Tier 2 feature - implement as a STUB following the strategy from priority.md:
[Copy the stub strategy from priority.md]

Files to Create
- /path/to/stub/file

[Brief instructions for minimal implementation]
```

### 7. Plan Structure
At the top of the document, include:
- High-level explanation of what needs to be done (3-4 sentences, information-dense)
- File paths of critically relevant files for immediate familiarization
- All documentation paths

Organize into phases where:
- Phase 1: Foundation and core setup
- Phase 2+: Feature implementations (can often run in parallel)
- Final Phase: Integration, testing, type validation

### 8. Do NOT Include Testing Steps
Skip individual testing tasks EXCEPT for the very last step, which should run type validation across the entire codebase.

Upon completion, inform the user:
"Parallelization plan complete. Run `/5-execution` to begin implementation."

Important notes:
- Accuracy is critical - mistakes in the plan cause implementation failures
- Be thorough in research - slow and informed beats fast and wrong
- Only parallelize Tier 1 tasks completely
- Mark Tier 2 tasks clearly as stubs
- Ensure dependency chains are correct
