#!/usr/bin/env zsh
# Ops Deck: a solid black, segmented strip for work days (option D in docs/sketchybar-designs.html).
#
#   1 2 4 5 │ Ghostty │ MR 2 │ .....notch..... WARP off  MIC live  79% │ IST 06:56 │ Wed 11 Nov 17:21
#
#   left   occupied AeroSpace workspaces (focused one underlined; click to switch) · front app
#          · MRs waiting on your review (GitLab; hidden at zero; click for a popup)
#   right  WARP (only when disconnected) · mic/camera live · battery · IST · volume (2 s) · clock
#
# Black, like the notch, so the notch disappears into the bar.

source "$CONFIG_DIR/colors.sh"
P="$CONFIG_DIR/plugins/deck"
I="$CONFIG_DIR/plugins/island"   # reuses a few island scripts (front app, battery, volume, clock)
FONT="JetBrainsMono Nerd Font"

[[ -x "$CONFIG_DIR/helpers/bin/sbprivacy" ]] || "$CONFIG_DIR/helpers/build.sh" >/dev/null 2>&1 &!

sketchybar --bar \
  height=32 color=0xf2000000 position=top sticky=on topmost=off \
  padding_left=0 padding_right=0 margin=0 y_offset=0 corner_radius=0 \
  border_width=0 blur_radius=0 shadow=off notch_width=185

sketchybar --default \
  updates=when_shown padding_left=0 padding_right=0 background.drawing=off \
  icon.font="$FONT:Bold:10.5" icon.color=$OVERLAY1 icon.padding_left=10 icon.padding_right=6 \
  label.font="$FONT:Medium:12.0" label.color=$TEXT label.padding_left=0 label.padding_right=10

# Thin vertical divider between segments
divider() {  # divider <name> <position>
  sketchybar --add item "$1" "$2" \
    --set "$1" icon="│" icon.font="$FONT:Light:16.0" icon.color=0x59ffffff \
          icon.padding_left=0 icon.padding_right=0 label.drawing=off
}

# ---- left: workspaces ---------------------------------------------------------------
# One item per AeroSpace workspace; deck/spaces.sh shows the occupied ones and underlines
# the focused one (icon.background as a 2px bar at the bottom of the segment).
sketchybar --add event aerospace_workspace_change
for ws in $(aerospace list-workspaces --all 2>/dev/null); do
  [[ "$ws" =~ '^[A-Za-z0-9-]+$' ]] || continue
  sketchybar --add item "ws.$ws" left \
    --set "ws.$ws" drawing=off icon="$ws" icon.font="$FONT:Bold:12.0" icon.color=$SUBTEXT0 \
          icon.width=26 icon.align=center icon.padding_left=0 icon.padding_right=0 label.drawing=off \
          icon.background.drawing=on icon.background.height=2 icon.background.y_offset=-15 \
          icon.background.color=$TRANSPARENT icon.background.corner_radius=0 \
          click_script="aerospace workspace $ws"
done
# Hidden controller: refreshes every workspace segment in one pass.
sketchybar --add item spaces left \
  --set spaces drawing=off updates=on update_freq=10 script="$P/spaces.sh" \
  --subscribe spaces aerospace_workspace_change front_app_switched system_woke
divider div.ws left

# ---- left: front app ------------------------------------------------------------------
sketchybar --add item front_app left \
  --set front_app icon.font="$FONT:Bold:13.0" icon.color=$GREEN icon.padding_left=10 \
        label.font="$FONT:Medium:12.0" label.max_chars=24 label.padding_right=10 \
        script="$I/front_app.sh" \
  --subscribe front_app front_app_switched
divider div.app left

# ---- left: MRs waiting on your review (network: GITLAB_HOST from local.env, via glab) -------
# Hidden at zero. Click for a popup of titles + age; click a row to open it. See deck/mr.sh.
# (PagerDuty on-call is not built: it would need a new API token.)
sketchybar --add item mr left \
  --set mr drawing=off updates=on update_freq=300 icon="MR" \
        label.font="$FONT:Bold:12.0" label.color=$BLUE \
        popup.align=left popup.height=26 popup.y_offset=2 \
        popup.background.color=$MANTLE popup.background.border_color=$SURFACE1 \
        popup.background.border_width=1 popup.background.corner_radius=10 \
        script="$P/mr.sh" \
  --subscribe mr mouse.clicked mouse.exited.global system_woke
divider div.mr left
sketchybar --set div.mr drawing=off

# ---- right (first added = rightmost) ------------------------------------------------------
sketchybar --add item clock right \
  --set clock update_freq=30 icon.drawing=off label.font="$FONT:Bold:12.0" \
        label.padding_left=10 label.padding_right=12 script="$I/clock.sh" \
  --subscribe clock system_woke

sketchybar --add item volume right \
  --set volume drawing=off updates=on icon.font="$FONT:Bold:13.0" icon.color=$SUBTEXT0 \
        label.color=$SUBTEXT0 script="$I/volume.sh" \
  --subscribe volume volume_change
divider div.ist right

sketchybar --add item ist right \
  --set ist icon="IST" update_freq=30 script="$P/ist.sh" --subscribe ist system_woke
divider div.bat right

sketchybar --add item battery right \
  --set battery update_freq=60 icon.font="$FONT:Bold:13.0" icon.padding_right=5 \
        script="$I/battery.sh" \
  --subscribe battery power_source_change system_woke

# Alert segments: hidden until they apply. updates=on so they keep polling while hidden.
sketchybar --add item mic right \
  --set mic drawing=off updates=on update_freq=3 icon="MIC" icon.color=$RED \
        label.color=$RED script="$P/mic.sh" \
  --add item warp right \
  --set warp drawing=off updates=on update_freq=15 icon="WARP" label="off" label.color=$RED \
        script="$P/warp.sh" \
  --subscribe warp system_woke mouse.clicked

sketchybar --update
sketchybar --trigger aerospace_workspace_change \
  FOCUSED_WORKSPACE="$(aerospace list-workspaces --focused 2>/dev/null)"
