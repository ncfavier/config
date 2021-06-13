{ pkgs, lib, here, ... }: lib.optionalAttrs here.isServer {
  imports = builtins.attrValues (lib.importDir ./.);

  environment.systemPackages = [
    pkgs.alacritty.terminfo
  ];
}
