## File Size Guidelines

### Stream Deck Plugin Code Files
- **Actions**: 100-200 lines; refactor beyond 400 lines
- **UI components**: 100-200 lines; extract sub-components beyond 300 lines
- **Utilities**: 200-300 lines; split beyond 500 lines
- **Plugin manifest/backend**: Keep modular and focused; split beyond 600 lines

**Key principle:** Prefer logical coherence over arbitrary limits. A complete 350-line action handler is better than splitting related functionality across multiple files.

### File Reading Strategy
- **<300 lines**: Read entire file with Read tool
- **300-800 lines**: Read strategically; use offset/limit for targeted sections
- **800+ lines**: Use Grep first, then Read specific sections

### Token Budget Awareness
Each file read consumes tokens from the 1M context window. Prefer targeted reads (Grep + offset/limit) for large files to preserve context capacity for actual implementation work.
