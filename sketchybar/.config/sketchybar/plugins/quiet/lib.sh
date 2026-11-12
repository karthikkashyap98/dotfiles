#!/usr/bin/env zsh
# Quiet Text: shared helpers, sourced by every plugins/quiet script (not run directly).
#
# Alerts (warp, mic, mr, cpu) never draw themselves. Each one writes its wanted state to
# $Q_STATE/<key> ("COLOR<TAB>label", or empty when it doesn't apply) and calls q_layout,
# which decides what fits: at most 3 alerts (2 while the battery is red), most urgent first,
# the rest folded into "+N". Priority: battery < 20% > warp off > mic live > mr > cpu.

source "$CONFIG_DIR/colors.sh"
export LC_ALL=en_US.UTF-8   # launchd may start us in the C locale; needed for (L) and the bidi strip

# Local colors (Quiet Text only): Catppuccin TEXT at a few opacities.
Q_TEXT=0xc4cdd6f4    # ~75%: everything at rest
Q_FAINT=0x66cdd6f4   # IST outside working hours
Q_DIM=0x55cdd6f4     # the · separators
Q_MORE=0x99cdd6f4    # "+N"

# Per-user temp dir (never /tmp). launchd doesn't always export TMPDIR.
Q_STATE="${TMPDIR:-$(getconf DARWIN_USER_TEMP_DIR 2>/dev/null)}"
Q_STATE="${Q_STATE%/}/sketchybar-quiet"
[[ -d "$Q_STATE" ]] || mkdir -p -m 700 "$Q_STATE"

Q_ORDER=(warp mic mr cpu)   # urgency order (battery is handled separately; it is always drawn)

# Strip control and bidi/zero-width characters from untrusted text, lowercase it, and cap it.
q_clean() {  # q_clean <text> <max>
  local s="${1//[[:cntrl:]]/}"
  s="${s//[$'​'-$'‏'$' '$' '$'‪'-$'‮'$'⁠'$'⁦'-$'⁩'$'﻿']/}"
  s="${(L)s}"
  (( ${#s} > $2 )) && s="${s[1,$(( $2 - 1 ))]}…"
  print -r -- "$s"
}

# Write a state file atomically. Returns 1 when nothing changed (so callers can skip q_layout).
q_state_set() {  # q_state_set <key> <value>
  local f="$Q_STATE/$1" old=""
  [[ -r "$f" ]] && old="$(<"$f")"
  [[ "$old" == "$2" ]] && return 1
  print -r -- "$2" >| "$f.$$" && mv -f "$f.$$" "$f"
}

q_transparent() { print -r -- "0x00${1#0x??}"; }   # 0xAARRGGBB -> 0x00RRGGBB

q_layout() {
  zmodload zsh/system 2>/dev/null
  local lock="$Q_STATE/.lock" fd
  : >>| "$lock"
  zsystem flock -t 3 -f fd "$lock" 2>/dev/null || fd=""

  local -a items show hide args fade was
  [[ -r "$Q_STATE/.items" ]] && items=(${(f)"$(<"$Q_STATE/.items")"})   # alert keys this theme added
  [[ -r "$Q_STATE/.shown" ]] && was=(${(f)"$(<"$Q_STATE/.shown")"})
  local slots=3 k line color label prev=" ${was[*]} "
  [[ -r "$Q_STATE/bat" && "$(<"$Q_STATE/bat")" == 1 ]] && slots=2

  for k in $Q_ORDER; do
    (( ${items[(Ie)$k]} )) || continue
    line=""; [[ -r "$Q_STATE/$k" ]] && line="$(<"$Q_STATE/$k")"
    [[ -n "$line" ]] || continue
    if (( ${#show} < slots )); then show+=$k; else hide+=$k; fi
  done

  for k in $Q_ORDER; do
    (( ${items[(Ie)$k]} )) || continue
    if (( ${show[(Ie)$k]} )); then
      line="$(<"$Q_STATE/$k")"
      color="${line%%$'\t'*}" label="${line#*$'\t'}"
      [[ "$color" =~ '^0x[0-9a-fA-F]{8}$' ]] || color=$Q_TEXT
      if [[ "$prev" == *" $k "* ]]; then
        args+=(--set "q.$k" drawing=on label="$label" label.color=$color --set "q.$k.sep" drawing=on)
      else   # newly shown: fade in from transparent
        args+=(--set "q.$k" drawing=on label="$label" label.color="$(q_transparent $color)"
               --set "q.$k.sep" drawing=on label.color="$(q_transparent $Q_DIM)")
        fade+=(--set "q.$k" label.color=$color --set "q.$k.sep" label.color=$Q_DIM)
      fi
    else
      args+=(--set "q.$k" drawing=off --set "q.$k.sep" drawing=off)
    fi
  done

  # "+N": the folded alerts, listed in a popup when clicked.
  args+=(--remove '/q\.more\.row\..*/')
  if (( ${#hide} )); then
    local i=0
    for k in $hide; do
      line="$(<"$Q_STATE/$k")"
      color="${line%%$'\t'*}" label="${line#*$'\t'}"
      [[ "$color" =~ '^0x[0-9a-fA-F]{8}$' ]] || color=$Q_TEXT
      (( i++ ))
      args+=(--add item "q.more.row.$i" popup.q.more
             --set "q.more.row.$i" label="$label" label.color=$color
                   label.padding_left=14 label.padding_right=14
                   click_script="sketchybar --set q.more popup.drawing=off")
    done
    if [[ "$prev" == *" +more "* ]]; then
      args+=(--set q.more drawing=on label="+${#hide}" --set q.more.sep drawing=on)
    else
      args+=(--set q.more drawing=on label="+${#hide}" label.color="$(q_transparent $Q_MORE)"
             --set q.more.sep drawing=on)
      fade+=(--set q.more label.color=$Q_MORE)
    fi
    show+=(+more)
  else
    args+=(--set q.more drawing=off popup.drawing=off --set q.more.sep drawing=off)
  fi

  print -r -- "${(F)show}" >| "$Q_STATE/.shown"
  if (( ${#fade} )); then
    sketchybar "${args[@]}" --animate tanh 20 "${fade[@]}" >/dev/null 2>&1
  else
    sketchybar "${args[@]}" >/dev/null 2>&1
  fi

  [[ -n "$fd" ]] && zsystem flock -u "$fd" 2>/dev/null
}
