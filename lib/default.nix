machines: lib: prev: with lib; {
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

  # Like modulesIn, but imports the files.
  exprsIn = dir: mapAttrs (_: f: import f) (modulesIn dir);

  # Like catAttrs, but operates on an attribute set of attribute sets
  # instead of a list of attribute sets.
  catAttrs' = key: set:
    listToAttrs (concatMap (name:
      let v = set.${name}; in
      if v ? ${key} then [(nameValuePair name v.${key})] else []
    ) (attrNames set));


  # Collects the inputs of a flake recursively (with possible duplicates).
  collectFlakeInputs = input:
    [ input ] ++ concatMap collectFlakeInputs (builtins.attrValues (input.inputs or {}));

  # Gets all the outputs of a derivation as a list.
  getAllOutputs = drv:
    if drv ? outputs then attrVals drv.outputs drv else [ drv ];

  versionAtMost = a: b: versionAtLeast b a;

  # Creates a simple module with an `enable` option.
  mkEnableModule = name: cfg: {
    options = setAttrByPath name { enable = mkEnableOption (last name); };
    imports = cfg.imports or [] ++ [
      ({ config, ... }: { config = mkIf (getAttrFromPath name config).enable (removeAttrs cfg [ "imports" ]); })
    ];
  };

  my = import ./my.nix lib machines;
}
