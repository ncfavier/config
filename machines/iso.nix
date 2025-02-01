{
  identity = {
    isISO = true;
    hostname = null;
  };

  nixos = { lib, modulesPath, myModulesPath, pkgs, ... }: with lib; {
    imports = [
      "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
      "${myModulesPath}/theme.nix"
      "${myModulesPath}/networking.nix"
      "${myModulesPath}/home-manager.nix"
      "${myModulesPath}/users.nix"
      "${myModulesPath}/localisation.nix"
      "${myModulesPath}/console.nix"
      "${myModulesPath}/shell"
      "${myModulesPath}/gpg.nix"
      "${myModulesPath}/git.nix"
      "${myModulesPath}/nix.nix"
    ];

    options = {
      secrets = mkSinkUndeclaredOptions {};
    };

    config = {
      boot.supportedFilesystems = genAttrs [ "reiserfs" "xfs" "cifs" "f2fs" ] (_: mkForce false);

      console.font = "Lat2-Terminus16";

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
        });
      }) ];

      environment.systemPackages = with pkgs; [
        sops
        age
        ssh-to-age
      ];

      environment.variables.EDITOR = "vim";
    };
  };
}
