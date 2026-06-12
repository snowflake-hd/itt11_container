{
  description = "ITT11 Container Development Environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
  };

  outputs = { self, nixpkgs }: let
    system = "x86_64-linux";

    pkgs = import nixpkgs {
        inherit system;

        config.allowUnfree = true;
     };

    lib = import ./modules/lib.nix;

    mariadb = import ./modules/mariadb.nix {
      inherit pkgs self lib;
    };

    mongodb = import ./modules/mongodb.nix {
      inherit pkgs self lib;
    };
  in {
    devShells.${system} = {
      default = mariadb;
      mariadb = mariadb;
      mongodb = mongodb;
    };
  };
}