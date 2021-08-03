inputs: lib: prev: with lib; {
  importDir = dir: pipe dir [
    builtins.readDir
    (mapAttrsToList (name: type:
      if type == "regular" && hasSuffix ".nix" name && name != "default.nix" then
        [ { name = removeSuffix ".nix" name; value = import (dir + "/${name}"); } ]
      else if type == "directory" && pathExists (dir + "/${name}/default.nix") then
        [ { inherit name; value = import (dir + "/${name}"); } ]
      else
        []
    ))
    concatLists
    listToAttrs
  ];

  exportToBash = vars: concatStringsSep "\n" (mapAttrsToList (name: value:
    if isAttrs value then
      "declare -A ${name}=(${
        concatStringsSep " " (mapAttrsToList (n: v:
          "[${escapeShellArg n}]=${escapeShellArg v}"
        ) value)
      })"
    else if isList value then
      "declare -a ${name}=(${escapeShellArgs value})"
    else
      "declare -- ${name}=${escapeShellArg value}"
  ) vars);

  my = import ./my.nix inputs lib;
}
