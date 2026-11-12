#!/usr/bin/env zsh
# Mocha Pills clock: "Wed 11 Nov 17:51". Click for a popup with the full date and IST time.
source "$CONFIG_DIR/plugins/pills/lib.sh"

case "$SENDER" in
  mouse.exited.global) sketchybar --set "$NAME" popup.drawing=off; exit 0 ;;
  mouse.clicked)       sketchybar --set "$NAME" popup.drawing=toggle ;;
esac

sketchybar --set "$NAME" label="$(date '+%a %-d %b %H:%M')" \
  --set pills.clock.date label="$(date '+%A, %-d %B %Y')" \
  --set pills.clock.ist  label="IST $(TZ=Asia/Kolkata date '+%H:%M · %a %-d %b')"
