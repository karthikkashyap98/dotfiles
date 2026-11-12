#!/usr/bin/env zsh
# Quiet Text: front app name, lowercase, fading in on each switch.
source "$CONFIG_DIR/plugins/quiet/lib.sh"

APP="$INFO"
if [[ -z "$APP" ]]; then   # startup (--update) has no $INFO
  APP="$(lsappinfo info -only name "$(lsappinfo front)" 2>/dev/null | sed -n 's/.*"LSDisplayName"="\(.*\)"/\1/p')"
fi
APP="$(q_clean "$APP" 24)"
[[ -n "$APP" ]] || exit 0

sketchybar --set "$NAME" label="$APP" label.color="$(q_transparent $Q_TEXT)" \
  --animate tanh 12 --set "$NAME" label.color=$Q_TEXT
