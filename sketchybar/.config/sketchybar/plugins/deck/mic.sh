#!/usr/bin/env zsh
# Ops Deck mic/camera segment: "MIC live · Zoom" / "CAM live" while in use, hidden otherwise.
# Uses helpers/bin/sbprivacy, which only reads the OS "in use" flags (no permissions, no audio/video).
source "$CONFIG_DIR/colors.sh"

PRIV="$CONFIG_DIR/helpers/bin/sbprivacy"
MIC=0 CAM=0 APP=-
[[ -x "$PRIV" ]] && IFS=$'\t' read -r MIC CAM APP < <("$PRIV" 2>/dev/null)

if (( MIC || CAM )); then
  if (( MIC && CAM )); then KEY="MIC+CAM"; elif (( MIC )); then KEY="MIC"; else KEY="CAM"; fi
  LABEL="live"; [[ -n "$APP" && "$APP" != "-" ]] && LABEL+=" · $APP"
  sketchybar --set "$NAME" drawing=on icon="$KEY" label="$LABEL" \
    --animate sin 45 --set "$NAME" label.color=$DIM_RED label.color=$RED
else
  sketchybar --set "$NAME" drawing=off
fi
