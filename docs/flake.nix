{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      flake = false;
    };
    nixvim = {
      url = "github:nix-community/nixvim";
      flake = false;
    };
    root = {
      url = "path:./..";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      flake-utils,
      nixpkgs,
      home-manager,
      nixvim,
      root,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import (nixvim + /docs/pkgs.nix) {
          inherit system nixpkgs;
        };
        lib = import (home-manager + /modules/lib/stdlib-extended.nix) pkgs.lib;

        moduleOptions =
          mod:
          builtins.removeAttrs ((lib.evalModules {
            modules = [
              { config._module.check = false; }
              mod
            ];
            specialArgs = {
              inherit pkgs;
            };
          }).options) [ "_module" ];

        options = {
          nixos = moduleOptions root.nixosModules.default;
          hm = moduleOptions root.homeManagerModules.default;
        };

        options-json = builtins.mapAttrs (
          k: options:
          (pkgs.nixosOptionsDoc {
            inherit options;
            warningsAreErrors = false;
          }).optionsJSON
        ) options;
      in
      {
        packages.default =
          pkgs.runCommand "generate-docs"
            {
              nativeBuildInputs = with pkgs; [
                nixos-render-docs
              ];
            }
            ''
              mkdir $out
              ${lib.concatLines (
                builtins.attrValues (
                  builtins.mapAttrs (k: v: ''
                    nixos-render-docs -j $NIX_BUILD_CORES options commonmark \
                      --manpage-urls ${pkgs.path}/doc/manpage-urls.json \
                      --revision "" \
                      ${v}/share/doc/nixos/options.json \
                      $out/${lib.toUpper k}.md
                  '') options-json
                )
              )}
            '';
      }
    );
}
