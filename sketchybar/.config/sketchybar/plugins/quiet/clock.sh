#!/usr/bin/env zsh
# Quiet Text: "wed 11 · 17:51". The date and time are two items so the · can be dim.
source "$CONFIG_DIR/plugins/quiet/lib.sh"
sketchybar --set q.date label="${(L)$(date '+%a %-d')}" --set "$NAME" label="$(date '+%H:%M')"
