#!/usr/bin/env zsh
# Glyph Rail WARP: a red shield, only while WARP is disconnected. Click reconnects.
# Hover shows "WARP off · click".
source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/plugins/glyph/reveal.sh"
glyph_hover "$RED" && exit 0

warp_connected() {
  command -v warp-cli >/dev/null || return 0   # no WARP installed: nothing to warn about
  warp-cli status 2>/dev/null | grep -q 'Status update: Connected'
}

if [[ "$SENDER" == "mouse.clicked" ]]; then
  warp_connected || warp-cli connect >/dev/null 2>&1
  sleep 2
fi

if warp_connected; then
  sketchybar --set "$NAME" drawing=off label.drawing=off label.width=0
else
  WAS="$(sketchybar --query "$NAME" 2>/dev/null | jq -r '.geometry.drawing // "off"')"
  sketchybar --set "$NAME" drawing=on icon=$'' label="WARP off · click"
  [[ "$WAS" == "on" ]] || sketchybar --animate sin 30 --set "$NAME" icon.color=$TEXT icon.color=$RED
fi
