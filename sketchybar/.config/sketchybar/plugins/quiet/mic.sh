#!/usr/bin/env zsh
# Quiet Text: "mic live · zoom.us" / "cam live" / "mic+cam live · app" (red) while in use.
# helpers/bin/sbprivacy only reads the OS "in use" flags: no permissions, no audio or video.
source "$CONFIG_DIR/plugins/quiet/lib.sh"

PRIV="$CONFIG_DIR/helpers/bin/sbprivacy"
MIC=0 CAM=0 APP=-
[[ -x "$PRIV" ]] && IFS=$'\t' read -r MIC CAM APP < <("$PRIV" 2>/dev/null)
[[ "$MIC" == 1 ]] || MIC=0
[[ "$CAM" == 1 ]] || CAM=0

STATE=""
if (( MIC || CAM )); then
  if (( MIC && CAM )); then L="mic+cam live"; elif (( MIC )); then L="mic live"; else L="cam live"; fi
  APP="$(q_clean "$APP" 12)"
  [[ -n "$APP" && "$APP" != "-" ]] && L+=" · $APP"
  STATE="$RED"$'\t'"$L"
fi
q_state_set mic "$STATE" && q_layout
exit 0
