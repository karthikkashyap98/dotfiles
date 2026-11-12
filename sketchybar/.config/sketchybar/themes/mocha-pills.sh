#!/usr/bin/env zsh
# Mocha Pills: the original pill bar, cleaned up and on Catppuccin Mocha (option A in
# docs/sketchybar-designs.html).
#
#   [ 1 2 (5) 7 ] [ Ghostty ]   ....notch....   [WARP off] [Mic live] [ 45%] [ 82%] [ IST 22:10] [ Wed 11 Nov 17:51]
#
#   left   occupied AeroSpace workspaces (focused one is the single filled mauve pill; click to
#          switch; empty ones hide) · front app
#   right  alerts only while true (MRs to review if GITLAB_HOST is set, WARP off, mic/cam live)
#          · volume (2 s after a change) · battery % (always) · IST (dim off-hours) · clock
#          (click for a date + IST popup)
#
# Transparent bar; every pill shares one translucent surface. Item names are all pills.* so they
# never collide with names other themes' plugins hardcode.

source "$CONFIG_DIR/colors.sh"
P="$CONFIG_DIR/plugins/pills"
I="$CONFIG_DIR/plugins/island"   # battery.sh and volume.sh are reused as-is (they only use $NAME)
FONT="JetBrainsMono Nerd Font"

PILL_BG=0xe6313244
PILL_MUTED=0xffa6adc8
MAUVE_CLEAR=0x00cba6f7

[[ -x "$CONFIG_DIR/helpers/bin/sbprivacy" ]] || "$CONFIG_DIR/helpers/build.sh" >/dev/null 2>&1 &!

sketchybar --bar \
  height=32 color=$TRANSPARENT position=top sticky=on topmost=off \
  padding_left=8 padding_right=8 margin=0 y_offset=0 corner_radius=0 \
  border_width=0 blur_radius=0 shadow=off notch_width=185

sketchybar --default \
  updates=when_shown padding_left=3 padding_right=3 \
  background.drawing=on background.color=$PILL_BG background.corner_radius=8 \
  background.height=26 background.border_width=0 \
  icon.font="$FONT:Bold:13.0" icon.color=$TEXT icon.padding_left=10 icon.padding_right=6 \
  label.font="$FONT:Medium:12.5" label.color=$TEXT label.padding_left=0 label.padding_right=10

# ---- left: workspaces pill --------------------------------------------------------------
# One item per AeroSpace workspace (pills.ws.<name>) inside one bracket that draws the shared
# surface. pills.spaces (hidden controller) shows occupied ones and fills the focused one.
spacer() {  # spacer <name>: a few px of inset so the mauve fill doesn't touch the bracket edge
  sketchybar --add item "$1" left \
    --set "$1" width=3 padding_left=0 padding_right=0 background.drawing=off \
          icon.drawing=off label.drawing=off
}

sketchybar --add event aerospace_workspace_change
ws_items=()
spacer pills.ws.lpad
for ws in ${(f)"$(aerospace list-workspaces --all 2>/dev/null)"}; do
  [[ "$ws" =~ '^[A-Za-z0-9-]+$' ]] || continue
  case "$ws" in
    1) glyph=$'\U000f0176' ;;   # the user's glyph for workspace 1 (kept from classic)
    *) glyph="$ws" ;;
  esac
  sketchybar --add item "pills.ws.$ws" left \
    --set "pills.ws.$ws" drawing=off padding_left=0 padding_right=0 \
          icon="$glyph" icon.font="$FONT:ExtraBold:12.5" icon.color=$PILL_MUTED \
          icon.width=26 icon.align=center icon.padding_left=0 icon.padding_right=0 \
          label.drawing=off \
          background.color=$MAUVE_CLEAR background.height=20 background.corner_radius=6 \
          click_script="aerospace workspace '$ws'"
  ws_items+=("pills.ws.$ws")
done
spacer pills.ws.rpad
sketchybar --add bracket pills.ws pills.ws.lpad "${ws_items[@]}" pills.ws.rpad \
  --set pills.ws background.drawing=on background.color=$PILL_BG \
        background.corner_radius=8 background.height=26

sketchybar --add item pills.spaces left \
  --set pills.spaces drawing=off updates=on update_freq=10 label="" script="$P/spaces.sh" \
  --subscribe pills.spaces aerospace_workspace_change front_app_switched space_windows_change system_woke

# ---- left: front app ------------------------------------------------------------------------
sketchybar --add item pills.front_app left \
  --set pills.front_app padding_left=6 icon.font="$FONT:Bold:14.0" icon.color=$GREEN \
        label.max_chars=24 script="$P/front_app.sh" \
  --subscribe pills.front_app front_app_switched

# ---- right (first added = rightmost) --------------------------------------------------------
sketchybar --add item pills.clock right \
  --set pills.clock update_freq=30 icon=$'' icon.color=$BLUE \
        label.font="$FONT:Bold:12.5" \
        popup.align=right popup.height=24 popup.y_offset=4 \
        popup.background.color=$MANTLE popup.background.border_color=$SURFACE1 \
        popup.background.border_width=1 popup.background.corner_radius=8 \
        script="$P/clock.sh" \
  --subscribe pills.clock system_woke mouse.clicked mouse.exited.global \
  --add item pills.clock.date popup.pills.clock \
  --set pills.clock.date background.drawing=off icon=$'' icon.color=$BLUE \
        icon.padding_left=12 label.padding_right=14 \
  --add item pills.clock.ist popup.pills.clock \
  --set pills.clock.ist background.drawing=off icon=$'' icon.color=$LAVENDER \
        icon.padding_left=12 label.padding_right=14

sketchybar --add item pills.ist right \
  --set pills.ist update_freq=30 icon=$'' icon.color=$LAVENDER script="$P/ist.sh" \
  --subscribe pills.ist system_woke

sketchybar --add item pills.battery right \
  --set pills.battery update_freq=60 icon.font="$FONT:Bold:14.0" icon.padding_right=5 \
        script="$I/battery.sh" \
  --subscribe pills.battery power_source_change system_woke

sketchybar --add item pills.volume right \
  --set pills.volume drawing=off updates=on icon.font="$FONT:Bold:14.0" icon.color=$SUBTEXT0 \
        label.color=$SUBTEXT0 script="$I/volume.sh" \
  --subscribe pills.volume volume_change

# Alert pills: hidden until true; updates=on so they keep polling while hidden.
sketchybar --add item pills.privacy right \
  --set pills.privacy drawing=off updates=on update_freq=3 icon.color=$RED label.color=$RED \
        label.max_chars=28 script="$P/privacy.sh" \
  --subscribe pills.privacy system_woke

sketchybar --add item pills.warp right \
  --set pills.warp drawing=off updates=on update_freq=15 icon.color=$RED label.color=$RED \
        script="$P/warp.sh" \
  --subscribe pills.warp system_woke mouse.clicked

# MRs awaiting review: only when local.env has a GITLAB_HOST (read as data, never sourced).
GITLAB_HOST_VALUE="$(sed -n 's/^GITLAB_HOST=//p' "$CONFIG_DIR/local.env" 2>/dev/null | head -1)"
if [[ "$GITLAB_HOST_VALUE" =~ '^[a-z0-9.-]+$' ]]; then
  sketchybar --add item pills.review right \
    --set pills.review drawing=off updates=on update_freq=300 \
          icon.color=$BLUE label.font="$FONT:Bold:12.5" \
          popup.align=right popup.height=26 popup.y_offset=4 \
          popup.background.color=$MANTLE popup.background.border_color=$SURFACE1 \
          popup.background.border_width=1 popup.background.corner_radius=8 \
          script="$P/review.sh" \
    --subscribe pills.review mouse.clicked mouse.exited.global system_woke
fi
unset GITLAB_HOST_VALUE

sketchybar --update
sketchybar --trigger aerospace_workspace_change \
  FOCUSED_WORKSPACE="$(aerospace list-workspaces --focused 2>/dev/null)"
