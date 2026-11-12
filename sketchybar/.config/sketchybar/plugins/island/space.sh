#!/usr/bin/env zsh
# Focused AeroSpace workspace, with a small bounce when it changes.
# $FOCUSED_WORKSPACE comes from exec-on-workspace-change in aerospace.toml.
source "$CONFIG_DIR/colors.sh"

WS="${FOCUSED_WORKSPACE:-$(aerospace list-workspaces --focused 2>/dev/null)}"
[[ -n "$WS" ]] || exit 0

case "$WS" in
  1) ICON="󰅶" ;;   # kept from the classic theme
  *) ICON="$WS" ;;
esac

CURRENT="$(sketchybar --query "$NAME" 2>/dev/null | jq -r '.icon.value // empty')"
[[ "$CURRENT" == "$ICON" ]] && exit 0

sketchybar --set "$NAME" icon="$ICON" \
  --animate sin 14 --set "$NAME" icon.y_offset=5 icon.y_offset=0
