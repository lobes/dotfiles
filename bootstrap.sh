#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE}")"

function init() {
    
}
# Create symlinks
ln -s ${PWD}/.zshrc ~/.zshrc
ln -s ${PWD}/.gitconfig ~/.gitconfig