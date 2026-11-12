#!/usr/bin/env zsh
# Mocha Pills mic/camera alert: "Mic live · Zoom" while in use, hidden otherwise.
# helpers/bin/sbprivacy only reads the OS "in use" flags (no permissions, no audio/video).
source "$CONFIG_DIR/plugins/pills/lib.sh"

PRIV="$CONFIG_DIR/helpers/bin/sbprivacy"
MIC=0 CAM=0 APP=-
[[ -x "$PRIV" ]] && IFS=$'\t' read -r MIC CAM APP < <("$PRIV" 2>/dev/null)
[[ "$MIC" == 1 ]] || MIC=0
[[ "$CAM" == 1 ]] || CAM=0

if (( MIC || CAM )); then
  if (( MIC && CAM )); then WHAT="Mic + Cam"; elif (( MIC )); then WHAT="Mic"; else WHAT="Cam"; fi
  if (( CAM )); then ICON=$''; else ICON=$''; fi
  LABEL="$WHAT live"
  APP="$(clean_text "$APP" 18)"
  [[ -n "$APP" && "$APP" != "-" ]] && LABEL+=" · $APP"
  pill_show "$NAME" $RED $RED icon="$ICON" label="$LABEL"
else
  pill_hide "$NAME"
fi
