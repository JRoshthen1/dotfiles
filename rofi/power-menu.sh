#!/usr/bin/env bash

# System info
uptime="$(uptime -p | sed -e 's/up //g')"

# Icons (Nerd Font) with Pango markup — large icon, small label
shutdown='<span size="xx-large">󰐥</span>  <span size="x-small">Shutdown</span>'
reboot='<span size="xx-large">󰜉</span>  <span size="x-small">Reboot</span>'
lock='<span size="xx-large"></span>  <span size="x-small">Lock</span>'
suspend='<span size="xx-large">󰒲</span>  <span size="x-small">Suspend</span>'
hibernate='<span size="xx-large">󰤄</span>  <span size="x-small">Hibernate</span>'
logout='<span size="xx-large">󰍃</span>  <span size="x-small">Logout</span>'

# Rofi menus
rofi_cmd() {
  rofi -dmenu \
    -format i \
    -markup-rows \
    -p "Goodbye ${USER}" \
    -mesg "Uptime: $uptime" \
    -theme ~/.config/rofi/powermenu.rasi
}

confirm_cmd() {
  rofi -dmenu \
    -p 'Confirmation' \
    -mesg 'Are you Sure?' \
    -theme ~/.config/rofi/confirm.rasi
}

# Show confirmation dialog
confirm_exit() {
  echo -e "$yes\n$no" | confirm_cmd
}

# Show power menu (order must match the case index below)
run_rofi() {
  echo -e "$shutdown\n$reboot\n$lock\n$suspend\n$hibernate\n$logout" | rofi_cmd
}

# Detect running compositor and execute the correct logout command
perform_logout() {
  if pgrep -x Hyprland >/dev/null; then
    hyprctl dispatch exit
  elif pgrep -x niri >/dev/null; then
    niri msg action quit --skip-confirmation
  elif pgrep -x mangowm >/dev/null; then
    mangowm-msg exit
  else
    loginctl terminate-session "$XDG_SESSION_ID"
  fi
}

# Execute the chosen action
run_cmd() {
  selected="$(confirm_exit)"
  if [[ "$selected" == "$yes" ]]; then
    case "$1" in
    --shutdown) systemctl poweroff ;;
    --reboot) systemctl reboot ;;
    --suspend) systemctl suspend ;;
    --hibernate) systemctl hibernate ;;
    --logout) perform_logout ;;
    esac
  else
    exit 0
  fi
}

yes=''
no=''

# Main — match by index (ordered as in run_rofi above)
chosen="$(run_rofi)"
case ${chosen} in
0) run_cmd --shutdown ;;
1) run_cmd --reboot ;;
2) /home/jrosh/.config/waylock/waylock ;;
3) run_cmd --suspend ;;
4) run_cmd --hibernate ;;
5) run_cmd --logout ;;
esac
