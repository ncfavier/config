{ lib, modulesPath, ... }: with lib; {
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal-new-kernel.nix"
    # TODO: use enable options
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
      experimental-features = nix-command flakes ca-derivations
      warn-dirty = false
    '';

    networking.useDHCP = true;

    i18n.supportedLocales = [ "en_GB.UTF-8/UTF-8" ];
    documentation.doc.enable = false;
    security.polkit.enable = false;
    services.udisks2.enable = false;
    xdg.sounds.enable = false;
    nixpkgs.overlays = [ (pkgs: prev: {
      firmwareLinuxNonfree = prev.firmwareLinuxNonfree.overrideAttrs (o: { # TODO linux-firmware
        postInstall = ''
          rm -rf "$out"/lib/firmware/{netronome,qcom,mellanox,mrvl}
        '';
        outputHash = "sha256-+rIkG+iWAfuUxboWXs2XxtMfnJfPIt0s18r+1HmlEGo=";
      });
    }) ];

    system.stateVersion = "21.11";
  };
}
