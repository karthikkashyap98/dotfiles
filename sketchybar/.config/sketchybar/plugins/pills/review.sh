#!/usr/bin/env zsh
# Mocha Pills: GitLab MRs waiting on your review (a variant of plugins/deck/mr.sh with its own
# item names: pills.review and pills.review.row.<n>).
#
# Data flow: one GitLab API request (to GITLAB_HOST, using your existing `glab` login) every
# 5 minutes and when you click the pill. Shown in the bar and its popup only; nothing written.
#
# Hardening: MR titles come from other people, so they are stripped of control/bidi characters,
# truncated, and passed to sketchybar as a quoted argument (never evaluated). Links are only
# embedded in a row's click action if they match the exact GitLab MR URL shape.
source "$CONFIG_DIR/plugins/pills/lib.sh"

# GITLAB_HOST lives in local.env (git-ignored). Read as data, never sourced.
HOST="$(sed -n 's/^GITLAB_HOST=//p' "$CONFIG_DIR/local.env" 2>/dev/null | head -1)"
[[ "$HOST" =~ '^[a-z0-9.-]+$' ]] || { sketchybar --set "$NAME" drawing=off; exit 0; }
REVIEWER="${GITLAB_REVIEWER:-$USER}"
[[ "$REVIEWER" =~ '^[A-Za-z0-9._-]+$' ]] || exit 0
command -v glab >/dev/null || exit 0

case "$SENDER" in
  mouse.exited.global)
    sketchybar --set "$NAME" popup.drawing=off
    exit 0 ;;
  mouse.clicked)
    sketchybar --set "$NAME" popup.drawing=toggle ;;   # then refresh below
esac

JSON="$(glab api --hostname "$HOST" \
  "merge_requests?scope=all&state=opened&reviewer_username=$REVIEWER&wip=no&order_by=updated_at&per_page=15" 2>/dev/null)" || exit 0
jq -e 'type == "array"' <<<"$JSON" >/dev/null 2>&1 || exit 0   # error object: keep the last state

N="$(jq 'length' <<<"$JSON")"
[[ "$N" =~ '^[0-9]+$' ]] || exit 0

if (( N == 0 )); then
  sketchybar --set "$NAME" popup.drawing=off --remove '/pills\.review\.row\..*/' >/dev/null 2>&1
  pill_hide "$NAME"
  exit 0
fi

PREV="$(sketchybar --query "$NAME" 2>/dev/null | jq -r '.label.value // "0"' | sed -n 's/^\([0-9]*\).*/\1/p')"

# iid \t title \t age \t url   (url empty unless it is a well-formed MR link on $HOST)
ROWS="$(jq -r --arg host "$HOST" '
  def age: (now - (sub("\\.[0-9]+"; "") | fromdateiso8601)) as $s
    | if $s < 3600 then "\(($s/60)|floor)m"
      elif $s < 86400 then "\(($s/3600)|floor)h"
      else "\(($s/86400)|floor)d" end;
  def clean: gsub("[\u0000-\u001f\u007f-\u009f​-‏  ‪-‮⁠⁦-⁩﻿]"; "")
    | if length > 48 then .[0:47] + "…" else . end;
  .[] | [ (.iid | tostring),
          (.title // "" | clean),
          ((.updated_at // .created_at // "") | try age catch "?"),
          (.web_url // "" | if (test("\n") | not) and test("^https://" + ($host | gsub("\\."; "\\.")) + "/[A-Za-z0-9._/-]+/-/merge_requests/[0-9]+$") then . else "" end)
        ] | @tsv' <<<"$JSON")"

FONT="JetBrainsMono Nerd Font"
args=(--remove '/pills\.review\.row\..*/')
i=0
while IFS=$'\t' read -r IID TITLE AGE URL; do
  [[ "$IID" =~ '^[0-9]+$' ]] || continue
  (( i++ ))
  row="pills.review.row.$i"
  click="sketchybar --set $NAME popup.drawing=off"
  [[ -n "$URL" ]] && click="open '$URL'; $click"
  args+=(--add item "$row" "popup.$NAME"
         --set "$row" icon="!$IID" icon.color=$BLUE icon.font="$FONT:Bold:11.5"
               icon.width=64 icon.padding_left=12 background.drawing=off
               label="$TITLE · $AGE" label.color=$TEXT label.font="$FONT:Medium:11.5"
               label.padding_right=14
               click_script="$click")
done <<<"$ROWS"

sketchybar "${args[@]}" >/dev/null 2>&1
pill_show "$NAME" $BLUE $TEXT icon=$'' label="$N to review"

# A new review request: flash the count.
if (( N > ${PREV:-0} )); then
  sketchybar --animate sin 30 --set "$NAME" label.color=$PEACH label.color=$TEXT
fi
