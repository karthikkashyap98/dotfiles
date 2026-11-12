#!/usr/bin/env zsh
# Quiet Text: battery percentage, always shown ("bat 72%", "bat 72%+" while on AC power).
# Yellow below 40%, red below 20%. Red also takes one of the three alert slots (see lib.sh).
source "$CONFIG_DIR/plugins/quiet/lib.sh"

BATT="$(pmset -g batt 2>/dev/null)"
PCT="$(grep -Eo '[0-9]+%' <<<"$BATT" | head -1 | tr -d '%')"
if [[ ! "$PCT" =~ '^[0-9]+$' ]]; then   # no battery (desktop)
  sketchybar --set "$NAME" drawing=off --set q.bat.sep drawing=off
  q_state_set bat 0 && q_layout
  exit 0
fi

C=$Q_TEXT URGENT=0
if   (( PCT < 20 )); then C=$RED URGENT=1
elif (( PCT < 40 )); then C=$YELLOW
fi
LABEL="bat ${PCT}%"
grep -q "AC Power" <<<"$BATT" && LABEL+="+"

sketchybar --set "$NAME" drawing=on label="$LABEL" --set q.bat.sep drawing=on \
  --animate tanh 10 --set "$NAME" label.color=$C
q_state_set bat $URGENT && q_layout
exit 0
