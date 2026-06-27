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

## Note on App Icons
The app launcher and shortcut wheel dynamically scan your `.desktop` files. Emojis and text-based symbols (like `♫`) are fully supported and will automatically adapt to your theme's typography and color settings!
