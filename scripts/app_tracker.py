#!/usr/bin/env python3
import json
import os
import subprocess
import time
from datetime import datetime, timedelta

DATA_FILE = os.path.expanduser("~/.cache/am_i_cooked_history.json")

# Category definitions
WASTED_APPS = {"discord", "steam", "spotify", "vlc", "mpv", "reddit", "twitter", "x", "youtube", "netflix", "twitch", "gaming", "genshin", "launcher"}
PRODUCTIVE_APPS = {"neovim", "nvim", "vim", "alacritty", "kitty", "foot", "wezterm", "code", "zed", "obsidian", "terminal", "antigravity", "emacs"}

# Class name → clean human-readable name mapping
CLASS_NAME_MAP = {
    "brave-browser": "Brave",
    "firefox": "Firefox",
    "chromium": "Chromium",
    "io.github.ungoogled_software.ungoogled_chromium": "Chromium",
    "google-chrome": "Chrome",
    "discord": "Discord",
    "steam": "Steam",
    "steam_proton": None,   # Will use window title instead
    "proton": None,
    "spotify": "Spotify",
    "vlc": "VLC",
    "mpv": "MPV",
    "obsidian": "Obsidian",
    "code": "VS Code",
    "code-oss": "VS Code",
    "zed": "Zed",
    "neovim": "Neovim",
    "nvim": "Neovim",
    "alacritty": "Alacritty",
    "kitty": "Kitty",
    "foot": "Foot Terminal",
    "wezterm": "WezTerm",
    "thunar": "Thunar",
    "nautilus": "Files",
    "org.gnome.nautilus": "Files",
    "dolphin": "Dolphin",
    "telegram-desktop": "Telegram",
    "signal": "Signal",
    "gimp": "GIMP",
    "inkscape": "Inkscape",
    "blender": "Blender",
    "krita": "Krita",
    "libreoffice": "LibreOffice",
    "quickshell": "Quickshell",
    "org.quickshell": "Quickshell",
    "qs": "Quickshell",
    "antigravity": "Antigravity",
    "systemsettings": "System Settings",
}

# Title keywords that identify games or apps running under proton/wine/generic classes
TITLE_GAME_KEYWORDS = {
    "genshin impact": "Genshin Impact",
    "honkai": "Honkai",
    "zenless zone zero": "Zenless Zone Zero",
    "star rail": "Honkai: Star Rail",
    "steam": "Steam",
    "hsr": "Honkai: Star Rail",
    "minecraft": "Minecraft",
    "league of legends": "League of Legends",
    "valorant": "Valorant",
    "counter-strike": "Counter-Strike",
    "dota": "Dota 2",
    "overwatch": "Overwatch",
    "cyberpunk": "Cyberpunk 2077",
    "elden ring": "Elden Ring",
    "witcher": "The Witcher",
    "stardew valley": "Stardew Valley",
    "terraria": "Terraria",
    "celeste": "Celeste",
}

def resolve_app_name(app_cls: str, title: str) -> str:
    """Resolve a clean, human-readable app name from the WM class and window title."""
    cls_lower = app_cls.lower()
    title_lower = title.lower()

    # Try direct class map first
    if cls_lower in CLASS_NAME_MAP:
        mapped = CLASS_NAME_MAP[cls_lower]
        if mapped is not None:
            # For browsers, check title for sites
            if mapped in ("Brave", "Firefox", "Chromium", "Chrome"):
                if "youtube" in title_lower:
                    return "YouTube"
                elif "reddit" in title_lower:
                    return "Reddit"
                elif "twitter" in title_lower or "x.com" in title_lower:
                    return "Twitter / X"
                elif "twitch" in title_lower:
                    return "Twitch"
                elif "netflix" in title_lower:
                    return "Netflix"
                elif "coursera" in title_lower:
                    return "Coursera"
                elif "github.com" in title_lower:
                    return "GitHub"
                elif "claude" in title_lower:
                    return "Claude AI"
                elif "gemini" in title_lower:
                    return "Gemini AI"
                elif "chatgpt" in title_lower:
                    return "ChatGPT"
                elif "stackoverflow" in title_lower:
                    return "Stack Overflow"
                return mapped
            return mapped
        # mapped is None — fall through to title resolution
    
    # Title-based game/app detection (handles steam_proton etc.)
    for keyword, clean_name in TITLE_GAME_KEYWORDS.items():
        if keyword in title_lower:
            return clean_name
    
    # If title is available and the class is a generic launcher/proton class, use title
    GENERIC_CLASSES = {"steam_proton", "proton", "wine", "wineserver", "java", "unityhub", "electron"}
    if cls_lower in GENERIC_CLASSES or cls_lower.startswith("com.") or cls_lower.startswith("org."):
        if title and len(title) > 1:
            # Clean up the title: strip common suffixes
            clean_title = title
            for suffix in [" - Mozilla Firefox", " - Chromium", " - Brave", " - Google Chrome"]:
                clean_title = clean_title.replace(suffix, "")
            return clean_title.strip()
    
    # Fallback: capitalize the class name
    if cls_lower and cls_lower not in ("", "unknown"):
        return app_cls.split(".")[0].capitalize()
    
    return "Desktop / Idle"


def load_data():
    if os.path.exists(DATA_FILE):
        try:
            with open(DATA_FILE, "r") as f:
                data = json.load(f)
                # Migrate old data: add all_time if missing
                if "all_time" not in data:
                    data["all_time"] = {}
                return data
        except Exception:
            pass
    return {
        "boot_time": time.time(),
        "last_tick": time.time(),
        "daily": {},    # "YYYY-MM-DD": { app_name: seconds }
        "weekly": {},   # "YYYY-WW": { app_name: seconds }
        "monthly": {},  # "YYYY-MM": { app_name: seconds }
        "all_time": {}  # { app_name: seconds } - persists forever
    }

def save_data(data):
    os.makedirs(os.path.dirname(DATA_FILE), exist_ok=True)
    with open(DATA_FILE, "w") as f:
        json.dump(data, f, indent=2)

def get_active_app():
    """Get the currently focused application with smart name resolution."""
    try:
        res = subprocess.run(["hyprctl", "activewindow", "-j"], capture_output=True, text=True, timeout=1)
        if res.returncode == 0 and res.stdout.strip():
            info = json.loads(res.stdout)
            app_cls = info.get("class", "").strip()
            title = info.get("title", "").strip()
            if app_cls:
                return resolve_app_name(app_cls, title)
    except Exception:
        pass
    return "Desktop / Idle"

def record_tick():
    data = load_data()
    now = time.time()
    dt = datetime.fromtimestamp(now)
    
    last_tick = data.get("last_tick", now)
    elapsed = now - last_tick
    # Ignore huge gaps (> 5 mins, laptop was suspended)
    if elapsed > 300:
        elapsed = 3.0
        
    data["last_tick"] = now
    
    app = get_active_app()
    if not app or app == "Desktop / Idle":
        save_data(data)
        return data
        
    day_key = dt.strftime("%Y-%m-%d")
    week_key = dt.strftime("%Y-W%U")
    month_key = dt.strftime("%Y-%m")
    
    # Initialize structures
    if "daily" not in data: data["daily"] = {}
    if "weekly" not in data: data["weekly"] = {}
    if "monthly" not in data: data["monthly"] = {}
    if "all_time" not in data: data["all_time"] = {}
    
    if day_key not in data["daily"]: data["daily"][day_key] = {}
    if week_key not in data["weekly"]: data["weekly"][week_key] = {}
    if month_key not in data["monthly"]: data["monthly"][month_key] = {}
    
    data["daily"][day_key][app] = data["daily"][day_key].get(app, 0) + elapsed
    data["weekly"][week_key][app] = data["weekly"][week_key].get(app, 0) + elapsed
    data["monthly"][month_key][app] = data["monthly"][month_key].get(app, 0) + elapsed
    data["all_time"][app] = data["all_time"].get(app, 0) + elapsed
    
    save_data(data)
    return data

def format_seconds(secs):
    secs = int(secs)
    h = secs // 3600
    m = (secs % 3600) // 60
    if h > 0:
        return f"{h}h {m}m"
    return f"{m}m"

def format_seconds_long(secs):
    """Format with days for lifetime stats."""
    secs = int(secs)
    d = secs // 86400
    h = (secs % 86400) // 3600
    m = (secs % 3600) // 60
    if d > 0:
        return f"{d}d {h}h {m}m"
    if h > 0:
        return f"{h}h {m}m"
    return f"{m}m"

def is_wasted_app(app_name):
    low = app_name.lower()
    for w in WASTED_APPS:
        if w in low:
            return True
    return False

def is_productive_app(app_name):
    low = app_name.lower()
    for p in PRODUCTIVE_APPS:
        if p in low:
            return True
    return False

def get_summaries():
    data = record_tick()
    now = time.time()
    dt = datetime.fromtimestamp(now)
    
    day_key = dt.strftime("%Y-%m-%d")
    week_key = dt.strftime("%Y-W%U")
    month_key = dt.strftime("%Y-%m")
    
    today_apps = data.get("daily", {}).get(day_key, {})
    week_apps = data.get("weekly", {}).get(week_key, {})
    month_apps = data.get("monthly", {}).get(month_key, {})
    all_time_apps = data.get("all_time", {})
    
    def process_period(app_dict, is_lifetime=False):
        sorted_apps = sorted(app_dict.items(), key=lambda x: x[1], reverse=True)
        total_secs = sum(app_dict.values())
        wasted_secs = sum(secs for name, secs in app_dict.items() if is_wasted_app(name))
        productive_secs = sum(secs for name, secs in app_dict.items() if is_productive_app(name))
        
        fmt_fn = format_seconds_long if is_lifetime else format_seconds
        
        top_list = []
        for name, secs in sorted_apps[:10]:
            top_list.append({
                "name": name,
                "formatted": fmt_fn(secs),
                "seconds": round(secs, 1),
                "is_wasted": is_wasted_app(name),
                "is_productive": is_productive_app(name)
            })
            
        return {
            "total_formatted": fmt_fn(total_secs),
            "total_seconds": round(total_secs, 1),
            "wasted_formatted": fmt_fn(wasted_secs),
            "wasted_seconds": round(wasted_secs, 1),
            "productive_formatted": fmt_fn(productive_secs),
            "productive_seconds": round(productive_secs, 1),
            "top_apps": top_list
        }
        
    uptime_secs = now - data.get("boot_time", now)
    
    # Calculate how many days of data we have
    days_tracked = len(data.get("daily", {}))
    
    return {
        "uptime_formatted": format_seconds(uptime_secs),
        "days_tracked": days_tracked,
        "daily": process_period(today_apps),
        "weekly": process_period(week_apps),
        "monthly": process_period(month_apps),
        "lifetime": process_period(all_time_apps, is_lifetime=True)
    }

if __name__ == "__main__":
    import sys
    if len(sys.argv) > 1 and sys.argv[1] == "--tick-only":
        # Lightweight background tick: just record the active app and exit silently
        record_tick()
    else:
        print(json.dumps(get_summaries(), indent=2))
