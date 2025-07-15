{
  description = "Example Gambit Scheme application using gambit-nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    gambit-nix.url = "path:.."; # normally would be "github:omarjatoi/gambit-nix"
  };

  outputs = { self, nixpkgs, flake-utils, gambit-nix, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { 
          inherit system;
          overlays = [ gambit-nix.overlays.default ];
        };
        
        # Build the print library
        print-lib = pkgs.gambit-lib.buildGambitLibrary {
          name = "print";
          src = ./lib;
        };
      in {
        packages = {
          default = pkgs.gambit-lib.buildGambitApp {
            name = "hello-world";
            src = ./src;
            main = "app.scm";
            dependencies = [ print-lib ];
          };
          
          # Also expose the library
          print = print-lib;
        };
        
        devShells.default = pkgs.gambit-lib.gambitDevShell {
          dependencies = [ print-lib ];
        };
        
        apps.default = flake-utils.lib.mkApp {
          drv = self.packages.${system}.default;
        };
      });
}
