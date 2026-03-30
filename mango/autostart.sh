#!/bin/bash
# ── MangoWM autostart ────────────────────────────────────────
# ~/.config/mango/autostart.sh

/usr/lib/xdg-desktop-portal-wlr  >/dev/null 2>&1 &

# Clipboard management
wl-clip-persist --clipboard regular --reconnect-tries 0 &
wl-paste --type text --watch cliphist store &
wl-paste --type image --watch cliphist store &

days_notify.sh &

# Color temperature
wlsunset -t 5000 -T 7000 -l 49.2 -L 20.3 -g 0.8 >/dev/null 2>&1 &


# Idle management: lock after 5 min
swayidle -w timeout 300 'waylock' & >/dev/null 2>&1 &

# Status bar
waybar -c ~/.config/mango/waybar.jsonc -s ~/.config/mango/waybar.css >/dev/null 2>&1 &

# Wallpaper
swaybg -i ~/Pictures/5m5kLI9.png -m fill &

mako &
