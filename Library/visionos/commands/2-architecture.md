I need to create a `.docs/plans/[feature-name]/architecture.md` document containing high-level technical information on Swift files, visionOS patterns, and spatial architecture relevant to implementing a new feature.

Please provide the feature description or the path to the planning directory (e.g., `.docs/plans/feature-name/`):

## Process

### 1. Read Existing Planning Documents
First, if the directory does not exist yet, create `.docs/plans/[feature-name]/`. If it exists already, read every file within `.docs/plans/[feature-name]/`, starting with `requirements.md`.

### 2. Determine Research Needs
After reading the requirements, identify what technical context is needed:
- Relevant Swift files and their purposes (Views, ViewModels, RealityKit entities, etc.)
- Data persistence (SwiftData, CloudKit, etc.)
- Established patterns or conventions (MVVM, spatial computing patterns, RealityKit usage)
- Shared components, utilities, or services
- External frameworks or SDKs used (RealityKit, ARKit, etc.)

### 3. Conduct Parallel Research
If you don't have enough information after reading existing planning documents, use @code-finder and/or @code-finder-advanced agents _in parallel_ to research different aspects of the codebase.

Each agent should:
- Investigate a specific aspect (e.g., "RealityKit entities", "spatial interactions", "immersive space management")
- Write findings to `.docs/plans/[feature-name]/[research-topic].docs.md`
- List ALL Swift files relevant to their search topic
- Provide clear explanations of how things work

Launch all research agents in the same function call for parallel execution.

### 4. Read Research Reports
Once all agents complete, read their research documents to gather the full technical picture.

### 5. Write Architecture Document
Using the template at `$CLAUDE_HOME/file-templates/architecture.template.md`, create `.docs/plans/[feature-name]/architecture.md`.

The architecture document should name:
- **Relevant Files**: Each Swift file with a brief description of its purpose
- **Data Models/Persistence**: SwiftData models, RealityKit components, or other data structures
- **Relevant Patterns**: Established visionOS conventions with examples
- **Relevant Docs**: Links to other documentation with usage context

Keep descriptions concise but information-dense. A developer should be able to read this document and quickly understand the technical landscape.

## Summary of Steps

1. List `.docs/plans/[feature-name]/`
2. Read every file within it
3. Create your todo list
4. Launch parallel agents to perform any necessary research
5. Read their research documents
6. Write `.docs/plans/[feature-name]/architecture.md`

Upon completion, inform the user:
"Architecture document complete. Run `/3-priority` next to prioritize what gets built."
