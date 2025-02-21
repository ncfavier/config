{ pkgs, ... }: {
  hm.programs.emacs = {
    enable = true;
    package = pkgs.emacs-gtk;
    extraPackages = epkgs: [ epkgs.agda2-mode ];
  };
}
