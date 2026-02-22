---
name: brainstorm
description: Explore requirements and design before implementation through structured dialogue
user-invocable: true
disable-model-invocation: true
---

# Brainstorming Ideas Into Designs

Help turn ideas into fully formed designs through collaborative dialogue. Scale effort to the task — a link in a header needs a different process than a new subsystem — but always confirm you understand what the user wants before you build anything.

Do NOT start implementation, write code, or scaffold anything until you have stated your understanding and the user has confirmed it. This applies to every task regardless of size.

## Anti-Pattern: Skipping Understanding

Simple tasks are where unchecked assumptions cause the most damage. You think you know the *what* and miss preferences about the *how*. Even when the task seems obvious, confirm before building.

## The Process

**Phase 1 -- Understanding the idea:**
- Check current project state first (files, docs, recent commits)
- Ask questions one at a time (only one per message)
- Prefer multiple choice when possible
- Focus on: purpose, constraints, success criteria
- State your understanding and get user confirmation before moving on

**Phase 2 -- Exploring approaches:**
- Propose 2-3 approaches with trade-offs
- Lead with your recommendation and reasoning
- Favor designs with isolated units and clean boundaries. In brownfield projects, explore existing codebase patterns before proposing new ones. Extend what's there rather than inventing parallel structures.

**Phase 3 -- Presenting the design:**
- Present in sections of 200-300 words
- Scale detail to section complexity: a simple CRUD endpoint gets a short section, a novel algorithm or tricky state machine gets a thorough one. Don't spread detail uniformly.
- Ask after each section whether it looks right
- Cover: architecture, components, data flow, error handling, testing
- Go back and clarify if something doesn't track
- Validate each section before moving on

Steps 1-2 always happen. Step 3 scales to the task — for small changes, ask the user if a full design walkthrough is needed rather than skipping it silently.

## After the Design

**Documentation:**
- Write validated design to `docs/plans/YYYY-MM-DD-<topic>-design.md`
- Commit via `/commit`

**Brainstorm marker:**
- Write `.brainstorm-latest` at repo root (gitignored):
  ```
  doc: docs/plans/YYYY-MM-DD-<topic>-design.md
  summary: <one-line summary, suitable for branch naming>
  ```
- Consumed by `wc` shell command for AI-powered branch naming.

**End the session** with:
> "To start implementation, create a worktree with `wc` -- it will use this brainstorm for branch naming."

Do NOT chain into planning, execution, or implementation. The brainstorm ends with the design.

## Key Principles

- **One question at a time**
- **Multiple choice preferred**
- **YAGNI ruthlessly** -- cut unnecessary features from all designs
- **Explore alternatives** -- always 2-3 approaches before settling
- **Incremental validation** -- present design in sections, validate each
