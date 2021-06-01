{ lib, here, ... }: {
  imports = lib.optionals here.isServer (builtins.attrValues (lib.importDir ./.));
}
