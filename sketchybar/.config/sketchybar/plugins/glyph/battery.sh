#!/usr/bin/env zsh
# Glyph Rail battery: glyph + percentage, always shown. Muted, yellow < 40%, red < 20%.
# Charging: bolt glyph (the color still follows the level).
source "$CONFIG_DIR/colors.sh"

BATT="$(pmset -g batt 2>/dev/null)"
PCT="$(grep -Eo '[0-9]+%' <<<"$BATT" | head -1 | tr -d '%')"
[[ "$PCT" =~ '^[0-9]+$' ]] || { sketchybar --set "$NAME" drawing=off; exit 0; }   # no battery

if   (( PCT >= 80 )); then ICON=$''
elif (( PCT >= 60 )); then ICON=$''
elif (( PCT >= 40 )); then ICON=$''
elif (( PCT >= 20 )); then ICON=$''
else                       ICON=$''
fi
grep -q "AC Power" <<<"$BATT" && ICON=$'\U000f0084'

C=$SUBTEXT0
if   (( PCT < 20 )); then C=$RED
elif (( PCT < 40 )); then C=$YELLOW
fi

sketchybar --set "$NAME" drawing=on icon="$ICON" label="${PCT}%" \
  --animate tanh 10 --set "$NAME" icon.color=$C label.color=$C
