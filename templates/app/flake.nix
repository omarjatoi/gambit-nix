{
  description = "Gambit Scheme application";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    gambit-nix.url = "github:omarjatoi/gambit-nix";
  };

  outputs = { nixpkgs, flake-utils, gambit-nix, ... }@inputs:
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
      in {
        packages.default = pkgs.gambit-lib.buildGambitApp {
          name = "my-app";
          src = ./.;
          dependencies = gambitDeps;
        };
        
        devShells.default = pkgs.gambit-lib.gambitDevShell {
          dependencies = gambitDeps;
        };
        
        apps.default = flake-utils.lib.mkApp {
          drv = inputs.self.packages.${system}.default;
        };
      });
}