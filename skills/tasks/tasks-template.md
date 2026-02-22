<!-- Task list template for feature implementation -->

# Tasks: [FEATURE NAME]

**Input**: Design documents from `.spec/[###-feature-name]/`
**Prerequisites**: blueprint.md (required), spec.md (required), optionally: research.md, data-model.md, contracts/

**Tests**: Only include test tasks if explicitly requested.
**Organization**: Tasks grouped by user story for independent implementation and testing.

## Format: `[ID] [P?] [Story?] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story (US1, US2, etc.)
- Include exact file paths in descriptions

<!-- Replace ALL sample tasks below with actual tasks from design documents. -->

## Phase 1: Setup

- [ ] T001 Create project structure per implementation plan
- [ ] T002 Initialize project with dependencies
- [ ] T003 [P] Configure linting and formatting

---

## Phase 2: Foundational (Blocking Prerequisites)

**Must complete before any user story work begins.**

- [ ] T004 Setup database schema and migrations
- [ ] T005 [P] Implement auth framework
- [ ] T006 [P] Setup API routing and middleware
- [ ] T007 Create base models/entities shared across stories

**Checkpoint**: Foundation ready -- user stories can begin.

---

## Phase 3: User Story 1 - [Title] (P1) MVP

**Goal**: [What this story delivers]
**Independent Test**: [How to verify standalone]

### Tests (optional -- only if requested)

- [ ] T010 [P] [US1] Contract test for [endpoint] in tests/contract/test_[name].py
- [ ] T011 [P] [US1] Integration test for [journey] in tests/integration/test_[name].py

### Implementation

- [ ] T012 [P] [US1] Create [Entity] model in src/models/[entity].py
- [ ] T013 [US1] Implement [Service] in src/services/[service].py
- [ ] T014 [US1] Implement [endpoint] in src/[location]/[file].py
- [ ] T015 [US1] Add validation and error handling

**Checkpoint**: User Story 1 fully functional and independently testable.

---

[Repeat for each additional user story (Phase 4: US2, Phase 5: US3, etc.), following the same pattern]

---

## Final Phase: Polish & Cross-Cutting

- [ ] TXXX [P] Documentation updates
- [ ] TXXX Code cleanup and refactoring
- [ ] TXXX Performance optimization
- [ ] TXXX Security hardening

---

## Dependencies

- **Setup (1)**: No dependencies
- **Foundational (2)**: Depends on Setup -- blocks all user stories
- **User Stories (3+)**: Depend on Foundational; can run in parallel or sequentially (P1 -> P2 -> P3)
- **Polish (Final)**: Depends on desired user stories complete
- **Within each story**: Tests (fail first) -> Models -> Services -> Endpoints -> Integration

## Implementation Strategy

1. Setup + Foundational -> Foundation ready
2. User Story 1 -> Test independently -> MVP
3. Add stories incrementally, each independently testable and deployable
