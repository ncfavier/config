lib: prev: {
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
}
