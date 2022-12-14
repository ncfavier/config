{ lib, pkgs, ... }: with lib; {
  hm = {
    programs.vim = {
      enable = true;
      plugins = with pkgs.vimPlugins; mkForce [
        ctrlp
        nerdtree
        nerdcommenter
        vim-sleuth
        vim-surround
        vim-easy-align
        vim-bracketed-paste
        vim-markdown
        haskell-vim
        vim-nix
        Coqtail
        coc-nvim
        agda-vim
      ];
      extraConfig = readFile ./rc.vim;
    };

    home.sessionVariables.EDITOR = "vim"; # TODO https://github.com/nix-community/home-manager/pull/3496

    home.packages = [ pkgs.nodejs ]; # for coc
    home.file.".vim/coc-settings.json".text = builtins.toJSON {
      languageserver = {
        disabledFeatures = [ "completion" ];
        nix = {
          command = "rnix-lsp";
          filetypes = [ "nix" ];
        };
      };
    };
  };
}
