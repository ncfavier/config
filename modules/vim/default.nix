{ lib, pkgs, ... }: with lib; {
  programs.vim = {
    defaultEditor = true;
    package = pkgs.vim_configurable.customize {
      name = "vim";
      wrapGui = true;
      vimrcConfig = {
        customRC = readFile ./rc.vim;
        packages.default.start = with pkgs.vimPlugins; [
          nerdtree
          nerdcommenter
          vim-surround
          vim-easy-align
          vim-markdown
          haskell-vim
          vim-nix
          vim-bracketed-paste
        ];
      };
    };
  };

  environment.systemPackages = [ (lowPrio pkgs.vim_configurable) ];
}
