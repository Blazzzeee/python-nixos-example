{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";

    flake-utils.url = "github:numtide/flake-utils";

    pyproject-nix = {
      url = "github:nix-community/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    uv2nix = {
      url = "github:pyproject-nix/uv2nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.pyproject-nix.follows = "pyproject-nix";
    };

    pyproject-build-systems = {
      url = "github:pyproject-nix/build-system-pkgs";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.pyproject-nix.follows = "pyproject-nix";
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    flake-utils,
    pyproject-nix,
    uv2nix,
    pyproject-build-systems,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        system = "x86_64-linux";
        inherit (nixpkgs) lib;
        pkgs = nixpkgs.legacyPackages.${system};

        python = pkgs.python3;

        # 1. Loads and parses pyproject.toml and uv.lock
        workspace = uv2nix.lib.workspace.loadWorkspace {
          workspaceRoot = ./.;
        };

        # 2. Generate a nix overlay from uv.lock via workspace
        uvLockedOverlay = workspace.mkPyprojectOverlay {
          sourcePreference = "wheel";
        };

        # 3. Makes a Python package set
        pythonSet = (pkgs.callPackage pyproject-nix.build.packages {inherit python;})
          .overrideScope (pkgs.lib.composeManyExtensions [
          pyproject-build-systems.overlays.default
          uvLockedOverlay
        ]);

        # This must exactly match in toml
        project = "fastapi-app";
        projNixPkg = pythonSet.${project};

        # 4. Generate a python runtime evironment
        PythonEnv =
          pythonSet.mkVirtualEnv
          (projNixPkg.pname + "env")
          workspace.deps.default;
      in {
        nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
          modules = [./configuration.nix];
        };

        packages.default = pkgs.stdenv.mkDerivation {
          pname = projNixPkg.pname;
          version = projNixPkg.version;
          src = ./app;

          nativeBuildInputs = [pkgs.makeWrapper];
          buidlInputs = [PythonEnv];

          installPhase = ''
            mkdir -p $out/bin
            cp main.py $out/bin/${projNixPkg.pname}-script
            chmod +x $out/bin/${projNixPkg.pname}-script
            makeWrapper ${PythonEnv}/bin/python $out/bin/${projNixPkg.pname} \
              --add-flags $out/bin/${projNixPkg.pname}--script

          '';
        };
      }
    );
}
