{ lib, this, pkgs, ... }: with lib; optionalAttrs this.isServer {
  imports = attrValues (modulesIn ./.);
}
