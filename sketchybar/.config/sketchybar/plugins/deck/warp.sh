#!/usr/bin/env zsh
# Ops Deck WARP segment: hidden while connected; "WARP off" in red otherwise. Click to reconnect.
source "$CONFIG_DIR/colors.sh"

warp_connected() {
  command -v warp-cli >/dev/null || return 0
  warp-cli status 2>/dev/null | grep -q 'Status update: Connected'
}

if [[ "$SENDER" == "mouse.clicked" ]]; then
  warp_connected || warp-cli connect >/dev/null 2>&1
  sleep 2
fi

if warp_connected; then
  sketchybar --set "$NAME" drawing=off
else
  sketchybar --set "$NAME" drawing=on \
    --animate sin 30 --set "$NAME" label.color=$TEXT label.color=$RED
fi
