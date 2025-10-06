#!/usr/bin/env python3
import i3ipc
import subprocess
import sys

i3 = i3ipc.Connection()

def get_current_window_title():
    """Get the title of the currently focused window, or 'Desktop' if no window is focused"""
    try:
        focused = i3.get_tree().find_focused()
        if focused and focused.window_class:
            # There's a focused window, return its title
            return focused.name or "Unknown Window"
        else:
            # No focused window (empty workspace), return Desktop
            return "Desktop"
    except Exception:
        return "Desktop"

def print_title():
    """Print the current window title or Desktop"""
    title = get_current_window_title()
    print(title, flush=True)

def on_event(i3, e):
    """Handle i3 events and update title"""
    print_title()

# Listen to changes
i3.on("window::new", on_event)
i3.on("window::close", on_event)
i3.on("window::move", on_event)
i3.on("window::title", on_event)
i3.on("window::focus", on_event)
i3.on("workspace::focus", on_event)

# Print initial title
print_title()

# Start the event loop
i3.main()
