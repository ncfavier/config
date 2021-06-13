{ pkgs, lib, ... }: {
  programs.vim = {
    defaultEditor = true;
    package = pkgs.vim_configurable.customize {
      name = "vim";
      wrapGui = true;
      vimrcConfig = {
        customRC = builtins.readFile ./rc.vim;
        packages.default.start = with pkgs.vimPlugins; [
          nerdtree
          nerdcommenter
          vim-surround
          vim-easy-align
          vim-markdown
          haskell-vim
          vim-nix
          # TODO vim-bracketed-paste https://nixpk.gs/pr-tracker.html?pr=126610
        ];
      };
    };
  };

  environment.systemPackages = [ (lib.lowPrio pkgs.vim_configurable) ];
}
