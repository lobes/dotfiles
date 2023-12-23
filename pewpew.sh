#!/usr/bin/env bash
set -euo pipefail

# gimmie-the-cashhh.gif
sudo -v

# hold-girdle.gif
while ((counter > 0)); do
  sudo -n true
  sleep 60
  kill -0 "$$" || exit
done 2>/dev/null &

# - EXECUTE THIS SCRIPT FROM YOUR REPO/PROJECT DIR - #
# todo: make the thing do the thing to removed neeed for ^
code="${HOME}/code"

function init() {
  echo "[SUP] :: TURN AND BURN!!!"
  echo "[SUP] :: Installing Nix..."
  # Install the Determinate.Systems (DS) nix because it doesn't break on macOS updates
  if [ ! -d "/nix" ]; then
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
  else
    # No `update` branch.
    # Would require an uninstall (can't find commands for that), then rerun
    echo "[YO]  :: /nix already exists -> skipping install"
  fi
  # Nix configuration must use flakes
  if ! nix flake --version; then
    echo "[OI]  :: Nix flakes not supported in this installation -> Go Fix It."
    exit 1
  fi

  # Nix as package manager:
  local packages=(
    ## ORDER MATTERS ##
    "bash"
    "git"
    ## REPO/PROD/ENV/BUILD SHIT ##
    "direnv"
    "nix-direnv"
    "helix"
    "just"
    ## CLI QOL ##
    "alacritty"
    "tmux"
    "ripgrep" # grep replacement
    "htop"
    "bat" # cat replacement
    "jq"
    "thefuck"
    "eza" # ls replacement
    "fzf"
    "zoxide" # cd replacement
    "rsync"
    "ranger" # console file manager
    ## CLI SERVICES ##
    "entr"
    "yt-dlp"
    "bitwarden-cli"
    "transmission"
    ## MISC. ##
    "obsidian --impure"
    ## ELM ##
    "elmPackages.elm"
    "elmPackages.elm-live"
    "elmPackages.elm-review"
    "elmPackages.elm-format"
    "elmPackages.elm-language-server"
    ## RUST ##
    "rustup"
    "rust-analyser"
    "cargo-zigbuild"
    ## HASKELL ##
  )
  installPackages "${packages[@]}"

  # Add nix-direnv to direnvrc
  source $HOME/.nix-profile/share/nix-direnv/direnvrc

  # Remove nix config because we use the one in the repo
  rm -f ~/.config/nix/nix.conf

  # Clone or update dotfiles repo
  if [ ! -d "${code}/dotfiles" ]; then
    git clone https://github.com/lobes/dotfiles.git ${code}/dotfiles
  else
    cd "${code}/dotfiles"
    git pull origin main
  fi

  # todo: call syncDotfiles() and pass in the paths of the dotfiles you want to sync

  # todo: figure out how to hush the stupid "default interactive shell is now zsh"
  # Add nix bash to standard shell list
  if ! grep -q ".nix-profile/bin/bash" /etc/shells; then
    sudo bash -c "echo '${HOME}/.nix-profile/bin/bash' >> /etc/shells"
  fi
  # Make bash default shell
  if [[ $(which sh) != *".nix-profile"* ]]; then
    chsh -s "${HOME}/.nix-profile/bin/bash"
  fi
  # Make helix the default editor
  export EDITOR=$(which hx)

  return
}

#:: List[packageName] -> packages
function installPackages() {
  for pkg in "$@"; do
    # Have to fernagle some shit if you want "impure" programs (Obsidian)

    if [[ ! $pkg =~ "--impure" ]]; then
      nix profile install nixpkgs#$pkg
    else
      # Allow impure packages
      export NIXPKGS_ALLOW_UNFREE=1 && nix profile install nixpkgs#$pkg
    fi
  done
}

init || exit 1
