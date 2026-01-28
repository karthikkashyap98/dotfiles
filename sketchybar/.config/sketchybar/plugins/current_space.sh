#!/usr/bin/env zsh

# $FOCUSED_WORKSPACE is injected by the trigger in aerospace.toml
WS="${FOCUSED_WORKSPACE:-$(aerospace list-workspaces --monitor focused --focused)}"

# Map certain workspaces to icons, else show the number
case "$WS" in
  1)
    ICON="󰅶"; L=7; R=7;;
  *)
    ICON="$WS"; L=9; R=10;;
esac

sketchybar --set "$NAME" \
  icon="$ICON" \
  icon.padding_left="$L" \
  icon.padding_right="$R"

