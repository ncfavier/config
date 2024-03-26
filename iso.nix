{ lib, modulesPath, ... }: with lib; {
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
    modules/theme.nix
    modules/networking.nix
    modules/home-manager.nix
    modules/users.nix
    modules/localisation.nix
    modules/console.nix
    modules/shell
    modules/gpg.nix
    modules/git.nix
    modules/nix.nix
  ];

  options = {
    secrets = mkSinkUndeclaredOptions {};
    boot.supportedFilesystems = mkOption {
      apply = subtractLists [ "reiserfs" "xfs" "cifs" "f2fs" ];
    };
  };

  config = {
    services.getty.autologinUser = mkForce my.username;

    # start wpa-supplicant on boot
    systemd.services.wpa_supplicant.wantedBy = mkForce [ "multi-user.target" ];

    # reduce size by removing unneeded firmware
    nixpkgs.overlays = [ (pkgs: prev: {
      linux-firmware = prev.linux-firmware.overrideAttrs (o: {
        postInstall = ''
          rm -rf "$out"/lib/firmware/{netronome,qcom,mellanox,mrvl,ath11k,ath10k,libertas}
          find -L "$out" -type l -delete # remove dangling symlinks so that compressFirmwareXz doesn't complain
        '';
        outputHash = null;
      });
    }) ];
  };
}
