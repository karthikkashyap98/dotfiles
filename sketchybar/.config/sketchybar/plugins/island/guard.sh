#!/usr/bin/env zsh
# Sourced by the ear/center scripts. layout.sh writes the names of "parked" items (the set
# that has no display to live on right now) to this file; a parked item's script exits early
# so it can't switch itself back on (battery.sh and warp.sh set drawing=on).
# No file, or $NAME not listed: the script runs exactly as before.
ISLAND_PARKED="${TMPDIR:-$(getconf DARWIN_USER_TEMP_DIR)}/sketchybar-island-parked"
[[ -r "$ISLAND_PARKED" ]] && grep -qxF -- "$NAME" "$ISLAND_PARKED" && exit 0
