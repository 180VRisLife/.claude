#!/usr/bin/env python3
"""
Hook that adds debugging or investigation prompts based on trigger words in user messages for iOS development.
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
        return PLANNING_PROMPT_FALLBACK

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
    r'\b(build.*fail|compile.*error|runtime.*error)\b',
    r'\b(xcode.*error|swift.*error)\b'
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
DEBUG_PROMPT_FALLBACK = """1. **Understand the codebase** - Read relevant files/models/views/view controllers to understand the codebase, and look up documentation for iOS frameworks and libraries.
   - For simple searches: Use direct tools (Read/Grep/Glob)
   - For quick code location: Use @code-finder agent
   - For complex bugs: Deploy PARALLEL @code-finder-advanced agents (in SINGLE function_calls block)
     - Split by subsystems (UI/SwiftUI, services, data/Core Data, networking) OR
     - Multiple agents investigating the same area from different angles
     - Lean towards parallel unless the bug is very simple
   - For systematic diagnosis: Use @root-cause-analyzer agent
2. **Identify 5-8 most likely root causes** - For non-obvious bugs, deploy PARALLEL @root-cause-analyzer agents (in SINGLE function_calls block)
   - Each agent focuses on different hypothesis categories (state management, threading/Main actor, memory/retain cycles, view lifecycle, external dependencies)
   - Multiple agents can review the same bug from different investigation angles
   - Default to parallel investigation unless bug is trivial
   - List potential reasons for the issue (logic errors, state management, threading issues, memory management, view lifecycle, retain cycles)
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
   - Logging statements: print(), NSLog, debugPrint, os_log (DEBUG-only)
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

Include relevant iOS debugging commands/tools (lldb, Xcode debugger, Instruments, breakpoints) and explain your reasoning for each step.

**Parallel Debugging Examples:**

Example 1: "SwiftUI view not updating when data changes"
→ Deploy 3 parallel @code-finder-advanced agents investigating different subsystems:
  - Agent 1: SwiftUI view hierarchy and @State/@ObservedObject bindings
  - Agent 2: Data models and Combine publishers
  - Agent 3: View lifecycle and update triggers

Example 2: "App crashes only on device, not simulator"
→ Deploy 2-3 parallel @root-cause-analyzer agents reviewing the same bug from different angles:
  - Agent 1: Memory constraints and device-specific resource limits hypothesis
  - Agent 2: Threading and Main actor isolation hypothesis
  - Agent 3: Permissions and entitlements hypothesis

Example 3: "UI freezing during network requests"
→ Deploy 3 parallel @root-cause-analyzer agents on different hypothesis categories:
  - Agent 1: Main thread blocking and async/await usage
  - Agent 2: Network request lifecycle and cancellation
  - Agent 3: UI update batching and rendering performance"""

INVESTIGATION_PROMPT_FALLBACK = """1. **Assess scope**: Read provided files directly. Use code-finder or code-finder-advanced for unknown/large codebases, direct tools (Read/Grep/Glob) for simple searches.

2. **Use code-finder or code-finder-advanced when**: Complex investigations, no clear starting point, discovering patterns across many files, unclear functionality location.

3. **Use direct tools when**: Simple searches in known files, specific paths provided, trivial lookups.

4. **Flow**: Start with context → code-finder or code-finder-advanced for broad discovery → understand patterns before suggesting → answer first, implement if asked.

5. **Multiple agents**: Split non-overlapping domains, launch parallel in single function_calls block. Example: UI/SwiftUI agents, networking agents, architecture agents.

Example: "How does authentication integrate with each of our services, and how could we refactor it with dependency injection?" → Use a code-finder first, and then multiple parallel code-finder-advanced tasks
Example: "Investigate and make plan out Core Data sync" → Use parallel code-finder tasks
Example: "Where is user validation implemented?" → Use code-finder task
Example: "Do we have a formatDate function" → Use grep/bash/etc tools directly

This workflow ensures efficient iOS investigation based on task complexity.
"""

IMPLEMENTATION_PROMPT_FALLBACK = """Before implementing iOS features, ensure you follow these critical practices:

1. **Understand Existing Patterns**
   - Search for similar implementations in the codebase first
   - Follow established architectural patterns (MVVM, Coordinators, etc.)
   - Maintain consistency with existing SwiftUI/UIKit code style
   - Reuse existing view components, utilities, and services

2. **iOS-Specific Security**
   - Validate and sanitize ALL user inputs
   - Use Keychain for sensitive data storage (never UserDefaults)
   - Implement proper App Transport Security (ATS) configurations
   - Handle authentication tokens securely
   - Respect user privacy with proper permission requests
   - Use parameterized queries for Core Data/SQL operations

3. **Error Handling & Edge Cases**
   - Handle all error conditions gracefully with proper Swift error handling
   - Provide meaningful user-facing error messages
   - Consider edge cases (empty states, nil values, data not loaded)
   - Add defensive nil-checking and guard statements
   - Implement proper logging for debugging (os_log, but remove debug logs before commit)

4. **iOS Testing Strategy**
   - Write unit tests for ViewModels and business logic
   - Add UI tests for critical user flows using XCTest
   - Test on multiple device sizes and orientations
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
   - Optimize image loading and caching

7. **iOS Accessibility**
   - Add proper accessibility labels and hints
   - Support Dynamic Type for text scaling
   - Ensure VoiceOver compatibility
   - Maintain sufficient color contrast
   - Support keyboard navigation and assistive technologies

8. **Documentation**
   - Document public APIs with Swift doc comments (///)
   - Explain complex logic or non-obvious SwiftUI behaviors
   - Update relevant documentation if behavior changes
   - Include usage examples for reusable components

9. **iOS-Specific Considerations**
   - Check iOS version availability for new APIs (@available)
   - Handle app lifecycle events properly
   - Manage memory carefully (avoid retain cycles)
   - Test on actual devices, not just simulator
   - Consider battery and network impact

Remember: iOS implementation is not just about making it work—it's about making it work reliably, securely, performantly, and in a way that respects iOS platform conventions.
"""

PLANNING_PROMPT_FALLBACK = """**Effective iOS Implementation Planning Guide**

Before creating any plan, conduct thorough investigation—NOTHING can be left to assumptions. Specificity is critical for successful iOS implementation.

A well-structured plan should include:

1. **Summary**
   - Clear, concise description of what functionality will be implemented
   - The core problem being solved or feature being added

2. **Reasoning/Motivation**
   - Why this approach was chosen
   - Trade-offs considered (performance vs simplicity, UIKit vs SwiftUI, flexibility vs complexity)
   - Key decisions made during investigation

3. **Current System Overview**
   - How the existing system works (be specific)
   - Key files and their responsibilities:
     - List actual file paths (e.g., Sources/Services/AuthService.swift, Sources/Views/DashboardView.swift)
     - Describe what each file does in the current implementation
   - Dependencies and data flow
   - iOS version requirements and framework dependencies

4. **New System Design**
   - How the system will work after implementation
   - New or modified files required:
     - List exact file paths that will be created or changed
     - Describe the purpose of each change
   - Integration points with existing code
   - View models, coordinators, or architectural components needed

5. **Other Relevant Context**
   - Utility functions or helpers needed (with file paths)
   - Protocol definitions or model structs (with file paths)
   - Configuration changes required (Info.plist, build settings, entitlements)
   - External dependencies or SPM/CocoaPods packages
   - Testing considerations (unit tests, UI tests)
   - Memory management considerations (retain cycles, weak references)
   - Threading requirements (@MainActor, background queues)

**What NOT to include in plans:**
- Code snippets or implementation details
- Timelines or effort estimates
- Self-evident advice for iOS developers
- Generic best practices
- Vague descriptions without file references

**Critical Requirements:**
- Every assertion must be based on actual investigation, not assumptions
- All file references must be exact paths discovered during research
- Dependencies between components must be explicitly mapped
- Edge cases and constraints must be identified through code analysis
- iOS framework APIs and their availability must be verified

Remember: A plan fails when it makes assumptions about behavior. Investigate thoroughly, reference specifically, plan comprehensively."""

# Prompt generator functions
def get_debug_prompt(cwd):
    """Generate debug prompt with loaded guide content"""
    debug_guide_content = load_debug_guide(cwd)
    return f"""
<system-reminder>The user has mentioned a key word or phrase that triggers this reminder for iOS debugging.

<debugging-workflow>
{debug_guide_content}
</debugging-workflow>

</system-reminder>
"""

def get_investigation_prompt(cwd):
    """Generate investigation prompt with loaded guide content"""
    investigation_guide_content = load_investigation_guide(cwd)
    return f"""
<system-reminder>The user has mentioned a key word or phrase that triggers this reminder for iOS investigation.

<investigation-workflow>
{investigation_guide_content}
</investigation-workflow>

</system-reminder>
"""

def get_implementation_prompt(cwd):
    """Generate implementation prompt with loaded guide content"""
    implementation_guide_content = load_implementation_guide(cwd)
    return f"""
<system-reminder>The user has mentioned implementing or building an iOS feature/component.

<ios-implementation-best-practices>
{implementation_guide_content}
</ios-implementation-best-practices>

</system-reminder>
"""

def get_planning_prompt(cwd):
    """Generate planning prompt with loaded guide content"""
    planning_guide_content = load_planning_guide(cwd)
    return f"""
<system-reminder>The user has mentioned creating or making a plan for iOS development. Here's some advice for making plans:

<planning-workflow>
{planning_guide_content}
</planning-workflow>

</system-reminder>
"""

def get_parallel_prompt(cwd):
    """Generate parallel prompt with loaded guide content"""
    parallel_guide_content = load_parallel_guide(cwd)
    return f"""
<system-reminder>The user has mentioned parallel execution or parallelization for iOS development.

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
