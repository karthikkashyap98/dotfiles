#!/usr/bin/env zsh
# Display controller: decides where the battery / WARP / IST group lives.
#
#   notched screen (MacBook)  -> the ears at q/e, fused with the notch (unchanged design)
#   any other screen          -> one centered island at "center" with the same contents
#
# Runs at theme load, on display_change / system_woke, and on island_relayout (sent once the
# sbdisplays helper has been built). Items only exist per bar through display=, so each group
# gets display=<arrangement ids>; a group with no screen is parked (hidden, no polling).
#
# Detection: helpers/bin/sbdisplays prints "<CGDirectDisplayID> <builtin> <notch>" per screen
# (NSScreen.safeAreaInsets.top > 0 = notch). That ID equals SketchyBar's DirectDisplayID, which
# maps to the arrangement-id that display= expects. Without the helper: ears everywhere (old look).
P="$CONFIG_DIR/plugins/island"
HELPER="$CONFIG_DIR/helpers/bin/sbdisplays"
PARKED="${TMPDIR:-$(getconf DARWIN_USER_TEMP_DIR)}/sketchybar-island-parked"
LAST="${TMPDIR:-$(getconf DARWIN_USER_TEMP_DIR)}/sketchybar-island-layout"

EARS=(battery warp ear.right)
CENTER=(island.warp island.battery island.sep island.ist)
# updates= each item has when it is live (matches the theme's settings)
typeset -A UPDATES=(
  battery when_shown warp on ear.right on
  island.warp on island.battery when_shown island.sep when_shown island.ist on
)

# Displays can still be settling when display_change fires.
[[ "$SENDER" == "display_change" ]] && sleep 1

JSON="$(sketchybar --query displays 2>/dev/null)" || exit 0
ALL=(${(f)"$(jq -r '.[]["arrangement-id"] | select(type == "number")' <<<"$JSON" 2>/dev/null)"})
(( ${#ALL} )) || exit 0

NOTCHED=()
if [[ -x "$HELPER" ]]; then
  while IFS=$'\t' read -r did builtin notch; do
    [[ "$did" =~ '^[0-9]+$' && "$notch" == 1 ]] || continue
    aid="$(jq -r --argjson d "$did" \
      'first(.[] | select(.DirectDisplayID == $d) | .["arrangement-id"]) // empty' <<<"$JSON")"
    [[ "$aid" =~ '^[0-9]+$' ]] && NOTCHED+=("$aid")
  done < <("$HELPER" 2>/dev/null)
else
  NOTCHED=("${ALL[@]}")
fi
OTHERS=(${ALL:|NOTCHED})

EAR_DISPLAYS="${(j:,:)${(@on)NOTCHED}}"
CENTER_DISPLAYS="${(j:,:)${(@on)OTHERS}}"
STATE="ears=$EAR_DISPLAYS center=$CENTER_DISPLAYS"
PREV="$(cat "$LAST" 2>/dev/null)"

# Parked list first, so a script that starts mid-switch already sees it.
parked=()
[[ -n "$EAR_DISPLAYS" ]]    || parked+=("${EARS[@]}")
[[ -n "$CENTER_DISPLAYS" ]] || parked+=("${CENTER[@]}")
print -rl -- "${parked[@]}" >| "$PARKED"
print -r -- "$STATE" >| "$LAST"

# group_args <display list> <items...>: build --set arguments for one group
args=()
group_args() {
  local displays="$1"; shift
  local item
  for item in "$@"; do
    if [[ -n "$displays" ]]; then
      # warp decides its own visibility (warp.sh); everything else is shown.
      if [[ "$item" == *warp ]]; then
        args+=(--set "$item" display="$displays" updates="${UPDATES[$item]}")
      else
        args+=(--set "$item" display="$displays" updates="${UPDATES[$item]}" drawing=on)
      fi
    else
      args+=(--set "$item" drawing=off updates=off)
    fi
  done
}
group_args "$EAR_DISPLAYS" "${EARS[@]}"
group_args "$CENTER_DISPLAYS" "${CENTER[@]}"
if [[ -n "$CENTER_DISPLAYS" ]]; then
  args+=(--set island.center display="$CENTER_DISPLAYS" drawing=on)
else
  args+=(--set island.center drawing=off)
fi
sketchybar "${args[@]}"

# Newly shown center island drops in from the top edge, like the ear segments do.
if [[ -n "$PREV" && "$PREV" != "$STATE" && -n "$CENTER_DISPLAYS" && "$PREV" == *"center=" ]]; then
  anim=()
  for item in island.battery island.sep island.ist; do anim+=(--set "$item" y_offset=0); done
  pre=()
  for item in island.battery island.sep island.ist; do pre+=(--set "$item" y_offset=34); done
  sketchybar "${pre[@]}" --animate tanh 18 "${anim[@]}"
fi

# Refresh contents of whichever groups are live (scripts of parked items exit via guard.sh).
sketchybar --trigger island_refresh
