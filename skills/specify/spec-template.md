# Feature Specification: [FEATURE NAME]

**Created**: [DATE]
**Status**: Draft
**Input**: User description: "[FEATURE_DESCRIPTION]"

## User Scenarios & Testing _(mandatory)_

<!-- Prioritize as user journeys (P1, P2, P3...). -->
<!-- Each story must be independently testable and deliver standalone value. -->

### User Story 1 - [Brief Title] (Priority: P1)

[Describe this user journey in plain language]

**Why this priority**: [Value and priority rationale]

**Independent Test**: [How to verify this story works on its own]

**Acceptance Scenarios**:

1. **Given** [initial state], **When** [action], **Then** [expected outcome]
2. **Given** [initial state], **When** [action], **Then** [expected outcome]

---

### User Story 2 - [Brief Title] (Priority: P2)

[Describe this user journey in plain language]

**Why this priority**: [Value and priority rationale]

**Independent Test**: [How to verify this story works on its own]

**Acceptance Scenarios**:

1. **Given** [initial state], **When** [action], **Then** [expected outcome]

---

[Add more user stories as needed, following the same pattern]

### Edge Cases

- What happens when [boundary condition]?
- How does system handle [error scenario]?

## Requirements _(mandatory)_

### Functional Requirements

- **FR-001**: System MUST [specific testable capability]
- **FR-002**: Users MUST be able to [key interaction]

_Mark unclear requirements with_: `[NEEDS CLARIFICATION: specific question]`

### Key Entities _(include if feature involves data)_

<!-- For application-level specs, track which features use each entity to define the shared domain model. -->

- **[Entity 1]**: [What it represents, key attributes without implementation] | Used by: [feature list]
- **[Entity 2]**: [What it represents, relationships to other entities] | Used by: [feature list]

## Feature Dependencies _(optional — application-level specs only)_

<!-- Include when the spec covers multiple features. Remove for single-feature specs. -->

| Feature        | Depends On                          | Priority |
| -------------- | ----------------------------------- | -------- |
| [Feature name] | [Features that must be built first] | P1/P2/P3 |

## Success Criteria _(mandatory)_

<!-- Measurable, technology-agnostic, user-focused outcomes. -->

### Measurable Outcomes

- **SC-001**: [User/business metric, e.g., "Users complete account creation in under 2 minutes"]
- **SC-002**: [Scale metric, e.g., "System handles 1000 concurrent users without degradation"]
- **SC-003**: [Satisfaction metric, e.g., "90% of users complete primary task on first attempt"]
