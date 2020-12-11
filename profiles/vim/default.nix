{ pkgs, lib, me, ... }: {
  #programs.vim = {
  #  defaultEditor = true;
  #  package = pkgs.vim_configurable.customize {
  #    name = "vim";
  #    vimrcConfig = {
  #      packages.plugins.start = with pkgs.vimPlugins; [
  #        nerdtree
  #        nerdcommenter
  #        vim-surround
  #        vim-easy-align
  #        colorizer
  #        vim-markdown
  #        vim-nix
  #      ];
  #      customRC = ''
  #      '';
  #    };
  #  };
  #};
  environment.sessionVariables.EDITOR = "vim";

  home-manager.users.${me}.programs.vim = {
    enable = true;
    plugins = with pkgs.vimPlugins; lib.mkForce [
      nerdtree
      nerdcommenter
      vim-surround
      vim-easy-align
      colorizer
      vim-markdown
      vim-nix
    ];
    extraConfig = builtins.readFile ./rc.vim;
  };
}
