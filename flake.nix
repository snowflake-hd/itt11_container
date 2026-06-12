{
  description = "ITT11 Container Development Environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
  };

  outputs = { self, nixpkgs }: let
    system = "x86_64-linux";

    pkgs = nixpkgs.legacyPackages.${system};

    mariadb = import ./modules/mariadb.nix {
      inherit pkgs self;
    };
    default = import ./modules/default.nix {
      inherit pkgs self;
    };
  in {
    devShells.${system} = {
      default = default;
      mariadb = mariadb;
    };
  };
}