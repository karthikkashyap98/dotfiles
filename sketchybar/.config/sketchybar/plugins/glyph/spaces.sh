#!/usr/bin/env zsh
# Glyph Rail workspaces: occupied workspaces are small grey dots; the focused one stretches
# into a mauve dash. Each dot is an item (glyph.ws.<n>) whose icon background is the dot.
source "$CONFIG_DIR/colors.sh"

DOT=6 DASH=16
FOCUSED="${FOCUSED_WORKSPACE:-$(aerospace list-workspaces --focused 2>/dev/null)}"
OCCUPIED=(${(f)"$(aerospace list-workspaces --monitor all --empty no 2>/dev/null)"})

args=()
for ws in ${(f)"$(aerospace list-workspaces --all 2>/dev/null)"}; do
  [[ "$ws" =~ '^[A-Za-z0-9-]+$' ]] || continue
  item="glyph.ws.$ws"
  if [[ "$ws" == "$FOCUSED" ]]; then
    args+=(--set "$item" drawing=on icon.width=$DASH icon.background.color=$MAUVE)
  elif (( ${OCCUPIED[(Ie)$ws]} )); then
    args+=(--set "$item" drawing=on icon.width=$DOT icon.background.color=$OVERLAY0)
  else
    args+=(--set "$item" drawing=off icon.width=$DOT)
  fi
done

(( ${#args} )) && sketchybar --animate tanh 12 "${args[@]}"
