import re

with open('/home/nick/.config/quickshell/modules/controlpanel/AppMixerDrawer.qml', 'r') as f:
    content = f.read()

content = content.replace("property color text: Services.Theme.text", "")
content = content.replace("property color subtext: Services.Theme.subtext", "")
content = content.replace("color: drawer.text", "color: Services.Theme.text")
content = content.replace("color: drawer.subtext", "color: Services.Theme.subtext")

with open('/home/nick/.config/quickshell/modules/controlpanel/AppMixerDrawer.qml', 'w') as f:
    f.write(content)
