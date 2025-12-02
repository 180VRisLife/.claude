# Agents

Claude automatically recognizes and selects appropriate agents based on the nature of your request.

*Note: Agents are workspace-local after running `/0-workspace` and exist in `./.claude/agents/` organized in `base/` and `specialist/` subdirectories.*

## How to Request Agents

### Implicit (Recommended)
- "Find where authentication is implemented" → Claude selects @code-finder
- "Build a new user profile feature" → Claude selects domain specialist
- "Debug why the API is failing" → Claude selects @root-cause-analyzer

### Explicit (When needed)
- "Use @code-finder-advanced to investigate the data flow"
- "Deploy @root-cause-analyzer to understand why this crashes"
- "Have @implementor build the service layer task from the plan"

## Base Agents

Available in all domains. Located in `./.claude/agents/base/`

```
@code-finder
```
Quickly locates specific code files, functions, classes, or patterns across the codebase (uses Haiku).

```
@code-finder-advanced
```
Deep investigation for complex relationships, cross-file analysis, and semantic understanding (uses Sonnet).

```
@implementor
```
Executes specific implementation tasks from parallel plans with strict adherence to requirements.

```
@library-docs-writer
```
Fetches and compresses external library documentation into concise reference files.

```
@root-cause-analyzer
```
Diagnoses why bugs are occurring through systematic investigation.

## Specialist Agents

Domain-specific agents vary by platform. Check `./.claude/agents/specialist/` fo available specialists.
