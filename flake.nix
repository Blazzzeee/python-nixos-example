{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";

    pyproject-nix = {
      url = "github:nix-community/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    pyproject-nix,
    ...
  }: let
    system = "x86_64-linux";
    inherit (nixpkgs) lib;
    pkgs = nixpkgs.legacyPackages.${system};

    server = import ./nix/server.nix {
      inherit pkgs pyproject-nix;
    };
  in {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      modules = [./configuration.nix];
    };

    packages.x86_64-linux = {
      server = server;
    };
  };
}
