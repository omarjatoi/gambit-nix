{
  description = "Modern Nix build system for Gambit Scheme";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ self.overlays.default ];
          };
        in
        {
          # Development shell for working on gambit-nix itself
          devShells.default = pkgs.mkShell {
            buildInputs = with pkgs; [
              gambit
              nixpkgs-fmt
              nil # Nix LSP
            ];
          };
        }
      ) // {
      # Main overlay providing Gambit build functions
      overlays.default = import ./nix/overlay.nix;

      # Templates for new Gambit projects
      templates = {
        app = {
          path = ./templates/app;
          description = "Template for a Gambit Scheme application";
        };
        library = {
          path = ./templates/library;
          description = "Template for a Gambit Scheme library";
        };
      };
    };
}
