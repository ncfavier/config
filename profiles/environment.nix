# TODO reorganise environment.nix
{ pkgs, me, ... }: {
  environment = {
    systemPackages = with pkgs; [
      ripgrep
    ];

    variables = rec {
      LESS = "ij3FRMK --mouse --wheel-lines=4";
      SYSTEMD_LESS = LESS;
      MANOPT = "--no-hyphenation";
      MANPAGER = "less -+F";
      NIX_SHELL_PRESERVE_PROMPT = "1";
    };
  };

  # programs.command-not-found = {
  #   enable = true;
  #   dbPath = "${fetchTarball "channel:nixos-unstable"}/programs.sqlite";
  # };

  home-manager.users.${me} = {
    programs.htop = {
      enable = true;
      colorScheme = 1;
      treeView = true;
    };

    home.file.".hushlogin".text = "";
  };
}
