{ inputs, config, pkgs, lib, here, ... }: {
  _module.args = let
    importNixpkgs = nixpkgs: import nixpkgs {
      inherit (config.nixpkgs) localSystem crossSystem config overlays;
    };
  in {
    pkgsStable = importNixpkgs inputs.nixos-stable;
  };

  nix = {
    package = pkgs.nixFlakes;

    trustedUsers = [ "root" "@wheel" ];

    nixPath = [ "nixpkgs=${inputs.nixos}" ];

    registry = {
      config.flake = inputs.self;
      nixos.flake = inputs.nixos;
      nixpkgs.flake = inputs.nixos;
      nixos-stable.flake = inputs.nixos-stable;
    };

    gc = {
      automatic = true;
      options = "--delete-older-than 30d";
    };
    optimise.automatic = true;

    extraOptions = ''
      experimental-features = nix-command flakes ca-references
      warn-dirty = false
      keep-outputs = true
      keep-derivations = true
    '';
  };

  nixpkgs = {
    overlays = [ inputs.nur.overlay ];
    config.allowUnfree = true; # :(
  };

  environment.systemPackages = with pkgs; [
    nixfmt
    nix-prefetch-github
    nixpkgs-fmt
    nixpkgs-review
  ];

  environment.sessionVariables.NIX_SHELL_PRESERVE_PROMPT = "1";

  programs.command-not-found.enable = false;
  hm.programs.nix-index.enable = true; # TODO nix-index

  hm.home.file.".nix-defexpr/default.nix".text = ''
    { wip ? false }: let
      self = builtins.getFlake (if wip then ${lib.strings.escapeNixString config.lib.meta.configPath} else "config");
      machines = self.nixosConfigurations;
      local = machines.${lib.strings.escapeNixIdentifier here.hostname};
    in {
      inherit self local;
      inherit (self) lib;
      inherit (local) config;
    } // machines // local._module.args
  '';
}
