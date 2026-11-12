#!/usr/bin/env zsh
# Quiet Text: "vol 45%" for 2 s after a change, then fades out. Not an alert (never folded).
source "$CONFIG_DIR/plugins/quiet/lib.sh"

[[ "$SENDER" == "volume_change" ]] || exit 0
VOL="$INFO"
[[ "$VOL" =~ '^[0-9]+$' ]] || exit 0

# Only the newest change may hide the item, so rapid key presses keep it on screen.
TOKEN="$Q_STATE/vol.token"
print -r -- "$$" >| "$TOKEN"

T=$(q_transparent $Q_TEXT) TD=$(q_transparent $Q_DIM)
if [[ "$(sketchybar --query "$NAME" 2>/dev/null | jq -r '.geometry.drawing // "off"')" == "on" ]]; then
  sketchybar --set "$NAME" label="vol ${VOL}%" label.color=$Q_TEXT
else
  sketchybar --set "$NAME" drawing=on label="vol ${VOL}%" label.color=$T \
             --set q.vol.sep drawing=on label.color=$TD \
    --animate tanh 12 --set "$NAME" label.color=$Q_TEXT --set q.vol.sep label.color=$Q_DIM
fi

{
  sleep 2
  [[ "$(<"$TOKEN")" == "$$" ]] || exit 0
  sketchybar --animate tanh 12 --set "$NAME" label.color=$T --set q.vol.sep label.color=$TD
  sleep 0.25
  [[ "$(<"$TOKEN")" == "$$" ]] && sketchybar --set "$NAME" drawing=off --set q.vol.sep drawing=off
} &!
