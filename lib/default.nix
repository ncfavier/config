lib: prev: with lib; {
  # Collects the top-level modules in a directory into an attribute set of paths.
  # A module `foo` can be either a file (`foo.nix`) or a directory (`foo/default.nix`).
  modulesIn = dir: pipe dir [
    builtins.readDir
    (mapAttrsToList (name: type:
      if type == "regular" && hasSuffix ".nix" name && name != "default.nix" then
        [ { name = removeSuffix ".nix" name; value = dir + "/${name}"; } ]
      else if type == "directory" && pathExists (dir + "/${name}/default.nix") then
        [ { inherit name; value = dir + "/${name}"; } ]
      else
        []
    ))
    concatLists
    listToAttrs
  ];

  my = import ./my.nix lib;
}
