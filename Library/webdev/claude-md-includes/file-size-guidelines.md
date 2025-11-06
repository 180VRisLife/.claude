## File Size Guidelines

### React/Next.js Code Files
- **Components**: 200-400 lines; extract sub-components beyond 600 lines
- **Pages (Next.js)**: 250-400 lines; extract sections beyond 700 lines
- **Hooks**: 100-200 lines; extract logic beyond 400 lines
- **Utilities**: 200-400 lines per module; split beyond 600 lines

**Key principle:** Prefer logical coherence over arbitrary limits. A comprehensive 550-line component with clear structure is better than artificially splitting related logic.

### File Reading Strategy
- **<300 lines**: Read entire file with Read tool
- **300-800 lines**: Read strategically; use offset/limit for targeted sections
- **800-2000 lines**: Use Grep first, then Read specific sections
- **>2000 lines**: Flag for refactoring

### Token Budget Awareness
Each file read consumes tokens from the 1M context window. Prefer targeted reads (Grep + offset/limit) for large files to preserve context capacity for actual implementation work.
