---
name: verify
description: Mandatory verification before claiming completion - no speculative language, evidence only
user-invocable: true
---

# Verification Before Completion

**Core principle:** Evidence before claims, always. No exceptions.

## The Gate Function

```
BEFORE claiming any status:

1. IDENTIFY: What command proves this claim?
2. RUN: Execute the FULL command (fresh, in this message)
3. READ: Full output, check exit code, count failures
4. VERIFY: Does output confirm the claim?
   - If NO: State actual status with evidence
   - If YES: State claim WITH evidence
5. ONLY THEN: Make the claim

Skip any step = unverified claim
```

## Verification Requirements

| Claim            | Requires                 | Not Sufficient                   |
| ---------------- | ------------------------ | -------------------------------- |
| Tests pass       | Test output: 0 failures  | Previous run, "should pass"      |
| Linter clean     | Linter output: 0 errors  | Partial check, extrapolation     |
| Build succeeds   | Build command: exit 0    | Linter passing, "logs look good" |
| Bug fixed        | Original symptom: passes | Code changed, assumed fixed      |
| Regression test  | Red-green cycle verified | Test passes once                 |
| Agent completed  | VCS diff shows changes   | Agent reports "success"          |
| Requirements met | Line-by-line checklist   | Tests passing alone              |

## Key Patterns

**Tests:**

```
[Run test command] -> [See: 34/34 pass] -> "All tests pass"
NOT: "Should pass now" / "Looks correct"
```

**Regression tests (TDD Red-Green):**

```
Write -> Run (pass) -> Revert fix -> Run (MUST FAIL) -> Restore -> Run (pass)
```

**Build:**

```
[Run build] -> [See: exit 0] -> "Build passes"
NOT: "Linter passed" (linter != compiler)
```

**Requirements:**

```
Re-read plan -> Create checklist -> Verify each -> Report gaps or completion
```

**Agent delegation:**

```
Agent reports success -> Check VCS diff -> Verify changes -> Report actual state
```

## Red Flags -- STOP

- Using "should", "probably", "seems to"
- Expressing satisfaction before verification
- About to commit/push/PR without verification
- Trusting agent success reports without independent verification
- Relying on partial verification
- Any wording implying success without having run verification

## When To Apply

**Always before:** completion claims, positive statements about work state, commits, PR creation, task completion, moving to next task, delegating to agents.

**No shortcuts. Run the command. Read the output. THEN claim the result.**
