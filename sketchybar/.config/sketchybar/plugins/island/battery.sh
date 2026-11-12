#!/usr/bin/env zsh
# Battery percentage, always shown in the left ear (next to the notch).
# Muted normally, yellow below 40%, red below 20%, green bolt while charging.
source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/plugins/island/guard.sh"   # exits if this copy is parked (layout.sh)

BATT="$(pmset -g batt 2>/dev/null)"
PCT="$(grep -Eo '[0-9]+%' <<<"$BATT" | head -1 | tr -d '%')"
[[ "$PCT" =~ '^[0-9]+$' ]] || { sketchybar --set "$NAME" drawing=off; exit 0; }   # no battery (desktop)

if   (( PCT >= 80 )); then ICON=$''
elif (( PCT >= 60 )); then ICON=$''
elif (( PCT >= 40 )); then ICON=$''
elif (( PCT >= 20 )); then ICON=$''
else                       ICON=$''
fi

ICON_COLOR=$SUBTEXT0 LABEL_COLOR=$SUBTEXT0
if   (( PCT < 20 )); then ICON_COLOR=$RED LABEL_COLOR=$RED
elif (( PCT < 40 )); then ICON_COLOR=$YELLOW
fi

if grep -q "AC Power" <<<"$BATT"; then
  ICON=$'\U000f0084'   # battery charging
  ICON_COLOR=$GREEN
fi

sketchybar --set "$NAME" drawing=on icon="$ICON" label="${PCT}%" \
  --animate tanh 10 --set "$NAME" icon.color=$ICON_COLOR label.color=$LABEL_COLOR
