## File Size Guidelines

### Stream Deck Plugin Code Files
- **Actions**: 50-150 lines per action file
- **UI components**: 50-100 lines per component
- **Utilities**: 100-150 lines per module
- **Plugin manifest/backend**: Keep modular and focused

### File Reading Strategy
- **<200 lines**: Read entire file with Read tool
- **200-500 lines**: Read with offset/limit for targeted sections
- **500+ lines**: Use Grep first, then Read specific sections

### Token Budget Awareness
Each file read consumes tokens from the 1M context window. Prefer targeted reads (Grep + offset/limit) for large files to preserve context capacity for actual implementation work.
