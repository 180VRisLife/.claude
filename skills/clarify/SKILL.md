---
name: clarify
description: Identify underspecified areas in the current feature spec by asking up to 5 targeted clarification questions and encoding answers back into the spec.
user-invocable: true
disable-model-invocation: true
argument-hint: "[focus area or context]"
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
5. Check which docs exist: spec.md, constitution.md, blueprint.md, tasks.md, research.md, data-model.md, contracts/, checklists/

Abort with error if any required file is missing (instruct user to run the prerequisite command).

## Outline

Goal: Detect and reduce ambiguity in the active feature spec. Record clarifications directly in the spec file.

If user explicitly skips clarification (e.g., exploratory spike), warn that downstream rework risk increases.

## Execution

1. Load spec from FEATURE_DIR/spec.md. If missing, instruct user to run `/specify` first.

2. Perform ambiguity scan using this taxonomy (mark each: Clear / Partial / Missing):
   - **Functional Scope**: Core goals, success criteria, explicit out-of-scope, user roles
     - _Application-level_: Are features well-bounded? Any overlap or gaps between features?
   - **Domain & Data Model**: Entities/attributes/relationships, identity rules, state transitions, scale assumptions
     - _Application-level_: Are shared entities consistent across features? Any entity claimed by multiple features with conflicting definitions?
   - **Interaction & UX**: Critical user journeys, error/empty/loading states, accessibility/localization
   - **Non-Functional**: Performance targets, scalability limits, reliability/availability, security/privacy, compliance
   - **Integration**: External services/APIs and failure modes, import/export formats, protocol/versioning
     - _Application-level_: How do features interact with each other (not just external services)?
   - **Edge Cases**: Negative scenarios, rate limiting, conflict resolution
   - **Constraints & Tradeoffs**: Technical constraints, rejected alternatives
   - **Terminology**: Canonical glossary terms, deprecated synonyms
   - **Completion Signals**: Testable acceptance criteria, measurable DoD indicators
   - **Misc**: TODO markers, vague adjectives ("robust", "intuitive") lacking quantification

   For Partial/Missing categories...
   Add candidate questions unless clarification wouldn't materially change implementation.

3. Generate prioritized queue of up to 5 clarification questions (max 10 across session). Before finalizing your question queue: verify you haven't over-indexed on one taxonomy category at the expense of others. A single missed category can matter more than depth in an already-covered one. Constraints:
   - Each answerable via multiple-choice (2-5 options) OR short answer (<=5 words)
   - Only questions whose answers impact...
     - Architecture, data modeling, task decomposition, test design, UX, ops readiness, or compliance
   - Cover highest-impact unresolved categories first; balance coverage
   - Exclude already-answered, stylistic, or plan-level execution details
   - Favor clarifications that reduce downstream rework risk

4. Sequential questioning loop:
   - Present ONE question at a time.
   - **Multiple-choice**: Analyze options and present recommended option prominently with reasoning.
     - Render all options as Markdown table.
     - Allow reply by letter, "yes"/"recommended" to accept recommendation, or custom short answer.
   - **Short-answer**: Provide suggested answer with reasoning.
     - Allow "yes"/"suggested" to accept, or custom answer (<=5 words).
   - Validate answer maps to an option or fits constraint.
     - Disambiguate if unclear (does not count as new question).
   - Record accepted answer in memory; advance to next question.
   - Stop when: all critical ambiguities resolved, user signals done, or 5 questions asked.
   - Never reveal future queued questions.

5. Integration after each accepted answer:
   - Ensure `## Clarifications` section exists (create after overview section if missing).
   - Under `### Session YYYY-MM-DD` subheading, append: `- Q: <question> -> A: <answer>`.
   - Apply clarification to the most appropriate spec section:
     - Functional -> Functional Requirements
     - Data shape -> Data Model
     - Non-functional -> Quality Attributes (convert vague adjective to metric)
     - Edge case -> Edge Cases / Error Handling
     - Terminology -> Normalize across spec; note `(formerly "X")` once if needed
   - If clarification invalidates earlier text, replace it (no contradictory leftovers).
   - Save spec after each integration (atomic overwrite). Preserve formatting and heading hierarchy.

6. Validation after each write:
   - One bullet per accepted answer in Clarifications (no duplicates)
   - Total asked <= 5
   - No lingering vague placeholders the answer was meant to resolve
   - No contradictory earlier statements remain
   - Markdown structure valid; terminology consistent

7. Write updated spec to FEATURE_DIR/spec.md.

8. Report completion:
   - Questions asked/answered count
   - Path to updated spec
   - Sections touched
   - Coverage summary: each taxonomy category with status (Resolved/Deferred/Clear/Outstanding)
   - If Outstanding or Deferred remain, recommend proceeding to `/blueprint` or re-running `/clarify`
   - Suggested next command

## Behavior Rules

- No meaningful ambiguities? Report "No critical ambiguities detected" and suggest proceeding.
- Spec missing? Instruct user to run `/specify` first.
- Never exceed 5 questions (disambiguation retries don't count as new questions).
- Respect early termination signals ("stop", "done", "proceed").
- Quota reached with unresolved high-impact categories? Flag under Deferred with rationale.
