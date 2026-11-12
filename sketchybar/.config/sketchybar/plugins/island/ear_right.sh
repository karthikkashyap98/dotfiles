#!/usr/bin/env zsh
# Right ear: the IST clock (teammates), or a pulsing "Mic live · <app>" / "Cam live".
# The mic/camera check is helpers/bin/sbprivacy: it reads the OS "in use" flags only.
# No permissions are needed and no audio or video is touched.
source "$CONFIG_DIR/colors.sh"

PRIV="$CONFIG_DIR/helpers/bin/sbprivacy"
MIC=0 CAM=0 APP=-
if [[ -x "$PRIV" ]]; then
  IFS=$'\t' read -r MIC CAM APP < <("$PRIV" 2>/dev/null)
fi

WAS_LIVE=0
[[ "$(sketchybar --query "$NAME" 2>/dev/null | jq -r '.label.value // ""')" == *live* ]] && WAS_LIVE=1

if (( MIC || CAM )); then
  if (( MIC && CAM )); then what="Mic + Cam"; elif (( MIC )); then what="Mic"; else what="Cam"; fi
  label="$what live"
  [[ "$APP" != "-" && -n "$APP" ]] && label+=" · $APP"

  sketchybar --set "$NAME" icon="●" icon.drawing=on icon.color=$RED \
             icon.padding_left=24 icon.padding_right=6 \
             label="$label" label.color=$RED label.padding_left=0
  (( WAS_LIVE )) || sketchybar --set "$NAME" y_offset=34 --animate tanh 18 --set "$NAME" y_offset=0
  # one slow pulse per update (every 3 s)
  sketchybar --animate sin 45 --set "$NAME" icon.color=$DIM_RED icon.color=$RED
else
  # Teammates in India: sun + bright during 09:00–19:00 IST, moon + muted outside it.
  # Both states use an icon so the ear keeps the same width as the left one.
  H=$(TZ=Asia/Kolkata date +%-H)
  TIME="$(TZ=Asia/Kolkata date +%H:%M)"
  if (( H >= 9 && H < 19 )); then
    sketchybar --set "$NAME" icon=$'\uf185' icon.drawing=on icon.color=$YELLOW \
               icon.padding_left=24 icon.padding_right=6 \
               label="IST $TIME" label.color=$TEXT label.padding_left=0
  else
    sketchybar --set "$NAME" icon=$'\uf186' icon.drawing=on icon.color=$SUBTEXT0 \
               icon.padding_left=24 icon.padding_right=6 \
               label="IST $TIME" label.color=$SUBTEXT0 label.padding_left=0
  fi
  (( WAS_LIVE )) && sketchybar --set "$NAME" y_offset=34 --animate tanh 18 --set "$NAME" y_offset=0
fi
