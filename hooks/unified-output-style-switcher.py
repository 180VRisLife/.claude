#!/usr/bin/env python3
"""
Unified output style switcher that detects context and applies the appropriate style.
"""
import json
import os
import re
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

# Set the appropriate output style
if context == 'visionos':
    output_style = "visionos/visionos-main"
else:
    output_style = "default/default-main"

# Output the style setting
output = {
    "outputStyle": output_style
}

print(json.dumps(output))
sys.exit(0)