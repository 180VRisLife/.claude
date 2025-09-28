#!/usr/bin/env python3
"""
Unified context-aware dispatcher that routes to appropriate development hooks based on project type.
Prevents duplicate execution of visionOS and default hooks.
"""
import json
import os
import re
import subprocess
import sys
from pathlib import Path
from typing import Optional, Set

# Cache file for storing detected context
CONTEXT_CACHE = Path.home() / ".claude" / ".context_cache"

def detect_project_context() -> str:
    """
    Detect the current project context based on file extensions in the working directory.
    Returns: 'visionos', 'default', or 'mixed'
    """
    # Check cache first
    if CONTEXT_CACHE.exists():
        cache_age = (Path.cwd().stat().st_mtime - CONTEXT_CACHE.stat().st_mtime)
        if cache_age < 3600:  # Cache valid for 1 hour
            with open(CONTEXT_CACHE, 'r') as f:
                cached_context = f.read().strip()
                if cached_context:
                    return cached_context

    cwd = Path.cwd()

    # visionOS indicators
    visionos_patterns = {
        '**/*.swift',
        '**/*.xcodeproj',
        '**/*.xcworkspace',
        '**/RealityKitContent/**',
        '**/*.reality',
        '**/Info.plist'
    }

    # Default (web/general) indicators
    default_patterns = {
        '**/*.js',
        '**/*.jsx',
        '**/*.ts',
        '**/*.tsx',
        '**/*.py',
        '**/*.java',
        '**/*.go',
        '**/*.rs',
        '**/package.json',
        '**/requirements.txt',
        '**/Cargo.toml',
        '**/go.mod'
    }

    has_visionos = False
    has_default = False

    # Check for visionOS files
    for pattern in visionos_patterns:
        if list(cwd.glob(pattern)):
            has_visionos = True
            break

    # Check for default files
    for pattern in default_patterns:
        if list(cwd.glob(pattern)):
            has_default = True
            break

    # Determine context
    if has_visionos and not has_default:
        context = 'visionos'
    elif has_default and not has_visionos:
        context = 'default'
    elif has_visionos and has_default:
        # Mixed project - look for dominant type
        swift_count = len(list(cwd.glob('**/*.swift')))
        other_count = len(list(cwd.glob('**/*.js'))) + len(list(cwd.glob('**/*.ts'))) + \
                     len(list(cwd.glob('**/*.jsx'))) + len(list(cwd.glob('**/*.tsx')))

        context = 'visionos' if swift_count > other_count else 'default'
    else:
        # No clear indicators, default to general
        context = 'default'

    # Cache the result
    try:
        CONTEXT_CACHE.parent.mkdir(exist_ok=True)
        with open(CONTEXT_CACHE, 'w') as f:
            f.write(context)
    except:
        pass  # Ignore cache write errors

    return context

def check_explicit_context(prompt: str) -> Optional[str]:
    """
    Check if the prompt explicitly mentions a specific context.
    Returns: 'visionos', 'default', or None
    """
    visionos_keywords = [
        r'\b(visionos|vision os|spatial|realitykit|arkit|swift|swiftui|xcode|reality composer)\b',
        r'\b(immersive|volumetric|3d window|spatial computing)\b'
    ]

    # Strong indicators for non-visionOS contexts
    non_visionos_keywords = [
        r'\b(react|vue|angular|node|nodejs|python|java|rust|go)\b',
        r'\b(npm|pip|cargo|maven|gradle)\b',
        r'\b(web|frontend|backend|api|rest|graphql)\b'
    ]

    prompt_lower = prompt.lower()

    # Check for explicit visionOS context
    for pattern in visionos_keywords:
        if re.search(pattern, prompt_lower):
            return 'visionos'

    # Check for explicit non-visionOS context
    for pattern in non_visionos_keywords:
        if re.search(pattern, prompt_lower):
            return 'default'

    return None

def load_hook_module(context: str):
    """
    Dynamically load and execute the appropriate hook based on context.
    """
    if context == 'visionos':
        hook_path = Path.home() / ".claude" / "hooks" / "visionos" / "visionos-custom-reminder.py"
    else:
        hook_path = Path.home() / ".claude" / "hooks" / "default" / "default-custom-reminder.py"

    if not hook_path.exists():
        return None

    # Execute the hook as a subprocess to maintain isolation
    try:
        result = subprocess.run(
            [sys.executable, str(hook_path)],
            input=json.dumps({"prompt": input_data.get("prompt", "")}),
            capture_output=True,
            text=True,
            timeout=5
        )

        if result.stdout:
            return result.stdout

    except Exception as e:
        print(f"Error executing hook: {e}", file=sys.stderr)

    return None

# Main execution
try:
    input_data = json.load(sys.stdin)
except json.JSONDecodeError as e:
    print(f"Error: Invalid JSON input: {e}", file=sys.stderr)
    sys.exit(1)

prompt = input_data.get("prompt", "")

# First check for explicit context in the prompt
explicit_context = check_explicit_context(prompt)

if explicit_context:
    context = explicit_context
else:
    # Detect context from project files
    context = detect_project_context()

# Load and execute the appropriate hook
output = load_hook_module(context)

if output:
    print(output, end='')

sys.exit(0)