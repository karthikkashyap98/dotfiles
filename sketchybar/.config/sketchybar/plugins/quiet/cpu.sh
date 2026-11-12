#!/usr/bin/env zsh
# Quiet Text: "cpu 94% node" when one process stays above 80% for ~30 s (6 polls at 5 s).
# Counter lives in $Q_STATE (per-user temp dir), as "<count><TAB><process>".
source "$CONFIG_DIR/plugins/quiet/lib.sh"

THRESHOLD=80 NEEDED=6
# Top process; keeps multi-word names like "Google Chrome Helper (Renderer)".
IFS=$'\t' read -r PCT PROC < <(ps -Aceo pcpu,comm -r 2>/dev/null |
  awk 'NR==2 { p = int($1); sub(/^[ \t]*[0-9.]+[ \t]+/, ""); print p "\t" $0 }')
[[ "$PCT" =~ '^[0-9]+$' ]] || exit 0

COUNTER="$Q_STATE/cpu.count"
COUNT=0 LAST=""
[[ -r "$COUNTER" ]] && IFS=$'\t' read -r COUNT LAST <"$COUNTER"
[[ "$COUNT" =~ '^[0-9]+$' ]] || COUNT=0

if (( PCT > THRESHOLD )); then
  if [[ "$PROC" == "$LAST" ]]; then (( COUNT = COUNT < NEEDED ? COUNT + 1 : NEEDED )); else COUNT=1; fi
else
  COUNT=0
fi
print -r -- "$COUNT"$'\t'"$PROC" >| "$COUNTER"

STATE=""
(( COUNT >= NEEDED )) && STATE="$PEACH"$'\t'"cpu ${PCT}% $(q_clean "$PROC" 14)"
q_state_set cpu "$STATE" && q_layout
exit 0
