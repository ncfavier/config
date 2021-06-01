{ lib, here, ... }: {
  imports = if here.isServer then builtins.attrValues (lib.importDir ./.) else [ ];
}
