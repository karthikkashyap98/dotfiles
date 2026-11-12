#!/usr/bin/env zsh
# Glyph Rail IST: sun (09:00–19:00 IST) or moon, muted off-hours. Hover shows "IST 22:10 · off hours".
source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/plugins/glyph/reveal.sh"
glyph_hover "$TEXT" && exit 0

H=$(TZ=Asia/Kolkata date +%-H)
T="$(TZ=Asia/Kolkata date +%H:%M)"
if (( H >= 9 && H < 19 )); then
  sketchybar --set "$NAME" icon=$'' icon.color=$SUBTEXT0 label="IST $T · work hours"
else
  sketchybar --set "$NAME" icon=$'' icon.color=$OVERLAY0 label="IST $T · off hours"
fi
glyph_refit
