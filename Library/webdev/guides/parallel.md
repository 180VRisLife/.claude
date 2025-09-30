# Parallel Execution Guide for Web Development

When implementing features for scalable React applications, parallel execution is crucial for efficiency. This guide explains when and how to use parallel execution in your development workflow.

## When to Use Parallel Execution

### 1. Independent Component Development
When creating multiple React components that don't depend on each other:
- Different page components
- Separate UI widgets
- Independent utility components
- Isolated feature modules

### 2. Separate Layer Implementation
When working on different architectural layers simultaneously:
- Frontend component + Backend API endpoint
- Database schema + Service layer
- UI components + State management
- Styling system + Component logic

### 3. Multiple Feature Branches
When implementing distinct features:
- User authentication + Dashboard analytics
- Payment processing + Email notifications
- Search functionality + Data export
- Admin panel + User profile

## How to Request Parallel Execution

Be explicit about parallel execution in your requests:

**Good Examples:**
- "Create the UserCard and ProductCard components in parallel"
- "Implement the authentication API endpoint and login form simultaneously"
- "Build the database schema and service layer at the same time"
- "Create these three independent pages in parallel: dashboard, settings, and profile"

**When NOT to Use Parallel:**
- Dependent tasks (e.g., "Create type definitions, then create the component that uses them")
- Sequential refactoring (e.g., "Update the API, then update all consumers")
- Debugging workflows (e.g., "Find the bug, then fix it")

## Parallel Execution Patterns for Web Development

### Pattern 1: Full-Stack Feature Development
```
Parallel Tasks:
1. Frontend: Create React component with mock data
2. Backend: Implement API endpoint with real data
3. Types: Define shared TypeScript interfaces

Dependencies:
- Both frontend and backend depend on shared types
- Integration testing depends on both frontend and backend
```

### Pattern 2: Multiple Page Components
```
Parallel Tasks:
1. Create Dashboard page
2. Create Settings page
3. Create Profile page

Dependencies:
- All use shared layout component (create first)
- All use shared navigation (create first)
```

### Pattern 3: UI System Development
```
Parallel Tasks:
1. Create Button component variants
2. Create Input component variants
3. Create Card component variants

Dependencies:
- All depend on design tokens (create first)
- All depend on base styles (create first)
```

## Best Practices

1. **Identify Shared Dependencies First**: Create shared types, interfaces, utilities, or base components before spawning parallel tasks.

2. **Clear Boundaries**: Ensure each parallel task has a well-defined scope with minimal overlap.

3. **Explicit Communication**: Tell Claude exactly which agents to use and what to build in parallel.

4. **Batch Execution**: When requesting parallel work, use phrases like "launch multiple agents" or "execute in parallel."

## Example Request

```
I need to implement a user management feature. Please work on these in parallel:

1. @react-component: Create the UserList component that displays users in a table
2. @api-endpoint: Create the /api/users endpoint with CRUD operations
3. @fullstack-feature: Create the user profile page with edit functionality

All should use the User type from src/types/user.ts
```

This approach maximizes efficiency while maintaining code quality and consistency across your web application.