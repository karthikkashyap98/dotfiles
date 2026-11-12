#!/usr/bin/env zsh
# Quiet Text: "+N" folded alerts. Click to list them in a popup; leaving the bar closes it.
# The popup rows (q.more.row.*) are built by q_layout in lib.sh.
case "$SENDER" in
  mouse.clicked)       sketchybar --set "$NAME" popup.drawing=toggle ;;
  mouse.exited.global) sketchybar --set "$NAME" popup.drawing=off ;;
esac
