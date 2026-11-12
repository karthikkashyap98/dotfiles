# Dotfiles
![MacOS](https://img.shields.io/badge/MacOS-8e8e93.svg?style=for-the-badge&logo=apple&logoColor=white)
![Sketchybar](https://img.shields.io/badge/Sketchybar-2c3e50?style=for-the-badge&logoColor=white)
![Aerospace](https://img.shields.io/badge/Aerospace-black?style=for-the-badge&logo=gnometerminal&logoColor=white)
![Ghostty](https://img.shields.io/badge/Ghostty-000000?style=for-the-badge)
![Neovim](https://img.shields.io/badge/neovim-%2357A143.svg?style=for-the-badge&logo=neovim&logoColor=white)
![ZSH](https://img.shields.io/badge/ZSH-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white)

## Tools and Configurations
- **AeroSpace**: Tiling window manager config.
- **Ghostty**: Terminal emulator (previously Alacritty — config kept in `alacritty/` but not stowed).
- **Neovim**: Kickstart Neovim setup with plugins.
- **SketchyBar**: themeable status bar with five switchable looks (see [SketchyBar themes](#sketchybar-themes)).
- **Tmux**: With TPM and cole-tmux.
- **Zsh**: Oh My Zsh, Powerlevel10k, autosuggestions, syntax highlighting.

## Installation

Requires Homebrew and Xcode Command Line Tools.

```bash
git clone https://github.com/karthikkashyap98/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh            # packages + shell + configs + tmux plugins
./install.sh --all      # also macOS settings and the sketchybar service
```

What each flag does:

| Flag | Effect |
|---|---|
| *(default)* | Brewfile packages, Oh My Zsh + plugins, stow configs, TPM |
| `--macos` | Keyboard repeat, dock autohide + no space reshuffling, tap-to-click, menu bar autohide |
| `--services` | Registers **only** `sketchybar` as a brew service (nothing else) |
| `--all` | Both of the above |

The script is idempotent — safe to re-run.

### Manual steps after install
1. Grant AeroSpace Accessibility permission (System Settings → Privacy & Security → Accessibility), then quit and reopen it.
2. Run `p10k configure` in a fresh shell, or copy your old `~/.p10k.zsh`.
3. `nvm install --lts` when you need Node.

## SketchyBar themes

`sketchybarrc` is only a loader: it sources `themes/<name>.sh`, and the plugins are shared. The design notes for every theme are in [`docs/sketchybar-designs.html`](docs/sketchybar-designs.html).

| Theme | Look |
|---|---|
| `quiet-text` *(default)* | Lowercase text on a blurred strip. Alerts (WARP off, mic live, MRs to review, CPU hog) appear only when they need you. |
| `notch-island` | Black islands and two ears that fuse with the MacBook notch. Shows one centered island on screens without a notch. |
| `glyph-rail` | Two frosted capsules of monochrome glyphs; hover a glyph to reveal its label. |
| `mocha-pills` | Catppuccin Mocha pills with tinted accents. |
| `ops-deck` | Solid black segmented work bar. |
| `classic` | The original Macchiato pill bar (`sketchybarrc-laptop`). |

```bash
sbtheme                # list themes
sbtheme glyph-rail     # switch (saved in ~/.local/state/sketchybar/theme) and reload
```

- **Native helpers**: `install.sh` runs `helpers/build.sh`, which compiles `sbprivacy` (is the mic or camera in use) and `sbdisplays` (which screen has the notch) into the git-ignored `helpers/bin/`. Neither needs any macOS permission. Re-run it after editing `helpers/src`.
- **MR review count (optional)**: the MR segment uses your existing `glab` login. Put the GitLab host in the git-ignored `~/.config/sketchybar/local.env` as `GITLAB_HOST=gitlab.example.com`. Without it, the segment stays hidden. The file is read as data, never sourced.
- **Nothing reads your calendar.** A meeting countdown was tried and removed on purpose.

## Learnings (why things are the way they are)

- **Packages live in `Brewfile`**, not `brew.txt` (kept for history). `brew.txt` had duplicate entries, `amethyst` conflicting with AeroSpace, and was missing `font-jetbrains-mono-nerd-font` — required by the sketchybar config.
- **TPM is bootstrapped manually** (`install.sh` clones it to `~/.tmux/plugins/tpm`). The repo's `tmux/.config/plugins/*` gitlinks have no `.gitmodules`, so `git clone --recurse-submodules` leaves them empty.
- **Powerlevel10k via Homebrew** needs a symlink into `$ZSH_CUSTOM/themes` for Oh My Zsh's `ZSH_THEME="powerlevel10k/powerlevel10k"` lookup to find it.
- **`NVM_DIR` is set explicitly** to `~/.nvm` before sourcing Homebrew's nvm, so installed Node versions survive Homebrew upgrades.
- **`.zshrc` avoids hardcoded usernames** — paths use `$HOME` and feature-guards (`command -v go`, directory checks) so the same config works on any machine.
- **AeroSpace triggers sketchybar with an absolute path** (`/opt/homebrew/bin/sketchybar`): apps launched via launchd don't inherit your shell's `PATH`.
- **No blind services**: `brew services` is used only for sketchybar, and only with `--services`/`--all`.
- **Work-specific values stay out of git**: this repo lives on personal GitHub, so work hostnames and similar go in git-ignored `local.env` files, never in committed config.
- **SketchyBar items with `drawing=off` stop polling** under the default `updates=when_shown`, so they can never turn themselves back on. Alert items set `updates=on`.
- **Each theme prefixes its item names** (`q.`, `glyph.`, `pills.`), so themes never collide with item names other plugins hardcode.
