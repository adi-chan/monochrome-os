#!/usr/bin/env python3
import json
import os
import re
import subprocess
import sys
import time
from app_tracker import get_summaries

def get_mpd_stats():
    try:
        res = subprocess.run(["mpc", "status"], capture_output=True, text=True, timeout=1)
        if res.returncode != 0 or not res.stdout.strip():
            return {"active": False, "state": "STOPPED", "title": "No Track Playing"}
            
        lines = [line.strip() for line in res.stdout.strip().split('\n') if line.strip()]
        if len(lines) == 1 and ("volume:" in lines[0] or "error:" in lines[0].lower()):
            return {"active": False, "state": "STOPPED", "title": "No Track Playing"}
            
        track_title = lines[0]
        state = "PLAYING"
        elapsed = "0:00"
        duration = "0:00"
        progress_pct = 0
        track_no = ""
        
        if len(lines) >= 2 and "[" in lines[1]:
            status_line = lines[1]
            if "[playing]" in status_line:
                state = "PLAYING"
            elif "[paused]" in status_line:
                state = "PAUSED"
            else:
                state = "STOPPED"
                
            # Parse track_no & times: #6/171   2:10/3:15 (66%)
            match_no = re.search(r'#(\d+/\d+)', status_line)
            if match_no:
                track_no = match_no.group(1)
                
            match_times = re.search(r'(\d+:\d+)/(\d+:\d+)\s*\(( \d+|\d+)%\)', status_line)
            if match_times:
                elapsed = match_times.group(1)
                duration = match_times.group(2)
                progress_pct = int(match_times.group(3))
                
        # Split artist if ' - ' is present
        artist = ""
        song_name = track_title
        if " - " in track_title:
            parts = track_title.split(" - ", 1)
            artist = parts[0]
            song_name = parts[1]
            
        return {
            "active": True,
            "state": state,
            "title": song_name,
            "artist": artist if artist else "MPD Track",
            "full_title": track_title,
            "elapsed": elapsed,
            "duration": duration,
            "progress_percent": progress_pct,
            "track_no": track_no
        }
    except Exception:
        return {"active": False, "state": "STOPPED", "title": "MPD Offline"}

def get_cpu_stats():
    try:
        with open('/proc/stat', 'r') as f:
            line = f.readline()
        parts = [float(x) for x in line.strip().split()[1:]]
        idle = parts[3] + parts[4]
        total = sum(parts)
        
        load1, load5, load15 = os.getloadavg()
        
        temp = None
        thermal_dirs = ['/sys/class/thermal/thermal_zone0/temp', '/sys/class/hwmon/hwmon0/temp1_input']
        for tpath in thermal_dirs:
            if os.path.exists(tpath):
                try:
                    with open(tpath, 'r') as tf:
                        raw_temp = float(tf.read().strip())
                        temp = raw_temp / 1000.0 if raw_temp > 1000 else raw_temp
                        break
                except Exception:
                    pass
        if temp is None:
            try:
                res = subprocess.run(['sensors'], capture_output=True, text=True, timeout=1)
                matches = re.findall(r'\+([0-9]+\.[0-9]+)°C', res.stdout)
                if matches:
                    temp = float(matches[0])
            except Exception:
                temp = 45.0
                
        return {
            "idle": idle,
            "total": total,
            "load1": round(load1, 2),
            "load5": round(load5, 2),
            "load15": round(load15, 2),
            "temp": round(temp, 1) if temp else 45.0
        }
    except Exception:
        return {"load1": 0.0, "load5": 0.0, "load15": 0.0, "temp": 45.0}

def get_cpu_percentage():
    try:
        with open('/proc/stat', 'r') as f:
            lines1 = f.readline().split()[1:]
        time.sleep(0.08)
        with open('/proc/stat', 'r') as f:
            lines2 = f.readline().split()[1:]
            
        t1 = sum(float(x) for x in lines1)
        t2 = sum(float(x) for x in lines2)
        idle1 = float(lines1[3]) + float(lines1[4])
        idle2 = float(lines2[3]) + float(lines2[4])
        
        total_diff = t2 - t1
        idle_diff = idle2 - idle1
        if total_diff == 0:
            return 0.0
        usage = ((total_diff - idle_diff) / total_diff) * 100.0
        return round(usage, 1)
    except Exception:
        return 0.0

def get_memory_stats():
    try:
        mem = {}
        with open('/proc/meminfo', 'r') as f:
            for line in f:
                parts = line.split(':')
                if len(parts) == 2:
                    key = parts[0].strip()
                    val = parts[1].strip().split()[0]
                    mem[key] = int(val)
                    
        total_kb = mem.get('MemTotal', 1)
        free_kb = mem.get('MemFree', 0)
        available_kb = mem.get('MemAvailable', free_kb)
        used_kb = total_kb - available_kb
        
        swap_total_kb = mem.get('SwapTotal', 0)
        swap_free_kb = mem.get('SwapFree', 0)
        swap_used_kb = swap_total_kb - swap_free_kb
        
        ram_percent = (used_kb / total_kb) * 100.0 if total_kb > 0 else 0
        swap_percent = (swap_used_kb / swap_total_kb) * 100.0 if swap_total_kb > 0 else 0
        
        return {
            "total_gb": round(total_kb / (1024 * 1024), 2),
            "used_gb": round(used_kb / (1024 * 1024), 2),
            "available_gb": round(available_kb / (1024 * 1024), 2),
            "ram_percent": round(ram_percent, 1),
            "swap_total_gb": round(swap_total_kb / (1024 * 1024), 2),
            "swap_used_gb": round(swap_used_kb / (1024 * 1024), 2),
            "swap_percent": round(swap_percent, 1)
        }
    except Exception:
        return {"total_gb": 16.0, "used_gb": 4.0, "ram_percent": 25.0, "swap_percent": 0.0}

def get_battery_stats():
    bat_path = None
    if os.path.exists('/sys/class/power_supply'):
        for item in os.listdir('/sys/class/power_supply'):
            if item.startswith('BAT'):
                bat_path = os.path.join('/sys/class/power_supply', item)
                break
            
    if not bat_path:
        return {"present": False, "capacity": 100, "status": "AC Power", "power_w": 0.0, "temp": 30.0}
        
    try:
        def read_val(filename, default="0"):
            fp = os.path.join(bat_path, filename)
            if os.path.exists(fp):
                with open(fp, 'r') as f:
                    return f.read().strip()
            return default
            
        capacity = int(read_val('capacity', '100'))
        status = read_val('status', 'Unknown')
        
        power_uw = float(read_val('power_now', read_val('current_now', '0')))
        voltage_uv = float(read_val('voltage_now', '10000000'))
        if power_uw > 1000 and voltage_uv > 0:
            power_w = round((power_uw * voltage_uv) / 1e12, 1) if power_uw > 1e6 else round(power_uw / 1e6, 1)
        else:
            power_w = 0.0
            
        temp_raw = float(read_val('temp', '300'))
        temp = round(temp_raw / 10.0, 1) if temp_raw > 100 else round(temp_raw, 1)
        
        return {
            "present": True,
            "capacity": capacity,
            "status": status,
            "power_w": power_w,
            "temp": temp
        }
    except Exception:
        return {"present": True, "capacity": 80, "status": "Discharging", "power_w": 12.5, "temp": 35.0}

def get_top_processes():
    try:
        res = subprocess.run(
            ["ps", "-eo", "pid,comm,%cpu,%mem", "--sort=-%cpu"],
            capture_output=True, text=True, timeout=2
        )
        lines = res.stdout.strip().split('\n')[1:6]
        top_cpu = []
        for line in lines:
            parts = line.split()
            if len(parts) >= 4:
                top_cpu.append({
                    "pid": parts[0],
                    "name": parts[1],
                    "cpu": float(parts[2]),
                    "mem": float(parts[3])
                })
                
        res_mem = subprocess.run(
            ["ps", "-eo", "pid,comm,%cpu,%mem", "--sort=-%mem"],
            capture_output=True, text=True, timeout=2
        )
        lines_mem = res_mem.stdout.strip().split('\n')[1:6]
        top_mem = []
        for line in lines_mem:
            parts = line.split()
            if len(parts) >= 4:
                top_mem.append({
                    "pid": parts[0],
                    "name": parts[1],
                    "cpu": float(parts[2]),
                    "mem": float(parts[3])
                })
                
        return {"top_cpu": top_cpu, "top_mem": top_mem}
    except Exception:
        return {"top_cpu": [], "top_mem": []}

def get_disk_stats():
    try:
        st = os.statvfs('/')
        total = (st.f_blocks * st.f_frsize) / (1024**3)
        free = (st.f_bavail * st.f_frsize) / (1024**3)
        used = total - free
        percent = (used / total) * 100.0 if total > 0 else 0
        return {
            "root_total_gb": round(total, 1),
            "root_used_gb": round(used, 1),
            "root_free_gb": round(free, 1),
            "root_percent": round(percent, 1)
        }
    except Exception:
        return {"root_total_gb": 500, "root_used_gb": 250, "root_percent": 50.0}

def get_active_window():
    try:
        res = subprocess.run(["hyprctl", "activewindow", "-j"], capture_output=True, text=True, timeout=1)
        if res.returncode == 0 and res.stdout.strip():
            data = json.loads(res.stdout)
            title = data.get("title", "")
            wm_class = data.get("class", "Terminal/App")
            return {"title": title, "class": wm_class}
    except Exception:
        pass
    return {"title": "Desktop / Rice", "class": "quickshell"}

def calculate_cooked_status(cpu_pct, mem_stats, bat_stats, cpu_stats, top_procs, disk_stats):
    reasons = []
    
    # Continuous Dynamic Formula:
    # 1. CPU (Weight: 30%)
    cpu_score = (cpu_pct / 100.0) * 30.0
    load1 = cpu_stats.get("load1", 0)
    if load1 > 4.0:
        cpu_score += 5.0
        reasons.append(f"High CPU load average ({load1})")
    elif load1 > 2.0:
        cpu_score += 2.5
        
    if cpu_pct > 70 and top_procs.get("top_cpu"):
        reasons.append(f"CPU at {cpu_pct}% ({top_procs['top_cpu'][0]['name']})")

    # 2. Memory (Weight: 25% RAM + 5% Swap)
    ram_pct = mem_stats.get("ram_percent", 0)
    ram_score = (ram_pct / 100.0) * 25.0
    if ram_pct > 80:
        reasons.append(f"Memory heavy: {ram_pct}% ({mem_stats['used_gb']}GB)")
        
    swap_pct = mem_stats.get("swap_percent", 0)
    swap_score = (swap_pct / 100.0) * 5.0
    if swap_pct > 30:
        reasons.append(f"Swap active ({swap_pct}%)")

    # 3. Thermals (Weight: 20%, baseline 35°C, max 85°C)
    temp = cpu_stats.get("temp", 40)
    if temp > 35:
        thermal_score = min(20.0, ((temp - 35.0) / 50.0) * 20.0)
    else:
        thermal_score = 0.0
    if temp > 70:
        reasons.append(f"High thermals ({temp}°C)")

    # 4. Battery / Power (Weight: 10%)
    bat_score = 0.0
    if bat_stats.get("present"):
        bat_cap = bat_stats.get("capacity", 100)
        status = bat_stats.get("status", "")
        if status == "Discharging":
            bat_score += ((100 - bat_cap) / 100.0) * 6.0
            if bat_cap < 20:
                reasons.append(f"Low battery ({bat_cap}%)")
        power_w = bat_stats.get("power_w", 0)
        if power_w > 5.0:
            bat_score += min(4.0, (power_w / 20.0) * 4.0)

    # 5. Disk (Weight: 5%)
    disk_pct = disk_stats.get("root_percent", 50)
    disk_score = (disk_pct / 100.0) * 5.0

    total_score = round(cpu_score + ram_score + swap_score + thermal_score + bat_score + disk_score, 1)
    cooked_score = min(100, max(0, int(total_score)))

    if cooked_score < 25:
        tier = "CHILLED"
        summary = "System running cool and optimal."
    elif cooked_score < 48:
        tier = "NOMINAL"
        summary = "Normal operational stats."
    elif cooked_score < 72:
        tier = "SIMMERING"
        summary = "Elevated system load detected."
    elif cooked_score < 88:
        tier = "HIGHLY COOKED"
        summary = "High resource pressure detected."
    else:
        tier = "CRITICAL OVERLOAD"
        summary = "CRITICAL THERMAL AND RESOURCE OVERLOAD!"

    if not reasons:
        reasons.append("All metrics within ideal limits.")

    return {
        "score": cooked_score,
        "tier": tier,
        "summary": summary,
        "reasons": reasons
    }

def main():
    cpu_pct = get_cpu_percentage()
    cpu_stats = get_cpu_stats()
    mem_stats = get_memory_stats()
    bat_stats = get_battery_stats()
    top_procs = get_top_processes()
    disk_stats = get_disk_stats()
    active_win = get_active_window()
    usage_analytics = get_summaries()
    mpd_stats = get_mpd_stats()

    cooked = calculate_cooked_status(cpu_pct, mem_stats, bat_stats, cpu_stats, top_procs, disk_stats)

    payload = {
        "timestamp": time.time(),
        "cooked": cooked,
        "cpu": {
            "usage_percent": cpu_pct,
            "temp": cpu_stats["temp"],
            "load1": cpu_stats["load1"],
            "load5": cpu_stats["load5"],
            "load15": cpu_stats["load15"]
        },
        "memory": mem_stats,
        "battery": bat_stats,
        "processes": top_procs,
        "disk": disk_stats,
        "active_window": active_win,
        "usage_analytics": usage_analytics,
        "mpd": mpd_stats
    }

    print(json.dumps(payload, indent=2))

if __name__ == "__main__":
    main()
