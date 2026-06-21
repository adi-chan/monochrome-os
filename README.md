# quickshell config

my personal quickshell setup for hyprland. it's clean, minimal, and heavily customized to fit my workflow. it replaces the standard waybar and rofi setup with something much more cohesive.

## features

* **right panel:** a unified control center holding everything important. handles network, bluetooth, volume, brightness, and system stats (cpu/ram).
* **dynamic app launcher:** opens instantly with `win + r`. it automatically scans the system and flatpak directories in the background every time it's opened to keep the app list perfectly synced.
* **media player:** integrated directly into the panel. features a slick bouncing equalizer animation inside the play button that only shows up when music is actually playing.
* **battery animation:** features a smooth, liquid-like filling animation while charging. 
* **date & time panel:** clean layout for tracking time without cluttering the main bar.
* **no weather clutter:** removed the weather module because i simply don't use it.

## showcase

here are some previews of how it looks and feels in action.

### the bar
![the bar](showcase/bar_showcase.mp4)

### right panel & media player
![right panel](showcase/rightpanel_showcase.mp4)

### date and time
![date and time](showcase/datetime_showcase.mp4)

## requirements

* hyprland
* quickshell
* playerctl (for media player)
* python3 (for the app launcher syncing script)
* nerd fonts (for icons)

## installation

clone this into your config folder:
```bash
git clone git@github.com:YourUsername/quickshell-config.git ~/.config/quickshell
```

reload quickshell and you're good to go.
