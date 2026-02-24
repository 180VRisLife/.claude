---
name: blueprint
description: Execute the implementation planning workflow using the plan template to generate design artifacts. Produces research, data models, API contracts, and blueprint.md.
user-invocable: true
disable-model-invocation: true
argument-hint: "[guidance or constraints]"
allowed-tools: Read, Grep, Glob, Write, Edit, Bash
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
5. Check which docs exist: spec.md, blueprint.md, tasks.md, research.md, data-model.md, contracts/, checklists/

Abort with error if any required file is missing (instruct user to run the prerequisite command).

## Outline

1. **Load context**: Read FEATURE_DIR/spec.md and `blueprint-template.md`.

2. **Execute plan workflow**: Fill Technical Context (mark unknowns as "NEEDS CLARIFICATION"), then Phase 0 and Phase 1 below.

3. **Stop and report**: blueprint path and generated artifacts.

## Phase 0: Outline & Research

1. Extract unknowns from Technical Context:
   - Each NEEDS CLARIFICATION becomes a research task; each dependency becomes a best practices task.

2. **Check for prior decisions**: Ask the user how they'd like to provide existing technical context (technology choices, architecture, conventions).

- Offer these options:
  - **Existing codebase** — provide a path and you'll read the project to extract decisions already made (language, framework, DB, patterns, etc.)
  - **Other sources** — provide a link (repo, docs, wiki) for you to review
  - **Manual input** — they'll describe the background themselves

  Incorporate whatever the user provides as established decisions.
  Don't re-derive app-level choices that are already settled — reference them and note only feature-specific additions or deviations.

3. Research and resolve each unknown given feature context. For each technology choice, find best practices for the domain. For each technology choice, consider whether the recommendation is driven by familiarity bias rather than fit for this feature's constraints. If a simpler alternative equally satisfies the spec, prefer it.

4. Consolidate in `FEATURE_DIR/research.md`:
   - Decision | Rationale | Alternatives considered

## Phase 1: Design & Contracts

**Prerequisites:** research.md complete

1. Extract entities from spec -> `FEATURE_DIR/data-model.md`: entity name, fields, relationships, validation rules, state transitions.
   - **Cross-feature check**: If other feature specs exist in `.spec/`, check their Key Entities for shared entities.
   - Ensure consistency with existing data models — reuse definitions rather than redefining.

1. Generate API contracts from functional requirements:
   - Each user action -> endpoint, standard REST/GraphQL patterns -> `FEATURE_DIR/contracts/` (OpenAPI/GraphQL schema).

1. Generate `FEATURE_DIR/quickstart.md` with integration scenarios and test setup.

Write the plan to `FEATURE_DIR/blueprint.md` using the blueprint template structure. ERROR on unresolved clarifications.
