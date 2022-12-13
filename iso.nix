{ lib, modulesPath, ... }: with lib; {
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal-new-kernel.nix"
    modules/theme.nix
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
      apply = subtractLists [ "reiserfs" "xfs" "cifs" "f2fs" ];
    };
  };

  config = {
    nix.settings = {
      experimental-features = [ "nix-command" "flakes" "ca-derivations" ];
      warn-dirty = false;
    };

    services.getty.autologinUser = mkForce my.username;

    # reduce size by removing unneeded firmware
    nixpkgs.overlays = [ (pkgs: prev: {
      linux-firmware = prev.linux-firmware.overrideAttrs (o: {
        postInstall = ''
          rm -rf "$out"/lib/firmware/{netronome,qcom,mellanox,mrvl,ath11k}
        '';
        outputHash = null;
      });
    }) ];
  };
}
