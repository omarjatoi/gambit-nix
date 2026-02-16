{
  description = "Gambit Scheme application";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    gambit-nix.url = "github:omarjatoi/gambit-nix";
  };

  outputs = { self, nixpkgs, flake-utils, gambit-nix, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ gambit-nix.overlays.default ];
        };

        # Add your Gambit library dependencies here
        gambitDeps = [
          # inputs.some-gambit-lib
        ];
      in
      {
        packages.default = pkgs.gambit-overlay.buildGambitApp {
          name = "my-app";
          src = ./.;
          dependencies = gambitDeps;
        };

        devShells.default = pkgs.gambit-overlay.gambitDevShell {
          dependencies = gambitDeps;
        };

        apps.default = flake-utils.lib.mkApp {
          drv = self.packages.${system}.default;
        };
      });
}
