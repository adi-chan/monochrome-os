import re

with open('/home/nick/.config/quickshell/modules/ShortcutWheel.qml', 'r') as f:
    content = f.read()

# Fix static borders to use Theme.border or a translucent Theme.text
content = re.sub(
    r'border\.color:\s*"#40ffffff"',
    r'border.color: Services.Theme.isDark ? "#40ffffff" : "#40000000"',
    content
)

# Fix gradient stops for canvas
content = re.sub(
    r'grad\.addColorStop\(0,\s*"#40ffffff"\);',
    r'grad.addColorStop(0, Services.Theme.isDark ? "#40ffffff" : "#20000000");',
    content
)
content = re.sub(
    r'grad\.addColorStop\(0\.7,\s*"#40ffffff"\);',
    r'grad.addColorStop(0.7, Services.Theme.isDark ? "#40ffffff" : "#20000000");',
    content
)

content = re.sub(
    r'grad\.addColorStop\(0,\s*"#10ffffff"\);',
    r'grad.addColorStop(0, Services.Theme.isDark ? "#10ffffff" : "#10000000");',
    content
)
content = re.sub(
    r'grad\.addColorStop\(1,\s*"#30ffffff"\);',
    r'grad.addColorStop(1, Services.Theme.isDark ? "#30ffffff" : "#30000000");',
    content
)

content = re.sub(
    r'color:\s*pop\.selectedIndex === -1 \? \(pop\.isEditing \? "#90ff3333" : "#60ffffff"\) : "transparent"',
    r'color: pop.selectedIndex === -1 ? (pop.isEditing ? "#90ff3333" : (Services.Theme.isDark ? "#60ffffff" : "#20000000")) : "transparent"',
    content
)
content = re.sub(
    r'border\.color:\s*pop\.isEditing \? "#ff3333" : "#80ffffff"',
    r'border.color: pop.isEditing ? "#ff3333" : (Services.Theme.isDark ? "#80ffffff" : "#80000000")',
    content
)

content = re.sub(
    r'color:\s*pop\.selectedIndex === index \? "#000000" : "#ffffff"',
    r'color: pop.selectedIndex === index ? (Services.Theme.isDark ? "#000000" : "#ffffff") : Services.Theme.text',
    content
)

with open('/home/nick/.config/quickshell/modules/ShortcutWheel.qml', 'w') as f:
    f.write(content)
