{
  myHm = {
    programs.direnv = {
      enable = true;
      enableNixDirenvIntegration = true;
      config = {
        global.warn_timeout = "999h";
      };
      stdlib = ''
        # store .direnv outside of the project directory
        base=''${XDG_CACHE_HOME:=$HOME/.cache}/direnv/layouts
        mkdir -p "$base"
        direnv_layout_dir() {
            printf '%s\n' "$base/$(printf '%s' "$PWD" | shasum | cut -d ' ' -f 1)"
        }
      '';
    };

    home.sessionVariables.DIRENV_LOG_FORMAT = "";
  };

  nixpkgs.overlays = [
    (self: super: {
      nix-direnv = super.nix-direnv.overrideAttrs (_: rec {
        version = "912b847b4d1ce7d41b41b796e1bcdebc14a4bc45";
        src = self.fetchFromGitHub {
          owner = "nix-community";
          repo = "nix-direnv";
          rev = version;
          sha256 = "sha256-0Se7g5ez061nZMUH+nyziTvdAMBG9pEs2FuYpcI9RqM=";
        };
      });
    })
  ];
}
