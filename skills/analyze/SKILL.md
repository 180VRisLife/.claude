---
name: analyze
description: Perform a non-destructive cross-artifact consistency and quality analysis across spec.md, blueprint.md, and tasks.md.
user-invocable: true
disable-model-invocation: true
argument-hint: "[focus area]"
allowed-tools: Read, Grep, Glob
---

## User Input

```text
$ARGUMENTS
```

**Optional** context. You **MUST** consider the user input before proceeding (if not empty).

## Goal

Identify inconsistencies, duplications, ambiguities, and underspecified items across `spec.md`, `blueprint.md`, and `tasks.md` before implementation. Run after `/tasks` has produced a complete `tasks.md`.

**STRICTLY READ-ONLY**: Do not modify any files. Output a structured analysis report.
Offer optional remediation plan (user must approve before any edits).

## Setup

Determine the current feature context:

1. Look for `.spec/` at the repo root. If missing: error — instruct user to run `/specify` first (it creates `.spec/`).
2. Within `.spec/`, find feature directories matching the `NNN-feature-name` pattern.
3. If one feature: use it. If multiple: list them and ask the user to choose (suggest most recently modified).
   - If none: error — instruct user to run `/specify` first.
4. Resolve: FEATURE_DIR = `.spec/<NNN-feature-name>/`
5. Check which docs exist: spec.md, blueprint.md, tasks.md, research.md, data-model.md, contracts/, checklists/

Abort with error if any required file is missing (instruct user to run the prerequisite command).

## Execution

### 1. Load Artifacts

Derive paths from FEATURE_DIR: SPEC, BLUEPRINT, TASKS = FEATURE_DIR/{spec,blueprint,tasks}.md

Load minimal necessary context from each:

- **spec.md**: Overview, Functional/Non-Functional Requirements, User Stories, Edge Cases
- **blueprint.md**: Architecture/stack, Data Model refs, Phases, Technical constraints
- **tasks.md**: Task IDs, Descriptions, Phase grouping, Parallel markers [P], Referenced file paths

### 2. Build Semantic Models

Internal representations (not included in output):

- **Requirements inventory**: Each requirement with a stable slug key (e.g., "User can upload file" -> `user-can-upload-file`)
- **User story/action inventory**: Discrete actions with acceptance criteria
- **Task coverage mapping**: Map tasks to requirements/stories by keyword and explicit references

### 3. Detection Passes

Limit to 50 findings total; summarize overflow.

**A. Duplication**: Near-duplicate requirements; mark lower-quality phrasing for consolidation.

**B. Ambiguity**: Vague adjectives (fast, scalable, secure, intuitive, robust) lacking measurable criteria.

- Unresolved placeholders (TODO, TKTK, ???, `<placeholder>`).

**C. Underspecification**: Requirements with verbs but missing object/measurable outcome.

- User stories missing acceptance criteria. Tasks referencing undefined components.

**D. Coverage Gaps**: Requirements with zero tasks. Tasks with no mapped requirement. Non-functional requirements not reflected in tasks.

**E. Inconsistency**: Terminology drift across files. Data entities in plan but absent in spec (or vice versa).

- Task ordering contradictions. Conflicting requirements.

**F. Cross-Feature Consistency** _(only when multiple feature specs exist in `.spec/`)_:

- Shared entities defined consistently across feature specs
- Technical Context doesn't conflict between feature blueprints
- No terminology drift across feature specs
- Feature dependencies from any application-level spec are satisfied (dependent features are specified)

### 4. Severity Assignment

- **CRITICAL**: Missing core artifact, or requirement with zero coverage blocking baseline functionality
- **HIGH**: Duplicate/conflicting requirement, ambiguous security/performance attribute, untestable acceptance criterion
- **MEDIUM**: Terminology drift, missing non-functional task coverage, underspecified edge case
- **LOW**: Style/wording improvements, minor redundancy

**Before finalizing severity, challenge each finding:** Could this "gap" be intentionally deferred or out-of-scope? Check spec assumptions and out-of-scope sections. Could this "inconsistency" be intentional evolution (blueprint refining a vague spec term)? Could this "duplication" be two distinct requirements using similar language? Downgrade or remove findings that don't survive. Prefer fewer accurate findings over comprehensive noisy ones.

### 5. Analysis Report

Output Markdown report (no file writes):

| ID  | Category | Severity | Location(s) | Summary | Recommendation |
| --- | -------- | -------- | ----------- | ------- | -------------- |

(One row per finding; stable IDs prefixed by category initial.)

**Coverage Summary:**

| Requirement Key | Has Task? | Task IDs | Notes |
| --------------- | --------- | -------- | ----- |

**Unmapped Tasks:** (if any)

**Metrics:** Total Requirements, Total Tasks, Coverage %, Ambiguity Count, Duplication Count, Critical Issues Count

### 6. Next Actions

- CRITICAL issues: Recommend resolving before implementation
- Only LOW/MEDIUM: User may proceed with improvement suggestions
- Provide explicit command suggestions (e.g., "Run /specify with refinement", "Run /blueprint to adjust architecture")

### 7. Offer Remediation

Ask: "Would you like me to suggest concrete remediation edits for the top N issues?" (Do NOT apply automatically.)
