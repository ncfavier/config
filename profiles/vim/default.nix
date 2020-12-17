{ pkgs, lib, me, ... }: {
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
      haskell-vim
      vim-nix
    ];
    extraConfig = builtins.readFile ./rc.vim;
  };
}
