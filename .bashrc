#!/usr/bin/env bash

# -- variables -- #
REPO_ROOT=~/code

# -- functions -- #

# Git clone using `user/repo` pair then enter repo
function gccd() {
  IFS='/' read -r user repo <<<"$1"
  cd ${REPO_ROOT}
  git clone git@github.com:$user/$repo
  cd $repo
}

# Add new alias to .bashrc and reload
function na() {
  from=$1
  to=$2

  echo "alias $1=$2" >>~/.bashrc
  source ~/.bashrc
}

# Argument: "in" for REPO_ROOT to HOME, "out" for HOME to REPO_ROOT
function syncDotfiles() {
  direction=$1
  src=""
  dest=""

  if [[ "$direction" == "in" ]]; then
    src="${REPO_ROOT}/dotfiles/"
    dest="~/"
  elif [[ "$direction" == "out" ]]; then
    src="~/"
    dest="${REPO_ROOT}/dotfiles/"
  else
    echo "Invalid direction. Use 'in' or 'out'."
    return 1
  fi

  # Create archive directory
  ARCHIVE=mktemp -d

  # Perform a dry run to identify files that would be overwritten
  # todo: use --include instead of --exclude
  rsync --dry-run --delete \
    --exclude ".git/" \
    --exclude ".DS_Store" \
    --exclude ".macOS" \
    --exclude "bootstrap.sh" \
    --exclude "README.md" \
    --exclude "LICENSE" \
    -avh --no-perms $src $dest | grep 'deleting' | awk '{print $2}' >delete_list.txt

  # Move files that would be overwritten to the archive directory
  while IFS= read -r line; do
    mv ~/"$line" "$ARCHIVE/"
  done <delete_list.txt

  # Perform actual sync
  rsync \
    --exclude ".git/" \
    --exclude ".DS_Store" \
    --exclude ".macOS" \
    --exclude "bootstrap.sh" \
    --exclude "README.md" \
    --exclude "LICENSE" \
    -avh --no-perms $src $dest

  # Clean up
  rm delete_list.txt
  echo "Archived overwritten files to $ARCHIVE"
  source ~/.bashrc
}
# -- aliases -- #

alias ls="exa"
alias ll="exa -alh"
alias tree="exa --tree"

alias cd="z"
alias zz="z -"

alias cat="bat -p"
