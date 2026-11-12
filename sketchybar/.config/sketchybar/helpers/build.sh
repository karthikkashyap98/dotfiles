#!/usr/bin/env zsh
# Builds the native helper used by the notch-island theme into helpers/bin (git-ignored).
#   sbprivacy   is the mic or camera in use right now (needs no permissions)
# Re-run after editing anything in helpers/src.
set -euo pipefail

HERE="${0:A:h}"
BIN="$HERE/bin"
SRC="$HERE/src"
mkdir -p "$BIN"

# --- sbprivacy -------------------------------------------------------------
if [[ ! -x "$BIN/sbprivacy" || "$SRC/privacy/main.swift" -nt "$BIN/sbprivacy" ]]; then
  echo "building sbprivacy"
  swiftc -O -o "$BIN/sbprivacy" "$SRC/privacy/main.swift"
  codesign --force --sign - --identifier dotfiles.sketchybar.privacy "$BIN/sbprivacy"
fi

echo "helpers ready in $BIN"
