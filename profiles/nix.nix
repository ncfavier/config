{ inputs, config, me, ... }: {
  nix = {
    trustedUsers = [ "root" "@wheel" ];

    gc = {
      automatic = true;
      options = "--delete-older-than 30d";
    };
    optimise.automatic = true;

    extraOptions = ''
      warn-dirty = false
      keep-outputs = true
      keep-derivations = true
    '';
  };

  nixpkgs.config.allowUnfree = true;

  home-manager.users.${me}.home.file.".nix-defexpr/default.nix".text = ''
    let
      nixos = import (builtins.getFlake "nixos") {};
      nixpkgs = import (builtins.getFlake "nixpkgs") {};
      self = builtins.getFlake "self";
      inherit (nixos) lib;
      machines = self.nixosConfigurations;
      local = self.nixosConfigurations.${config.networking.hostName};
    in {
      inherit nixos nixpkgs self lib local;
      inherit (local) config;
    } // machines // local._module.args
  '';
}
