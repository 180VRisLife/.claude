#!/usr/bin/env python3
"""
Claude Code Metrics Tracker Hook

Tracks tool usage metrics for the Grafana dashboard:
- Files modified (Edit/Write tools)
- Lines of code changed
- Commits made (git commit)
- Git failures

Run as PostToolUse hook.
Updated: Uses tool_response key (not tool_output).
"""

import json
import os
import sys
from datetime import datetime
from pathlib import Path

METRICS_FILE = Path.home() / ".claude" / "monitoring" / "metrics-tracking.json"


def load_metrics():
    """Load current metrics from file."""
    if not METRICS_FILE.exists():
        return {
            "commits_total": 0,
            "lines_added": 0,
            "lines_removed": 0,
            "files_modified": 0,
            "commands_blocked": 0,
            "git_failures": 0,
            "last_updated": ""
        }
    try:
        with open(METRICS_FILE) as f:
            return json.load(f)
    except (json.JSONDecodeError, IOError):
        return {
            "commits_total": 0,
            "lines_added": 0,
            "lines_removed": 0,
            "files_modified": 0,
            "commands_blocked": 0,
            "git_failures": 0,
            "last_updated": ""
        }


def save_metrics(metrics):
    """Save metrics to file."""
    metrics["last_updated"] = datetime.now().isoformat()
    METRICS_FILE.parent.mkdir(parents=True, exist_ok=True)
    with open(METRICS_FILE, 'w') as f:
        json.dump(metrics, f, indent=2)


def count_lines(text):
    """Count lines in text, handling None gracefully."""
    if not text:
        return 0
    return len(text.strip().split('\n')) if text.strip() else 0


def main():
    # Read hook input from stdin
    try:
        stdin_data = sys.stdin.read()
        if not stdin_data.strip():
            sys.exit(0)
        hook_input = json.loads(stdin_data)
    except (json.JSONDecodeError, Exception):
        sys.exit(0)

    tool_name = hook_input.get("tool_name", "")
    tool_input = hook_input.get("tool_input", {})
    tool_output = hook_input.get("tool_response", {})  # Claude sends tool_response, not tool_output

    metrics = load_metrics()
    updated = False

    # Track Edit tool usage
    if tool_name == "Edit":
        metrics["files_modified"] += 1
        old_string = tool_input.get("old_string", "")
        new_string = tool_input.get("new_string", "")
        old_lines = count_lines(old_string)
        new_lines = count_lines(new_string)
        if new_lines > old_lines:
            metrics["lines_added"] += (new_lines - old_lines)
        elif old_lines > new_lines:
            metrics["lines_removed"] += (old_lines - new_lines)
        updated = True

    # Track Write tool usage
    elif tool_name == "Write":
        metrics["files_modified"] += 1
        content = tool_input.get("content", "")
        metrics["lines_added"] += count_lines(content)
        updated = True

    # Track Bash commands
    elif tool_name == "Bash":
        command = tool_input.get("command", "")
        stdout = tool_output.get("stdout", "") if isinstance(tool_output, dict) else ""
        stderr = tool_output.get("stderr", "") if isinstance(tool_output, dict) else ""

        # Track git commits
        if "git commit" in command:
            # Check if commit was successful (look for commit hash in output)
            if stdout and ("[" in stdout or "create mode" in stdout.lower()):
                metrics["commits_total"] += 1
                updated = True
            elif stderr and "error" in stderr.lower():
                metrics["git_failures"] += 1
                updated = True

        # Track other git failures
        elif command.startswith("git "):
            if stderr and ("error" in stderr.lower() or "fatal" in stderr.lower()):
                metrics["git_failures"] += 1
                updated = True

    if updated:
        save_metrics(metrics)

    # Always exit successfully
    sys.exit(0)


if __name__ == "__main__":
    main()
