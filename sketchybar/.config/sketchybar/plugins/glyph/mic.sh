#!/usr/bin/env zsh
# Glyph Rail mic/camera: a red mic (or camera) glyph that pulses while in use, hidden otherwise.
# Hover shows "mic · Zoom". helpers/bin/sbprivacy only reads the OS "in use" flags.
source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/plugins/glyph/reveal.sh"
glyph_hover "$RED" && exit 0

DIM=${DIM_RED:-0xff7a3346}
PRIV="$CONFIG_DIR/helpers/bin/sbprivacy"
MIC=0 CAM=0 APP=-
[[ -x "$PRIV" ]] && IFS=$'\t' read -r MIC CAM APP < <("$PRIV" 2>/dev/null)
[[ "$MIC" == 1 ]] || MIC=0
[[ "$CAM" == 1 ]] || CAM=0

if (( MIC || CAM )); then
  if (( MIC && CAM )); then ICON=$'\U000f036c' WHAT="mic + cam"
  elif (( MIC )); then      ICON=$'\U000f036c' WHAT="mic"
  else                      ICON=$'\U000f0567' WHAT="cam"
  fi
  APP="$(glyph_clean "$APP" 20)"
  [[ -n "$APP" && "$APP" != "-" ]] && WHAT+=" · $APP"
  sketchybar --set "$NAME" drawing=on icon="$ICON" label="$WHAT" \
    --animate sin 45 --set "$NAME" icon.color=$DIM icon.color=$RED
  glyph_refit
else
  sketchybar --set "$NAME" drawing=off label.drawing=off label.width=0
fi
