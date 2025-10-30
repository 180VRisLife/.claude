## File Size Guidelines

### React/Next.js Code Files
- **Components**: 100-200 lines; extract sub-components beyond 300 lines
- **Pages (Next.js)**: 150-250 lines; extract sections beyond 400 lines
- **Hooks**: 50-150 lines; extract logic beyond 200 lines
- **Utilities**: 100-200 lines per module; split beyond 300 lines

### File Reading Strategy
- **<200 lines**: Read entire file with Read tool
- **200-500 lines**: Read with offset/limit for targeted sections
- **500-2000 lines**: Use Grep first, then Read specific sections
- **>2000 lines**: Flag for refactoring

### Token Budget Awareness
Each file read consumes tokens from the 1M context window. Prefer targeted reads (Grep + offset/limit) for large files to preserve context capacity for actual implementation work.
