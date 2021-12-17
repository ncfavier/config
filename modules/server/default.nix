{ lib, here, pkgs, ... }: with lib; optionalAttrs here.isServer {
  imports = attrValues (modulesIn ./.);
}
