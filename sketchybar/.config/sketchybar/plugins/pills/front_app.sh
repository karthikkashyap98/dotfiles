#!/usr/bin/env zsh
# Mocha Pills front app: role-colored icon + name; the name fades in and the icon rises on switch.
source "$CONFIG_DIR/plugins/pills/lib.sh"

APP="$INFO"
if [[ -z "$APP" ]]; then   # startup (--update) has no $INFO
  APP="$(lsappinfo info -only name "$(lsappinfo front)" 2>/dev/null | sed -n 's/.*"LSDisplayName"="\(.*\)"/\1/p')"
fi
APP="$(clean_text "$APP" 24)"
[[ -n "$APP" ]] || exit 0

case "$APP" in
  Ghostty|kitty|Terminal|iTerm2|Alacritty|WezTerm) ICON=$'' ;;      # terminal
  "Google Chrome"|Chromium)                        ICON=$'' ;;
  Firefox)                                         ICON=$'' ;;
  Safari)                                          ICON=$'' ;;
  Arc)                                             ICON=$'\U000f059f' ;;  # web
  Slack)                                           ICON=$'' ;;
  Code|"Visual Studio Code"|Cursor|Windsurf|Zed)  ICON=$'\U000f0a1e' ;;
  zoom.us|Zoom|FaceTime)                           ICON=$'\U000f0567' ;;  # video
  Finder)                                          ICON=$'\U000f0036' ;;
  Messages|WhatsApp|Discord)                       ICON=$'\U000f0361' ;;  # message
  Mail|Spark|Mimestream)                           ICON=$'' ;;
  Spotify)                                         ICON=$'' ;;
  Music)                                           ICON=$'' ;;
  Notion|Obsidian|Notes)                           ICON=$'\U000f082e' ;;  # notebook
  Calendar)                                        ICON=$'' ;;
  "System Settings")                               ICON=$'' ;;
  1Password*)                                      ICON=$'\U000f0306' ;;  # key
  "Activity Monitor")                              ICON=$'\U000f012a' ;;  # chart
  *)                                               ICON=$'' ;;      # window
esac

sketchybar --set "$NAME" icon="$ICON" label="$APP" \
           label.color="$(clear_of $TEXT)" icon.y_offset=-4 \
  --animate tanh 12 --set "$NAME" label.color=$TEXT icon.y_offset=0
