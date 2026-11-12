#!/usr/bin/env zsh
# Glyph Rail: two small frosted capsules of monochrome glyphs (option E in docs/sketchybar-designs.html).
#
#   ( ━ • •  )   ..........notch..........   (  2  18   22:10 )
#    left capsule                              right capsule
#
#   left   AeroSpace workspaces as dots (occupied = dot, focused = mauve dash; click to switch)
#          · front-app glyph (hover: app name)
#   right  mic/cam (red pulse, only while in use) · WARP shield (red, only while disconnected;
#          click reconnects) · MRs to review (peach merge glyph + count; needs GITLAB_HOST in
#          local.env, hidden at zero; click for a popup) · battery (glyph + % always)
#          · IST sun/moon (hover: "IST 22:10 · off hours") · time
#
# Hover reveal: see plugins/glyph/reveal.sh. All item names start with "glyph." so they can't
# collide with names other themes' plugins hardcode (div.mr, mr.row.*, ...).

source "$CONFIG_DIR/colors.sh"
P="$CONFIG_DIR/plugins/glyph"
FONT="JetBrainsMono Nerd Font"

# Local colors (not in colors.sh)
CAPSULE_BG=0xa81e1e2e     # Mocha base at 66%
CAPSULE_BORDER=0x14ffffff # 8% white hairline

[[ -x "$CONFIG_DIR/helpers/bin/sbprivacy" ]] || "$CONFIG_DIR/helpers/build.sh" >/dev/null 2>&1 &!

sketchybar --bar \
  height=32 color=$TRANSPARENT position=top sticky=on topmost=off \
  padding_left=8 padding_right=8 margin=0 y_offset=0 corner_radius=0 \
  border_width=0 blur_radius=0 shadow=off notch_width=185

sketchybar --default \
  updates=when_shown padding_left=0 padding_right=0 background.drawing=off \
  icon.font="$FONT:Regular:14.0" icon.color=$SUBTEXT0 icon.padding_left=7 icon.padding_right=7 \
  label.font="$FONT:Bold:11.0" label.color=$TEXT label.padding_left=0 label.padding_right=0

capsule=(
  background.drawing=on background.color=$CAPSULE_BG
  background.border_color=$CAPSULE_BORDER background.border_width=1
  background.height=26 background.corner_radius=13
  blur_radius=20
)

# Hover-reveal glyphs: label hidden (width 0) at rest; reveal.sh animates it open.
# label.padding_left must match GLYPH_LABEL_PAD and the font size GLYPH_LABEL_SIZE in reveal.sh.
reveal=(label.drawing=off label.width=0 label.padding_left=5 label.font="$FONT:Bold:11.0")

# Capsule edge padding: an empty spacer item at each outer edge.
spacer() {  # spacer <name> <position> <width>
  sketchybar --add item "$1" "$2" --set "$1" width="$3" icon.drawing=off label.drawing=off
}

# ---- left capsule: workspace dots · front app ------------------------------------------
sketchybar --add event aerospace_workspace_change
spacer glyph.pad.left left 13

for ws in $(aerospace list-workspaces --all 2>/dev/null); do
  [[ "$ws" =~ '^[A-Za-z0-9-]+$' ]] || continue
  sketchybar --add item "glyph.ws.$ws" left \
    --set "glyph.ws.$ws" drawing=off updates=on padding_right=5 \
          icon=" " icon.width=6 icon.padding_left=0 icon.padding_right=0 label.drawing=off \
          icon.background.drawing=on icon.background.height=6 icon.background.corner_radius=3 \
          icon.background.color=$OVERLAY0 \
          click_script="aerospace workspace $ws"
done
# Each dot is the icon's background (a fixed icon.width keeps item padding = the gap).
# Hidden controller: refreshes every dot in one pass (updates=on: it is never drawn).
sketchybar --add item glyph.spaces left \
  --set glyph.spaces drawing=off updates=on update_freq=10 script="$P/spaces.sh" \
  --subscribe glyph.spaces aerospace_workspace_change front_app_switched system_woke

sketchybar --add item glyph.app left \
  --set glyph.app icon.color=$TEXT icon.font="$FONT:Regular:15.0" \
        icon.padding_left=4 icon.padding_right=13 "${reveal[@]}" \
        script="$P/front_app.sh" \
  --subscribe glyph.app front_app_switched mouse.entered mouse.exited

sketchybar --add bracket glyph.rail.left glyph.pad.left '/glyph\.ws\..*/' glyph.app \
  --set glyph.rail.left "${capsule[@]}"

# ---- right capsule (first added = rightmost) ------------------------------------------------
sketchybar --add item glyph.clock right \
  --set glyph.clock update_freq=30 icon.drawing=off \
        label.font="$FONT:Bold:12.5" label.padding_left=7 label.padding_right=13 \
        script="$P/clock.sh" \
  --subscribe glyph.clock system_woke

sketchybar --add item glyph.ist right \
  --set glyph.ist update_freq=30 "${reveal[@]}" script="$P/ist.sh" \
  --subscribe glyph.ist system_woke mouse.entered mouse.exited

# Battery: glyph + percentage always visible (the one label that is never hidden).
sketchybar --add item glyph.battery right \
  --set glyph.battery update_freq=60 icon.padding_right=4 label.padding_right=2 \
        script="$P/battery.sh" \
  --subscribe glyph.battery power_source_change system_woke

# Alert glyphs: hidden until they apply. updates=on so they keep polling while hidden.
sketchybar --add item glyph.mr right \
  --set glyph.mr drawing=off updates=on update_freq=300 icon=$'' icon.color=$PEACH \
        icon.padding_right=4 label.color=$PEACH label.padding_right=2 \
        popup.align=right popup.height=26 popup.y_offset=4 \
        popup.background.color=$MANTLE popup.background.border_color=$SURFACE1 \
        popup.background.border_width=1 popup.background.corner_radius=10 \
        script="$P/mr.sh" \
  --subscribe glyph.mr mouse.clicked mouse.exited.global system_woke

sketchybar --add item glyph.warp right \
  --set glyph.warp drawing=off updates=on update_freq=15 icon=$'' icon.color=$RED \
        "${reveal[@]}" label.color=0x00f38ba8 script="$P/warp.sh" \
  --subscribe glyph.warp system_woke mouse.clicked mouse.entered mouse.exited

sketchybar --add item glyph.mic right \
  --set glyph.mic drawing=off updates=on update_freq=3 icon=$'\U000f036c' icon.color=$RED \
        "${reveal[@]}" label.color=0x00f38ba8 script="$P/mic.sh" \
  --subscribe glyph.mic mouse.entered mouse.exited

spacer glyph.pad.right right 6

sketchybar --add bracket glyph.rail.right glyph.pad.right glyph.mic glyph.warp glyph.mr \
        glyph.battery glyph.ist glyph.clock \
  --set glyph.rail.right "${capsule[@]}"

sketchybar --update
sketchybar --trigger aerospace_workspace_change \
  FOCUSED_WORKSPACE="$(aerospace list-workspaces --focused 2>/dev/null)"
