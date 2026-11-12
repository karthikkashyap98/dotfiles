#!/usr/bin/env zsh
# Ops Deck: GitLab MRs waiting on your review.
#
# Data flow: one GitLab API request (to GITLAB_HOST, using your existing `glab` login from the
# keyring) every 5 minutes and when you click the segment. The result is shown in the bar and
# its popup only; nothing is written to disk or logged.
#
# Hardening: MR titles come from other people, so they are stripped of control/bidi characters,
# truncated, and passed to sketchybar as a quoted argument (never evaluated). Links are only
# embedded in a row's click action if they match the exact GitLab MR URL shape.
source "$CONFIG_DIR/colors.sh"

# The GitLab host lives in local.env (git-ignored) so the work hostname isn't published:
#   echo 'GITLAB_HOST=gitlab.example.com' >> ~/.config/sketchybar/local.env
# Read as data (not sourced). Without it, the segment stays hidden.
HOST="$(sed -n 's/^GITLAB_HOST=//p' "$CONFIG_DIR/local.env" 2>/dev/null | head -1)"
[[ "$HOST" =~ '^[a-z0-9.-]+$' ]] || { sketchybar --set "$NAME" drawing=off --set div.mr drawing=off; exit 0; }
REVIEWER="${GITLAB_REVIEWER:-$USER}"   # GitLab username; matches your macOS login by default
[[ "$REVIEWER" =~ '^[A-Za-z0-9._-]+$' ]] || exit 0

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

if (( N == 0 )); then
  sketchybar --set "$NAME" drawing=off popup.drawing=off --set div.mr drawing=off \
             --remove '/mr\.row\..*/' >/dev/null 2>&1
  exit 0
fi

PREV="$(sketchybar --query "$NAME" 2>/dev/null | jq -r '.label.value // "0"')"

# iid \t title \t age \t url   (url empty unless it is a well-formed MR link on $HOST)
ROWS="$(jq -r --arg host "$HOST" '
  def age: (now - (sub("\\.[0-9]+"; "") | fromdateiso8601)) as $s
    | if $s < 3600 then "\(($s/60)|floor)m"
      elif $s < 86400 then "\(($s/3600)|floor)h"
      else "\(($s/86400)|floor)d" end;
  # jq turns \uXXXX into real characters, so the regex class holds the actual code points
  def clean: gsub("[\u0000-\u001f\u007f-\u009f\u200b-\u200f\u2028\u2029\u202a-\u202e\u2060\u2066-\u2069\ufeff]"; "")
    | if length > 48 then .[0:47] + "…" else . end;
  .[] | [ (.iid | tostring),
          (.title // "" | clean),
          ((.updated_at // .created_at // "") | try age catch "?"),
          (.web_url // "" | if (test("\n") | not) and test("^https://" + ($host | gsub("\\."; "\\.")) + "/[A-Za-z0-9._/-]+/-/merge_requests/[0-9]+$") then . else "" end)
        ] | @tsv' <<<"$JSON")"

args=(--remove '/mr\.row\..*/')
i=0
while IFS=$'\t' read -r IID TITLE AGE URL; do
  [[ "$IID" =~ '^[0-9]+$' ]] || continue
  (( i++ ))
  row="mr.row.$i"
  click="sketchybar --set $NAME popup.drawing=off"
  [[ -n "$URL" ]] && click="open '$URL'; $click"
  args+=(--add item "$row" "popup.$NAME"
         --set "$row" icon="!$IID" icon.color=$BLUE icon.font="JetBrainsMono Nerd Font:Bold:11.5"
               icon.width=64 icon.padding_left=12
               label="$TITLE · $AGE" label.color=$TEXT label.font="JetBrainsMono Nerd Font:Medium:11.5"
               label.padding_right=14
               click_script="$click")
done <<<"$ROWS"

sketchybar "${args[@]}" >/dev/null 2>&1
sketchybar --set "$NAME" drawing=on label="$N" --set div.mr drawing=on

# A new review request: flash the count.
if (( N > ${PREV:-0} )); then
  sketchybar --animate sin 30 --set "$NAME" label.color=$PEACH label.color=$BLUE
fi
