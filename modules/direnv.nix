{
  hm = {
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
}
