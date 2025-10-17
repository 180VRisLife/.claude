#!/usr/bin/env python3
"""
Hook that adds debugging or investigation prompts based on trigger words in user messages for Stream Deck plugin development.
"""
import json
import re
import sys
from pathlib import Path

# Load the shared parallel execution guide from local workspace
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

# Prompt improvement trigger patterns
PROMPT_IMPROVEMENT_PATTERNS = [
    r'\b(improv|enhanc).*\b(prompt|prompting)\b',
    r'\b(prompt|prompting).*\b(improv|enhanc)\b',
    r'\b(better|optimize|refine).*\b(prompt|prompting)\b',
    r'\b(prompt|prompting).*\b(better|optimize|refine)\b'
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

DEBUG_PROMPT = """
<system-reminder>The user has mentioned a key word or phrase that triggers this reminder for debugging.

<debugging-workflow>
1. **Understand the codebase** - Read relevant files/entities/assets to understand the codebase, and look up documentation for frameworks and libraries.
2. **Identify 5-8 most likely root causes** - List potential reasons for the issue (logic errors, state management, concurrency issues, memory management)
3. **Choose the 3 most likely causes** - Prioritize based on probability and impact
4. **Decide whether to implement or debug** - If the cause is obvious, implement the fix and inform the user. If the cause is not obvious, continue this workflow.

Steps for Non-obvious Causes:
5. **For each of the 3 causes, validate by adding targeted logging/debugging**
6. **Let the user test** - Have them run the app with the new logging
7. **Fix when solution is found** - Implement the actual fix once root cause is confirmed
8. **Remove debugging logs** - Clean up temporary debugging code

Remember:
- Reading the entire file usually uncovers more information than just a snippet
- Without complete context, edge cases will be missed
- Making assumptions leads to poor analysis—stepping through code and logic sequentially is the best way to find the root cause

Include relevant debugging commands/tools (debugger, profiler, logging) and explain your reasoning for each step.
</debugging-workflow>

</system-reminder>
"""

INVESTIGATION_PROMPT = """
<system-reminder>The user has mentioned a key word or phrase that triggers this reminder for investigation.

<investigation-workflow>
1. **Assess scope**: Read provided files directly. Use code-finder or code-finder-advanced for unknown/large codebases, direct tools (Read/Grep/Glob) for simple searches.

2. **Use code-finder or code-finder-advanced when**: Complex investigations, no clear starting point, discovering patterns across many files, unclear functionality location.

3. **Use direct tools when**: Simple searches in known files, specific paths provided, trivial lookups.

4. **Flow**: Start with context → code-finder or code-finder-advanced for broad discovery → understand patterns before suggesting → answer first, implement if asked.

5. **Multiple agents**: Split non-overlapping domains, launch parallel in single function_calls block. Example: UI components, services, data layer agents.

Example: "How does authentication integrate with each of our services, and how could we refactor it with dependency injection?" → Use a code-finder first, and then multiple parallel code-finder-advanced tasks
Example: "Investigate and make plan out database sync" → Use parallel code-finder tasks
Example: "Where is user validation implemented?" → Use code-finder task
Example: "Do we have a formatDate function" → Use grep/bash/etc tools directly
</investigation-workflow>

This workflow ensures efficient investigation based on task complexity.
"""

PROMPT_IMPROVEMENT_PROMPT = """
<system-reminder>The user has mentioned improving or enhancing prompts/prompting for Stream Deck plugin development.

CRITICAL: You MUST first read ~/.claude/guides/streamdeck/streamdeck-prompting-guide.md for comprehensive guidance on writing effective prompts. If you haven't read this guide yet in this conversation, read it immediately before proceeding with any prompt-related suggestions.

Only after reading and understanding this guide should you provide prompt improvement recommendations.

If the user is not looking to improve a prompt, or you have already read the guide, ignore this reminder.
</system-reminder>
"""

PLANNING_PROMPT = """
<system-reminder>The user has mentioned creating or making a plan for Stream Deck plugin development. Here's some advice for making plans:

<planning-workflow>
**Effective Implementation Planning Guide**

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
   - How the existing plugin works (be specific)
   - Key files and their responsibilities:
     - List actual file paths (e.g., src/actions/CounterAction.ts, ui/property-inspector.html, manifest.json)
     - Describe what each file does in the current implementation
   - Dependencies and data flow

4. **New System Design**
   - How the plugin will work after implementation
   - New or modified files required:
     - List exact file paths that will be created or changed
     - Describe the purpose of each change
   - Integration points with existing code

5. **Other Relevant Context**
   - Utility functions or helpers needed (with file paths)
   - Action class definitions or SDK types (with file paths)
   - Configuration changes required (manifest.json, property inspectors)
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

Remember: A plan fails when it makes assumptions about behavior. Investigate thoroughly, reference specifically, plan comprehensively.
</planning-workflow>

</system-reminder>
"""

def get_parallel_prompt(cwd):
    """Generate parallel prompt with loaded guide content"""
    parallel_guide_content = load_parallel_guide(cwd)
    return f"""
<system-reminder>The user has mentioned parallel execution or parallelization for Stream Deck plugin development.

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

# Check for debugging triggers
if check_patterns(prompt, DEBUG_PATTERNS):
    print(DEBUG_PROMPT)
    sys.exit(0)

# Check for investigation triggers
if check_patterns(prompt, INVESTIGATION_PATTERNS):
    print(INVESTIGATION_PROMPT)
    sys.exit(0)

# Check for prompt improvement triggers
if check_patterns(prompt, PROMPT_IMPROVEMENT_PATTERNS):
    print(PROMPT_IMPROVEMENT_PROMPT)
    sys.exit(0)

# Check for planning triggers
if check_patterns(prompt, PLANNING_PATTERNS):
    print(PLANNING_PROMPT)
    sys.exit(0)

# Check for parallelization triggers
if check_patterns(prompt, PARALLEL_PATTERNS):
    print(get_parallel_prompt(cwd))
    sys.exit(0)

# No triggers matched, allow normal processing
sys.exit(0)