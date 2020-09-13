{
  description = "ncfavier's configurations";

  inputs = {
    nixpkgs.url = "nixpkgs/master";
    nixos.url = "nixpkgs/release-20.09";
    home-manager.url = "github:rycee/home-manager/bqv-flakes";
  };

  outputs = inputs: {};
}
