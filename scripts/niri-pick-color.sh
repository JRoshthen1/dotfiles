#!/usr/bin/env bash

# Run the pick-color command and capture its full output
output=$(niri msg pick-color)

# Check if the command was successful and we got output
if [ -n "$output" ]; then
  # Extract the hex code (looks like #XXXXXX or #XXXXXXXX)
  # The output format shown: "Picked color: rgb(40, 40, 40)\nHex: #282828"
  hex_code=$(echo "$output" | grep -o '#[0-9A-Fa-f]\{6,8\}')

  # If hex code was found, copy it to the clipboard
  if [ -n "$hex_code" ]; then
    echo -n "$hex_code" | wl-copy

    # Send a notification with the full output
    notify-send "$output"
  else
    notify-send "Color Picker Error" "Could not find hex code in output:\n$output"
  fi
else
  notify-send "Color Picker Error" "Failed to pick a color. Did you click on a valid surface?"
fi
