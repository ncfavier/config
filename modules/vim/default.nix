{ pkgs, lib, ... }: {
  environment.sessionVariables.EDITOR = "vim";

  myHm.programs.vim = {
    enable = true;
    plugins = with pkgs.vimPlugins; lib.mkForce [
      nerdtree
      nerdcommenter
      vim-surround
      vim-easy-align
      vim-markdown
      haskell-vim
      vim-nix
    ];
    extraConfig = builtins.readFile ./rc.vim;
  };
}
