import os
import json
import configparser

def get_apps():
    apps = []
    dirs = ['/usr/share/applications', os.path.expanduser('~/.local/share/applications'), '/var/lib/flatpak/exports/share/applications']
    for d in dirs:
        if not os.path.exists(d):
            continue
        for root, _, files in os.walk(d):
            for file in files:
                if file.endswith('.desktop'):
                    path = os.path.join(root, file)
                    config = configparser.ConfigParser(interpolation=None)
                    try:
                        # Some desktop files have duplicate keys or missing sections, ignore errors
                        with open(path, 'r', encoding='utf-8') as f:
                            config.read_string('[Desktop Entry]\n' + f.read().split('[Desktop Entry]')[1])
                        
                        if 'Desktop Entry' in config:
                            entry = config['Desktop Entry']
                            if entry.get('NoDisplay', 'false').lower() == 'true':
                                continue
                            if entry.get('Type', '') != 'Application':
                                continue
                            
                            categories = entry.get('Categories', '')
                            if any(x in categories for x in ['Settings', 'System', 'Utility', 'ConsoleOnly']):
                                # Allow some exceptions if needed, but filter out most junk
                                if 'System' in categories and 'Emulator' not in categories and 'FileManager' not in categories:
                                    continue
                                if 'Utility' in categories and 'TextEditor' not in categories and 'Archiving' not in categories:
                                    continue
                                if 'Settings' in categories:
                                    continue

                            name = entry.get('Name', '')
                            if not name or 'Avahi' in name or 'Hardware Locality' in name:
                                continue
                            exec_cmd = entry.get('Exec', '').split('%')[0].strip()
                            if not exec_cmd:
                                continue
                            icon = entry.get('Icon', '')
                            desc = entry.get('Comment', '')
                            apps.append({
                                'name': name,
                                'exec': exec_cmd,
                                'icon': icon,
                                'desc': desc
                            })
                    except Exception:
                        pass
    return apps

if __name__ == '__main__':
    apps = get_apps()
    # deduplicate by name
    unique = {}
    for app in apps:
        if app['name'] not in unique:
            unique[app['name']] = app
    apps_list = sorted(list(unique.values()), key=lambda x: x['name'].lower())
    os.makedirs(os.path.expanduser('~/.config/quickshell/assets'), exist_ok=True)
    with open(os.path.expanduser('~/.config/quickshell/assets/apps.json'), 'w') as f:
        json.dump(apps_list, f)
