{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    ...
  }: let
    inherit (nixpkgs) lib;
    forAllSystems = lib.genAttrs lib.systems.flakeExposed;
  in {

    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      modules = [./configuration.nix];
    };
    
    devShells = forAllSystems (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        default = pkgs.mkShell {
          packages = [
            pkgs.python3
            pkgs.uv
          ];

          env = lib.optionalAttrs pkgs.stdenv.isLinux {
            # Python libraries often load native shared objects using dlopen(3).
            # Setting LD_LIBRARY_PATH makes the dynamic library loader aware of libraries without using RPATH for lookup.
            LD_LIBRARY_PATH = lib.makeLibraryPath pkgs.pythonManylinuxPackages.manylinux1;
          };

          shellHook = ''
            unset PYTHONPATH
            uv sync
            . .venv/bin/activate
          '';
        };
      }
    );
  };
}
