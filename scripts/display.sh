#!/bin/bash
input=$(printf "󰍹  Primary only\n󰍺  Secondary only\n󰍺 󰍹  Extend" | fuzzel --config /home/jrosh/.config/fuzzel/generic.ini --dmenu)

output_1="eDP-1"
output_2="HDMI-A-1"

case "$input" in
"󰍹  Primary only")
  niri msg output $output_2 off
  niri msg output $output_1 on
  ;;
"󰍺  Secondary only")
  niri msg output $output_1 off
  niri msg output $output_2 on
  ;;
"󰍺 󰍹  Extend")
  echo 'extended'
  niri msg output $output_1 on
  niri msg output $output_2 on
  ;;
esac
