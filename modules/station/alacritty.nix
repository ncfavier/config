{ lib, config, pkgs, pkgsPR, ... }: with lib; {
  hm.programs.alacritty = {
    enable = true;
    package = (pkgsPR 132544 "sha256-1vQGoc1LFT7ky81gwYkUZEpdJHPPSkkTSL2iXRahW1c=").alacritty;
    settings = with config.theme; {
      window = {
        dimensions = {
          columns = 80;
          lines = 25;
        };
        padding = {
          x = padding;
          y = padding;
        };
        decorations = "none";
      };
      font = {
        normal.family = font;
        size = 7;
      };
      colors = {
        primary = {
          inherit background foreground;
        };
        normal = {
          black   = background;
          red     = hot;
          green   = cold;
          yellow  = hot;
          blue    = cold;
          magenta = hot;
          cyan    = cold;
          white   = darkGrey;
        };
        bright = {
          black   = lightGrey;
          red     = hot;
          green   = cold;
          yellow  = hot;
          blue    = cold;
          magenta = hot;
          cyan    = cold;
          white   = foreground;
        };
      };
      selection.save_to_clipboard = true;
      cursor.style.blinking = "Always";
      key_bindings = [
        { key =  3; mods = "Alt"; chars = "\\e2"; }
        { key =  8; mods = "Alt"; chars = "\\e7"; }
        { key = 10; mods = "Alt"; chars = "\\e9"; }
        { key = 11; mods = "Alt"; chars = "\\e0"; }
      ];
    };
  };

  # nixpkgs.overlays = [ (self: super: {
  #   alacritty = super.alacritty.override {
  #     rustPlatform = super.rustPlatform // {
  #       buildRustPackage = o:
  #         super.rustPlatform.buildRustPackage (removeAttrs o [ "cargoSha256" ] // {
  #           cargoHash = "sha256-WRe4cGatWvUEF1IJ7Bucav+ROtNqWZ4thoYw5QHye+0=";
  #           version = "0.9.0";
  #           src = self.fetchFromGitHub {
  #             owner = "ncfavier";
  #             repo = "alacritty";
  #             rev = "live";
  #             sha256 = "i3YJaXFxjHw3q9lPqFXH522rMVdKWjmcuqP3Pip0LD0=";
  #           };
  #         });
  #     };
  #   };
  # }) ];

  # hm.xdg.configFile."alacritty/alacritty.yml".onChange = ''
  #   ${pkgs.procps}/bin/pkill ''${VERBOSE+-e} -USR1 -x alacritty
  # '';
}
