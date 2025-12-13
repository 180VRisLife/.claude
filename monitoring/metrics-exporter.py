#!/usr/bin/env python3
"""
Claude Code Metrics Exporter

Reads stats-cache.json and exposes it as Prometheus metrics on port 9464.
Run with: ~/.claude/monitoring/venv/bin/python ~/.claude/monitoring/metrics-exporter.py
"""

import json
import os
import time
from datetime import datetime, timedelta, timezone
from pathlib import Path
from prometheus_client import start_http_server, Gauge, Counter, Info

# State tracking for delta calculations
_previous_values = {}

# File paths
STATS_FILE = Path.home() / ".claude" / "stats-cache.json"
HISTORY_FILE = Path.home() / ".claude" / "history.jsonl"
TRACKING_FILE = Path.home() / ".claude" / "monitoring" / "metrics-tracking.json"
PROJECTS_DIR = Path.home() / ".claude" / "projects"
TIME_CACHE_FILE = Path.home() / ".claude" / "monitoring" / "time-cache.json"

# Define metrics - using names that match the dashboard
# Gauges for current totals
token_usage = Gauge('claude_code_token_usage', 'Token usage', ['model', 'type'])
cost_usage = Gauge('claude_code_cost_usage', 'Cost in USD', ['model'])
session_count = Gauge('claude_code_session_count', 'Number of sessions')

# Counters for time-windowed queries (these increment properly for increase() queries)
token_counter = Counter('claude_code_tokens', 'Token usage counter', ['model', 'type'])
cost_counter = Counter('claude_code_cost', 'Cost counter', ['model'])
tool_calls_counter = Counter('claude_code_tools', 'Tool calls counter')

# Time tracking metrics (Gauges for all-time totals)
active_time_cli = Gauge('claude_code_active_time_cli', 'Active CLI time in seconds')
active_time_user = Gauge('claude_code_active_time_user', 'Active user time in seconds')
active_time_total = Gauge('claude_code_active_time_total', 'Active time in seconds')

# Time tracking counters (for time-windowed queries)
active_time_cli_counter = Counter('claude_code_cli_seconds', 'Active CLI time counter')
active_time_user_counter = Counter('claude_code_user_seconds', 'Active user time counter')

# Activity metrics (Gauges for all-time totals)
commits_total = Gauge('claude_code_commits_total', 'Number of commits')
lines_of_code = Gauge('claude_code_lines_of_code', 'Lines of code changed')
tool_calls = Gauge('claude_code_tool_calls', 'Total tool invocations')
files_modified = Gauge('claude_code_files_modified', 'Files modified')

# Activity counters (for time-windowed queries)
commits_counter = Counter('claude_code_commit_count', 'Commits counter')
lines_counter = Counter('claude_code_line_count', 'Lines of code counter')
files_counter = Counter('claude_code_file_count', 'Files modified counter')

# Error/failure metrics (Gauges for all-time totals)
commands_blocked = Gauge('claude_code_commands_blocked', 'Commands blocked by hooks')
git_failures = Gauge('claude_code_git_failures', 'Git operation failures')
api_error_total = Gauge('claude_code_api_error_total', 'API errors')

# Error counters (for time-windowed queries)
commands_blocked_counter = Counter('claude_code_blocked_count', 'Commands blocked counter')
git_failures_counter = Counter('claude_code_gitfail_count', 'Git failures counter')

# Daily metrics
daily_messages = Gauge('claude_code_daily_messages', 'Daily message count', ['date'])
daily_sessions = Gauge('claude_code_daily_sessions', 'Daily session count', ['date'])
daily_tool_calls = Gauge('claude_code_daily_tool_calls', 'Daily tool call count', ['date'])

# Info metric
claude_info = Info('claude_code', 'Claude Code information')

# Model pricing (per 1M tokens)
MODEL_PRICING = {
    'claude-opus-4-5-20251101': {'input': 15.0, 'output': 75.0, 'cache_read': 1.5, 'cache_write': 18.75},
    'claude-sonnet-4-5-20250929': {'input': 3.0, 'output': 15.0, 'cache_read': 0.3, 'cache_write': 3.75},
    'claude-haiku-4-5-20251001': {'input': 0.8, 'output': 4.0, 'cache_read': 0.08, 'cache_write': 1.0},
}


def calculate_cost(model: str, input_tokens: int, output_tokens: int,
                   cache_read: int, cache_write: int) -> float:
    """Calculate estimated cost for a model's usage."""
    pricing = MODEL_PRICING.get(model, MODEL_PRICING['claude-sonnet-4-5-20250929'])
    cost = (
        (input_tokens / 1_000_000) * pricing['input'] +
        (output_tokens / 1_000_000) * pricing['output'] +
        (cache_read / 1_000_000) * pricing['cache_read'] +
        (cache_write / 1_000_000) * pricing['cache_write']
    )
    return cost


def load_stats():
    """Load stats from cache file."""
    if not STATS_FILE.exists():
        return None
    try:
        with open(STATS_FILE) as f:
            return json.load(f)
    except (json.JSONDecodeError, IOError):
        return None


def load_tracking():
    """Load tracking metrics from hook-populated file."""
    if not TRACKING_FILE.exists():
        return {
            "commits_total": 0,
            "lines_added": 0,
            "lines_removed": 0,
            "files_modified": 0,
            "commands_blocked": 0,
            "git_failures": 0,
        }
    try:
        with open(TRACKING_FILE) as f:
            return json.load(f)
    except (json.JSONDecodeError, IOError):
        return {
            "commits_total": 0,
            "lines_added": 0,
            "lines_removed": 0,
            "files_modified": 0,
            "commands_blocked": 0,
            "git_failures": 0,
        }


def load_time_cache() -> dict:
    """Load cached time calculations."""
    if not TIME_CACHE_FILE.exists():
        return {"processed_files": {}, "cli_time": 0, "user_time": 0}
    try:
        with open(TIME_CACHE_FILE) as f:
            return json.load(f)
    except (json.JSONDecodeError, IOError):
        return {"processed_files": {}, "cli_time": 0, "user_time": 0}


def save_time_cache(cache: dict):
    """Save time calculations cache."""
    TIME_CACHE_FILE.parent.mkdir(parents=True, exist_ok=True)
    with open(TIME_CACHE_FILE, 'w') as f:
        json.dump(cache, f)


def parse_timestamp(ts: str) -> datetime:
    """Parse ISO timestamp to datetime."""
    # Handle both formats: with/without milliseconds
    ts = ts.replace('Z', '+00:00')
    try:
        return datetime.fromisoformat(ts)
    except ValueError:
        return datetime.now(timezone.utc)


def count_sessions() -> int:
    """Count total number of sessions from session files."""
    if not PROJECTS_DIR.exists():
        return 0

    count = 0
    for project_dir in PROJECTS_DIR.iterdir():
        if not project_dir.is_dir():
            continue
        for session_file in project_dir.glob("*.jsonl"):
            # Count main session files (UUIDs), not agent files
            if not session_file.name.startswith("agent-"):
                count += 1
    return count


def calculate_tokens_from_sessions() -> dict:
    """
    Calculate token usage directly from session files (real-time).
    Returns dict of {model: {input, output, cacheRead, cacheCreation}}
    """
    usage_by_model = {}

    if not PROJECTS_DIR.exists():
        return usage_by_model

    for project_dir in PROJECTS_DIR.iterdir():
        if not project_dir.is_dir():
            continue
        for session_file in project_dir.glob("*.jsonl"):
            if session_file.name.startswith("agent-"):
                continue
            try:
                with open(session_file) as f:
                    for line in f:
                        if not line.strip():
                            continue
                        try:
                            entry = json.loads(line)
                            msg = entry.get("message", {})
                            model = msg.get("model", "")
                            usage = msg.get("usage", {})

                            if model and usage:
                                if model not in usage_by_model:
                                    usage_by_model[model] = {
                                        "input": 0, "output": 0,
                                        "cacheRead": 0, "cacheCreation": 0
                                    }
                                usage_by_model[model]["input"] += usage.get("input_tokens", 0)
                                usage_by_model[model]["output"] += usage.get("output_tokens", 0)
                                usage_by_model[model]["cacheRead"] += usage.get("cache_read_input_tokens", 0)
                                usage_by_model[model]["cacheCreation"] += usage.get("cache_creation_input_tokens", 0)
                        except json.JSONDecodeError:
                            continue
            except (IOError, OSError):
                continue

    return usage_by_model


def calculate_real_time_from_sessions() -> tuple[float, float]:
    """
    Calculate actual CLI and user time from session files.
    Returns (cli_time_seconds, user_time_seconds)

    CLI time: Duration from user message to assistant response completion
    User time: Duration from assistant response to next user message
    """
    cache = load_time_cache()
    total_cli_time = cache.get("cli_time", 0)
    total_user_time = cache.get("user_time", 0)
    processed = cache.get("processed_files", {})

    if not PROJECTS_DIR.exists():
        return total_cli_time, total_user_time

    # Find all session files (UUIDs, not agent- prefixed)
    session_files = []
    for project_dir in PROJECTS_DIR.iterdir():
        if project_dir.is_dir():
            for f in project_dir.glob("*.jsonl"):
                # Skip agent files and process only main session files
                if not f.name.startswith("agent-"):
                    session_files.append(f)

    updated = False
    for session_file in session_files:
        file_key = str(session_file)
        file_mtime = session_file.stat().st_mtime

        # Skip if already processed and not modified
        if file_key in processed and processed[file_key] >= file_mtime:
            continue

        try:
            messages = []
            with open(session_file) as f:
                for line in f:
                    line = line.strip()
                    if not line:
                        continue
                    try:
                        entry = json.loads(line)
                        # Only process user and assistant messages with timestamps
                        if entry.get("type") in ("user",) or (
                            entry.get("message", {}).get("role") == "assistant"
                        ):
                            ts = entry.get("timestamp")
                            if ts:
                                messages.append({
                                    "type": entry.get("type", entry.get("message", {}).get("role")),
                                    "timestamp": parse_timestamp(ts),
                                    "role": entry.get("message", {}).get("role", entry.get("type"))
                                })
                    except json.JSONDecodeError:
                        continue

            # Sort by timestamp
            messages.sort(key=lambda x: x["timestamp"])

            # Calculate time gaps
            session_cli = 0
            session_user = 0

            for i in range(len(messages) - 1):
                curr = messages[i]
                next_msg = messages[i + 1]
                gap = (next_msg["timestamp"] - curr["timestamp"]).total_seconds()

                # Cap individual gaps at 30 minutes (ignore long idle periods)
                if gap > 1800:
                    continue

                if curr["role"] == "user" and next_msg["role"] == "assistant":
                    # User sent message -> Claude responded = CLI time
                    session_cli += gap
                elif curr["role"] == "assistant" and next_msg["role"] == "user":
                    # Claude responded -> User sent next = User time
                    session_user += gap

            # For new files, add to totals; for updated files, we're reprocessing
            if file_key not in processed:
                total_cli_time += session_cli
                total_user_time += session_user

            processed[file_key] = file_mtime
            updated = True

        except (IOError, OSError):
            continue

    if updated:
        cache["processed_files"] = processed
        cache["cli_time"] = total_cli_time
        cache["user_time"] = total_user_time
        save_time_cache(cache)

    return total_cli_time, total_user_time


def update_metrics():
    """Update all Prometheus metrics from session files (real-time)."""
    # Count sessions
    session_count.set(count_sessions())

    # Get real-time token usage from session files
    model_usage = calculate_tokens_from_sessions()
    total_cost = 0

    for model, usage in model_usage.items():
        input_tokens = usage.get('input', 0)
        output_tokens = usage.get('output', 0)
        cache_read = usage.get('cacheRead', 0)
        cache_write = usage.get('cacheCreation', 0)

        # Set gauge metrics (current totals)
        token_usage.labels(model=model, type='input').set(input_tokens)
        token_usage.labels(model=model, type='output').set(output_tokens)
        token_usage.labels(model=model, type='cacheRead').set(cache_read)
        token_usage.labels(model=model, type='cacheCreation').set(cache_write)

        # Increment counter metrics by delta (for time-windowed queries)
        for token_type, value in [('input', input_tokens), ('output', output_tokens),
                                   ('cacheRead', cache_read), ('cacheCreation', cache_write)]:
            key = f"token_{model}_{token_type}"
            prev = _previous_values.get(key, 0)
            if value > prev:
                token_counter.labels(model=model, type=token_type).inc(value - prev)
            _previous_values[key] = value

        # Calculate and set cost
        model_cost = calculate_cost(model, input_tokens, output_tokens, cache_read, cache_write)
        cost_usage.labels(model=model).set(model_cost)

        # Increment cost counter by delta
        cost_key = f"cost_{model}"
        prev_cost = _previous_values.get(cost_key, 0)
        if model_cost > prev_cost:
            cost_counter.labels(model=model).inc(model_cost - prev_cost)
        _previous_values[cost_key] = model_cost

        total_cost += model_cost

    # Load tracking metrics from hook-populated file for tool calls
    tracking = load_tracking()
    total_tool_calls_sum = tracking.get("files_modified", 0)  # Approximate from hook data

    tool_calls.set(total_tool_calls_sum)

    # Increment tool calls counter by delta
    prev_tools = _previous_values.get('tool_calls', 0)
    if total_tool_calls_sum > prev_tools:
        tool_calls_counter.inc(total_tool_calls_sum - prev_tools)
    _previous_values['tool_calls'] = total_tool_calls_sum

    # Real time calculation from session files
    cli_time, user_time = calculate_real_time_from_sessions()

    # Set gauge metrics (all-time totals)
    active_time_cli.set(cli_time)
    active_time_user.set(user_time)
    active_time_total.set(cli_time + user_time)

    # Increment time counters by delta (for time-windowed queries)
    prev_cli = _previous_values.get('cli_time', 0)
    prev_user = _previous_values.get('user_time', 0)
    if cli_time > prev_cli:
        active_time_cli_counter.inc(cli_time - prev_cli)
    if user_time > prev_user:
        active_time_user_counter.inc(user_time - prev_user)
    _previous_values['cli_time'] = cli_time
    _previous_values['user_time'] = user_time

    # Load tracking metrics from hook-populated file
    tracking = load_tracking()

    # Set info from tracking data
    claude_info.info({
        'files_modified': str(tracking.get('files_modified', 0)),
        'lines_changed': str(tracking.get('lines_added', 0) + tracking.get('lines_removed', 0)),
        'source': 'session-files',
    })

    # Set gauge metrics (all-time totals)
    commits_val = tracking.get("commits_total", 0)
    lines_val = tracking.get("lines_added", 0) + tracking.get("lines_removed", 0)
    files_val = tracking.get("files_modified", 0)
    blocked_val = tracking.get("commands_blocked", 0)
    git_fail_val = tracking.get("git_failures", 0)

    commits_total.set(commits_val)
    lines_of_code.set(lines_val)
    files_modified.set(files_val)
    commands_blocked.set(blocked_val)
    git_failures.set(git_fail_val)
    api_error_total.set(0)

    # Increment counters by delta (for time-windowed queries)
    prev_commits = _previous_values.get('commits', 0)
    prev_lines = _previous_values.get('lines', 0)
    prev_files = _previous_values.get('files', 0)
    prev_blocked = _previous_values.get('blocked', 0)
    prev_git_fail = _previous_values.get('git_fail', 0)

    if commits_val > prev_commits:
        commits_counter.inc(commits_val - prev_commits)
    if lines_val > prev_lines:
        lines_counter.inc(lines_val - prev_lines)
    if files_val > prev_files:
        files_counter.inc(files_val - prev_files)
    if blocked_val > prev_blocked:
        commands_blocked_counter.inc(blocked_val - prev_blocked)
    if git_fail_val > prev_git_fail:
        git_failures_counter.inc(git_fail_val - prev_git_fail)

    _previous_values['commits'] = commits_val
    _previous_values['lines'] = lines_val
    _previous_values['files'] = files_val
    _previous_values['blocked'] = blocked_val
    _previous_values['git_fail'] = git_fail_val

    ratio = cli_time / user_time if user_time > 0 else 0
    cli_hrs = cli_time / 3600
    user_hrs = user_time / 3600
    print(f"[{datetime.now().strftime('%H:%M:%S')}] Cost: ${total_cost:.2f} | CLI: {cli_hrs:.1f}h | You: {user_hrs:.1f}h | Ratio: {ratio:.1f}x")


def main():
    print("Claude Code Metrics Exporter")
    print(f"Stats file: {STATS_FILE}")
    print(f"Serving metrics on http://localhost:9464/metrics")
    print("-" * 50)

    # Start HTTP server
    start_http_server(9464)

    # Update metrics every 30 seconds
    while True:
        update_metrics()
        time.sleep(30)


if __name__ == '__main__':
    main()
