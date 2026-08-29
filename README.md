# 🖤 Monochrome OS

A highly customized, animated desktop shell environment built with **Quickshell** for **Hyprland**.

[![Repo](https://img.shields.io/badge/GitHub-monochrome--os-black?logo=github)](https://github.com/adi-chan/monochrome-os)

---

## 🚀 Quick One-Line Automated Installation

If you are on **Arch Linux**, clone the repository and run the automated installer script:

```bash
git clone https://github.com/adi-chan/monochrome-os.git ~/.config/quickshell
cd ~/.config/quickshell
./install.sh
```

---

## 🛠️ Requirements & Manual Installation

### System Dependencies

- **Quickshell** (`quickshell-git` from AUR)
- **Hyprland**
- `python3` (for desktop application parsing scripts)
- `dunst` (for notifications)
- `pw-play` (for audio jingles)
- `mpd` & `mpc` (for music player & queue management)
- `cava` (audio visualizer)
- `ttf-jetbrains-mono-nerd` (font icons & typography)

### Manual Setup

1. **Clone repository**:
   ```bash
   mkdir -p ~/.config
   git clone https://github.com/adi-chan/monochrome-os.git ~/.config/quickshell
   ```

2. **Setup Music Presence (Discord Rich Presence)**:
   ```bash
   mkdir -p ~/tools
   curl -L -o ~/tools/musicpresence-2.3.6-linux-x86_64.AppImage \
       https://github.com/ungit/music-presence/releases/download/v2.3.6/musicpresence-2.3.6-linux-x86_64.AppImage
   chmod +x ~/tools/musicpresence-2.3.6-linux-x86_64.AppImage
   ```

3. **Enable Services & System Fonts**:
   ```bash
   systemctl --user enable --now mpd
   gsettings set org.gnome.desktop.interface font-name 'JetBrains Mono 11'
   ```

4. **Add Hyprland Keybinds (`hyprland.conf`)**:
   ```conf
   # Auto-start Quickshell
   exec-once = quickshell

   # Bind Shortcut Wheel (Hold to open)
   bind = SUPER, Tab, exec, sh -c 'touch /tmp/qs_wheel_holding; sleep 0.15; if [ -f /tmp/qs_wheel_holding ]; then touch /tmp/qs_wheel_open; fi'
   bindrt = SUPER, Tab, exec, rm -f /tmp/qs_wheel_holding /tmp/qs_wheel_open
   ```

---

## ✨ Features & Capabilities

- **Shortcut Wheel**: A beautifully animated, radial "hold-to-open" app launcher (`SUPER + Tab`).
  - **Zero-Click Edit Mode**: Hold the shortcut key, hover the center ring (`+` icon) for **1 second**, and release on any app slot to hot-swap it.
  - Native support for dynamic app replacement via an intuitive search menu.
  - Monochrome emoji & Nerd Font symbol support.
  - Silky smooth scale-up hover animations with HD mipmapping.
- **App Launcher**: A centered, fast search overlay for searching and launching installed desktop applications.
- **Media Dashboard & Queue Popup**:
  - Full MPD integration with real-time track info, progress seeking, and visualizer.
  - Balanced playback controls with `mpc` shuffle and loop mode toggle.
  - Dedicated floating **Queue & Library Popup (`MediaQueuePopup.qml`)** for browsing playlists and upcoming songs in a tall view.
  - Native **Discord Music Presence Toggle Button (`󰙯`)** right next to the player switcher to start/stop Discord Rich Presence.
- **Notification Center**: Drop-down panel showcasing recent notifications via `dunst`, featuring an unread badge indicator, sound jingles, and smooth fade-in animations.
- **Control Panel**: Quick access to network, bluetooth, audio profiles, power modes, and quick scripts.
- **Top Bar**: A clean, minimalistic status bar displaying workspaces, active window title, battery status (laptop auto-detect), and system tray.

---

## 📖 Must Read / Configuration Guide

To get the most out of your setup, here is how everything works and how you can customize it:

### ⚙️ Shortcut Wheel & Zero-Click Edit Mode
To swap an application slot on the wheel:
1. Open the wheel (hold `SUPER + Tab`).
2. Keep your mouse resting in the center ring (on the `+` icon) for **1 second**.
3. The `+` will morph into an `X`, and the ring color will change to indicate **Edit Mode**.
4. Move your mouse to the app slot you want to replace and release `SUPER + Tab`. The App Launcher will pop up so you can search and assign any new app!

### 🎵 Custom Sounds
The wheel and notifications use custom audio jingles. To replace them with your own audio files, swap:
- `assets/wheel_open.mp3`
- `assets/wheel_select.mp3`

### 🖼️ Wallpaper
The Date/Time panel displays your current wallpaper. To change it, edit `assets/wallpaper_path.txt` and paste the absolute path to your wallpaper image.

### 🔔 Notifications
The notification center hooks directly into `dunst`. When you receive a notification, a counter badge will automatically appear. Click the bell to open the history drop-down.

### 🔋 Battery & System
The top bar is fully plug-and-play. It automatically detects battery status, active window titles, and system tray applications.

### 🎨 Note on App Icons
The app launcher and shortcut wheel dynamically scan your system `.desktop` files. Emojis and text-based symbols (like `♫`) are fully supported and automatically adapt to your theme's typography and color settings.
