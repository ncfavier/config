{ lib, here, pkgs, ... }: lib.optionalAttrs here.isServer {
  imports = builtins.attrValues (lib.importDir ./.);

  environment.systemPackages = [
    pkgs.alacritty.terminfo
  ];
}
