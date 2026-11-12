#!/usr/bin/env zsh
# Ops Deck workspaces: show occupied workspaces (plus the focused one), underline the focused one.
source "$CONFIG_DIR/colors.sh"

FOCUSED="${FOCUSED_WORKSPACE:-$(aerospace list-workspaces --focused 2>/dev/null)}"
OCCUPIED=(${(f)"$(aerospace list-workspaces --monitor all --empty no 2>/dev/null)"})

args=()
for ws in ${(f)"$(aerospace list-workspaces --all 2>/dev/null)"}; do
  [[ "$ws" =~ '^[A-Za-z0-9-]+$' ]] || continue
  if [[ "$ws" == "$FOCUSED" ]]; then
    args+=(--set "ws.$ws" drawing=on icon.color=$TEXT background.drawing=on
           background.color=0x1f89b4fa background.height=32 background.corner_radius=0
           icon.background.color=$BLUE)
  elif (( ${OCCUPIED[(Ie)$ws]} )); then
    args+=(--set "ws.$ws" drawing=on icon.color=$SUBTEXT0 background.drawing=off
           icon.background.color=$TRANSPARENT)
  else
    args+=(--set "ws.$ws" drawing=off)
  fi
done

(( ${#args} )) && sketchybar --animate tanh 10 "${args[@]}"
