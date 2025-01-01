{ inputs, lib, this, config, pkgs, ... }: with lib; {
  imports = [
    inputs.sops-nix.nixosModules.default
    (mkAliasOptionModule [ "secrets" ] [ "sops" "secrets" ])
  ];

  system.extraDependencies = collectFlakeInputs inputs.sops-nix;

  sops = {
    gnupg.sshKeyPaths = [];
    age.sshKeyPaths = [ "${config.my.home}/.ssh/id_ed25519" ];

    secrets = let
      secretsDir = "${inputs.self}/secrets";
    in mapAttrs' (name: _: let
      parts = splitString "." name;
      base = head parts;
      format = if length parts > 1 then elemAt parts 1 else "binary";
    in nameValuePair base {
      sopsFile = "${secretsDir}/${name}";
      inherit format;
      key = this.hostname;
    }) (builtins.readDir secretsDir);
  };

  my.extraGroups = [ "keys" ];

  environment = {
    systemPackages = [ pkgs.sops pkgs.age ];
  };

  hm = {
    programs.password-store = {
      enable = true;
      package = pkgs.pass.withExtensions (e: [ e.pass-otp ]);
    };

    xdg.dataFile.password-store.source =
      config.hm.lib.file.mkOutOfStoreSymlink config.synced.password-store.path;
  };

  nix.settings = {
    substituters = [ "https://mic92.cachix.org" ];
    trusted-public-keys = [ "mic92.cachix.org-1:gi8IhgiT3CYZnJsaW7fxznzTkMUOn1RY4GmXdT/nXYQ=" ];
  };
}
