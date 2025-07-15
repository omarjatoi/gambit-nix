final: prev: {
  gambit-lib = {
    # Build a Gambit Scheme library
    buildGambitLibrary = import ./build-library.nix { pkgs = final; };
    
    # Build a Gambit Scheme application
    buildGambitApp = import ./build-app.nix { pkgs = final; };
    
    # Create development shell with Gambit tooling
    gambitDevShell = import ./dev-shell.nix { pkgs = final; };
    
    # Utility functions
    compileGambit = import ./compile.nix { pkgs = final; };
    linkGambitLibs = import ./linker.nix { pkgs = final; };
  };
}