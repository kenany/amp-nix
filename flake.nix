{
  description = "Nix package for Amp - Frontier coding agent for your terminal and editor";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }: let
    overlay = final: prev: {
      amp-cli = final.callPackage ./package.nix {};
    };
  in
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [overlay];
      };
    in {
      packages = {
        default = pkgs.amp-cli;
        amp-cli = pkgs.amp-cli;
      };

      apps = {
        default = {
          type = "app";
          program = "${pkgs.amp-cli}/bin/amp";
        };
        amp-cli = {
          type = "app";
          program = "${pkgs.amp-cli}/bin/amp";
        };
      };

      devShells.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          cachix
          nix-prefetch-git
          nixpkgs-fmt
          nushell
        ];
      };
    })
    // {
      overlays.default = overlay;
    };
}
