{
  description = "ITT11 Container Development Environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
  };

  outputs = { self, nixpkgs }: let
    system = "x86_64-linux";

    pkgs = nixpkgs.legacyPackages.${system};
    lib = import ./modules/lib.nix;

    mariadb = import ./modules/mariadb.nix {
      inherit pkgs self lib;
    };
  in {
    devShells.${system} = {
      default = mariadb;
      mariadb = mariadb;
    };
  };
}