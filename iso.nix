{ inputs, lib, modulesPath, ... }: with lib; {
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal-new-kernel.nix"
    inputs.self.nixosModules.networking
    inputs.self.nixosModules.home-manager
    inputs.self.nixosModules.users
    inputs.self.nixosModules.localisation
    inputs.self.nixosModules.console
    inputs.self.nixosModules.shell
    inputs.self.nixosModules.gpg
    inputs.self.nixosModules.git
    inputs.self.nixosModules.cachix
  ];

  options = {
    secrets = mkSinkUndeclaredOptions {};
    nix.gcRoots = mkSinkUndeclaredOptions {};
    boot.supportedFilesystems = mkOption {
      apply = subtractLists [ "zfs" "btrfs" "reiserfs" "xfs" "cifs" "f2fs" ];
    };
  };

  config = {
    services.getty = {
      helpLine = mkForce "";
      autologinUser = mkForce my.username;
    };

    nix.extraOptions = ''
      experimental-features = nix-command flakes ca-references ca-derivations
      warn-dirty = false
    '';

    system.stateVersion = "21.11";
  };
}
