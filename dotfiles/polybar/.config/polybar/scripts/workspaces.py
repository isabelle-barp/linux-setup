#!/usr/bin/env python3
import i3ipc
import subprocess
import re
import os
import json

# Configuration
FALLBACK_STYLE = "short"  # Options: "short", "full", "none"
FALLBACK_LENGTH = 3       # Length for short fallback

# Map application classes to icons (Nerd Fonts, Font Awesome, etc.)
ICON_MAP = {
    "firefox": "  ",
    "google-chrome": "  ",
    "spotify": "  ",
    "alacritty": "  ",
    "cursor": "  ",
    "jetbrains-webstorm": "  ",
    "jetbrains-datagrip": "  ",
    "jetbrains-pycharm": "  ",
    "wavebox": "  ",
    "1password": "  ",
    "conky": "  ",
    "obsidian": "  "
}

# Map terminal processes to icons
TERMINAL_PROCESS_ICONS = {
    "vim": "  ",
    "htop": "  ",
    "git": "  ",
    "ssh": "  ",
    "python": "  ",
    "python3": "  ",
    "node": "  ",
    "npm": "  ",
    "yarn": "  ",
    "docker": "  ",
    "kubectl": "  ",
    "systemctl": "  ",
    "pacman": " 󰮯 ",
    "yay": " 󰏗 ",
    "paru": "  ",
    "ranger": "  ",
    "lf": "  ",
    "mc": "  ",
    "tmux": "  ",
    "screen": "  ",
    "zsh": "  ",
    "cargo": "  ",
    "go": "  ",
    "rustc": "  ",
    "gcc": "  ",
    "g++": "  ",
    "make": "  ",
    "cmake": "  ",
    "ninja": "  ",
    "k9s": "  "
}

# Map browser processes to icons based on common websites/services
BROWSER_PROCESS_ICONS = {
    # Development
    "github": "  ",
    "gitlab": "  ",
    "stackoverflow": "  ",
    "stackexchange": "  ",
    "dev.to": "  ",
    "codepen": "  ",
    "jsfiddle": "  ",
    "replit": "  ",
    "codesandbox": "  ",
    "datadog": "  ",
    "gitkraken": "  ",
    
    # Social Media
    "twitter": "  ",
    "x.com": "  ",
    "facebook": "  ",
    "instagram": "  ",
    "linkedin": "  ",
    "reddit": "  ",
    "discord": "  ",
    "slack": "  ",
    "telegram": "  ",
    
    # Video/Streaming
    "youtube": "  ",
    "twitch": "  ",
    "netflix": "  ",
    "hulu": "  ",
    "disney": "  ",
    "amazon": "  ",
    
    # Productivity
    "gmail": " 󰊫 ",
    "outlook": " 󰴢 ",
    "calendar": "  ",
    "drive": "  ",
    "docs": "  ",
    "sheets": "  ",
    "slides": "  ",
    "notion": "  ",
    "trello": "  ",
    "asana": "  ",
    "jira": "  ",
    "confluence": "  ",
    "teams": " 󰊻 ",
    
    # Cloud/DevOps
    "aws": "  ",
    "azure": "  ",
    "gcp": "  ",
    "digitalocean": "  ",
    "heroku": "  ",
    "vercel": "  ",
    "netlify": "  ",
    
    # E-commerce
    "amazon": "  ",
    "ebay": "  ",
    "etsy": "  ",
    "shopify": "  ",
    
    # News/Information
    "wikipedia": "  ",
    "medium": "  ",
    "hackernews": "  ",
    "techcrunch": "  ",
    
    # Music
    "spotify": "  ",
    "soundcloud": "  ",
    "bandcamp": "  ",
    
    # Other common sites
    "google": "  ",
    "bing": "  ",
    "duckduckgo": "  ",
    "apple": "  ",
    "appstore": "  ",
}

# Map web services to icons for Wavebox
WAVEBOX_SERVICE_ICONS = {
    # Development
    "github": "  ",
    "gitlab": "  ",
    "stackoverflow": "  ",
    "stack overflow": "  ",
    "dev.to": "  ",
    "codepen": "  ",
    "replit": "  ",
    "datadog": "  ",
    "gitkraken": "  ",
    
    # Social Media
    "twitter": "  ",
    "x.com": "  ",
    "facebook": "  ",
    "instagram": "  ",
    "linkedin": "  ",
    "reddit": "  ",
    "discord": "  ",
    "slack": "  ",
    "telegram": "  ",
    "whatsapp": "  ",
    
    # Video/Streaming
    "youtube": "  ",
    "twitch": "  ",
    "netflix": "  ",
    "hulu": "  ",
    "disney": "  ",
    "amazon": "  ",
    
    # Productivity
    "gmail": " 󰊫 ",
    "outlook": "  ",
    "calendar": "  ",
    "drive": "  ",
    "docs": "  ",
    "sheets": "  ",
    "slides": "  ",
    "notion": "  ",
    "trello": "  ",
    "asana": "  ",
    "jira": "  ",
    "confluence": "  ",
    "teams": "  ",
    "zoom": "  ",
    "meet": " 󰋀 ",
    
    # Cloud/DevOps
    "aws": "  ",
    "azure": "  ",
    "gcp": "  ",
    "digitalocean": "  ",
    "heroku": "  ",
    "vercel": "  ",
    "netlify": "  ",
    "datadog": "  ",
    
    # E-commerce
    "amazon": "  ",
    "ebay": "  ",
    "etsy": "  ",
    "shopify": "  ",
    
    # News/Information
    "wikipedia": "  ",
    "medium": "  ",
    "hackernews": "  ",
    "techcrunch": "  ",
    
    # Music
    "spotify": "  ",
    "soundcloud": "  ",
    "bandcamp": "  ",
    "apple-music": "  ",
    
    # Other common sites
    "google": "  ",
    "bing": "  ",
    "duckduckgo": "  ",
    "apple": "  ",
    "appstore": "  ",
    "google docs": "  ",
    "google sheets": "  ",
    "google slides": "  ",
    "google drive": "  ",
    "microsoft teams": "  ",
    "microsoft office": "  ",
}

i3 = i3ipc.Connection()

def get_browser_processes():
    """Get processes running in browser windows by examining browser processes"""
    try:
        browser_processes = {}
        
        # Check for Chrome/Chromium processes
        for browser_cmd in ['google-chrome', 'chromium', 'chrome']:
            try:
                result = subprocess.run(['ps', '-o', 'pid,ppid,cmd', '--no-headers', '-C', browser_cmd], 
                                      capture_output=True, text=True, check=True)
                
                lines = result.stdout.strip().split('\n')
                for line in lines:
                    if not line.strip():
                        continue
                        
                    parts = line.strip().split(None, 2)
                    if len(parts) >= 3:
                        pid = int(parts[0])
                        cmd = parts[2]
                        
                        # Extract URL or site from command line arguments
                        # Chrome processes often have --app= or similar flags
                        if '--app=' in cmd:
                            # Extract the URL from --app=URL
                            app_match = re.search(r'--app=([^\s]+)', cmd)
                            if app_match:
                                url = app_match.group(1)
                                site = extract_site_from_url(url)
                                if site:
                                    browser_processes[pid] = site
                        elif '--new-window' in cmd or '--new-tab' in cmd:
                            # This might be a new window/tab, we can't easily determine the site
                            pass
                        else:
                            # For regular browser processes, we can't easily determine the current site
                            # without more complex process inspection
                            pass
            except subprocess.CalledProcessError:
                # Browser not running or not found
                pass
        
        # Check for Firefox processes
        try:
            result = subprocess.run(['ps', '-o', 'pid,ppid,cmd', '--no-headers', '-C', 'firefox'], 
                                  capture_output=True, text=True, check=True)
            
            lines = result.stdout.strip().split('\n')
            for line in lines:
                if not line.strip():
                    continue
                    
                parts = line.strip().split(None, 2)
                if len(parts) >= 3:
                    pid = int(parts[0])
                    cmd = parts[2]
                    
                    # Firefox processes are harder to inspect for current URL
                    # We'll use a simpler approach based on window titles
                    pass
        except subprocess.CalledProcessError:
            # Firefox not running or not found
            pass
        
        return browser_processes
        
    except Exception:
        return {}

def extract_site_from_url(url):
    """Extract the main site name from a URL"""
    try:
        # Remove protocol
        if '://' in url:
            url = url.split('://', 1)[1]
        
        # Remove www.
        if url.startswith('www.'):
            url = url[4:]
        
        # Get the domain
        domain = url.split('/')[0].split('?')[0].split('#')[0]
        
        # Extract the main site name (e.g., 'github' from 'github.com')
        if '.' in domain:
            site = domain.split('.')[0]
        else:
            site = domain
        
        return site.lower()
    except:
        return None

def get_alacritty_processes():
    """Get processes running in Alacritty terminals by examining all alacritty processes"""
    try:
        # Get all alacritty processes
        result = subprocess.run(['ps', '-o', 'pid,ppid,cmd', '--no-headers', '-C', 'alacritty'], 
                              capture_output=True, text=True, check=True)
        
        alacritty_processes = {}
        lines = result.stdout.strip().split('\n')
        
        for line in lines:
            if not line.strip():
                continue
                
            parts = line.strip().split(None, 2)
            if len(parts) >= 3:
                pid = int(parts[0])
                ppid = int(parts[1])
                cmd = parts[2]
                
                # Get child processes of this alacritty instance
                child_result = subprocess.run(['ps', '-o', 'pid,ppid,cmd', '--no-headers', '--ppid', str(pid)], 
                                            capture_output=True, text=True, check=True)
                
                child_lines = child_result.stdout.strip().split('\n')
                if child_lines and child_lines != ['']:
                    # Find the most recent child process (excluding shell)
                    child_processes = []
                    for child_line in child_lines:
                        child_parts = child_line.strip().split(None, 2)
                        if len(child_parts) >= 3:
                            child_processes.append({
                                'pid': int(child_parts[0]),
                                'ppid': int(child_parts[1]),
                                'cmd': child_parts[2]
                            })
                    
                    if child_processes:
                        # Find non-shell processes first
                        non_shell_processes = [p for p in child_processes 
                                             if p['cmd'] and not any(shell in p['cmd'] for shell in ['zsh', 'bash', 'fish', 'sh'])]
                        
                        if non_shell_processes:
                            foreground = max(non_shell_processes, key=lambda x: x['pid'])
                        else:
                            # If only shell processes, look for grandchildren (processes running in the shell)
                            shell_pid = max(child_processes, key=lambda x: x['pid'])['pid']
                            try:
                                grandchild_result = subprocess.run(['ps', '-o', 'pid,ppid,cmd', '--no-headers', '--ppid', str(shell_pid)], 
                                                                capture_output=True, text=True, check=True)
                                
                                grandchild_lines = grandchild_result.stdout.strip().split('\n')
                                if grandchild_lines and grandchild_lines != ['']:
                                    grandchild_processes = []
                                    for grandchild_line in grandchild_lines:
                                        grandchild_parts = grandchild_line.strip().split(None, 2)
                                        if len(grandchild_parts) >= 3:
                                            grandchild_processes.append({
                                                'pid': int(grandchild_parts[0]),
                                                'ppid': int(grandchild_parts[1]),
                                                'cmd': grandchild_parts[2]
                                            })
                                    
                                    if grandchild_processes:
                                        # Find the most recent grandchild process
                                        foreground = max(grandchild_processes, key=lambda x: x['pid'])
                                    else:
                                        # No grandchildren, use shell
                                        foreground = max(child_processes, key=lambda x: x['pid'])
                                else:
                                    # No grandchildren, use shell
                                    foreground = max(child_processes, key=lambda x: x['pid'])
                            except subprocess.CalledProcessError:
                                # No grandchildren, use shell
                                foreground = max(child_processes, key=lambda x: x['pid'])
                        
                        # Extract command name
                        cmd_parts = foreground['cmd'].split()
                        if cmd_parts:
                            process_name = os.path.basename(cmd_parts[0])
                            alacritty_processes[pid] = process_name
        
        return alacritty_processes
        
    except subprocess.CalledProcessError:
        return {}

def get_window_pid_from_title(window):
    """Try to get the PID of a window by matching its title with process information"""
    try:
        # Get window title
        title = window.name or ""
        
        # Get all alacritty processes with their PIDs
        result = subprocess.run(['ps', '-o', 'pid,ppid,cmd', '--no-headers', '-C', 'alacritty'], 
                              capture_output=True, text=True, check=True)
        
        lines = result.stdout.strip().split('\n')
        for line in lines:
            if not line.strip():
                continue
                
            parts = line.strip().split(None, 2)
            if len(parts) >= 3:
                pid = int(parts[0])
                # For now, we'll use a simple approach: match by process order
                # This is not perfect but should work for most cases
                pass
        
        return None
    except:
        return None

def get_wavebox_window_info(window):
    """Get information about Wavebox window processes"""
    try:
        # Try to get window title and extract service information
        title = window.name or ""
        
        if not title:
            return None
        
        title_lower = title.lower()
        
        # Check for specific service patterns in title
        for service, icon in WAVEBOX_SERVICE_ICONS.items():
            if service in title_lower:
                return service
        
        # Try to extract from common title patterns
        if " - " in title:
            potential_site = title.split(" - ")[-1].lower()
            for browser in ["wavebox", "chrome", "chromium"]:
                potential_site = potential_site.replace(browser, "").strip()
            
            for service, icon in WAVEBOX_SERVICE_ICONS.items():
                if service in potential_site:
                    return service
        
        # Try to extract from URL patterns in title
        if "://" in title:
            url_match = re.search(r'https?://([^/\s]+)', title)
            if url_match:
                domain = url_match.group(1)
                site = extract_site_from_url(domain)
                if site and site in WAVEBOX_SERVICE_ICONS:
                    return site
        
        return None
        
    except Exception:
        return None

def get_window_icon(window):
    """Get the appropriate icon for a window, considering terminal and browser processes"""
    wm_class = (window.window_class or "").lower()
    window_title = window.name or ""
    
    # Check if it's an Alacritty window
    if wm_class == "alacritty":
        # Get all alacritty processes and their foreground processes
        alacritty_processes = get_alacritty_processes()
        
        # For Alacritty, we can use the window title to help identify which process is running
        # Alacritty often shows the current command in the title
        if window_title:
            # Check if the title contains any of our known process names
            title_lower = window_title.lower()
            for process_name, icon in TERMINAL_PROCESS_ICONS.items():
                if process_name in title_lower:
                    return icon
        
        # If no match by title, try to use the process list
        # We'll use a simple approach: assign processes to windows by order
        if alacritty_processes:
            # Get all Alacritty windows in the current workspace
            workspace = window.workspace()
            alacritty_windows = [w for w in workspace.leaves() if w.window_class and w.window_class.lower() == "alacritty"]
            
            # Find the index of this window among Alacritty windows
            try:
                window_index = alacritty_windows.index(window)
                process_pids = list(alacritty_processes.keys())
                if window_index < len(process_pids):
                    pid = process_pids[window_index]
                    process_name = alacritty_processes[pid]
                    if process_name in TERMINAL_PROCESS_ICONS:
                        return TERMINAL_PROCESS_ICONS[process_name]
            except (ValueError, IndexError):
                pass
        
        # Fallback to default Alacritty icon
        return ICON_MAP.get(wm_class, "")
    
    # Check if it's a browser window
    elif wm_class in ["google-chrome", "chromium", "firefox"]:
        # For browsers, we'll use the window title to determine the site
        if window_title:
            title_lower = window_title.lower()
            
            # Special cases for specific services that don't always include the main site name
            if "pipelines" in title_lower and ("recent" in title_lower or "azure" in title_lower):
                return BROWSER_PROCESS_ICONS.get("azure", ICON_MAP.get(wm_class, ""))
            if "dev.azure.com" in title_lower:
                return BROWSER_PROCESS_ICONS.get("azure", ICON_MAP.get(wm_class, ""))
            if "gmail" in title_lower or "inbox" in title_lower and "gmail" in title_lower:
                return BROWSER_PROCESS_ICONS.get("gmail", ICON_MAP.get(wm_class, ""))
            
            # Check if the title contains any of our known site names
            for site_name, icon in BROWSER_PROCESS_ICONS.items():
                if site_name in title_lower:
                    return icon
            
            # Try to extract site from common title patterns
            # Many browsers show "Site Name - Browser" or "Page Title | Site Name"
            if " - " in window_title:
                # Extract the part after the last " - " which is often the site
                potential_site = window_title.split(" - ")[-1].lower()
                # Remove browser name if present
                for browser in ["google chrome", "chromium", "firefox", "mozilla"]:
                    potential_site = potential_site.replace(browser, "").strip()
                
                # Check if this matches any of our site names
                for site_name, icon in BROWSER_PROCESS_ICONS.items():
                    if site_name in potential_site:
                        return icon
            
            # Try to extract from URL patterns in title
            # Some browsers show URLs in the title
            if "://" in window_title:
                url_match = re.search(r'https?://([^/\s]+)', window_title)
                if url_match:
                    domain = url_match.group(1)
                    site = extract_site_from_url(domain)
                    if site and site in BROWSER_PROCESS_ICONS:
                        return BROWSER_PROCESS_ICONS[site]
        
        # Fallback to default browser icon
        return ICON_MAP.get(wm_class, "")
    
    # Check if it's a Wavebox window
    elif wm_class == "wavebox":
        service = get_wavebox_window_info(window)
        if service and service in WAVEBOX_SERVICE_ICONS:
            return WAVEBOX_SERVICE_ICONS[service]
        
        # Fallback to default Wavebox icon
        return ICON_MAP.get(wm_class, "")
    
    # For other windows, use the standard icon mapping
    return ICON_MAP.get(wm_class, "")

def get_workspace_icons(workspace):
    """Get icons for all windows in a workspace"""
    icons = []
    for window in workspace.leaves():
        icon = get_window_icon(window)
        
        # Fallback system - only apply to windows without icons
        if not icon or icon.strip() == "":
            wm_class = (window.window_class or "").lower()
            
            # For Alacritty, browser, and Wavebox windows, we should already have the default icon from ICON_MAP
            # If we don't, it means there's an issue with the icon mapping
            if wm_class in ["alacritty", "google-chrome", "chromium", "firefox", "wavebox"]:
                # This shouldn't happen, but if it does, use the default icon
                icon = ICON_MAP.get(wm_class, "")
            
            # Apply fallback system for other applications
            if not icon or icon.strip() == "":
                if FALLBACK_STYLE == "short":
                    fallback = wm_class[:FALLBACK_LENGTH].upper() if wm_class else "???"
                    icons.append(fallback)
                elif FALLBACK_STYLE == "full":
                    fallback = wm_class.upper() if wm_class else "UNKNOWN"
                    icons.append(fallback)
                elif FALLBACK_STYLE == "none":
                    continue
                else:
                    fallback = wm_class[:FALLBACK_LENGTH].upper() if wm_class else "???"
                    icons.append(fallback)
            else:
                icons.append(icon)
        else:
            icons.append(icon)
    return icons

def print_all_workspaces():
    """Print all workspaces with their applications"""
    try:
        # Get existing workspaces and create a mapping
        existing_workspaces = i3.get_tree().workspaces()
        workspace_map = {ws.name: ws for ws in existing_workspaces}
        
        focused_workspace = i3.get_tree().find_focused().workspace()
        workspace_outputs = []
        
        # Show all 10 workspaces (1-10) as configured in i3
        for i in range(1, 11):
            ws_name = str(i)
            ws = workspace_map.get(ws_name)
            
            if ws is None:
                # Workspace doesn't exist yet - show as empty
                is_focused = focused_workspace and ws_name == focused_workspace.name
                if is_focused:
                    # Focused nonexistent workspace - dimmed blue with click
                    workspace_outputs.append(f"%{{A1:i3-msg workspace number {ws_name}:}}%{{F#5E81AC}}{ws_name}%{{F-}}%{{A}}")
                else:
                    # Unfocused nonexistent workspace - dimmed gray with click
                    workspace_outputs.append(f"%{{A1:i3-msg workspace number {ws_name}:}}%{{F#4C566A}}{ws_name}%{{F-}}%{{A}}")
            else:
                # Workspace exists - check if it has windows
                icons = get_workspace_icons(ws)
                is_empty = len(ws.leaves()) == 0
                is_focused = focused_workspace and ws_name == focused_workspace.name
                
                if is_empty:
                    # Empty workspace styling with click
                    if is_focused:
                        workspace_outputs.append(f"%{{A1:i3-msg workspace number {ws_name}:}}%{{F#A3BE8C}}{ws_name}%{{F-}}%{{A}}")
                    else:
                        workspace_outputs.append(f"%{{A1:i3-msg workspace number {ws_name}:}}%{{F#3B4252}}{ws_name}%{{F-}}%{{A}}")
                else:
                    # Workspace with windows - make entire area clickable (number + icons)
                    if is_focused:
                        workspace_outputs.append(f"%{{A1:i3-msg workspace number {ws_name}:}}%{{F#A3BE8C}}{ws_name} {' '.join(icons)}%{{F-}}%{{A}}")
                    else:
                        workspace_outputs.append(f"%{{A1:i3-msg workspace number {ws_name}:}}%{{F#D08770}}{ws_name} {' '.join(icons)}%{{F-}}%{{A}}")
        
        if workspace_outputs:
            result = f"%{{F#EBCB8B}} | %{{F-}}".join(workspace_outputs)
        else:
            result = ""
            
        print(result, flush=True)
        
    except Exception as e:
        print("", flush=True)

def on_event(i3, e):
    print_all_workspaces()

# Listen to changes
i3.on("window::new", on_event)
i3.on("window::close", on_event)
i3.on("window::move", on_event)
i3.on("window::title", on_event)
i3.on("window::focus", on_event)
i3.on("workspace::focus", on_event)

print_all_workspaces()
i3.main()