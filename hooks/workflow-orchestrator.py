#!/usr/bin/env python3
"""
Workflow Orchestrator Hook
Intelligently injects workflow guides based on user prompts for enhanced context-aware assistance.
- Injects foundation.md once per session (not on every prompt)
- Conditionally injects additional guides based on trigger keywords (once per session each)
- Supports stacking multiple guides for comprehensive guidance
- Uses session state tracking to prevent context bloat from repeated injections
"""
import hashlib
import json
import os
import re
import sys
from pathlib import Path

# Session state tracking
# Session is determined by Claude Code's process ID (ppid) - when Claude restarts, new PID = new session

def get_session_file(cwd):
    """Get session file path based on cwd + parent process (Claude Code's PID)"""
    ppid = os.getppid()  # Claude Code's process - changes when Claude restarts
    # Use MD5 for deterministic hashing (Python's hash() is randomized per-process)
    cwd_hash = hashlib.md5(cwd.encode()).hexdigest()[:12]
    session_id = f"{cwd_hash}-{ppid}"
    return Path(f"/tmp/claude-workflow-{session_id}.json")

def get_injected_guides(session_file):
    """Read which guides have been injected this session (based on Claude Code PID)"""
    try:
        if session_file.exists():
            with open(session_file) as f:
                return set(json.load(f).get("injected", []))
    except Exception:
        pass
    return set()

def save_injected_guides(session_file, guides):
    """Save which guides have been injected this session"""
    try:
        with open(session_file, 'w') as f:
            json.dump({"injected": list(guides)}, f)
    except Exception:
        pass  # Fail silently - injection still works, just won't dedupe

# Load guides from local workspace
def load_guide(cwd, guide_name):
    """Load guide from workspace .claude/guides folder"""
    guide_path = Path(cwd) / ".claude" / "guides" / f"{guide_name}.md"
    try:
        with open(guide_path, 'r') as f:
            return f.read()
    except Exception:
        return None

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
    r'\b(implement|build|create|develop|code|write|add).*\b(feature|function|component|service|module|class|view|entity)\b',
    r'\b(make|build|create|develop)\s+(this|it|the)\b',
    r'\b(let\'s|can you|please)\s+(implement|build|create|develop|code|write)\b',
    r'\bstart (implementing|building|coding|developing)\b',
    r'\b(fix|refactor|optimize|deploy|update|modify)\b'
]

# Planning trigger patterns
PLANNING_PATTERNS = [
    r'\b(make|create|develop|write|build).*\bplan\b',
    r'\bplan\s+(out|for|the)\b',
    r'\bplanning\s+(out|for|the)\b',
    r'\b(implementation|feature|system|architecture)\s+plan\b',
    r'\b(design a plan|map out|architect)\b'
]

# Brainstorming trigger patterns
BRAINSTORMING_PATTERNS = [
    r'\b(brainstorm|brainstorming)\b'
]

# Deep research trigger patterns
DEEP_RESEARCH_PATTERNS = [
    r'\b(deep research)\b'
]

# Parallel execution trigger patterns
PARALLEL_PATTERNS = [
    r'\b(parallel|in parallel|concurrently|simultaneously)\b',
    r'\b(multiple agents|spawn agents|launch agents)\b',
    r'\b(batch|batches|paralleli[sz]e|paralleli[sz]ation)\b'
]

# Prompt generator functions
def get_foundation_prompt(cwd):
    """Generate foundation development mode prompt (always loaded)"""
    content = load_guide(cwd, "always-active/foundation")
    if not content:
        return None
    return f"""
<system-reminder>Foundation professional development mode is active.

<developer-principles>
{content}
</developer-principles>

</system-reminder>
"""

def get_debug_prompt(cwd):
    """Generate debug prompt with loaded guide content"""
    content = load_guide(cwd, "debug")
    if not content:
        return None
    return f"""
<system-reminder>The user has mentioned a key word or phrase that triggers this reminder for debugging.

<debugging-workflow>
{content}
</debugging-workflow>

</system-reminder>
"""

def get_investigation_prompt(cwd):
    """Generate investigation prompt with loaded guide content"""
    content = load_guide(cwd, "investigation")
    if not content:
        return None
    return f"""
<system-reminder>The user has mentioned a key word or phrase that triggers this reminder for investigation.

<investigation-workflow>
{content}
</investigation-workflow>

</system-reminder>
"""

def get_implementation_prompt(cwd):
    """Generate implementation prompt with loaded guide content"""
    content = load_guide(cwd, "implementation")
    if not content:
        return None
    return f"""
<system-reminder>The user has mentioned implementing or building a feature/component.

<implementation-best-practices>
{content}
</implementation-best-practices>

</system-reminder>
"""

def get_planning_prompt(cwd):
    """Generate planning prompt with loaded guide content"""
    content = load_guide(cwd, "planning")
    if not content:
        return None
    return f"""
<system-reminder>The user has mentioned creating or making a plan for development. Here's some advice for making plans:

<planning-workflow>
{content}
</planning-workflow>

</system-reminder>
"""

def get_brainstorming_prompt(cwd):
    """Generate brainstorming prompt with loaded guide content"""
    content = load_guide(cwd, "brainstorming")
    if not content:
        return None
    return f"""
<system-reminder>The user has mentioned brainstorming or collaborative discovery.

<brainstorming-workflow>
{content}
</brainstorming-workflow>

</system-reminder>
"""

def get_deep_research_prompt(cwd):
    """Generate deep research prompt with loaded guide content"""
    content = load_guide(cwd, "deep-research")
    if not content:
        return None
    return f"""
<system-reminder>The user has requested deep research or systematic investigation.

<deep-research-workflow>
{content}
</deep-research-workflow>

</system-reminder>
"""

def get_parallel_prompt(cwd):
    """Generate parallel execution prompt with loaded guide content"""
    content = load_guide(cwd, "parallel")
    if not content:
        return None
    return f"""
<system-reminder>The user has mentioned parallel execution or agent delegation.

<parallel-execution-workflow>
{content}
</parallel-execution-workflow>

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

# Session state tracking - get already injected guides
session_file = get_session_file(cwd)
already_injected = get_injected_guides(session_file)

# Collect all matching guides with their names (only if not already injected)
triggered = []

# Load foundation.md first (only if not already injected this session)
if "FOUNDATION" not in already_injected:
    foundation_prompt = get_foundation_prompt(cwd)
    if foundation_prompt:
        triggered.append(("FOUNDATION", foundation_prompt))

# Check for brainstorming triggers (highest priority for special modes)
if "BRAINSTORMING" not in already_injected and check_patterns(prompt, BRAINSTORMING_PATTERNS):
    brainstorming_prompt = get_brainstorming_prompt(cwd)
    if brainstorming_prompt:
        triggered.append(("BRAINSTORMING", brainstorming_prompt))

# Check for deep research triggers
if "DEEP_RESEARCH" not in already_injected and check_patterns(prompt, DEEP_RESEARCH_PATTERNS):
    deep_research_prompt = get_deep_research_prompt(cwd)
    if deep_research_prompt:
        triggered.append(("DEEP_RESEARCH", deep_research_prompt))

# Check for planning triggers (takes precedence over implementation)
if "PLANNING" not in already_injected and check_patterns(prompt, PLANNING_PATTERNS):
    planning_prompt = get_planning_prompt(cwd)
    if planning_prompt:
        triggered.append(("PLANNING", planning_prompt))

# Check for implementation triggers
if "IMPLEMENTATION" not in already_injected and check_patterns(prompt, IMPLEMENTATION_PATTERNS):
    implementation_prompt = get_implementation_prompt(cwd)
    if implementation_prompt:
        triggered.append(("IMPLEMENTATION", implementation_prompt))

# Check for debugging triggers
if "DEBUG" not in already_injected and check_patterns(prompt, DEBUG_PATTERNS):
    debug_prompt = get_debug_prompt(cwd)
    if debug_prompt:
        triggered.append(("DEBUG", debug_prompt))

# Check for investigation triggers
if "INVESTIGATION" not in already_injected and check_patterns(prompt, INVESTIGATION_PATTERNS):
    investigation_prompt = get_investigation_prompt(cwd)
    if investigation_prompt:
        triggered.append(("INVESTIGATION", investigation_prompt))

# Check for parallel execution triggers
if "PARALLEL" not in already_injected and check_patterns(prompt, PARALLEL_PATTERNS):
    parallel_prompt = get_parallel_prompt(cwd)
    if parallel_prompt:
        triggered.append(("PARALLEL", parallel_prompt))

# Save newly injected guides to session state
if triggered:
    newly_injected = already_injected | {name for name, _ in triggered}
    save_injected_guides(session_file, newly_injected)

    output = []

    # Build the announcement instruction for Claude
    trigger_names = [name for name, _ in triggered]

    # Format previously active guides (exclude FOUNDATION from "already active" display since it's always there)
    previously_active = [g for g in already_injected if g != "FOUNDATION"]

    # Build announcement instruction
    announcement_parts = []
    announcement_parts.append(f"**New:** {', '.join(trigger_names)}")
    if previously_active:
        announcement_parts.append(f"**Already active:** {', '.join(sorted(previously_active))}")

    instruction = f"""<system-reminder>
IMPORTANT: Workflow guides have been injected for this request.

You MUST announce this to the user at the START of your response using this exact format:
📋 Guides: {' | '.join(announcement_parts)}

This announcement is mandatory - do not skip it. After the announcement, proceed with your response normally.
</system-reminder>
"""
    output.append(instruction)

    # Then add the actual guide content
    for name, prompt_text in triggered:
        output.append(prompt_text)

    print("\n\n".join(output))

# Allow normal processing
sys.exit(0)
