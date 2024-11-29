# Dotfiles
![Debian](https://img.shields.io/badge/Debian-D70A53?style=for-the-badge&logo=debian&logoColor=white)
![MacOS](https://img.shields.io/badge/MacOS-8e8e93.svg?style=for-the-badge&logo=apple&logoColor=white)
![i3WM](https://img.shields.io/badge/i3WM-2e3440?style=for-the-badge&logo=i3&logoColor=white)
![Sketchybar](https://img.shields.io/badge/Sketchybar-2c3e50?style=for-the-badge&logoColor=white)
![Aerospace](https://img.shields.io/badge/Aerospace-black?style=for-the-badge&logo=gnometerminal&logoColor=white)
![Alacritty](https://img.shields.io/badge/Alacritty-F46D01?style=for-the-badge&logo=alacritty&logoColor=white)
![Neovim](https://img.shields.io/badge/neovim-%252357A143.svg?style=for-the-badge&logo=neovim&logoColor=white)
![ZSH](https://img.shields.io/badge/ZSH-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white)

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


