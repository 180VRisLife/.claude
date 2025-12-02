 # Workflow Commands

Execute these domain-specific commands in order when building a new feature.

**Tip:** Clear Claude's memory and tag in `.docs/plans/[FEATURENAME]` before triggering each command.

## Full Workflow

### `/1-requirements`
Creates a requirements document with user flows, functional requirements, and UI/system specifications.

### `/2-architecture`
Documents architecture overview, relevant files, patterns, and database schemas (technical design).

### `/3-priority`
Ruthlessly prioritizes features into 3 tiers:
- **Tier 1** - Build now
- **Tier 2** - Stub/placeholder
- **Tier 3** - Future

### `/4-parallelization`
Creates parallelizable task breakdown with dependencies, agent assignments, and implementation phases. Includes smart detection to suggest sequential execution for simple projects (<5 Tier 1 tasks).

### `/5-execution`
Orchestrates implementation with phase-by-phase review pauses. Re-runnable (tracks progress via execution-status.json), supports iterative feedback, and allows one-shot mode.
