# TODO {environment,bash}.nix -> shell.nix?
{ pkgs, ... }: {
  environment = {
    systemPackages = with pkgs; [
      manpages
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

  # TODO automatically add channel
  # programs.command-not-found = {
  #   enable = true;
  #   dbPath = "${fetchTarball "channel:nixos-unstable"}/programs.sqlite";
  # };

  # TODO top

  myHm = {
    programs.htop = {
      enable = true;
      colorScheme = 1;
      treeView = true;
    };

    home.file.".hushlogin".text = "";
  };

  documentation.dev.enable = true;
}
