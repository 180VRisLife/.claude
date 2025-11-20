# Implementation Best Practices for Default Development

## Before You Begin: Agent Selection

For complex implementations, consider using specialized agents:

**Feature Development**:
- @backend - API endpoints, services, data layers
- @frontend - UI components, pages, styling
- @fullstack - Full-stack features spanning frontend and backend

**Investigation First**:
- @code-finder - Locate existing patterns to follow
- @code-finder-advanced - Understand complex architectural relationships

**Task Execution**:
- @implementor - Execute well-defined tasks from plans

For simple changes (1-4 files), implement directly. For complex features, deploy appropriate specialist agents.

## Implementation Best Practices

Before implementing, ensure you follow these critical practices:

1. **Understand Existing Patterns**
   - Search for similar implementations in the codebase first
   - Follow established architectural patterns and conventions
   - Maintain consistency with existing code style and structure
   - Reuse existing utilities, helpers, and components where possible

2. **Security First**
   - Validate and sanitize ALL user inputs
   - Prevent injection attacks (SQL, XSS, command injection, etc.)
   - Use parameterized queries for database operations
   - Implement proper authentication and authorization checks
   - Never expose sensitive data (API keys, credentials, tokens)
   - Use secure communication (HTTPS, encrypted connections)

3. **Error Handling & Edge Cases**
   - Handle all error conditions gracefully
   - Provide meaningful error messages
   - Consider edge cases (empty data, null values, boundary conditions)
   - Implement proper logging for debugging (but remove before commit)
   - Add defensive programming checks

4. **Testing Strategy**
   - Write unit tests for core logic
   - Add integration tests for complex workflows
   - Test error conditions and edge cases
   - Ensure tests are maintainable and readable

5. **Code Quality**
   - Write clean, readable, self-documenting code
   - Add comments only for complex logic that needs explanation
   - Keep functions/methods focused and single-purpose
   - Follow SOLID principles and design patterns
   - Avoid code duplication (DRY principle)

6. **Performance Considerations**
   - Avoid unnecessary computations or re-renders
   - Use appropriate data structures and algorithms
   - Consider lazy loading and code splitting for large features
   - Profile and optimize bottlenecks if needed

7. **Accessibility (for UI components)**
   - Ensure keyboard navigation works properly
   - Add proper ARIA labels and roles
   - Maintain sufficient color contrast
   - Support screen readers

8. **Documentation**
   - Document public APIs, complex functions, and non-obvious behavior
   - Update relevant documentation files if behavior changes
   - Include usage examples for complex features

Remember: Implementation is not just about making it work—it's about making it work reliably, securely, and maintainably.
