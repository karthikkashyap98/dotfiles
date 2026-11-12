#!/usr/bin/env zsh
# Mocha Pills shared helpers. Sourced by plugins/pills/*.sh (not executed on its own).
source "$CONFIG_DIR/colors.sh"

PILL_BG=0xe6313244      # the one translucent surface every pill shares
PILL_BG_CLEAR=0x00313244
PILL_MUTED=0xffa6adc8

# 0xffRRGGBB -> 0x00RRGGBB (same color, fully transparent) for fades
clear_of() { print -r -- "0x00${1[5,-1]}"; }

pill_drawing() {
  sketchybar --query "$1" 2>/dev/null | jq -r '.geometry.drawing // "off"'
}

# pill_show <item> <icon color> <label color> [extra --set properties...]
# Fades the pill in (tanh) if it was hidden; otherwise just updates it in place.
pill_show() {
  local name="$1" ic="$2" lc="$3"; shift 3
  if [[ "$(pill_drawing "$name")" == "on" ]]; then
    sketchybar --set "$name" "$@" icon.color="$ic" label.color="$lc"
    return
  fi
  sketchybar --set "$name" "$@" drawing=on background.color=$PILL_BG_CLEAR \
                    icon.color="$(clear_of "$ic")" label.color="$(clear_of "$lc")" \
    --animate tanh 15 --set "$name" background.color=$PILL_BG icon.color="$ic" label.color="$lc"
}

# pill_hide <item>: fades the pill out, then stops drawing it (it keeps updating: updates=on).
pill_hide() {
  local name="$1"
  [[ "$(pill_drawing "$name")" == "on" ]] || return 0
  sketchybar --animate tanh 12 --set "$name" background.color=$PILL_BG_CLEAR \
             icon.color=0x00000000 label.color=0x00000000
  sleep 0.3
  sketchybar --set "$name" drawing=off
}

# Untrusted display text (app names, MR titles): drop control/bidi/zero-width characters, cap length.
clean_text() {  # clean_text <text> <max chars>
  local s="$1" max="${2:-24}"
  s="${s//[[:cntrl:]]/}"
  s="${s//[$'​'-$'‏'$' '-$'‮'$'⁠'-$'⁩'$'﻿']/}"
  (( ${#s} > max )) && s="${s[1,max-1]}…"
  print -r -- "$s"
}
