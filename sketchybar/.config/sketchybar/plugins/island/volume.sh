#!/usr/bin/env zsh
# Volume: fades in for 2 seconds after you change it, then hides again.
source "$CONFIG_DIR/colors.sh"

[[ "$SENDER" == "volume_change" ]] || exit 0
VOL="$INFO"
[[ "$VOL" =~ '^[0-9]+$' ]] || exit 0

if   (( VOL == 0 )); then ICON=$''
elif (( VOL < 40 )); then ICON=$''
else                      ICON=$''
fi

# Only the newest change may hide the item, so rapid key presses keep it on screen.
TOKEN="${TMPDIR:-$(getconf DARWIN_USER_TEMP_DIR)}/sketchybar-island-volume"
print -r -- "$$" >| "$TOKEN"

sketchybar --set "$NAME" drawing=on icon="$ICON" label="${VOL}%" \
  --animate tanh 8 --set "$NAME" icon.color=$SUBTEXT0 label.color=$SUBTEXT0

{
  sleep 2
  [[ "$(<"$TOKEN")" == "$$" ]] || exit 0
  sketchybar --animate tanh 12 --set "$NAME" icon.color=0x00a6adc8 label.color=0x00a6adc8
  sleep 0.25
  [[ "$(<"$TOKEN")" == "$$" ]] && sketchybar --set "$NAME" drawing=off
} &!
