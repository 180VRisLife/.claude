---
name: checklist
description: Generate a requirements-quality checklist for a specific concern (security, UX, API, etc.).
user-invocable: true
disable-model-invocation: true
argument-hint: "[checklist focus, e.g., security, ux, api]"
allowed-tools: Read, Grep, Glob, Write, Edit, Bash
---

## Core Concept: Unit Tests for Requirements

Checklists validate the **quality of requirements writing**, not implementation behavior.

**WRONG** (testing implementation):
"Verify the button clicks correctly" | "Test error handling works"

**CORRECT** (testing requirements):
"Is 'prominent display' quantified with specific sizing?" | "Are hover state requirements consistent across all interactive elements?"

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

## Execution

1. **Clarify intent**: Derive up to 3 contextual questions from user phrasing + spec/blueprint signals.
   - Only ask about information that materially changes checklist content. Skip if already clear from `$ARGUMENTS`.

   Question generation:
   - Extract domain keywords, risk indicators, stakeholder hints from input and docs
   - Cluster into candidate focus areas (max 4) ranked by relevance
   - Formulate from archetypes:
     - Scope refinement, risk prioritization, depth calibration, audience framing, boundary exclusion, scenario gap detection
   - Present options as compact tables when useful; label Q1/Q2/Q3
   - After answers, up to 2 follow-ups (Q4/Q5) if major scenario classes remain unclear
   - Defaults if no interaction: Standard depth, Reviewer audience, top 2 clusters

2. **Understand request**: Combine `$ARGUMENTS` + answers to derive theme, must-have items, and category scaffolding.
   - Infer missing context from spec/blueprint/tasks.

3. **Load feature context**: Read relevant portions of spec.md, blueprint.md, tasks.md from FEATURE_DIR.
   - Summarize long sections rather than embedding raw text.

4. **Generate checklist**:
   - Create `FEATURE_DIR/checklists/[domain].md` (e.g., `ux.md`, `api.md`, `security.md`)
   - Each run creates a NEW file (append if filename exists)
   - Use `checklist-template.md` for structure
   - Number items CHK001+ sequentially

   **Quality dimensions for categories**: Completeness, Clarity, Consistency, Measurability, Scenario Coverage, Edge Cases, Non-Functional Requirements, Dependencies & Assumptions, Ambiguities & Conflicts

   **Item rules**:
   - Question format asking about requirement quality, not implementation behavior
   - Include quality dimension tag: `[Completeness]`, `[Clarity]`, `[Consistency]`, etc.
   - Reference spec section `[Spec X.Y]` or use markers: `[Gap]`, `[Ambiguity]`, `[Conflict]`, `[Assumption]`
   - > =80% of items must include traceability references
   - Soft cap: prioritize by risk/impact if >40 candidates; merge near-duplicates; batch low-impact edge cases
   - After generating items, scan for blind spots: are there relevant dimensions with zero items? (Functional Scope, Integration, Edge Cases, Non-Functional, Completion Signals). Add at least one item per uncovered dimension that applies.

   **Prohibited**:
   Items starting with "Verify/Test/Confirm/Check" + implementation behavior/details, references to code execution or system behavior.

   **Required patterns**: "Are [requirements] defined for [scenario]?" | "Is [vague term] quantified with specific criteria?" | "Are requirements consistent between [A] and [B]?" | "Does the spec define [missing aspect]?"

5. **Report**: file path, item count, focus areas, depth level, actor/timing.
