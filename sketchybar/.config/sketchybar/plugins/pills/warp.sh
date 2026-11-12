#!/usr/bin/env zsh
# Mocha Pills WARP alert: hidden while connected; red "WARP off" pill otherwise. Click to reconnect.
source "$CONFIG_DIR/plugins/pills/lib.sh"

warp_connected() {
  command -v warp-cli >/dev/null || return 0   # no WARP installed: nothing to warn about
  warp-cli status 2>/dev/null | grep -q 'Status update: Connected'
}

if [[ "$SENDER" == "mouse.clicked" ]]; then
  warp_connected || warp-cli connect >/dev/null 2>&1
  sleep 2
fi

if warp_connected; then
  pill_hide "$NAME"
else
  pill_show "$NAME" $RED $RED icon=$'' label="WARP off"
fi
