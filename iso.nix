{ inputs, pkgs, modulesPath, ... }: {
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
    inputs.self.nixosModules.localisation
  ];

  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  environment.systemPackages = with pkgs; [ git ];

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };
}
