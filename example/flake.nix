{
  description = "Example Gambit Scheme application using gambit-nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    gambit-nix.url = "path:.."; # normally would be "github:omarjatoi/gambit-nix"
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      gambit-nix,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ gambit-nix.overlays.default ];
        };

        zigcc = pkgs.gambit-overlay.mkZigCC { };

        # Build the print library
        print-lib = pkgs.gambit-overlay.buildGambitLibrary {
          name = "print";
          src = ./lib;
        };

        # Build the print library with zig cc
        print-lib-zig = pkgs.gambit-overlay.buildGambitLibrary {
          name = "print";
          src = ./lib;
          cc = zigcc;
        };
      in
      {
        packages = {
          default = pkgs.gambit-overlay.buildGambitApp {
            name = "hello-world";
            src = ./src;
            main = "app.scm";
            dependencies = [ print-lib ];
          };

          # Build with zig cc
          hello-world-zig = pkgs.gambit-overlay.buildGambitApp {
            name = "hello-world";
            src = ./src;
            main = "app.scm";
            cc = zigcc;
            dependencies = [ print-lib-zig ];
          };

          # Also expose the library
          print = print-lib;
        };

        devShells.default = pkgs.gambit-overlay.gambitDevShell {
          dependencies = [ print-lib ];
        };

        apps.default = flake-utils.lib.mkApp {
          drv = self.packages.${system}.default;
        };
      }
    );
}
