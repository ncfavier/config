{ inputs, lib, modulesPath, pkgs, ... }: with lib; {
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
    inputs.self.nixosModules.home-manager
    inputs.self.nixosModules.users
    inputs.self.nixosModules.localisation
    inputs.self.nixosModules.console
    inputs.self.nixosModules.shell
    inputs.self.nixosModules.gpg
    inputs.self.nixosModules.git
    inputs.self.nixosModules.cachix
  ];

  options.secrets = mkSinkUndeclaredOptions {};

  config = {
    services.getty = {
      helpLine = mkForce "";
      autologinUser = mkForce my.username;
    };

    nix = {
      package = pkgs.nixFlakes;
      extraOptions = ''
        experimental-features = nix-command flakes ca-references ca-derivations
        warn-dirty = false
      '';
    };

    system.stateVersion = "21.05";
  };
}
