#!/usr/bin/env zsh
# Mocha Pills IST pill: teammates' time. Bright 09:00–19:00 IST, dim outside it.
source "$CONFIG_DIR/plugins/pills/lib.sh"
H=$(TZ=Asia/Kolkata date +%-H)
if (( H >= 9 && H < 19 )); then IC=$LAVENDER LC=$TEXT; else IC=$OVERLAY0 LC=$OVERLAY1; fi
sketchybar --set "$NAME" label="IST $(TZ=Asia/Kolkata date +%H:%M)" \
  --animate tanh 10 --set "$NAME" icon.color=$IC label.color=$LC
