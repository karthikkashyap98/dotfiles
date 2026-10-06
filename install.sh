#!/usr/bin/env bash
#
# Dotfiles bootstrap for macOS (Apple Silicon).
# Idempotent: safe to re-run; existing things are skipped.
#
# Usage:
#   ./install.sh                 # core setup (packages, shell, configs, tmux plugins)
#   ./install.sh --macos         # also apply macOS settings (keyboard, dock, trackpad, menu bar)
#   ./install.sh --services      # also register sketchybar as a brew service (the ONLY service)
#   ./install.sh --all           # everything above
#
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WITH_MACOS=0
WITH_SERVICES=0

for arg in "$@"; do
  case "$arg" in
    --macos)    WITH_MACOS=1 ;;
    --services) WITH_SERVICES=1 ;;
    --all)      WITH_MACOS=1; WITH_SERVICES=1 ;;
    *) echo "Unknown option: $arg"; exit 1 ;;
  esac
done

log()  { printf '\033[1;36m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mWARN:\033[0m %s\n' "$*"; }

# ---------------------------------------------------------------- packages ---
if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew is required. Install it first: https://brew.sh"; exit 1
fi
if ! xcode-select -p >/dev/null 2>&1; then
  echo "Xcode Command Line Tools are required. Run: xcode-select --install"; exit 1
fi

log "Installing packages from Brewfile (casks may prompt for permissions)"
brew bundle --file="$DOTFILES_DIR/Brewfile"

# ------------------------------------------------------------------- shell ---
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  log "Installing Oh My Zsh (unattended)"
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
  log "Oh My Zsh already present, skipping"
fi

# The installer generates its own .zshrc — remove it so stow can link ours.
if [ -f "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ]; then
  log "Removing generated ~/.zshrc (will be replaced by stow)"
  rm -f "$HOME/.zshrc"
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
for repo in zsh-users/zsh-autosuggestions zsh-users/zsh-syntax-highlighting; do
  dest="$ZSH_CUSTOM/plugins/${repo##*/}"
  if [ ! -d "$dest" ]; then
    log "Cloning ${repo##*/}"
    git clone --depth 1 "https://github.com/$repo" "$dest"
  fi
done

# brew-installed powerlevel10k must be discoverable by oh-my-zsh's theme lookup
mkdir -p "$ZSH_CUSTOM/themes"
ln -sfn "$(brew --prefix)/share/powerlevel10k" "$ZSH_CUSTOM/themes/powerlevel10k"

mkdir -p "$HOME/.nvm"

# ------------------------------------------------------------------ configs ---
log "Stowing configs (zsh tmux aerospace sketchybar nvim)"
(
  cd "$DOTFILES_DIR"
  for pkg in zsh tmux aerospace sketchybar nvim; do
    stow -t "$HOME" "$pkg"
  done
)

# -------------------------------------------------------------------- tmux ----
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
  log "Installing tmux plugin manager (TPM)"
  git clone --depth 1 https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi
# NOTE: the repo's tmux/.config/plugins/* gitlinks have no .gitmodules, so a
# recursive clone leaves them empty — plugins are installed via TPM instead.
log "Installing tmux plugins via TPM"
"$HOME/.tmux/plugins/tpm/bin/install_plugins" || warn "TPM install failed; press <C-s>+I inside tmux instead"

# ----------------------------------------------------------------- services ---
if [ "$WITH_SERVICES" -eq 1 ]; then
  log "Registering sketchybar as a brew service (the only service used)"
  brew services start felixkratz/formulae/sketchybar
else
  log "Skipping services (pass --services to start sketchybar)"
fi

# ----------------------------------------------------------- macOS settings ---
if [ "$WITH_MACOS" -eq 1 ]; then
  log "Applying macOS settings"
  # Keyboard: minimal repeat delay, max repeat speed
  defaults write -g KeyRepeat -int 2
  defaults write -g InitialKeyRepeat -int 15
  # Dock: autohide, no auto-rearrange of spaces
  defaults write com.apple.dock autohide -bool true
  defaults write com.apple.dock mru-spaces -bool false
  # Dock size: intentionally NOT touched (machine-dependent)
  # defaults write com.apple.dock tilesize -int 28
  # Trackpad: tap to click (built-in and Bluetooth)
  defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
  defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
  defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
  # Auto-hide menu bar (fully applies after logout/login)
  defaults write NSGlobalDomain _HIHideMenuBar -bool true
  killall Dock 2>/dev/null || true
else
  log "Skipping macOS settings (pass --macos to apply)"
fi

# ------------------------------------------------------------- wrap-up notes --
cat <<'EOF'

Done. Remaining manual steps:
  1. Grant AeroSpace Accessibility permission (System Settings > Privacy & Security)
     then quit/reopen it. Add it to Login Items if desired.
  2. Run `p10k configure` in a fresh shell (or copy your old ~/.p10k.zsh).
  3. Menu-bar auto-hide fully applies after logout/login.
  4. Install Node when needed:  nvm install --lts
EOF
