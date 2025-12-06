#!/usr/bin/env python3
"""
Parallel Execution Hook (PostToolUse)
Injects parallelization guide after ExitPlanMode, using shared session tracking
with the workflow orchestrator to prevent duplicate injections.
"""
import hashlib
import json
import logging
import os
import sys
from pathlib import Path

# --- Logging Configuration ---
LOG_FILE = "/tmp/claude_supervisor.log"

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    filename=LOG_FILE,
    filemode='a'
)

# --- Session State Tracking (shared with workflow-orchestrator.py) ---
def get_session_file(cwd):
    """Get session file path based on cwd + parent process (Claude Code's PID)"""
    ppid = os.getppid()
    cwd_hash = hashlib.md5(cwd.encode()).hexdigest()[:12]
    session_id = f"{cwd_hash}-{ppid}"
    return Path(f"/tmp/claude-workflow-{session_id}.json")

def get_injected_guides(session_file):
    """Read which guides have been injected this session"""
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
        pass

def main():
    logging.info("--- Parallel PostToolUse Hook Triggered ---")
    try:
        hook_input = json.load(sys.stdin)

        if hook_input.get("tool_name") != "ExitPlanMode":
            sys.exit(0)

        cwd = hook_input.get("cwd", "")

        # Check session state - skip if PARALLEL already injected
        session_file = get_session_file(cwd)
        already_injected = get_injected_guides(session_file)

        if "PARALLEL" in already_injected:
            logging.info("PARALLEL guide already injected this session. Skipping.")
            sys.exit(0)

        logging.info("ExitPlanMode detected. Injecting PARALLEL guide.")

        # Load the parallel execution guide from local workspace
        parallel_guide_path = Path(cwd) / ".claude" / "guides" / "parallel.md"
        try:
            with open(parallel_guide_path, 'r') as f:
                parallel_guide_content = f.read()
            logging.info(f"Successfully loaded parallel guide from {parallel_guide_path}")
        except FileNotFoundError:
            logging.error(f"Parallel guide not found at {parallel_guide_path}")
            sys.exit(0)
        except Exception as e:
            logging.error(f"Error loading parallel guide: {e}")
            sys.exit(0)

        # Build announcement (same format as workflow orchestrator)
        previously_active = [g for g in already_injected if g != "FOUNDATION"]
        announcement_parts = ["**New:** PARALLEL"]
        if previously_active:
            announcement_parts.append(f"**Already active:** {', '.join(sorted(previously_active))}")

        reflection_prompt = f"""<system-reminder>
IMPORTANT: Workflow guide has been injected for parallelization.

You MUST announce this to the user at the START of your response using this exact format:
📋 Guides: {' | '.join(announcement_parts)}

**Parallelize the Plan**

The initial plan has been drafted. Now, review and apply these parallelization principles:

<parallel-execution-workflow>
{parallel_guide_content}
</parallel-execution-workflow>

CRITICAL ADDITIONAL REQUIREMENTS:
- ONLY use parallelization if there is more than one file to modify (with one file, implement it yourself)
- Delegate EVERY step, even single-task stages (unless trivial) to avoid clogging your context window
- No more than one primary task per agent
- Consider dependencies between components when planning parallel execution

Please present your analysis of parallel stages based on the guide above, then proceed with the first stage.

</system-reminder>"""

        # Update session state to mark PARALLEL as injected
        newly_injected = already_injected | {"PARALLEL"}
        save_injected_guides(session_file, newly_injected)
        logging.info("Marked PARALLEL as injected in session state.")

        response = {
            "hookSpecificOutput": {
                "hookEventName": "PostToolUse",
                "additionalContext": reflection_prompt
            }
        }

        logging.info("Injecting parallelization context.")
        print(json.dumps(response), flush=True)

    except Exception as e:
        logging.exception("An unexpected error occurred in the Parallel hook.")

if __name__ == "__main__":
    main()
