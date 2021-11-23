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

    networking.useDHCP = true;

    i18n.supportedLocales = [ "en_GB.UTF-8/UTF-8" ];
    documentation.doc.enable = false;
    security.polkit.enable = false;
    services.udisks2.enable = false;
    xdg.sounds.enable = false;
    nixpkgs.overlays = [ (self: super: {
      firmwareLinuxNonfree = super.firmwareLinuxNonfree.overrideAttrs (o: {
        postInstall = ''
          rm -rf "$out"/lib/firmware/{netronome,qcom,mellanox,mrvl}
        '';
        outputHash = "sha256-jz2isuCebjam9UYHTxzIkPr1u/Jv2mbp/onp3Det1Rk=";
      });
    }) ];

    system.stateVersion = "21.11";
  };
}
