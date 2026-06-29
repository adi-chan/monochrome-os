import re

with open('/home/nick/.config/quickshell/modules/EdgeMixer.qml', 'r') as f:
    content = f.read()

content = re.sub(r'color:\s*"#2a2a2a"', 'color: Services.Theme.border', content)
content = re.sub(r'color:\s*"#ffffff"', 'color: Services.Theme.text', content)

with open('/home/nick/.config/quickshell/modules/EdgeMixer.qml', 'w') as f:
    f.write(content)
