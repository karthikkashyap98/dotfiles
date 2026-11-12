#!/usr/bin/env zsh
# Quiet Text: "warp off" (red) while Cloudflare WARP isn't connected. Click to reconnect.
source "$CONFIG_DIR/plugins/quiet/lib.sh"

warp_connected() {
  command -v warp-cli >/dev/null || return 0   # no WARP installed: nothing to warn about
  warp-cli status 2>/dev/null | grep -q 'Status update: Connected'
}

if [[ "$SENDER" == "mouse.clicked" ]]; then
  warp_connected || warp-cli connect >/dev/null 2>&1
  sleep 2
fi

if warp_connected; then STATE=""; else STATE="$RED"$'\t'"warp off"; fi
q_state_set warp "$STATE" && q_layout
exit 0
