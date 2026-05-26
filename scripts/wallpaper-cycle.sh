#!/usr/bin/env bash

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
STATE_FILE="/tmp/wallpaper_index"

# Build sorted array of images
mapfile -t WALLS < <(find "$WALLPAPER_DIR" -maxdepth 1 -type f \
  \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" \) | sort)

COUNT=${#WALLS[@]}
[[ $COUNT -eq 0 ]] && exit 1

# Read current index, default to 0
INDEX=$(cat "$STATE_FILE" 2>/dev/null || echo 0)

# Advance to next
INDEX=$(((INDEX + 1) % COUNT))
echo "$INDEX" >"$STATE_FILE"

# Kill existing swaybg and launch new one
pkill swaybg
swaybg -i "${WALLS[$INDEX]}" &
