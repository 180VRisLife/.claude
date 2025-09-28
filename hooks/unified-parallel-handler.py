#!/usr/bin/env python3
"""
Unified parallel execution handler that detects context and routes to appropriate parallel guide.
"""
import json
import os
import sys
from pathlib import Path

# Import context detection from the dispatcher
sys.path.insert(0, str(Path.home() / ".claude" / "hooks"))
from unified_context_dispatcher import detect_project_context, check_explicit_context

try:
    input_data = json.load(sys.stdin)
except json.JSONDecodeError as e:
    print(f"Error: Invalid JSON input: {e}", file=sys.stderr)
    sys.exit(1)

prompt = input_data.get("prompt", "")

# Check for explicit context in prompt first
explicit_context = check_explicit_context(prompt)

if explicit_context:
    context = explicit_context
else:
    # Detect from project
    context = detect_project_context()

# Load the appropriate parallel guide based on context
if context == 'visionos':
    guide_path = Path.home() / ".claude" / "guides" / "visionos" / "visionos-parallel.md"
else:
    guide_path = Path.home() / ".claude" / "guides" / "default" / "default-parallel.md"

# If guide doesn't exist, try the shared guide
if not guide_path.exists():
    guide_path = Path.home() / ".claude" / "guides" / "parallel.md"

if guide_path.exists():
    try:
        with open(guide_path, 'r') as f:
            guide_content = f.read()

        # Output the guide content as a system reminder
        print(f"""<system-reminder>
Parallel execution guide for {context} context:

{guide_content}
</system-reminder>""")
    except Exception as e:
        print(f"Error loading parallel guide: {e}", file=sys.stderr)

sys.exit(0)