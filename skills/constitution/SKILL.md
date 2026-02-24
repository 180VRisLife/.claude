---
name: constitution
description: Create or update the project constitution — core principles, constraints, and governance rules that guide all specification and implementation work.
user-invocable: true
disable-model-invocation: true
argument-hint: "[principles or update description]"
allowed-tools: Read, Grep, Glob, Write, Edit
---

## User Input

```text
$ARGUMENTS
```

**Optional** context. You **MUST** consider the user input before proceeding (if not empty).

## Setup

1. Locate the repository root (look for `.git/`)
2. Ensure `.spec/` exists at the repo root (`mkdir -p .spec/`)
3. Check for `.spec/constitution.md`:
   - Found → **amendment** workflow (load it)
   - Not found → **creation** workflow

## Execution

### 1. Load or Initialize

- **Amendment**: Read `.spec/constitution.md`, parse current version from footer (`Version: X.Y.Z`)
  - Extract existing sections
- **Creation**: Read `skills/constitution/template.md` and use it as the base structure
  - Set initial version to `0.0.0`

### 2. Collect Principles and Context

- Parse `$ARGUMENTS` for explicit principles, constraints, or update descriptions
- Scan for context:
  - `README.md`, `CLAUDE.md`
  - Project manifests (`package.json`/`Cargo.toml`/`pyproject.toml`)
  - `.spec/` feature specs
- **Amendment**: Identify which existing sections the user input affects

If `$ARGUMENTS` is empty **and** creation workflow: ask the user to describe core principles and constraints. Present 2-3 starter questions (one at a time, multiple choice preferred).

### 3. Draft Constitution Content

Write concrete, declarative, testable principles. Each must be:

- **Declarative**: States what IS, not what SHOULD be
- **Testable**: An observer could verify compliance
- **Specific**: No vague adjectives without quantification

**Creation**: Populate all template sections from step 2.
**Amendment**: Apply changes to relevant sections; preserve unchanged content.
Replace `[PLACEHOLDER]` tokens with concrete values. If undetermined, ask the user.

### 4. Version Bump

Apply semver. **Creation**: `0.0.0` → `1.0.0`. Record bump rationale (e.g., "MINOR: added data-privacy principle").

### 5. Validation

Verify: no unexplained `[BRACKET]` placeholders, ISO 8601 dates, all principles declarative and testable, valid semver, governance includes amendment procedure, no contradictions. Fix and re-validate (max 3 iterations).

### 6. Write Constitution

Write to `.spec/constitution.md`. Preserve markdown formatting and heading hierarchy.

### 7. Report

- **Path**: `.spec/constitution.md`
- **Version**: `X.Y.Z` (bump type and rationale)
- **Sections**: List written or modified
- **Principles count**: Total in constitution
- **Suggested commit message**: e.g., `docs(spec): ratify project constitution v1.0.0`
- **Suggested next command**: `/specify` for new projects, `/analyze` if specs exist

## Behavior Rules

- Empty `$ARGUMENTS` on amendment? Ask what the user wants to change — do not regenerate
- Constitution exists + new principles? Amend, don't overwrite
- Never remove existing principles without explicit user confirmation
- Feature-scoped input (not project-wide)? Suggest `/specify` instead
- Respect the template structure but allow custom sections between Constraints and Governance
- All principles must be concrete — reject vague aspirational language; ask to quantify
