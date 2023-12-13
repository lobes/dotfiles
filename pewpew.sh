#!/usr/bin/env bash
set -euo pipefail

# - EXECUTE THIS SCRIPT FROM YOUR REPO/PROJECT DIR - #
code="~/code"

function init() {
    # Install Determinate.Systems nix:
    if [ ! -d "/nix" ]; then
        curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
    else
        echo "/nix directory already exists, skipping install"
    fi
    # Check if Nix configuration has flakes
    if ! nix flake --version; then
        echo "Nix flakes not supported in this installation."
        exit 1
    fi

    # The goods: #cmd
    local packages=(
        "git" #git
        "warp-terminal --impure"
        "helix"      #hx
        "yt-dlp"     #yt-dlp
        "ripgrep"    #rg
        "htop"       #htop
        "tree"       #tree
        "bat"        #bat
        "nix-direnv" #direnv
        "obsidian --impure"
        "just"          #just
        "bitwarden-cli" #bw
        "bash"          #sh
    )
    installPackages "${packages[@]}"

    # Add nix-direnv to direnvrc
    source $HOME/.nix-profile/share/nix-direnv/direnvrc

    # Remove nix config because we use the one in the repo
    rm -f ~/.config/nix/nix.conf

    # Clone dotfiles repo
    if [ ! -d "${code}/dotfiles" ]; then
        git clone https://github.com/lobes/dotfiles.git ${code}/dotfiles
    fi

    local dotfiles=(
        ".bashrc"
        ".variables"
        ".aliases"
        ".functions"
        ".config/helix/config.toml"
        ".config/htop/htoprc"
        ".config/nix/nix.conf"
    )
    sync "${dotfiles[@]}"

    # Make bash default shell
    if ! grep -q ".nix-profile/bin/bash" /etc/shells; then
        sudo bash -c "echo '${HOME}/.nix-profile/bin/bash' >> /etc/shells"
    fi
    chsh -s "${HOME}/.nix-profile/bin/bash"

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
        # Extract the directory from the file path
        local dir=$(dirname "$code/dotfiles/$file")

        # Check if the directory exists, if not create it
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            echo "Created directory $dir."
        fi

        if [ -f "$HOME/$file" ]; then
            echo "File $HOME/$file already exists."

            # Prompt for user input
            while true; do
                read -p "Choose action for $HOME/$file: [a]bort | [s]kip | [D]elete | [b]ackup: " action
                action=${action:-d} # Set default to 'd' if input is empty

                case $action in
                "a")
                    echo "Sync aborted."
                    return 1
                    ;;
                "s")
                    echo "Skipping $HOME/$file."
                    break
                    ;;
                "d")
                    rm "$HOME/$file"
                    ln -s "$code/dotfiles/$file" "$HOME/$file"
                    echo "Deleted and created symlink for $HOME/$file."
                    break
                    ;;
                "b")
                    mv "$HOME/$file" "$HOME/${file}.backup"
                    ln -s "$code/dotfiles/$file" "$HOME/$file"
                    echo "Backup created and symlink set for $HOME/$file."
                    break
                    ;;
                *)
                    echo "Invalid option. Please enter 'a' to abort, 's' to skip, 'd' to delete, or 'b' to backup."
                    ;;
                esac
            done
        else
            ln -s "$code/dotfiles/$file" "$HOME/$file"
            echo "Symlink created for $HOME/$file."
        fi
    done
}

init || exit 1
