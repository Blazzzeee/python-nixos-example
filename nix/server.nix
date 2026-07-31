{
  description = "basic python project wrapper";

  inputs = {
    pyproject-nix = {
      url = "github:nix-community/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    pyproject-nix,
    ...
  }: let
    system = "x86_64-linux";
    inherit (nixpkgs) lib;

    project = pyproject-nix.lib.project.loadPyproject {
      projectRoot = ../.;
    };

    pkgs = nixpkgs.legacyPackages.${system};

    python = pkgs.python3;
  in {
    packages.${system}.default = let
      attrs = project.renderers.buildPythonPackage {inherit python;};
    in
      python.pkgs.buildPythonPackage attrs;
  };
}
