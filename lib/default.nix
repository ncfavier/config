lib: prev: {
  my = import ./my.nix lib;

  theme = import ./theme.nix;

  importDir = dir: lib.pipe dir [
    builtins.readDir
    (lib.mapAttrsToList (name: type:
      if type == "regular" && lib.hasSuffix ".nix" name && name != "default.nix" then
        [ { name = lib.removeSuffix ".nix" name; value = import (dir + "/${name}"); } ]
      else if type == "directory" && builtins.pathExists (dir + "/${name}/default.nix") then
        [ { inherit name; value = import (dir + "/${name}"); } ]
      else
        []
    ))
    builtins.concatLists
    builtins.listToAttrs
  ];

  exportToShell = vars: lib.concatStringsSep "\n" (lib.mapAttrsToList (name: value:
    if lib.isAttrs value then
      "declare -A ${name}=(${
        lib.concatStringsSep " " (lib.mapAttrsToList (n: v:
          "[${lib.escapeShellArg n}]=${lib.escapeShellArg v}"
        ) value)
      })"
    else if lib.isList value then
      "declare -a ${name}=(${lib.escapeShellArgs value})"
    else
      "declare -- ${name}=${lib.escapeShellArg value}"
  ) vars);
}
