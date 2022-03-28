{ lib, modulesPath, ... }: with lib; {
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal-new-kernel.nix"
    modules/networking.nix
    modules/home-manager.nix
    modules/users.nix
    modules/localisation.nix
    modules/console.nix
    modules/shell
    modules/gpg.nix
    modules/git.nix
    modules/cachix.nix
  ];

  options = {
    secrets = mkSinkUndeclaredOptions {};
    boot.supportedFilesystems = mkOption {
      apply = subtractLists [ "zfs" "btrfs" "reiserfs" "xfs" "cifs" "f2fs" ];
    };
  };

  config = {
    nix.settings = {
      experimental-features = [ "nix-command" "flakes" "ca-derivations" ];
      warn-dirty = false;
    };

    services.getty = {
      helpLine = mkForce "";
      autologinUser = mkForce my.username;
    };

    # networking.useNetworkd = mkForce false;
    # networking.useDHCP = mkForce true;

    # reduce size
    i18n.supportedLocales = [ "en_GB.UTF-8/UTF-8" ];
    documentation.doc.enable = false;
    security.polkit.enable = false;
    services.udisks2.enable = false;
    xdg.sounds.enable = false;
    nixpkgs.overlays = [ (pkgs: prev: {
      linux-firmware = prev.linux-firmware.overrideAttrs (o: {
        postInstall = ''
          rm -rf "$out"/lib/firmware/{netronome,qcom,mellanox,mrvl}
        '';
        outputHash = null;
      });
    }) ];

    system.stateVersion = "21.11";
  };
}
