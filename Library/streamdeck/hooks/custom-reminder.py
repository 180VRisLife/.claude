#!/usr/bin/env python3
"""
Hook that adds debugging or investigation prompts based on trigger words in user messages for Stream Deck plugin development.
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
    r'\b(implement|build|create|develop|code|write|add).*\b(feature|function|component|service|module|class|action)\b',
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

# Prompt generator functions
def get_debug_prompt(cwd):
    """Generate debug prompt with loaded guide content"""
    content = load_guide(cwd, "debug")
    if not content:
        return None
    return f"""
<system-reminder>The user has mentioned a key word or phrase that triggers this reminder for streamdeck debugging.

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
<system-reminder>The user has mentioned a key word or phrase that triggers this reminder for streamdeck investigation.

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
<system-reminder>The user has mentioned implementing or building a streamdeck feature/component.

<streamdeck-implementation-best-practices>
{content}
</streamdeck-implementation-best-practices>

</system-reminder>
"""

def get_planning_prompt(cwd):
    """Generate planning prompt with loaded guide content"""
    content = load_guide(cwd, "planning")
    if not content:
        return None
    return f"""
<system-reminder>The user has mentioned creating or making a plan for streamdeck development. Here's some advice for making plans:

<planning-workflow>
{content}
</planning-workflow>

</system-reminder>
"""

def get_parallel_prompt(cwd):
    """Generate parallel prompt with loaded guide content"""
    content = load_guide(cwd, "parallel")
    if not content:
        return None
    return f"""
<system-reminder>The user has mentioned parallel execution or parallelization for Stream Deck plugin development.

<parallelization-guide>
{content}
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
    debug_prompt = get_debug_prompt(cwd)
    if debug_prompt:
        triggered.append(("DEBUG", debug_prompt))

# Check for investigation triggers
if check_patterns(prompt, INVESTIGATION_PATTERNS):
    investigation_prompt = get_investigation_prompt(cwd)
    if investigation_prompt:
        triggered.append(("INVESTIGATION", investigation_prompt))

# Check for implementation triggers
if check_patterns(prompt, IMPLEMENTATION_PATTERNS):
    implementation_prompt = get_implementation_prompt(cwd)
    if implementation_prompt:
        triggered.append(("IMPLEMENTATION", implementation_prompt))

# Check for planning triggers
if check_patterns(prompt, PLANNING_PATTERNS):
    planning_prompt = get_planning_prompt(cwd)
    if planning_prompt:
        triggered.append(("PLANNING", planning_prompt))

# Check for parallelization triggers
if check_patterns(prompt, PARALLEL_PATTERNS):
    parallel_prompt = get_parallel_prompt(cwd)
    if parallel_prompt:
        triggered.append(("PARALLELIZATION", parallel_prompt))

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