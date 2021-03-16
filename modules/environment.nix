{ pkgs, ... }: {
  environment = {
    systemPackages = with pkgs; [
      manpages
      ripgrep
      tree
      ncdu
      file
      gnumake
      jq
      python3
    ];

    sessionVariables = rec {
      LESS = "ij3FRMK --mouse --wheel-lines=4";
      SYSTEMD_LESS = LESS;
      MANOPT = "--no-hyphenation";
      MANPAGER = "less -+F";
      NIX_SHELL_PRESERVE_PROMPT = "1";
    };

    etc.topdefaultrc.source = ./toprc;
  };

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
