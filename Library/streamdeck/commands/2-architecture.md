I need to create a `.docs/plans/[feature-name]/architecture.md` document containing high-level technical information on plugin files, Stream Deck SDK patterns, and architecture relevant to implementing a new feature.

Please provide the feature description or the path to the planning directory (e.g., `.docs/plans/feature-name/`):

## Process

### 1. Read Existing Planning Documents
First, if the directory does not exist yet, create `.docs/plans/[feature-name]/`. If it exists already, read every file within `.docs/plans/[feature-name]/`, starting with `requirements.md`.

### 2. Determine Research Needs
After reading the requirements, identify what technical context is needed:
- Relevant files and their purposes (Actions, Property Inspectors, event handlers, etc.)
- Plugin manifest structure and settings
- Established patterns or conventions (SDK event handling, state management, communication)
- Shared utilities, modules, or services
- External libraries or APIs used

### 3. Conduct Parallel Research
If you don't have enough information after reading existing planning documents, use @code-finder and/or @code-finder-advanced agents _in parallel_ to research different aspects of the codebase.

Each agent should:
- Investigate a specific aspect (e.g., "Action handlers", "Property Inspector communication", "manifest structure")
- Write findings to `.docs/plans/[feature-name]/[research-topic].docs.md`
- List ALL plugin files relevant to their search topic
- Provide clear explanations of how things work

Launch all research agents in the same function call for parallel execution.

### 4. Read Research Reports
Once all agents complete, read their research documents to gather the full technical picture.

### 5. Write Architecture Document
Using the template at `$CLAUDE_HOME/file-templates/architecture.template.md`, create `.docs/plans/[feature-name]/architecture.md`.

The architecture document should name:
- **Relevant Files**: Each plugin file with a brief description of its purpose
- **Manifest/Settings**: Plugin manifest entries, action definitions, or settings schemas
- **Relevant Patterns**: Established Stream Deck SDK conventions with examples
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
