#!/usr/bin/env zsh
# Left ear, WARP segment: only visible while WARP is not connected ("warp off").
# Drops out of the notch next to the battery; slides back in once WARP reconnects.
# Click it to run `warp-cli connect`.
source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/plugins/island/guard.sh"   # exits if this copy is parked (layout.sh)

HIDDEN_OFFSET=34   # far enough to sit fully outside the 32px bar

warp_connected() {
  command -v warp-cli >/dev/null || return 0   # no WARP installed: nothing to warn about
  warp-cli status 2>/dev/null | grep -q 'Status update: Connected'
}

if [[ "$SENDER" == "mouse.clicked" ]]; then
  warp_connected || warp-cli connect >/dev/null 2>&1
  sleep 2   # give WARP a moment, then fall through to refresh the ear
fi

alerts=()
icon=""

if ! warp_connected; then
  alerts+=("warp off")
  icon=$''   # shield
fi

VISIBLE="$(sketchybar --query "$NAME" 2>/dev/null | jq -r '.geometry.drawing // "off"')"

if (( ${#alerts} )); then
  label="${(j: · :)alerts}"
  if [[ "$VISIBLE" != "on" ]]; then
    sketchybar --set "$NAME" icon="$icon" label="$label" y_offset=$HIDDEN_OFFSET drawing=on \
      --animate tanh 18 --set "$NAME" y_offset=0
  else
    sketchybar --set "$NAME" icon="$icon" label="$label"
  fi
elif [[ "$VISIBLE" == "on" ]]; then
  sketchybar --animate tanh 14 --set "$NAME" y_offset=$HIDDEN_OFFSET
  sleep 0.3
  sketchybar --set "$NAME" drawing=off y_offset=0
fi
