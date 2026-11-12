#!/usr/bin/env zsh
# Quiet Text: focused AeroSpace workspace (mauve, bold), with a small bounce when it changes.
# $FOCUSED_WORKSPACE comes from exec-on-workspace-change in aerospace.toml.
source "$CONFIG_DIR/plugins/quiet/lib.sh"

WS="${FOCUSED_WORKSPACE:-$(aerospace list-workspaces --focused 2>/dev/null)}"
[[ "$WS" =~ '^[A-Za-z0-9-]+$' ]] || exit 0
WS="${(L)WS}"

CURRENT="$(sketchybar --query "$NAME" 2>/dev/null | jq -r '.label.value // empty')"
[[ "$CURRENT" == "$WS" ]] && exit 0

sketchybar --set "$NAME" label="$WS" \
  --animate sin 14 --set "$NAME" label.y_offset=3 label.y_offset=0
