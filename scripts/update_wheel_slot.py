#!/usr/bin/env python3
import json
import sys

def main():
    if len(sys.argv) < 5:
        print("Usage: update_wheel_slot.py <index> <name> <exec> <icon>")
        sys.exit(1)
        
    index = int(sys.argv[1])
    name = sys.argv[2]
    exec_cmd = sys.argv[3]
    icon = sys.argv[4]
    
    file_path = "/home/nick/.config/quickshell/assets/wheel.json"
    
    try:
        with open(file_path, 'r') as f:
            data = json.load(f)
            
        if 0 <= index < len(data):
            data[index]["name"] = name
            data[index]["exec"] = exec_cmd
            data[index]["icon"] = icon
            
        with open(file_path, 'w') as f:
            json.dump(data, f, indent=4)
            
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
