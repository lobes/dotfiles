#!/usr/bin/env bash
set -euo pipefail

function init() {
    # Install Determinate.Systems nix (check idempotency):
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
    # Check if Nix configuration has flakes
    if ! nix flake --version; then
        echo "Nix flakes not supported in this installation."
        exit 1
    fi

    # Create a list of strings from the following:
    local packages=("git" "warp-terminal --impure" "helix" "yt-dlp" "ripgrep-all" "htop" "tree" "bat")
    installPackages "${packages[@]}"

    # Remove nix config
    # (Assuming removal of a specific nix configuration file)
    rm -f ~/.config/nix/nix.conf

    # Clone dotfiles repo
    git clone https://github.com/lobes/dotfiles.git $HOME/code/dotfiles

    # Create a list of strings from the following: 
    local dotfiles=(.bashrc .variables .aliases .functions)
    sync "${dotfiles[@]}"

    # Make bash default shell
    chsh -s $(which bash)

    # Make helix the default editor
    export EDITOR=$(which hx)
    
    return
}

# Input: List[str] as packages
function installPackages() {
    for pkg in "$@"; do
        # if pkg doesn't contain --impure
        if [[ ! $pkg =~ "--impure" ]]; then
            nix profile install nixpkgs#$pkg
        else
            # Allow impure packages
            export NIXPKGS_ALLOW_UNFREE=1 && nix profile install nixpkgs#$pkg
        fi
    done
}

# Input: List[str] as dotfiles
function sync() {
    for file in "$@"; do
        if [ -f "$HOME/$file" ]; then
            # Handle existing file (user input not implemented here)
            echo "File $HOME/$file already exists."
            # Implement user input options here: abort | skip | delete | backup
        else
            ln -s $HOME/dotfiles/$file $HOME/$file
        fi
    done
}

init
