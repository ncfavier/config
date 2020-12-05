{ me, configPath, ... }: {
  home-manager.users.${me}.programs = {
    bash = {
      enable = true;
      shellAliases = {
        config = "sudo nixos-rebuild --flake ${configPath} -v";
      };
    };

    readline = {
      enable = true;
      bindings = {
        "\\e[A" = "history-search-backward";
        "\\e[B" = "history-search-forward";
      };
    };
  };
}
