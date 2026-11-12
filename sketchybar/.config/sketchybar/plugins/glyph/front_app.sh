#!/usr/bin/env zsh
# Glyph Rail front app: the app's glyph only. Its name is the hover label.
# Icon map copied from plugins/island/front_app.sh.
source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/plugins/glyph/reveal.sh"
glyph_hover "$TEXT" && exit 0

APP="$INFO"
if [[ -z "$APP" ]]; then   # startup (--update) has no $INFO
  APP="$(lsappinfo info -only name "$(lsappinfo front)" 2>/dev/null | sed -n 's/.*"LSDisplayName"="\(.*\)"/\1/p')"
fi
# Untrusted text: drop control characters, cap the length. Only ever passed as a quoted argument.
APP="$(glyph_clean "$APP" 24)"
[[ -n "$APP" ]] || exit 0

case "$APP" in
  Ghostty|kitty|Terminal|iTerm2|Alacritty|WezTerm) ICON=$'' ;;      # terminal
  "Google Chrome"|Chromium)                        ICON=$'' ;;
  Firefox)                                         ICON=$'' ;;
  Safari)                                          ICON=$'' ;;
  Arc)                                             ICON=$'\U000f059f' ;; # web
  Slack)                                           ICON=$'' ;;
  Code|"Visual Studio Code"|Cursor|Windsurf|Zed)  ICON=$'\U000f0a1e' ;;
  zoom.us|Zoom|FaceTime)                           ICON=$'\U000f0567' ;; # video
  Finder)                                          ICON=$'\U000f0036' ;;
  Messages|WhatsApp|Discord)                       ICON=$'\U000f0361' ;; # message
  Mail|Spark|Mimestream)                           ICON=$'' ;;
  Spotify)                                         ICON=$'' ;;
  Music)                                           ICON=$'' ;;
  Notion|Obsidian|Notes)                           ICON=$'\U000f082e' ;; # notebook
  Calendar)                                        ICON=$'' ;;
  "System Settings")                               ICON=$'' ;;
  1Password*)                                      ICON=$'\U000f0306' ;; # key
  "Activity Monitor")                              ICON=$'\U000f012a' ;; # chart
  *)                                               ICON=$'' ;;     # window
esac

sketchybar --set "$NAME" icon="$ICON" label="$APP" icon.y_offset=-3 \
  --animate tanh 12 --set "$NAME" icon.y_offset=0
glyph_refit
