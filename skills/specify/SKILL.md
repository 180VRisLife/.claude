---
name: specify
description: Create or update the feature specification from a natural language feature description. Generates spec.md with user stories, requirements, and success criteria.
user-invocable: true
disable-model-invocation: true
argument-hint: "[feature description]"
allowed-tools: Read, Grep, Glob, Write, Edit, Bash
---

## User Input

```text
$ARGUMENTS
```

**REQUIRED**: Feature description to specify. If empty, ERROR: "No feature description provided. Usage: `/specify [feature description]`"

## Setup

Determine the current feature context:

1. Look for `.spec/` at the repo root. If missing: it will be created in step 2 of Outline.
2. Within `.spec/`, find feature directories matching the `NNN-feature-name` pattern.
3. If one feature: use it. If multiple: list them and ask the user to choose (suggest most recently modified).
   - If none: proceed (this is expected for new features).
4. Resolve: FEATURE_DIR = `.spec/<NNN-feature-name>/` (will be created in step 2 of Outline)
5. Check which docs exist: spec.md, constitution.md, blueprint.md, tasks.md, research.md, data-model.md, contracts/, checklists/

## Outline

The text after `/specify` is the feature description. If empty: ERROR "No feature description provided."

1. **Generate a concise short name** (2-4 words, action-noun format):
   - Examples: "user-auth", "oauth2-api-integration", "fix-payment-timeout"
   - Preserve technical terms/acronyms

2. **Create spec directory**:
   a. Find the highest feature number in `.spec/` directories matching the NNN pattern
   b. Use N+1 (or 1 if none found) to create:
   - `mkdir -p .spec/<N+1>-<short-name>/checklists`
   - Set FEATURE_DIR = `.spec/<N+1>-<short-name>/` and SPEC_FILE = `FEATURE_DIR/spec.md`

3. Load `spec-template.md` for required sections.

4. **Detect scope**:
   - If the input describes multiple features, a whole system, or an entire application → treat this as an **application-level spec**:
     - User Stories become **feature-level journeys** — each "story" represents a distinct feature with P1/P2/P3 priority indicating order
     - Key Entities become the **shared domain model** — all entities and relationships across features, tracking which features use each entity
     - Functional Requirements capture **cross-cutting concerns** (auth, error handling, logging, etc.) alongside feature-specific capabilities
     - Success Criteria remain **application-level** metrics
     - Include the optional **Feature Dependencies** section from the template
   - If the input describes a single feature → proceed as normal (remove the Feature Dependencies section)

5. **Parse and generate spec**:
   - Replace `[FEATURE_DESCRIPTION]` in the template's Input field with the user's actual feature description
   - Extract actors, actions, data, constraints from the description
   - Make informed guesses using context and industry standards
   - For each assumption made instead of marking NEEDS CLARIFICATION: would a different reasonable assumption change scope, data model, or UX significantly? If yes, mark it NEEDS CLARIFICATION instead.
   - Mark with `[NEEDS CLARIFICATION: question]` ONLY when:
     - choice significantly impacts scope/UX, multiple reasonable interpretations exist, and no default exists
   - **Maximum 3 `[NEEDS CLARIFICATION]` markers** -- prioritize: scope > security > UX > technical
   - Document assumptions in the Assumptions section
   - Every requirement must be testable
   - Fill all mandatory template sections; remove inapplicable optional sections entirely (including Feature Dependencies for single-feature specs)

6. Write the specification to SPEC_FILE using the template structure.

7. **Specification Quality Validation**:

   a. Generate `FEATURE_DIR/checklists/requirements.md` with validation items covering:
   - Content quality (no implementation details, user-focused)
   - Requirement completeness (testable, measurable, bounded scope)
   - Feature readiness (acceptance criteria, user scenarios, no implementation leakage)

   b. Review spec against each checklist item. For failures:
   - Update the spec to fix issues (max 3 iterations)
   - If still failing after 3 iterations, document in checklist notes

   c. If `[NEEDS CLARIFICATION]` markers remain (max 3), present to user:

   ```markdown
   ## Question [N]: [Topic]

   **Context**: [Quote relevant spec section]
   **What we need to know**: [Specific question]
   **Suggested Answers**:
   | Option | Answer | Implications |
   |--------|--------|--------------|
   | A | [answer] | [implications] |
   | B | [answer] | [implications] |
   | C | [answer] | [implications] |
   | Custom | Provide your own | |
   ```

   Present all questions together, wait for responses, update spec, re-validate.

   d. Update checklist with pass/fail status after each iteration.

8. Report: spec file path, checklist results, readiness for `/clarify` or `/blueprint`.

## Guidelines

- Focus on **WHAT** users need and **WHY** -- avoid HOW (no tech stack, APIs, code structure)
- Written for business stakeholders, not developers
- Do not embed checklists in the spec

### Success Criteria

Success criteria must be measurable, tech-agnostic, user-focused, and verifiable with no implementation details.

**Good**: "Users complete checkout in under 3 minutes" | "95% of searches return results in under 1 second"
**Bad**: "API response under 200ms" | "Redis cache hit rate above 80%" (implementation-specific)

### Reasonable Defaults (don't ask about these)

Data retention, performance targets, error handling, auth method, integration patterns.

Use industry-standard defaults and document in Assumptions.
