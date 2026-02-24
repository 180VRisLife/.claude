---
name: tasks
description: Generate an actionable, dependency-ordered tasks.md for the feature based on available design artifacts.
user-invocable: true
disable-model-invocation: true
argument-hint: "[guidance or constraints]"
allowed-tools: Read, Grep, Glob, Write, Edit
---

## User Input

```text
$ARGUMENTS
```

**Optional** context. You **MUST** consider the user input before proceeding (if not empty).

## Setup

Determine the current feature context:

1. Look for `.spec/` at the repo root. If missing: error — instruct user to run `/specify` first (it creates `.spec/`).
2. Within `.spec/`, find feature directories matching the `NNN-feature-name` pattern.
3. If one feature: use it. If multiple: list them and ask the user to choose (suggest most recently modified).
   - If none: error — instruct user to run `/specify` first.
4. Resolve: FEATURE_DIR = `.spec/<NNN-feature-name>/`
5. Check which docs exist:
   - constitution.md, spec.md, blueprint.md, tasks.md, research.md, data-model.md, contracts/, checklists/

Abort with error if any required file is missing (instruct user to run the prerequisite command).

## Outline

1. **Load design documents** from FEATURE_DIR:
   - **Required**: blueprint.md (tech stack, structure), spec.md (user stories with priorities)
   - **Optional**: data-model.md, contracts/, research.md, quickstart.md
   - Generate tasks based on what is available.

2. **Generate tasks** organized by user story:
   - Extract tech stack/structure from blueprint.md, user stories (P1, P2, P3...) from spec.md
   - Map entities (data-model.md) and interface contracts (contracts/) to their user stories
   - Extract research decisions for setup tasks
   - Validate: each user story has all needed tasks and is independently testable

3. **Write tasks.md** using `tasks-template.md`:
   - Phase 1: Setup
   - Phase 2: Foundational prerequisites
   - Phase 3+: One per user story (priority order)
   - Each task must be specific enough for an LLM to execute without additional context

4. **Report**: path, total count, count per story, parallel opportunities, MVP scope suggestion.

## Task Format

Every task MUST follow: `- [ ] [TaskID] [P?] [Story?] Description with file path`

- **Checkbox**: Always `- [ ]`
- **Task ID**: Sequential (T001, T002...)
- **[P]**: Include only if parallelizable (different files, no dependencies)
- **[Story]**: [US1], [US2], etc. -- required for user story phases only (not Setup/Foundational/Polish)
- **Description**: Clear action with exact file path

Examples:

- `- [ ] T001 Create project structure per implementation plan`
- `- [ ] T012 [P] [US1] Create User model in src/models/user.py`
- WRONG: `- [ ] Create User model` (missing ID) | `- [ ] T001 [US1] Create model` (missing file path)

## Task Organization

- **From User Stories**:
  - Each story (P1, P2, P3) gets its own phase with models, services, interfaces, and optionally tests
- **From Contracts/Data Model**:
  - Map each interface contract and entity to the user story it serves; shared entities go in Setup or earliest story
- **From Infrastructure**:
  - Shared -> Setup (Phase 1), blocking -> Foundational (Phase 2), story-specific -> within that story

Tests are OPTIONAL -- only generate test tasks if explicitly requested.

### Phase Structure

- **Phase 1**: Setup (project init)
- **Phase 2**: Foundational (blocking prerequisites -- MUST complete before user stories)
- **Phase 3+**: User Stories in priority order. Within each: Models -> Services -> Interfaces -> Integration
- **Final Phase**: Polish & cross-cutting concerns
