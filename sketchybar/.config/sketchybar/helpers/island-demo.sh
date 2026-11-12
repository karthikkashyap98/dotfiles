#!/usr/bin/env zsh
# Plays each Notch Island state for a few seconds so you can see the animations,
# then hands every item back to its real script. Changes nothing on your system.
source "$CONFIG_DIR/colors.sh" 2>/dev/null || source "$HOME/.config/sketchybar/colors.sh"
say() { print -P "%F{cyan}==>%f $1"; }

say "left ear: warp off segment drops out of the notch"
sketchybar --set warp icon=$'' label="warp off" y_offset=34 drawing=on \
  --animate tanh 18 --set warp y_offset=0
sleep 4
say "left ear: slides back in"
sketchybar --animate tanh 14 --set warp y_offset=34; sleep 0.3
sketchybar --set warp drawing=off y_offset=0

say "right ear: mic live (pulsing)"
sketchybar --set ear.right icon="●" icon.drawing=on icon.color=$RED icon.padding_left=24 icon.padding_right=6 \
  label="Mic live · Zoom" label.color=$RED label.padding_left=0 y_offset=34 \
  --animate tanh 18 --set ear.right y_offset=0
for _ in 1 2 3; do sketchybar --animate sin 45 --set ear.right icon.color=$DIM_RED icon.color=$RED; sleep 1.5; done

say "right island: volume appears for 2 s"
sketchybar --trigger volume_change INFO=45
sleep 3

say "workspace bounce + app fade"
sketchybar --trigger aerospace_workspace_change FOCUSED_WORKSPACE=9; sleep 1.2
sketchybar --trigger aerospace_workspace_change FOCUSED_WORKSPACE="$(aerospace list-workspaces --focused)"

say "restoring real state"
sketchybar --update
