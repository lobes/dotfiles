#!/usr/bin/env bash

#!/usr/bin/env zsh

set -euo pipefail

cd "$(dirname "${ZSH_SOURCE}")"

function init() {
    return
}

# Create symlinks
files=(
    .zshrc 
    .gitconfig 
    .functions 
    .aliases
    .keybinds
)

for file in "${files[@]}"; do
    if [ ! -L ~/$file ]; then
        if [ -e ~/$file ]; then
            mv ~/$file ~/${file}_old
        fi
        ln -s ${PWD}/$file ~/$file
    fi
done
