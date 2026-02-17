---
name: security
description: Review git diffs for security vulnerabilities including injection, XSS, deserialization, and credential exposure
user-invocable: true
---

**Arguments:** `$ARGUMENTS` - Optional: `staged`, commit range, or file path

## Context

- Diff: !`git diff HEAD`
- Git root: !`git rev-parse --show-toplevel 2>/dev/null || echo "Not a git repo"`

## Scope Resolution

| Argument | Diff Command |
|----------|--------------|
| (none) | `git diff HEAD` |
| `staged` | `git diff --cached` |
| `<commit>` or `<range>` | `git diff <commit>` |
| `<file>` | `git diff HEAD -- <file>` |

## Vulnerability Categories

Scan for patterns in these categories:
- Command injection (shell/exec/eval/subprocess)
- XSS (innerHTML, dangerouslySetInnerHTML, document.write)
- SQL injection (string concatenation, missing parameterization)
- Unsafe deserialization (pickle, yaml.load, unserialize)
- Credential exposure (hardcoded secrets, API keys, tokens)
- Path traversal (unsanitized user input in file paths)
- Weak cryptography (MD5/SHA1 for security, ECB mode, weak keys)
- GitHub Actions injection (`${{ github.event.* }}` in run blocks)

## Challenge Each Finding

Before reporting, test each finding against: (1) Context check — is there sanitization/validation within 5-10 lines or in the call chain? (2) Reachability — can untrusted input actually reach this code path? (3) Framework protection — does the framework handle this by default (e.g. ORM parameterization, React JSX escaping)? (4) Test vs prod — could this be test/example code? Downgrade or drop findings that fail these checks. If uncertain, keep but note the uncertainty.

## Rules

- Only report >= 75% confidence findings
- Skip test files and documentation
- Check for nearby sanitization before reporting

## Output

Report findings as:
```
### [SEVERITY] Category - file:line
<code snippet>
**Risk**: <impact>  **Fix**: <remediation>
```

Or if clean: "No high-confidence security issues found." with scan summary.
