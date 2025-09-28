#!/usr/bin/env python3
"""
Check if the macOS screen is locked.
Returns exit code 0 if screen is locked, 1 if unlocked.

This is designed for the use case where you explicitly lock your Mac
when walking away and want notifications only when away from your desk.
"""

import sys
try:
    import Quartz
except ImportError:
    print("Error: Quartz module not available. This script requires macOS with Python 3.", file=sys.stderr)
    sys.exit(2)

def is_screen_locked():
    """
    Check if the screen is currently locked.

    Returns:
        True if screen is locked, False if unlocked, None if unable to determine
    """
    try:
        # Get the current session dictionary
        session_dict = Quartz.CGSessionCopyCurrentDictionary()

        if session_dict is None:
            # No UI session available (shouldn't happen in normal use)
            return None

        # Check if screen is locked
        # CGSSessionScreenIsLocked = 1 means locked (user pressed lock button)
        # If the key doesn't exist, screen is unlocked
        return session_dict.get("CGSSessionScreenIsLocked", 0) == 1

    except Exception as e:
        print(f"Error checking screen lock state: {e}", file=sys.stderr)
        return None

if __name__ == "__main__":
    lock_state = is_screen_locked()

    if lock_state is None:
        # Unable to determine lock state - assume unlocked for safety
        # (don't want to spam notifications if something goes wrong)
        sys.exit(1)
    elif lock_state:
        # Screen is locked - user is away
        sys.exit(0)
    else:
        # Screen is unlocked - user is at their desk
        sys.exit(1)