# Webdev Implementation Best Practices

## Before You Begin: Agent Selection

For complex implementations, consider using specialized agents:

**Feature Development**:
- @react-component - React components, UI elements, styling
- @api-endpoint - API endpoints and backend services
- @fullstack-feature - Full-stack web features

**Investigation First**:
- @code-finder - Locate existing patterns to follow
- @code-finder-advanced - Understand complex architectural relationships

**Task Execution**:
- @implementor - Execute well-defined tasks from plans

For simple changes (1-4 files), implement directly. For complex features, deploy appropriate specialist agents.

## Implementation Best Practices

Before implementing web features, ensure you follow these critical practices:

1. **Understand Existing Patterns**
   - Search for similar implementations in the codebase first
   - Follow established architectural patterns (component structure, state management)
   - Maintain consistency with existing React/Next.js/framework code style
   - Reuse existing components, hooks, utilities, and services

2. **Web Security First**
   - Validate and sanitize ALL user inputs (client AND server-side)
   - Prevent XSS attacks (avoid dangerouslySetInnerHTML unless absolutely necessary)
   - Prevent SQL injection (use parameterized queries, ORMs)
   - Implement CSRF protection for state-changing operations
   - Use proper authentication and authorization (JWT, sessions, etc.)
   - Never expose API keys or secrets in client-side code
   - Implement proper CORS policies
   - Use HTTPS for all production deployments

3. **Error Handling & Edge Cases**
   - Handle all error conditions gracefully (network failures, API errors)
   - Provide meaningful user-facing error messages
   - Consider edge cases (empty states, loading states, no data)
   - Add defensive checks for null/undefined values
   - Implement proper error boundaries in React
   - Log errors appropriately for debugging

4. **Web Testing Strategy**
   - Write unit tests for business logic and utility functions
   - Add component tests for React components
   - Test API endpoints (integration tests)
   - Test error conditions and edge cases
   - Consider end-to-end tests for critical user flows
   - Ensure tests are maintainable and readable

5. **Code Quality**
   - Write clean, readable, self-documenting code
   - Use meaningful variable and function names
   - Keep functions/components focused and single-purpose
   - Follow framework best practices and conventions
   - Avoid prop drilling (use context, state management libraries)
   - Use TypeScript types properly (avoid 'any')

6. **Performance Considerations**
   - Avoid unnecessary re-renders (React.memo, useMemo, useCallback)
   - Use appropriate data structures and algorithms
   - Implement code splitting and lazy loading
   - Optimize images (next/image, lazy loading, proper formats)
   - Minimize bundle size (tree shaking, analyze bundles)
   - Use server-side rendering or static generation appropriately
   - Implement proper caching strategies

7. **Web Accessibility**
   - Use semantic HTML elements
   - Add proper ARIA labels and roles
   - Ensure keyboard navigation works properly
   - Maintain sufficient color contrast (WCAG AA/AAA)
   - Support screen readers
   - Test with accessibility tools (axe, Lighthouse)

8. **Documentation**
   - Document public APIs and complex components
   - Add JSDoc comments for functions and types
   - Explain complex logic or non-obvious behaviors
   - Update relevant documentation if behavior changes
   - Include usage examples for reusable components

9. **Web-Specific Considerations**
   - Test across different browsers (Chrome, Firefox, Safari, Edge)
   - Ensure responsive design works on mobile and desktop
   - Consider SEO implications (meta tags, semantic HTML, SSR/SSG)
   - Handle loading states and progressive enhancement
   - Implement proper error boundaries
   - Consider offline functionality (PWA features if needed)
   - Monitor web vitals (LCP, FID, CLS)

Remember: Web implementation is not just about making it work—it's about making it work reliably, securely, accessibly, and performantly across all browsers and devices.
