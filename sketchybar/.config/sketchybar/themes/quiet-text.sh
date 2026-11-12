#!/usr/bin/env zsh
# Quiet Text: no pills, no icons (option C in docs/sketchybar-designs.html).
# If a word appears on the bar, it needs you.
#
#   1  ghostty            .....notch.....    warp off · 2 mr · +1 · ist 22:10 · bat 72% · wed 11 · 17:51
#
#   left   focused AeroSpace workspace (mauve, bold; small bounce on change) · front app, lowercase
#   right  at rest: ist (dim outside 09:00-19:00 IST) · battery % (always) · date · time
#          alerts, colored words shown only while true, fading in:
#            warp off (red; click reconnects) · mic live · <app> / cam live (red)
#            N mr (peach; only with GITLAB_HOST in local.env; click for a popup) · cpu 94% <proc>
#          battery turns yellow < 40%, red < 20%. vol 45% shows for 2 s after a change.
#
# Width budget ~420px per side: at most 3 alerts (2 while the battery is red), the rest fold
# into a dim "+N" (click to list them). Priority: battery < 20% > warp > mic > mr > cpu.
# Alerts don't draw themselves; plugins/quiet/lib.sh (q_layout) decides what is shown.
#
# Notch on this MacBook: 185 x 32 pt, so bar height 32 matches it.

source "$CONFIG_DIR/plugins/quiet/lib.sh"   # colors.sh + Q_* colors + Q_STATE
P="$CONFIG_DIR/plugins/quiet"
FONT="JetBrainsMono Nerd Font"

[[ -x "$CONFIG_DIR/helpers/bin/sbprivacy" ]] || "$CONFIG_DIR/helpers/build.sh" >/dev/null 2>&1 &!

# Fresh state for this load (truncate, don't delete): no stale alerts from a previous session.
for f in warp mic mr cpu bat .shown cpu.count mr.count; do : >| "$Q_STATE/$f"; done

sketchybar --bar \
  height=32 color=0x6611111b position=top sticky=on topmost=off \
  padding_left=14 padding_right=14 margin=0 y_offset=0 corner_radius=0 \
  border_width=0 blur_radius=30 shadow=off notch_width=185

sketchybar --default \
  updates=when_shown padding_left=0 padding_right=0 background.drawing=off \
  icon.drawing=off \
  label.font="$FONT:Medium:12.0" label.color=$Q_TEXT label.padding_left=0 label.padding_right=0

popup=(
  popup.align=right popup.height=24 popup.y_offset=2
  popup.background.color=$MANTLE popup.background.border_color=$SURFACE1
  popup.background.border_width=1 popup.background.corner_radius=8
)

# Dim middle dot. Items that come and go each own the dot to their right.
sep() {  # sep <name> [drawing]
  sketchybar --add item "$1" right \
    --set "$1" drawing="${2:-on}" label="·" label.color=$Q_DIM \
          label.padding_left=4 label.padding_right=8   # the glyph sits right of centre; this evens the gaps
}

# ---- left: workspace, app ------------------------------------------------------------
sketchybar --add event aerospace_workspace_change \
  --add item q.ws left \
  --set q.ws label.font="$FONT:Bold:12.0" label.color=$MAUVE label.padding_right=12 \
        script="$P/space.sh" click_script="aerospace workspace-back-and-forth" \
  --subscribe q.ws aerospace_workspace_change \
  --add item q.app left \
  --set q.app label.max_chars=24 script="$P/app.sh" \
  --subscribe q.app front_app_switched

# ---- right (first added = rightmost) ---------------------------------------------------
# Resting readouts: ist · bat · date · time
sketchybar --add item q.time right \
  --set q.time update_freq=30 script="$P/clock.sh" \
  --subscribe q.time system_woke
sep q.date.sep
sketchybar --add item q.date right
sep q.bat.sep
sketchybar --add item q.bat right \
  --set q.bat update_freq=60 script="$P/battery.sh" \
  --subscribe q.bat power_source_change system_woke
sep q.ist.sep
sketchybar --add item q.ist right \
  --set q.ist update_freq=30 script="$P/ist.sh" \
  --subscribe q.ist system_woke

# Volume: 2 s after a change, then gone.
sep q.vol.sep off
sketchybar --add item q.vol right \
  --set q.vol drawing=off updates=on script="$P/volume.sh" \
  --subscribe q.vol volume_change

# "+N" for folded alerts (drawn by q_layout).
sep q.more.sep off
sketchybar --add item q.more right \
  --set q.more drawing=off updates=on label.color=$Q_MORE "${popup[@]}" script="$P/more.sh" \
  --subscribe q.more mouse.clicked mouse.exited.global

# Alerts, least urgent first so the most urgent sits nearest the notch.
# All hidden by default; updates=on so they keep polling while hidden.
ITEMS=(warp mic cpu)

sep q.cpu.sep off
sketchybar --add item q.cpu right \
  --set q.cpu drawing=off updates=on update_freq=5 label.max_chars=26 script="$P/cpu.sh"

# MRs only when local.env names a GitLab host (read as data, never sourced).
GL_HOST="$(sed -n 's/^GITLAB_HOST=//p' "$CONFIG_DIR/local.env" 2>/dev/null | head -1)"
if [[ "$GL_HOST" =~ '^[a-z0-9.-]+$' ]]; then
  ITEMS+=(mr)
  sep q.mr.sep off
  sketchybar --add item q.mr right \
    --set q.mr drawing=off updates=on update_freq=300 "${popup[@]}" script="$P/mr.sh" \
    --subscribe q.mr mouse.clicked mouse.exited.global system_woke
fi
unset GL_HOST

sep q.mic.sep off
sketchybar --add item q.mic right \
  --set q.mic drawing=off updates=on update_freq=3 label.max_chars=28 script="$P/mic.sh"

sep q.warp.sep off
sketchybar --add item q.warp right \
  --set q.warp drawing=off updates=on update_freq=15 script="$P/warp.sh" \
  --subscribe q.warp system_woke mouse.clicked

print -r -- "${(F)ITEMS}" >| "$Q_STATE/.items"

sketchybar --update
sketchybar --trigger aerospace_workspace_change \
  FOCUSED_WORKSPACE="$(aerospace list-workspaces --focused 2>/dev/null)"
