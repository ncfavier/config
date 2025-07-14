{ inputs, lib, this, config, pkgs, ... }: with lib; {
  imports = [
    inputs.sops-nix.nixosModules.default
    (mkAliasOptionModule [ "secrets" ] [ "sops" "secrets" ])
  ];

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

  hm = mkMerge [
    {
      home.activation.generateAgeKeyfile = ''
        mkdir -p "''${XDG_CONFIG_HOME:-$HOME/.config}/sops/age"
        ${getExe pkgs.ssh-to-age} -private-key -i ${head config.sops.age.sshKeyPaths} > "''${XDG_CONFIG_HOME:-$HOME/.config}/sops/age/keys.txt" || true
      '';
    }

    (mkIf config.services.syncthing.enable {
      programs.password-store = {
        enable = true;
        package = pkgs.pass.withExtensions (e: [ e.pass-otp ]);
      };

      xdg.dataFile.password-store.source =
        config.hm.lib.file.mkOutOfStoreSymlink config.synced.password-store.path;
    })
  ];

  nix.settings = {
    substituters = [ "https://mic92.cachix.org" ];
    trusted-public-keys = [ "mic92.cachix.org-1:gi8IhgiT3CYZnJsaW7fxznzTkMUOn1RY4GmXdT/nXYQ=" ];
  };
}
