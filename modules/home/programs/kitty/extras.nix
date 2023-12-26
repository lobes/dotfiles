{ config, lib, pkgs, ... }:


let
  inherit (lib) generators concatStringsSep mkIf mkOption optionalAttrs types;

  cfg = config.programs.kitty.extras;

  # Create a Kitty config string from a Nix set
  setToKittyConfig = with generators; toKeyValue { mkKeyValue = mkKeyValueDefault { } " "; };

  # Write a Nix set representing a kitty config into the Nix store
  writeKittyConfig = fileName: config: pkgs.writeTextDir "${fileName}" (setToKittyConfig config);

  # Path in Nix store containing light and dark kitty color configs
  kitty-colors = pkgs.symlinkJoin {
    name = "kitty-colors";
    paths = [
      (writeKittyConfig "dark-colors.conf" cfg.colors.dark)
      (writeKittyConfig "light-colors.conf" cfg.colors.light)
    ];
  };

  # Shell scripts for changing Kitty colors
  term-background = pkgs.writeShellScriptBin "term-background" ''
    # Accepts arguments "light" or "dark". If shell is running in a Kitty window set the colors.
    if [ -n "$KITTY_WINDOW_ID" ]; then
      kitty @ --to $KITTY_LISTEN_ON set-colors --all --configured \
        ${kitty-colors}/"$1"-colors.conf &
    fi
  '';
  term-light = pkgs.writeShellScriptBin "term-light" ''
    ${term-background}/bin/term-background light
  '';
  term-dark = pkgs.writeShellScriptBin "term-dark" ''
    ${term-background}/bin/term-background dark
  '';

  socket = "unix:/tmp/mykitty";

in
{

  options.programs.kitty.extras = {
    colors = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          When enable, commands <command>term-dark</command> and <command>term-light</command> will
          toggle between your dark and a light colors.

          <command>term-background</command> which accepts one argument (the value of which should
          be <literal>dark</literal> or <literal>light</literal>) is also avaible.

          (Note that the Kitty setting <literal>allow_remote_control = true</literal> is set to
          enable this functionality.)
        '';
      };

      dark = mkOption {
        type = with types; attrsOf str;
        default = { };
        description = ''
          Kitty color settings for dark background colorscheme.
        '';
      };

      light = mkOption {
        type = with types; attrsOf str;
        default = { };
        description = ''
          Kitty color settings for light background colorscheme.
        '';
      };

      common = mkOption {
        type = with types; attrsOf str;
        default = { };
        description = ''
          Kitty color settings that the light and dark background colorschemes share.
        '';
      };

      default = mkOption {
        type = types.enum [ "dark" "light" ];
        default = "dark";
        description = ''
          The colorscheme Kitty opens with.
        '';
      };
    };

  };

  config = mkIf config.programs.kitty.enable {

    home.packages = mkIf cfg.colors.enable [
      term-light
      term-dark
      term-background
    ];

    programs.kitty.settings = optionalAttrs cfg.colors.enable
      (
        cfg.colors.common // cfg.colors.${cfg.colors.default} // {
          allow_remote_control = "yes";
          listen_on = socket;
        }
      );

    programs.kitty.darwinLaunchOptions = mkIf pkgs.stdenv.isDarwin [
      "--listen-on ${socket}"
    ];

  };

}
