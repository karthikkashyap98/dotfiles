#!/usr/bin/env zsh
# Glyph Rail hover reveal. Sourced by the glyph scripts (not run on its own).
#
#   glyph_hover <argb>   handle mouse.entered / mouse.exited for $NAME; returns 1 for other events
#   glyph_refit          re-measure an open label after its text changed
#
# At rest a glyph's label is label.drawing=off, label.width=0. On enter it is drawn at width 0
# and transparent, then animated to its measured width and full color; on exit it animates
# back to 0 / transparent and is switched off once the animation is done (unless re-entered).
#
# The width is computed, not "dynamic": dynamic is not a number, so it can't be animated.
# JetBrains Mono is monospaced (600/1000 em advance), so width = chars * 0.6 * font size.

GLYPH_LABEL_SIZE=11      # must match label.font size in themes/glyph-rail.sh
GLYPH_LABEL_PAD=5        # label.padding_left on hover items (counted inside label.width)
GLYPH_FRAMES=12

export LC_ALL=en_US.UTF-8   # so ${#x} / ${x[1,n]} count characters, not bytes
[[ "$NAME" =~ '^[a-z0-9.]+$' ]] || exit 0
GLYPH_TOKEN="${TMPDIR:-$(getconf DARWIN_USER_TEMP_DIR)}/sketchybar-glyph-reveal-$NAME"

_glyph_width() {
  local n
  n="$(sketchybar --query "$NAME" 2>/dev/null | jq -r '.label.value // "" | length')"
  [[ "$n" =~ '^[0-9]+$' ]] || n=0
  (( n == 0 )) && { print 0; return; }
  print $(( GLYPH_LABEL_PAD + (n * GLYPH_LABEL_SIZE * 6 + 9) / 10 + 1 ))
}

glyph_hover() {
  local color="${1:-$TEXT}"; local clear="0x00${color:4}"
  case "$SENDER" in
    mouse.entered)
      print -r -- "$$" >| "$GLYPH_TOKEN"
      local w; w="$(_glyph_width)"
      (( w > 0 )) || return 0
      if [[ "$(sketchybar --query "$NAME" 2>/dev/null | jq -r '.label.drawing // "off"')" != "on" ]]; then
        sketchybar --set "$NAME" label.drawing=on label.width=0 label.color="$clear"
      fi
      sketchybar --animate tanh $GLYPH_FRAMES --set "$NAME" label.width="$w" label.color="$color"
      return 0 ;;
    mouse.exited)
      print -r -- "$$" >| "$GLYPH_TOKEN"
      sketchybar --animate tanh $GLYPH_FRAMES --set "$NAME" label.width=0 label.color="$clear"
      {
        sleep 0.3
        [[ "$(<"$GLYPH_TOKEN")" == "$$" ]] && sketchybar --set "$NAME" label.drawing=off
      } &!
      return 0 ;;
  esac
  return 1
}

glyph_refit() {
  [[ "$(sketchybar --query "$NAME" 2>/dev/null | jq -r '.label.drawing // "off"')" == "on" ]] || return 0
  local w; w="$(_glyph_width)"
  sketchybar --animate tanh 8 --set "$NAME" label.width="$w"
}

# glyph_clean <text> <max>: untrusted text (app names) minus control, zero-width and bidi
# characters, truncated. The result is only ever passed to sketchybar as a quoted argument.
glyph_clean() {
  local t="$1"
  t="${t//[[:cntrl:]]/}"
  t="${t//[$'\u200b'-$'\u200f'$'\u2028'-$'\u202e'$'\u2060'-$'\u2069'$'\ufeff']/}"
  print -r -- "${t[1,$2]}"
}
