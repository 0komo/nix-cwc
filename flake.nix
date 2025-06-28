{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-compat.url = "github:edolstra/flake-compat";
  };

  outputs =
    { nixpkgs, flake-utils, ... }:
    let
      inherit (nixpkgs) lib;

      mkPackageSet = final: {
        cwc = final.callPackage ./pkgs/cwc { };
      };
    in
    lib.mergeAttrsList [
      (flake-utils.lib.eachDefaultSystem (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          packages = mkPackageSet pkgs;
        }
      ))

      rec {
        overlays.default = final: prev: mkPackageSet final;

        nixosModules.default = import ./modules/nixos { inherit mkPackageSet; };
        nixosModules.cwc = nixosModules.default;

        homeManagerModules.default = import ./modules/home-manager { inherit mkPackageSet; };
        homeManagerModules.cwc = homeManagerModules.default;
      }
    ];
}
