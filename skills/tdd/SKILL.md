---
name: tdd
description: Enforce strict test-driven development - RED-GREEN-REFACTOR with no production code without failing tests
user-invocable: true
---

# Test-Driven Development (TDD)

Write the test first. Watch it fail. Write minimal code to pass.

**Core principle:** If you didn't watch the test fail, you don't know if it tests the right thing.

## When to Use

**Always** for new features, bug fixes, refactoring, behavior changes.

**Exceptions (ask human partner):** throwaway prototypes, generated code, configuration files.

## The Iron Law

```
NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
```

Write code before the test? Delete it. Start over. No exceptions -- don't keep as "reference", don't "adapt" it.

## Red-Green-Refactor

### RED -- Write Failing Test

Write one minimal test showing what should happen.

<Good>
```typescript
test('retries failed operations 3 times', async () => {
  let attempts = 0;
  const operation = () => {
    attempts++;
    if (attempts < 3) throw new Error('fail');
    return 'success';
  };

const result = await retryOperation(operation);

expect(result).toBe('success');
expect(attempts).toBe(3);
});

````
Clear name, tests real behavior, one thing
</Good>

<Bad>
```typescript
test('retry works', async () => {
  const mock = jest.fn()
    .mockRejectedValueOnce(new Error())
    .mockRejectedValueOnce(new Error())
    .mockResolvedValueOnce('success');
  await retryOperation(mock);
  expect(mock).toHaveBeenCalledTimes(3);
});
````

Vague name, tests mock not code
</Bad>

**Requirements:** One behavior. Clear name. Real code (no mocks unless unavoidable).

### Verify RED -- Watch It Fail

**MANDATORY. Never skip.**

Run tests. Confirm:

- Test fails (not errors)
- Failure message is expected
- Fails because feature missing (not typos)

Test passes? You're testing existing behavior. Fix test.
Test errors? Fix error, re-run until it fails correctly.

### GREEN -- Minimal Code

Write simplest code to pass the test. Don't add features, refactor other code, or "improve" beyond the test.

<Good>
```typescript
async function retryOperation<T>(fn: () => Promise<T>): Promise<T> {
  for (let i = 0; i < 3; i++) {
    try {
      return await fn();
    } catch (e) {
      if (i === 2) throw e;
    }
  }
  throw new Error('unreachable');
}
```
Just enough to pass
</Good>

<Bad>
```typescript
async function retryOperation<T>(
  fn: () => Promise<T>,
  options?: {
    maxRetries?: number;
    backoff?: 'linear' | 'exponential';
    onRetry?: (attempt: number) => void;
  }
): Promise<T> {
  // YAGNI
}
```
Over-engineered
</Bad>

### Verify GREEN -- Watch It Pass

**MANDATORY.** Run tests. Confirm: test passes, other tests still pass, no warnings.

Test fails? Fix code, not test. Other tests fail? Fix now.

### REFACTOR -- Clean Up

After green only: remove duplication, improve names, extract helpers. Keep tests green. Don't add behavior.

Then: next failing test for next behavior.

## Good Tests

| Quality          | Good                                | Bad                                                 |
| ---------------- | ----------------------------------- | --------------------------------------------------- |
| **Minimal**      | One thing. "and" in name? Split it. | `test('validates email and domain and whitespace')` |
| **Clear**        | Name describes behavior             | `test('test1')`                                     |
| **Shows intent** | Demonstrates desired API            | Obscures what code should do                        |

## Example: Bug Fix

**Bug:** Empty email accepted

**RED**

```typescript
test("rejects empty email", async () => {
  const result = await submitForm({ email: "" });
  expect(result.error).toBe("Email required");
});
```

**Verify RED** -- `FAIL: expected 'Email required', got undefined`

**GREEN**

```typescript
function submitForm(data: FormData) {
  if (!data.email?.trim()) {
    return { error: "Email required" };
  }
  // ...
}
```

**Verify GREEN** -- `PASS`

**REFACTOR** -- Extract validation for multiple fields if needed.

## Red Flags -- Delete Code, Start Over

- Code written before test
- Test passes immediately (testing existing behavior)
- Can't explain why test failed
- Rationalizing "just this once", "too simple to test", "I'll test after"
- Keeping pre-test code as "reference"
- "TDD is dogmatic, I'm being pragmatic"

## When Stuck

| Problem                | Solution                                                        |
| ---------------------- | --------------------------------------------------------------- |
| Don't know how to test | Write wished-for API. Write assertion first. Ask human partner. |
| Test too complicated   | Design too complicated. Simplify interface.                     |
| Must mock everything   | Code too coupled. Use dependency injection.                     |
| Test setup huge        | Extract helpers. Still complex? Simplify design.                |

## Verification Checklist

Before marking work complete:

- [ ] Every new function/method has a test
- [ ] Watched each test fail before implementing
- [ ] Each test failed for expected reason
- [ ] Wrote minimal code to pass each test
- [ ] All tests pass, output pristine
- [ ] Tests use real code (mocks only if unavoidable)
- [ ] Edge cases and errors covered

When adding mocks or test utilities, read @testing-anti-patterns.md to avoid testing mock behavior instead of real behavior.

## Final Rule

```
Production code -> test exists and failed first
Otherwise -> not TDD
```

No exceptions without human partner's permission.
