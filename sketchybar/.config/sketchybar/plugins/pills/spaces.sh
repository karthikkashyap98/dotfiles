#!/usr/bin/env zsh
# Mocha Pills workspaces: shows occupied AeroSpace workspaces (and the focused one) as numbers.
# The focused one is the single filled (mauve) pill; the fill fades across, and the new one bounces.
# Hidden controller item; the number items are pills.ws.<name>. The last focused workspace is kept
# in this item's label (no disk state).
source "$CONFIG_DIR/plugins/pills/lib.sh"

FOCUSED="${FOCUSED_WORKSPACE:-$(aerospace list-workspaces --focused 2>/dev/null)}"
[[ "$FOCUSED" =~ '^[A-Za-z0-9-]+$' ]] || FOCUSED=""
OCCUPIED=(${(f)"$(aerospace list-workspaces --monitor all --empty no 2>/dev/null)"})
PREV="$(sketchybar --query "$NAME" 2>/dev/null | jq -r '.label.value // ""')"

MAUVE_CLEAR="$(clear_of $MAUVE)"
args=()
for ws in ${(f)"$(aerospace list-workspaces --all 2>/dev/null)"}; do
  [[ "$ws" =~ '^[A-Za-z0-9-]+$' ]] || continue
  item="pills.ws.$ws"
  if [[ "$ws" == "$FOCUSED" ]]; then
    args+=(--set "$item" drawing=on background.color=$MAUVE icon.color=$CRUST)
  elif (( ${OCCUPIED[(Ie)$ws]} )); then
    args+=(--set "$item" drawing=on background.color=$MAUVE_CLEAR icon.color=$PILL_MUTED)
  else
    args+=(--set "$item" drawing=off background.color=$MAUVE_CLEAR)
  fi
done

(( ${#args} )) && sketchybar --animate tanh 12 "${args[@]}"

if [[ -n "$FOCUSED" && "$FOCUSED" != "$PREV" ]]; then
  sketchybar --set "$NAME" label="$FOCUSED" \
    --animate sin 14 --set "pills.ws.$FOCUSED" icon.y_offset=4 icon.y_offset=0
fi
