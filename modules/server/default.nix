{ lib, here, pkgs, ... }: with lib; optionalAttrs here.isServer {
  imports = attrValues (importDir ./.);

  environment.systemPackages = [
    pkgs.alacritty.terminfo
  ];
}
