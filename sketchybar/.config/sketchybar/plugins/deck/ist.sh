#!/usr/bin/env zsh
# Ops Deck IST segment: teammates' time; bright during 09:00–19:00 IST, muted outside it.
source "$CONFIG_DIR/colors.sh"
H=$(TZ=Asia/Kolkata date +%-H)
if (( H >= 9 && H < 19 )); then C=$TEXT; else C=$OVERLAY1; fi
sketchybar --set "$NAME" label="$(TZ=Asia/Kolkata date +%H:%M)" label.color=$C
