import os
import re

files_to_update = [
    "modules/BatteryMenu.qml",
    "modules/DateTime.qml",
    "modules/PowerMenu.qml",
    "modules/RightBtn.qml",
    "modules/Workspaces.qml",
    "modules/NotifButton.qml",
    "modules/NotificationCenter.qml",
    "modules/controlpanel/Volume.qml",
    "modules/controlpanel/NetworkMenu.qml",
    "modules/controlpanel/BluetoothMenu.qml",
    "modules/datetimepanel/Reminders.qml",
    "bar/Bar.qml"
]

for file_path in files_to_update:
    full_path = os.path.join("/home/nick/.config/quickshell", file_path)
    if not os.path.exists(full_path):
        continue
        
    with open(full_path, "r") as f:
        content = f.read()
        
    original_content = content
        
    if "import qs.services as Services" not in content:
        content = content.replace("import QtQuick\n", "import QtQuick\nimport qs.services as Services\n")

    # Simple replacements
    content = re.sub(r'color:\s*"#000000"', 'color: Services.Theme.bgSolid', content)
    content = re.sub(r'color:\s*"#ffffff"', 'color: Services.Theme.text', content)
    
    # Backgrounds
    content = re.sub(r'color:\s*"(?:#0c0c0c|#11111b|#1e1e2e|#2b2b2b|#313244|#3e3f49|#413b3b)"', 'color: Services.Theme.bg', content)
    
    # Borders
    content = re.sub(r'border\.color:\s*"(?:#2a2a2a|#30ffffff|#45475a|#3a3a3a|#313244|#000000)"', 'border.color: Services.Theme.border', content)
    
    # Subtext
    content = re.sub(r'color:\s*"(?:#666666|#a6adc8|#aaaaaa|#bac2de|#ccc|#cdd6f4)"', 'color: Services.Theme.subtext', content)
    
    # Text tags that have color property in a single line
    content = re.sub(r'color:\s*"#[0-9a-fA-F]+"', 'color: Services.Theme.text', content) # Catch remaining colors if any that were not matched, maybe a bit dangerous but should catch text colors

    if original_content != content:
        with open(full_path, "w") as f:
            f.write(content)
        print(f"Updated {file_path}")
