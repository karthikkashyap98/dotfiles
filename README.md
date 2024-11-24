# Dotfiles
<img width="1680" alt="image" src="https://github.com/user-attachments/assets/26f5f3de-79b0-451d-b927-1bd3c5c02140">

## Tools and Configurations
- **Aerospace**: Tiling Window Manager config.
- **Alacritty**: Terminal emulator configuration.
- **Neovim**: Kickstart Neovim setup with plugins.
- **SketchyBar**: macOS status bar customizations.
- **Zsh**: Shell configuration and aliases.

## Installation Guide
Clone the repository:
```bash
git clone https://github.com/yourusername/dotfiles.git
cd dotfiles
```

Install the necessary tools listed in brew.txt using Homebrew:
```bash
xargs brew install < brew.txt
```

Use the dotfile manager, GNU Stow, to symlink the configurations:
stow <tool-name>


> Note: Homebrew and Zsh must be installed **before** proceeding with the setup.


