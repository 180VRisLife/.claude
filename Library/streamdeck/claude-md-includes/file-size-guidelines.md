## File Size Guidelines

### Stream Deck Plugin Code Files
- **Actions**: 50-150 lines; refactor beyond 200 lines
- **UI components**: 50-100 lines; extract sub-components beyond 150 lines
- **Utilities**: 100-150 lines; split beyond 250 lines
- **Plugin manifest/backend**: Keep modular and focused; split beyond 300 lines

### File Reading Strategy
- **<200 lines**: Read entire file with Read tool
- **200-500 lines**: Read with offset/limit for targeted sections
- **500+ lines**: Use Grep first, then Read specific sections

### Token Budget Awareness
Each file read consumes tokens from the 1M context window. Prefer targeted reads (Grep + offset/limit) for large files to preserve context capacity for actual implementation work.
