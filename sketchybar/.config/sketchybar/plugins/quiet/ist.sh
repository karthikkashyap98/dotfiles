#!/usr/bin/env zsh
# Quiet Text: teammates' clock, "ist HH:MM"; dimmer outside 09:00-19:00 IST.
source "$CONFIG_DIR/plugins/quiet/lib.sh"
H=$(TZ=Asia/Kolkata date +%-H)
if (( H >= 9 && H < 19 )); then C=$Q_TEXT; else C=$Q_FAINT; fi
sketchybar --set "$NAME" label="ist $(TZ=Asia/Kolkata date +%H:%M)" label.color=$C
