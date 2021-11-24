{ lib, pkgs, ... }: with lib; {
  programs.vim = {
    defaultEditor = true;
    package = pkgs.vim_configurable;
  };

  hm.programs.vim = {
    enable = true;
    plugins = with pkgs.vimPlugins; mkForce [
      nerdtree
      nerdcommenter
      vim-surround
      vim-easy-align
      vim-bracketed-paste
      vim-markdown
      haskell-vim
      vim-nix
      Coqtail
    ];
    extraConfig = readFile ./rc.vim;
  };
}
