# Quickshell Config for Hyprland

A highly customized and animated desktop shell environment built with Quickshell for Hyprland.

## Features

- **Shortcut Wheel**: A beautifully animated, radial "hold-to-open" app launcher.
  - **Zero-Click Edit Mode**: Hold the shortcut key, hover the center ring for 1 second, and simply release on an app slot to hot-swap it.
  - Native support for dynamic app replacement via an intuitive search menu.
  - Monochrome emoji support for clean typography-based icons.
  - Silky smooth scale-up hover animations with HD mipmapping.
- **App Launcher**: A centered, fast search overlay for launching applications.
- **Notification Center**: Drop-down panel showcasing recent notifications via Dunst, featuring an unread badge indicator, sound jingles, and smooth fade-in animations.
- **Control Panel**: Quick access to network, bluetooth, audio, and quick scripts.
- **Top Bar**: A clean, minimalistic status bar displaying workspaces, active window, and system tray.

## Requirements

- Quickshell
- Hyprland
- `python3` (for app parsing scripts)
- `dunst` (for notifications)
- `paplay` (for audio jingles)

## Installation

1. Clone this repository into your config directory:
   ```bash
   git clone https://github.com/yourusername/quickshell-config ~/.config/quickshell
   ```

2. Add the following to your `hyprland.conf`:
   ```conf
   # Launch Quickshell
   exec-once = quickshell

   # Bind Shortcut Wheel (Hold to open)
   bind = SUPER, Tab, exec, sh -c 'touch /tmp/qs_wheel_holding; sleep 0.15; if [ -f /tmp/qs_wheel_holding ]; then touch /tmp/qs_wheel_open; fi'
   bindrt = SUPER, Tab, exec, rm -f /tmp/qs_wheel_holding /tmp/qs_wheel_open
   ```

3. Reload Quickshell.

## Must Read / Configuration Guide

To get the most out of your new setup, here is how everything works and how you can customize it:

### ⚙️ Shortcut Wheel
The Shortcut Wheel has a hidden **Zero-Click Edit Mode**. To swap an app:
1. Open the wheel (hold `SUPER + Tab`).
2. Keep your mouse resting perfectly in the center ring (on the `+` icon) for **1 second**.
3. The `+` will morph into an `X`, and the ring will change style to indicate you are in Edit Mode.
4. Move your mouse to the app slot you want to replace and release `SUPER + Tab`. The App Launcher will pop up so you can search and assign a new app!

### 🖼️ Wallpaper
The Date/Time panel displays your current wallpaper. To change it, simply edit the `assets/wallpaper_path.txt` file and paste the absolute path to your wallpaper image.

### 🔔 Notifications
The notification center hooks directly into `dunst`. When you receive a notification, a counter badge will automatically appear. The drop-down panel will let you review your recent notification history.

### 🔋 Battery & System
The top bar is fully plug-and-play. It will automatically detect your battery status (if you are on a laptop), your current active window title, and your system tray apps.

### 🎵 Custom Sounds
The wheel uses custom audio jingles for opening and selecting apps. If you want to change them, simply replace `assets/wheel_open.mp3` and `assets/wheel_select.mp3` with your own audio files!

## Note on App Icons
The app launcher and shortcut wheel dynamically scan your `.desktop` files. Emojis and text-based symbols (like `♫`) are fully supported and will automatically adapt to your theme's typography and color settings!
