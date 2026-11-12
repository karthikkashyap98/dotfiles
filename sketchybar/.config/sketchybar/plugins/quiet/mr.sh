#!/usr/bin/env zsh
# Quiet Text: "N mr" (peach) when GitLab MRs wait on your review. Click for a popup of titles.
# A variant of plugins/deck/mr.sh with Quiet Text item names (q.mr, q.mr.row.*) and no icons.
#
# Data flow: one GitLab API request (to GITLAB_HOST, using your existing `glab` login from the
# keyring) every 5 minutes and when you click the segment. Shown in the bar and its popup only;
# only the count (not titles or links) is written to the per-user temp dir.
#
# Hardening: MR titles come from other people, so they are stripped of control/bidi characters,
# truncated, and passed to sketchybar as a quoted argument (never evaluated). Links are only
# embedded in a row's click action if they match the exact GitLab MR URL shape.
source "$CONFIG_DIR/plugins/quiet/lib.sh"

# GITLAB_HOST lives in local.env (git-ignored). Read as data, never sourced.
HOST="$(sed -n 's/^GITLAB_HOST=//p' "$CONFIG_DIR/local.env" 2>/dev/null | head -1)"
if [[ ! "$HOST" =~ '^[a-z0-9.-]+$' ]]; then
  q_state_set mr "" && q_layout
  exit 0
fi
REVIEWER="${GITLAB_REVIEWER:-$USER}"   # GitLab username; matches your macOS login by default
[[ "$REVIEWER" =~ '^[A-Za-z0-9._-]+$' ]] || exit 0

case "$SENDER" in
  mouse.exited.global)
    sketchybar --set "$NAME" popup.drawing=off
    exit 0 ;;
  mouse.clicked)
    sketchybar --set "$NAME" popup.drawing=toggle ;;   # then refresh below
esac

command -v glab >/dev/null || exit 0
JSON="$(glab api --hostname "$HOST" \
  "merge_requests?scope=all&state=opened&reviewer_username=$REVIEWER&wip=no&order_by=updated_at&per_page=15" 2>/dev/null)" || exit 0
jq -e 'type == "array"' <<<"$JSON" >/dev/null 2>&1 || exit 0   # error object: keep the last state

N="$(jq 'length' <<<"$JSON")"
[[ "$N" =~ '^[0-9]+$' ]] || exit 0

PREV=0; [[ -r "$Q_STATE/mr.count" ]] && PREV="$(<"$Q_STATE/mr.count")"
[[ "$PREV" =~ '^[0-9]+$' ]] || PREV=0
print -r -- "$N" >| "$Q_STATE/mr.count"

if (( N == 0 )); then
  sketchybar --set "$NAME" popup.drawing=off --remove '/q\.mr\.row\..*/' >/dev/null 2>&1
  q_state_set mr "" && q_layout
  exit 0
fi

# iid \t title \t age \t url   (url empty unless it is a well-formed MR link on $HOST)
ROWS="$(jq -r --arg host "$HOST" '
  def age: (now - (sub("\\.[0-9]+"; "") | fromdateiso8601)) as $s
    | if $s < 3600 then "\(($s/60)|floor)m"
      elif $s < 86400 then "\(($s/3600)|floor)h"
      else "\(($s/86400)|floor)d" end;
  # jq turns \uXXXX into real characters, so the regex class holds the actual code points
  def clean: gsub("[\u0000-\u001f\u007f-\u009f​-‏  ‪-‮⁠⁦-⁩﻿]"; "")
    | if length > 48 then .[0:47] + "…" else . end;
  .[] | [ (.iid | tostring),
          (.title // "" | clean),
          ((.updated_at // .created_at // "") | try age catch "?"),
          (.web_url // "" | if (test("\n") | not) and test("^https://" + ($host | gsub("\\."; "\\.")) + "/[A-Za-z0-9._/-]+/-/merge_requests/[0-9]+$") then . else "" end)
        ] | @tsv' <<<"$JSON")"

args=(--remove '/q\.mr\.row\..*/')
i=0
while IFS=$'\t' read -r IID TITLE AGE URL; do
  [[ "$IID" =~ '^[0-9]+$' ]] || continue
  (( i++ ))
  row="q.mr.row.$i"
  click="sketchybar --set q.mr popup.drawing=off"
  [[ -n "$URL" ]] && click="open '$URL'; $click"   # URL matched the strict pattern above (no quotes)
  args+=(--add item "$row" popup.q.mr
         --set "$row" label="!$IID  $TITLE · $AGE" label.color=$Q_TEXT
               label.padding_left=14 label.padding_right=14
               click_script="$click")
done <<<"$ROWS"
sketchybar "${args[@]}" >/dev/null 2>&1

q_state_set mr "$PEACH"$'\t'"$N mr" && q_layout

# A new review request: one soft flash (only if it is on the bar, not folded into +N).
if (( N > PREV )) && [[ -r "$Q_STATE/.shown" && "$(<"$Q_STATE/.shown")" == *mr* ]]; then
  sketchybar --animate sin 30 --set "$NAME" label.color=$TEXT label.color=$PEACH
fi
exit 0
