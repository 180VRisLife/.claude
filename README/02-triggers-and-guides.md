# Triggers and Guides

## Thinking Keywords

Trigger extended thinking by including these keywords in your prompt:

| Keyword | Tokens | Use Case |
|---------|--------|----------|
| **think** | 4,000 | Standard problem-solving (5-15 seconds) |
| **megathink** | 10,000 | Complex refactoring and design |
| **ultrathink** | 31,999 | Tackling seemingly impossible tasks |

## Workflow Guides

The Workflow Orchestrator injects contextual guides based on keywords. **foundation.md** is always active.

| Primary | Also Triggers | Purpose |
|---------|---------------|---------|
| `/brainstorm` | — | Socratic questioning, collaborative discovery |
| `/deep-research` | — | Evidence-based systematic investigation |
| `/plan` | planning | Research-only mode, no implementation |
| `/implement` | build, code, create | Feature implementation best practices |
| `/debug` | bug, error | Debugging workflow and error investigation |
| `/investigate` | research, analyze | Code investigation and pattern analysis |
| `/parallel` | batch, simultaneously | Parallel execution and agent delegation |

## Activation

1. **Slash commands** - `/debug`, `/plan`, etc.
2. **Keywords in prompts** - "debug this authentification issue"

Guides stack together: "plan out this debug" → foundation + planning + debug
