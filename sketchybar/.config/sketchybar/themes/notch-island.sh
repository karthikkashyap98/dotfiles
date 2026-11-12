#!/usr/bin/env zsh
# Notch Island: black islands at the screen edges, plus two "ears" that fuse with the notch.
#
#   [ 1 │ Ghostty ]     [warp off][82%]▓▓notch▓▓[IST 22:10]     [ 45%  Wed 11 Nov 08:40 ]
#    left island             left ear (q)       right ear (e)      right island
#
#   left island   focused AeroSpace workspace · front app
#   left ear      battery % (always; yellow < 40%, red < 20%, green bolt when charging).
#                 When WARP is disconnected a red "warp off" segment drops out of the notch
#                 and joins the ear; click it to reconnect.
#   right ear     IST clock (dim outside 09:00–19:00 IST). Becomes a pulsing
#                 "Mic live · <app>" / "Cam live" whenever the mic or a camera is in use.
#   right island  volume (shown for 2 s after a change) · date and time
#
# Notch on this MacBook: 185 x 32 pt (measured), so bar height 32 matches it exactly.
#
# Screens without a notch (external monitors, or clamshell mode) get no ears. The same group
# becomes ONE centered island there instead:   [ warp off  82% │ IST 22:10 ]
# plugins/island/layout.sh picks the screens for each version (display=) via the sbdisplays
# helper and re-runs on display_change, so plugging a monitor in or out adapts live.

source "$CONFIG_DIR/colors.sh"
P="$CONFIG_DIR/plugins/island"
FONT="JetBrainsMono Nerd Font"

# Ears: full bar height (sketchybar doesn't draw backgrounds taller than the bar), with
# -14px of padding tucking each ear under the notch so they look joined to it.
EAR_HEIGHT=32
EAR_LIFT=0
EAR_TUCK=-14
# Battery ear: same total width as the right ear (119pt), with the icon + % centered in the
# visible part (the 14pt tucked under the notch doesn't count). 30 outer + 45 inner (14 tucked).
BATTERY_PAD_OUTER=30
BATTERY_PAD_INNER=45

sketchybar --bar \
  height=32 color=$TRANSPARENT position=top sticky=on topmost=off \
  padding_left=6 padding_right=6 margin=0 y_offset=0 corner_radius=0 \
  border_width=0 blur_radius=0 shadow=off notch_width=185

sketchybar --default \
  updates=when_shown \
  padding_left=0 padding_right=0 \
  background.drawing=off \
  icon.font="$FONT:Bold:14.0" icon.color=$ISLAND_TEXT icon.padding_left=0 icon.padding_right=6 \
  label.font="$FONT:Medium:12.5" label.color=$ISLAND_TEXT label.padding_left=0 label.padding_right=0

island=(
  background.drawing=on background.color=$BLACK
  background.border_color=$HAIRLINE background.border_width=1
  background.height=28 background.corner_radius=10
)
ear=(
  background.drawing=on background.color=$BLACK
  background.height=$EAR_HEIGHT background.y_offset=$EAR_LIFT background.corner_radius=10
)

# ---- left island: workspace │ front app -------------------------------------------
sketchybar --add event island_refresh --add event island_relayout

sketchybar --add event aerospace_workspace_change \
  --add item space left \
  --set space icon.font="$FONT:ExtraBold:13.0" icon.color=$MAUVE \
        icon.padding_left=12 icon.padding_right=8 label.drawing=off \
        script="$P/space.sh" click_script="aerospace workspace-back-and-forth" \
  --subscribe space aerospace_workspace_change \
  --add item space.sep left \
  --set space.sep icon="│" icon.color=0x40ffffff icon.font="$FONT:Regular:13.0" \
        icon.padding_right=8 label.drawing=off \
  --add item front_app left \
  --set front_app icon.padding_right=7 label.padding_right=12 label.max_chars=22 \
        script="$P/front_app.sh" \
  --subscribe front_app front_app_switched \
  --add bracket island.left space space.sep front_app \
  --set island.left "${island[@]}"

# ---- left ear (q = left of the notch): battery, plus WARP when it's down ---------------
# q items stack outward from the notch: battery is added first so it hugs the notch.
sketchybar --add item battery q \
  --set battery update_freq=60 "${ear[@]}" \
        padding_right=$EAR_TUCK icon.padding_left=$BATTERY_PAD_OUTER icon.padding_right=5 \
        label.padding_right=$BATTERY_PAD_INNER \
        script="$P/battery.sh" \
  --subscribe battery power_source_change system_woke island_refresh

# The warp segment overlaps the battery by 12px (black on black) so the two read as one ear.
# updates=on: it must keep polling while hidden, or it could never reappear.
sketchybar --add item warp q \
  --set warp drawing=off updates=on update_freq=15 "${ear[@]}" \
        padding_right=-12 icon.color=$RED icon.padding_left=14 \
        label.color=$RED label.padding_right=16 \
        script="$P/warp.sh" \
  --subscribe warp system_woke mouse.clicked island_refresh

# ---- right ear (e = right of the notch): IST clock / mic + camera live ---------------
sketchybar --add item ear.right e \
  --set ear.right updates=on update_freq=3 "${ear[@]}" \
        padding_left=$EAR_TUCK icon.drawing=off icon.font="$FONT:Bold:11.0" \
        label.padding_left=$(( -EAR_TUCK + 10 )) label.padding_right=14 \
        script="$P/ear_right.sh" \
  --subscribe ear.right system_woke island_refresh

# ---- right island: volume · clock (first added = rightmost) ------------------------------
sketchybar --add item clock right \
  --set clock update_freq=30 icon.drawing=off \
        label.font="$FONT:Bold:12.5" label.padding_left=12 label.padding_right=12 \
        script="$P/clock.sh" \
  --subscribe clock system_woke \
  --add item volume right \
  --set volume drawing=off updates=on icon.padding_left=12 icon.color=$SUBTEXT0 \
        label.color=$SUBTEXT0 script="$P/volume.sh" \
  --subscribe volume volume_change \
  --add bracket island.right volume clock \
  --set island.right "${island[@]}"

# ---- center island (screens without a notch): the ears' contents as one island ------------
# Same scripts as the ears (each acts on $NAME); ear_right.sh takes the icon padding as $1.
# Center items are laid out left to right in the order added.
sketchybar --add item island.warp center \
  --set island.warp drawing=off updates=on update_freq=15 \
        icon.color=$RED icon.padding_left=12 label.color=$RED label.padding_right=4 \
        script="$P/warp.sh" \
  --subscribe island.warp system_woke mouse.clicked island_refresh \
  --add item island.battery center \
  --set island.battery update_freq=60 icon.padding_left=12 icon.padding_right=5 \
        script="$P/battery.sh" \
  --subscribe island.battery power_source_change system_woke island_refresh \
  --add item island.sep center \
  --set island.sep icon="│" icon.color=0x40ffffff icon.font="$FONT:Regular:13.0" \
        icon.padding_left=10 icon.padding_right=10 label.drawing=off \
  --add item island.ist center \
  --set island.ist updates=on update_freq=3 icon.drawing=off icon.font="$FONT:Bold:11.0" \
        label.padding_right=12 script="$P/ear_right.sh 0" \
  --subscribe island.ist system_woke island_refresh \
  --add bracket island.center island.warp island.battery island.sep island.ist \
  --set island.center "${island[@]}"

# ---- display controller: ears on the notched screen, center island everywhere else --------
sketchybar --add item island.layout left \
  --set island.layout drawing=off updates=on script="$P/layout.sh" \
  --subscribe island.layout display_change system_woke island_relayout

# Place both groups now (synchronously) so nothing flashes on the wrong screen at load.
NAME=island.layout SENDER=startup "$P/layout.sh"

# Build the native helpers on first run (no permissions needed). Async so the bar isn't
# blocked; once built, re-run the layout so the notch detection takes over.
if [[ ! -x "$CONFIG_DIR/helpers/bin/sbprivacy" || ! -x "$CONFIG_DIR/helpers/bin/sbdisplays" ]]; then
  { "$CONFIG_DIR/helpers/build.sh" >/dev/null 2>&1 && sketchybar --trigger island_relayout; } &!
fi

sketchybar --update
sketchybar --trigger aerospace_workspace_change \
  FOCUSED_WORKSPACE="$(aerospace list-workspaces --focused 2>/dev/null)"
