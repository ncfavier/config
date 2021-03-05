{
  myHm = {
    programs.direnv = {
      enable = true;
      enableNixDirenvIntegration = true;
      config = {
        global.warn_timeout = "42h";
      };
      stdlib = ''
        base=''${XDG_CACHE_HOME:=$HOME/.cache}/direnv/layouts
        mkdir -p "$base"
        direnv_layout_dir() {
            printf '%s\n' "$base/$(shasum <<< "$PWD" | cut -d ' ' -f 1)"
        }
      '';
    };

    home.sessionVariables.DIRENV_LOG_FORMAT = "";
  };
}
