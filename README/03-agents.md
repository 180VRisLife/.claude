# Agents

Claude automatically recognizes and selects appropriate agents based on the nature of your request.

*Note: Base agents are global and located in `~/.claude/agents/`. They are available in all projects without needing to copy them locally.*

## How to Request Agents

### Implicit (Recommended)

- "Find where authentication is implemented" → Claude selects @code-finder
- "Build a new user profile feature" → Claude selects @implementor
- "Debug why the API is failing" → Claude selects @root-cause-analyzer

### Explicit (When needed)

- "Use @code-finder-advanced to investigate the data flow"
- "Deploy @root-cause-analyzer to understand why this crashes"
- "Have @implementor build the feature from the plan"

## Base Agents

Available in all domains. Located in `~/.claude/agents/`

```text
@code-finder
```

Quickly locates specific code files, functions, classes, or patterns across the codebase (uses Haiku).

```text
@code-finder-advanced
```

Deep investigation for complex relationships, cross-file analysis, and semantic understanding (uses Sonnet).

```text
@implementor
```

Executes specific implementation tasks from parallel plans with strict adherence to requirements.

```text
@root-cause-analyzer
```

Diagnoses why bugs are occurring through systematic investigation.

```text
@docs-fetcher
```

Fetches and compresses external documentation into LLM-optimized format. Used by `/docs` command for parallel doc generation.
