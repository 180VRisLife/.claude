# Testing Anti-Patterns

**Load when:** writing/changing tests, adding mocks, or tempted to add test-only methods to production code.

**Core principle:** Test what the code does, not what the mocks do.

## The Iron Laws

```
1. NEVER test mock behavior
2. NEVER add test-only methods to production classes
3. NEVER mock without understanding dependencies
```

## Anti-Pattern 1: Testing Mock Behavior

**Bad:** Asserting on mock elements instead of real behavior.

```typescript
test('renders sidebar', () => {
  render(<Page />);
  expect(screen.getByTestId('sidebar-mock')).toBeInTheDocument();
});
```

**Fix:** Test real component or don't mock it.

```typescript
test('renders sidebar', () => {
  render(<Page />);  // Don't mock sidebar
  expect(screen.getByRole('navigation')).toBeInTheDocument();
});
```

**Gate:** Before asserting on any mock element, ask: "Am I testing real behavior or mock existence?" If mock existence: delete the assertion or unmock the component.

## Anti-Pattern 2: Test-Only Methods in Production

**Bad:** Adding methods to production classes that are only called in tests.

```typescript
class Session {
  async destroy() {
    // Only used in afterEach()
    await this._workspaceManager?.destroyWorkspace(this.id);
  }
}
```

**Fix:** Put cleanup logic in test utilities.

```typescript
// test-utils/
export async function cleanupSession(session: Session) {
  const workspace = session.getWorkspaceInfo();
  if (workspace) {
    await workspaceManager.destroyWorkspace(workspace.id);
  }
}
```

**Gate:** Before adding any method to a production class, ask: "Is this only used by tests?" If yes: put it in test utilities. Also: "Does this class own this resource's lifecycle?" If no: wrong class.

## Anti-Pattern 3: Mocking Without Understanding

**Bad:** Over-mocking breaks behavior the test depends on.

```typescript
test("detects duplicate server", () => {
  // Mock prevents config write that test depends on!
  vi.mock("ToolCatalog", () => ({
    discoverAndCacheTools: vi.fn().mockResolvedValue(undefined),
  }));
  await addServer(config);
  await addServer(config); // Should throw - but won't!
});
```

**Fix:** Mock at the correct level -- preserve behavior the test needs.

```typescript
test("detects duplicate server", () => {
  vi.mock("MCPServerManager"); // Just mock slow server startup
  await addServer(config); // Config written
  await addServer(config); // Duplicate detected
});
```

**Gate:** Before mocking, identify the real method's side effects. If the test depends on any of them, mock at a lower level. If unsure: run with real implementation first, then add minimal mocking.

Red flags: "I'll mock this to be safe", mocking without understanding the dependency chain.

## Anti-Pattern 4: Incomplete Mocks

**Bad:** Only mocking fields you think you need.

```typescript
const mockResponse = {
  status: "success",
  data: { userId: "123", name: "Alice" },
  // Missing: metadata that downstream code uses
};
```

**Fix:** Mirror the complete real data structure.

```typescript
const mockResponse = {
  status: "success",
  data: { userId: "123", name: "Alice" },
  metadata: { requestId: "req-789", timestamp: 1234567890 },
};
```

**Gate:** Before creating mock data, check the real API response structure. Include ALL fields the system might consume downstream. If uncertain, include all documented fields.

## Quick Reference

| Anti-Pattern                            | Fix                                           |
| --------------------------------------- | --------------------------------------------- |
| Assert on mock elements                 | Test real component or unmock it              |
| Test-only methods in production         | Move to test utilities                        |
| Mock without understanding              | Understand dependencies first, mock minimally |
| Incomplete mocks                        | Mirror real API completely                    |
| Over-complex mocks (setup >50% of test) | Consider integration tests                    |

## Red Flags

- Assertions checking for `*-mock` test IDs
- Methods only called in test files
- Mock setup is >50% of test
- Test fails when you remove mock
- Can't explain why mock is needed
- Mocking "just to be safe"
