#!/usr/bin/env python3
"""
Hook that adds debugging or investigation prompts based on trigger words in user messages for default development.
"""
import json
import re
import sys
from pathlib import Path

# Load guides from local workspace
def load_debug_guide(cwd):
    """Load debug guide from workspace .claude folder"""
    guide_path = Path(cwd) / ".claude" / "guides" / "debug.md"
    try:
        with open(guide_path, 'r') as f:
            return f.read()
    except Exception:
        return DEBUG_PROMPT_FALLBACK

def load_investigation_guide(cwd):
    """Load investigation guide from workspace .claude folder"""
    guide_path = Path(cwd) / ".claude" / "guides" / "investigation.md"
    try:
        with open(guide_path, 'r') as f:
            return f.read()
    except Exception:
        return INVESTIGATION_PROMPT_FALLBACK

def load_implementation_guide(cwd):
    """Load implementation guide from workspace .claude folder"""
    guide_path = Path(cwd) / ".claude" / "guides" / "implementation.md"
    try:
        with open(guide_path, 'r') as f:
            return f.read()
    except Exception:
        return IMPLEMENTATION_PROMPT_FALLBACK

def load_planning_guide(cwd):
    """Load planning guide from workspace .claude folder"""
    guide_path = Path(cwd) / ".claude" / "guides" / "planning.md"
    try:
        with open(guide_path, 'r') as f:
            return f.read()
    except Exception:
        return IMPLEMENTATION_PROMPT_FALLBACK

def load_parallel_guide(cwd):
    """Load parallel guide from workspace .claude folder"""
    guide_path = Path(cwd) / ".claude" / "guides" / "parallel.md"
    try:
        with open(guide_path, 'r') as f:
            return f.read()
    except Exception as e:
        return f"Error loading parallel guide: {e}"

# Debugging trigger patterns
DEBUG_PATTERNS = [
    r'\b(debug|debugging|bug)\b',
    r'\b(why.*not work|what.*wrong|not working)\b',
    r'\b(crash|exception|error|failed|\^\^\^)\b',
    r'\b(build.*fail|compile.*error|runtime.*error)\b'
]

# Investigation trigger patterns
INVESTIGATION_PATTERNS = [
    r'\b(investigate|research|analyze|examine|explore|understand)\b',
    r'\b(how does.*work|figure out|explain|find out)\b',
    r'\b(code review|audit|inspect)\b',
    r'\b(data.*flow|architecture|system.*design)\b'
]

# Implementation trigger patterns
IMPLEMENTATION_PATTERNS = [
    r'\b(implement|build|create|develop|code|write|add).*\b(feature|function|component|service|module|class|view)\b',
    r'\b(make|build|create|develop)\s+(this|it|the)\b',
    r'\b(let\'s|can you|please)\s+(implement|build|create|develop|code|write)\b',
    r'\bstart (implementing|building|coding|developing)\b'
]

# Planning trigger patterns
PLANNING_PATTERNS = [
    r'\b(make|create|develop|write|build).*\bplan\b',
    r'\bplan\s+(out|for|the)\b',
    r'\bplanning\s+(out|for|the)\b',
    r'\b(implementation|feature|system|architecture)\s+plan\b'
]

# Parallelization trigger patterns
PARALLEL_PATTERNS = [
    r'\b(parallel|parallelize|parallelization|concurrently|simultaneously)\b',
    r'\bin parallel\b',
    r'\bat the same time\b',
    r'\bconcurrent execution\b'
]

# Fallback prompts (used when guide files are not available)
DEBUG_PROMPT_FALLBACK = """1. **Understand the codebase** - Read relevant files/entities/assets to understand the codebase, and look up documentation for frameworks and libraries.
   - For simple searches: Use direct tools (Read/Grep/Glob)
   - For quick code location: Use @code-finder agent
   - For complex bugs: Deploy PARALLEL @code-finder-advanced agents (in SINGLE function_calls block)
     - Split by subsystems (UI/SwiftUI, AppKit, services, data, terminal integration) OR
     - Multiple agents investigating the same area from different angles
     - Lean towards parallel unless the bug is very simple
   - For systematic diagnosis: Use @root-cause-analyzer agent
2. **Identify 5-8 most likely root causes** - For non-obvious bugs, deploy PARALLEL @root-cause-analyzer agents (in SINGLE function_calls block)
   - Each agent focuses on different hypothesis categories (state management, async/threading, memory/lifecycle, external dependencies, AppKit/terminal integration)
   - Multiple agents can review the same bug from different investigation angles
   - Default to parallel investigation unless bug is trivial
   - List potential reasons for the issue (logic errors, state management, concurrency issues, memory management)
3. **Choose the 3 most likely causes** - Consolidate findings from parallel investigations and prioritize based on probability and impact
4. **Decide whether to implement or debug** - If the cause is obvious, implement the fix and inform the user. If the cause is not obvious, continue this workflow.

Steps for Non-obvious Causes:
5. **Add iterative logging to narrow down the issue**:
   - Start with broad, high-level logging to identify which subsystem/section contains the bug
   - Test and analyze output to determine the rough area
   - Add narrow, targeted logging within that specific section
   - Test again to pinpoint the exact issue
   - Focus on decision points and state changes—avoid overwhelming logs by logging everything
6. **Let the user test** - Have them run the app with the new logging
7. **Fix when solution is found** - Implement the actual fix once root cause is confirmed
8. **Remove all debugging artifacts** - Clean up temporary debugging code:
   - Logging statements: console.log/debug/warn, print(), NSLog, println, debugPrint, os_log (DEBUG-only)
   - Debug flags: DEBUG = true, isDebug = true, isDevelopment = true
   - Code markers: // DEBUG, // TEMP, // REMOVE, // FIXME (debugging context)
   - Test artifacts: Hardcoded test values, mock data, fake API responses
   - Commented debugging code blocks
   - Excessive verbose logging added during development
   - EXCEPTIONS (allowed): Debug UI features (user-facing diagnostic screens) OR release diagnostics infrastructure (like DebugLogger, properly gated for production)

Remember:
- Reading the entire file usually uncovers more information than just a snippet
- Without complete context, edge cases will be missed
- Making assumptions leads to poor analysis—stepping through code and logic sequentially is the best way to find the root cause

Include relevant debugging commands/tools (debugger, profiler, logging) and explain your reasoning for each step.

**Parallel Debugging Examples:**

Example 1: "Terminal output not rendering correctly"
→ Deploy 3 parallel @code-finder-advanced agents investigating different subsystems:
  - Agent 1: SwiftTerm integration and PTY handling
  - Agent 2: Text rendering and AppKit view hierarchy
  - Agent 3: Terminal state management and buffer updates

Example 2: "App works in Debug but crashes in Release"
→ Deploy 2-3 parallel @root-cause-analyzer agents reviewing the same bug from different angles:
  - Agent 1: Compiler optimizations and undefined behavior hypothesis
  - Agent 2: Debug-only dependencies and conditional compilation hypothesis
  - Agent 3: Memory layout and retain cycle hypothesis

Example 3: "Performance degrades over time"
→ Deploy 3 parallel @root-cause-analyzer agents on different hypothesis categories:
  - Agent 1: Memory management and retain cycles
  - Agent 2: Resource cleanup and lifecycle issues
  - Agent 3: Data accumulation and cache management"""

INVESTIGATION_PROMPT_FALLBACK = """1. **Assess scope**: Read provided files directly. Use code-finder or code-finder-advanced for unknown/large codebases, direct tools (Read/Grep/Glob) for simple searches.

2. **Use code-finder or code-finder-advanced when**: Complex investigations, no clear starting point, discovering patterns across many files, unclear functionality location.

3. **Use direct tools when**: Simple searches in known files, specific paths provided, trivial lookups.

4. **Flow**: Start with context → code-finder or code-finder-advanced for broad discovery → understand patterns before suggesting → answer first, implement if asked.

5. **Multiple agents**: Split non-overlapping domains, launch parallel in single function_calls block. Example: UI components, services, data layer agents.

Example: "How does authentication integrate with each of our services, and how could we refactor it with dependency injection?" → Use a code-finder first, and then multiple parallel code-finder-advanced tasks
Example: "Investigate and make plan out database sync" → Use parallel code-finder tasks
Example: "Where is user validation implemented?" → Use code-finder task
Example: "Do we have a formatDate function" → Use grep/bash/etc tools directly

This workflow ensures efficient investigation based on task complexity.
"""

IMPLEMENTATION_PROMPT = """
<system-reminder>The user has mentioned implementing or building a macOS feature/component.

<macos-implementation-best-practices>
Before implementing macOS features, ensure you follow these critical practices:

1. **Understand Existing Patterns**
   - Search for similar implementations in the codebase first
   - Follow established architectural patterns (MVVM, Coordinators, etc.)
   - Maintain consistency with existing AppKit/SwiftUI code style
   - Reuse existing view components, utilities, and services

2. **macOS-Specific Security**
   - Validate and sanitize ALL user inputs
   - Use Keychain for sensitive data storage (never UserDefaults)
   - Implement proper sandboxing and entitlements
   - Handle authentication securely
   - Request proper permissions for file access, camera, microphone, etc.
   - Use parameterized queries for database operations

3. **Error Handling & Edge Cases**
   - Handle all error conditions gracefully with proper Swift error handling
   - Provide meaningful user-facing error messages
   - Consider edge cases (empty states, nil values, data not loaded)
   - Add defensive nil-checking and guard statements
   - Implement proper logging for debugging (os_log, but remove debug logs before commit)

4. **macOS Testing Strategy**
   - Write unit tests for ViewModels and business logic
   - Add UI tests for critical user flows using XCTest
   - Test on multiple macOS versions if needed
   - Test error conditions and edge cases
   - Ensure tests are maintainable and readable

5. **Code Quality**
   - Write clean, readable, self-documenting Swift code
   - Use meaningful variable and function names
   - Keep functions/methods focused and single-purpose
   - Follow Swift API design guidelines
   - Avoid retain cycles (use weak/unowned references appropriately)
   - Use @MainActor appropriately for UI updates

6. **Performance Considerations**
   - Avoid blocking the main thread (use async/await, Task)
   - Use appropriate data structures and algorithms
   - Implement lazy loading for heavy resources
   - Profile with Instruments for performance bottlenecks
   - Optimize resource usage for long-running applications

7. **macOS Accessibility**
   - Add proper accessibility labels and hints
   - Support VoiceOver compatibility
   - Ensure keyboard navigation works properly
   - Maintain sufficient color contrast
   - Support assistive technologies

8. **Documentation**
   - Document public APIs with Swift doc comments (///)
   - Explain complex logic or non-obvious behaviors
   - Update relevant documentation if behavior changes
   - Include usage examples for reusable components

9. **macOS-Specific Considerations**
   - Check macOS version availability for new APIs (@available)
   - Handle app lifecycle events properly
   - Manage memory carefully (avoid retain cycles)
   - Consider window management and multi-window scenarios
   - Support menu bar integration if applicable
   - Handle system appearance changes (light/dark mode)

Remember: macOS implementation is not just about making it work—it's about making it work reliably, securely, performantly, and in a way that respects macOS platform conventions.
</macos-implementation-best-practices>
"""

IMPLEMENTATION_PROMPT_FALLBACK = """Before implementing macOS features, ensure you follow these critical practices:

1. **Understand Existing Patterns**
   - Search for similar implementations in the codebase first
   - Follow established architectural patterns (MVVM, Coordinators, etc.)
   - Maintain consistency with existing AppKit/SwiftUI code style
   - Reuse existing view components, utilities, and services

2. **macOS-Specific Security**
   - Validate and sanitize ALL user inputs
   - Use Keychain for sensitive data storage (never UserDefaults)
   - Implement proper sandboxing and entitlements
   - Handle authentication securely
   - Request proper permissions for file access, camera, microphone, etc.
   - Use parameterized queries for database operations

3. **Error Handling & Edge Cases**
   - Handle all error conditions gracefully with proper Swift error handling
   - Provide meaningful user-facing error messages
   - Consider edge cases (empty states, nil values, data not loaded)
   - Add defensive nil-checking and guard statements
   - Implement proper logging for debugging (os_log, but remove debug logs before commit)

4. **macOS Testing Strategy**
   - Write unit tests for ViewModels and business logic
   - Add UI tests for critical user flows using XCTest
   - Test on multiple macOS versions if needed
   - Test error conditions and edge cases
   - Ensure tests are maintainable and readable

5. **Code Quality**
   - Write clean, readable, self-documenting Swift code
   - Use meaningful variable and function names
   - Keep functions/methods focused and single-purpose
   - Follow Swift API design guidelines
   - Avoid retain cycles (use weak/unowned references appropriately)
   - Use @MainActor appropriately for UI updates

6. **Performance Considerations**
   - Avoid blocking the main thread (use async/await, Task)
   - Use appropriate data structures and algorithms
   - Implement lazy loading for heavy resources
   - Profile with Instruments for performance bottlenecks
   - Optimize resource usage for long-running applications

7. **macOS Accessibility**
   - Add proper accessibility labels and hints
   - Support VoiceOver compatibility
   - Ensure keyboard navigation works properly
   - Maintain sufficient color contrast
   - Support assistive technologies

8. **Documentation**
   - Document public APIs with Swift doc comments (///)
   - Explain complex logic or non-obvious behaviors
   - Update relevant documentation if behavior changes
   - Include usage examples for reusable components

9. **macOS-Specific Considerations**
   - Check macOS version availability for new APIs (@available)
   - Handle app lifecycle events properly
   - Manage memory carefully (avoid retain cycles)
   - Consider window management and multi-window scenarios
   - Support menu bar integration if applicable
   - Handle system appearance changes (light/dark mode)

Remember: macOS implementation is not just about making it work—it's about making it work reliably, securely, performantly, and in a way that respects macOS platform conventions.
"""

PLANNING_PROMPT_FALLBACK = """**Effective Implementation Planning Guide**

Before creating any plan, conduct thorough investigation—NOTHING can be left to assumptions. Specificity is critical for successful implementation.

A well-structured plan should include:

1. **Summary**
   - Clear, concise description of what functionality will be implemented
   - The core problem being solved or feature being added

2. **Reasoning/Motivation**
   - Why this approach was chosen
   - Trade-offs considered (performance vs simplicity, flexibility vs complexity)
   - Key decisions made during investigation

3. **Current System Overview**
   - How the existing system works (be specific)
   - Key files and their responsibilities:
     - List actual file paths (e.g., src/services/AuthService.js, src/components/Dashboard.jsx)
     - Describe what each file does in the current implementation
   - Dependencies and data flow

4. **New System Design**
   - How the system will work after implementation
   - New or modified files required:
     - List exact file paths that will be created or changed
     - Describe the purpose of each change
   - Integration points with existing code

5. **Other Relevant Context**
   - Utility functions or helpers needed (with file paths)
   - Interface definitions or model interfaces (with file paths)
   - Configuration changes required (config files, environment variables)
   - External dependencies or libraries
   - Testing considerations (unit tests, integration tests)

**What NOT to include in plans:**
- Code snippets or implementation details
- Timelines or effort estimates
- Self-evident advice for developers
- Generic best practices
- Vague descriptions without file references

**Critical Requirements:**
- Every assertion must be based on actual investigation, not assumptions
- All file references must be exact paths discovered during research
- Dependencies between components must be explicitly mapped
- Edge cases and constraints must be identified through code analysis

Remember: A plan fails when it makes assumptions about behavior. Investigate thoroughly, reference specifically, plan comprehensively."""

# Prompt generator functions
def get_debug_prompt(cwd):
    """Generate debug prompt with loaded guide content"""
    debug_guide_content = load_debug_guide(cwd)
    return f"""
<system-reminder>The user has mentioned a key word or phrase that triggers this reminder for macos debugging.

<debugging-workflow>
{debug_guide_content}
</debugging-workflow>

</system-reminder>
"""

def get_investigation_prompt(cwd):
    """Generate investigation prompt with loaded guide content"""
    investigation_guide_content = load_investigation_guide(cwd)
    return f"""
<system-reminder>The user has mentioned a key word or phrase that triggers this reminder for macos investigation.

<investigation-workflow>
{investigation_guide_content}
</investigation-workflow>

</system-reminder>
"""

def get_implementation_prompt(cwd):
    """Generate implementation prompt with loaded guide content"""
    implementation_guide_content = load_implementation_guide(cwd)
    return f"""
<system-reminder>The user has mentioned implementing or building a macos feature/component.

<macos-implementation-best-practices>
{implementation_guide_content}
</macos-implementation-best-practices>

</system-reminder>
"""

def get_planning_prompt(cwd):
    """Generate planning prompt with loaded guide content"""
    planning_guide_content = load_planning_guide(cwd)
    return f"""
<system-reminder>The user has mentioned creating or making a plan for macos development. Here's some advice for making plans:

<planning-workflow>
{planning_guide_content}
</planning-workflow>

</system-reminder>
"""

def get_parallel_prompt(cwd):
    """Generate parallel prompt with loaded guide content"""
    parallel_guide_content = load_parallel_guide(cwd)
    return f"""
<system-reminder>The user has mentioned parallel execution or parallelization for development.

<parallelization-guide>
{parallel_guide_content}
</parallelization-guide>

</system-reminder>
"""

def check_patterns(text, patterns):
    """Check if any pattern matches the text (case insensitive)."""
    for pattern in patterns:
        if re.search(pattern, text, re.IGNORECASE):
            return True
    return False

try:
    input_data = json.load(sys.stdin)
except json.JSONDecodeError as e:
    print(f"Error: Invalid JSON input: {e}", file=sys.stderr)
    sys.exit(1)

prompt = input_data.get("prompt", "")
cwd = input_data.get("cwd", "")

# Collect all matching reminders with their names
triggered = []

# Check for debugging triggers
if check_patterns(prompt, DEBUG_PATTERNS):
    triggered.append(("DEBUG", get_debug_prompt(cwd)))

# Check for investigation triggers
if check_patterns(prompt, INVESTIGATION_PATTERNS):
    triggered.append(("INVESTIGATION", get_investigation_prompt(cwd)))

# Check for implementation triggers
if check_patterns(prompt, IMPLEMENTATION_PATTERNS):
    triggered.append(("IMPLEMENTATION", get_implementation_prompt(cwd)))

# Check for planning triggers
if check_patterns(prompt, PLANNING_PATTERNS):
    triggered.append(("PLANNING", get_planning_prompt(cwd)))

# Check for parallelization triggers
if check_patterns(prompt, PARALLEL_PATTERNS):
    triggered.append(("PARALLELIZATION", get_parallel_prompt(cwd)))

# Print each reminder with instruction for Claude to report
if triggered:
    output = []

    # First, tell Claude to report what was triggered
    trigger_names = [name for name, _ in triggered]
    instruction = f"""<system-reminder>
IMPORTANT: Immediately inform the user that the following reminder hooks were triggered:
{', '.join(trigger_names)}

Display this to the user in a clear, visible format before proceeding with their request.
</system-reminder>
"""
    output.append(instruction)

    # Then add the actual reminder content
    for name, prompt_text in triggered:
        output.append(prompt_text)

    print("\n\n".join(output))

# Allow normal processing
sys.exit(0)