{ pkgs, ... }: {
  environment = {
    systemPackages = with pkgs; [
      ripgrep
    ];

    variables = rec {
      LESS = "ij3FRMK --mouse --wheel-lines=4";
      SYSTEMD_LESS = LESS;
    };
  };

  programs = {
    vim.defaultEditor = true;
  };
}
