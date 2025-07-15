{ pkgs }:

{ name ? "gambit-dev"
, dependencies ? []
, gambit ? pkgs.gambit
, extraPackages ? []
, shellHook ? ""
}:

pkgs.mkShell {
  inherit name;
  
  buildInputs = [
    gambit
    pkgs.rlwrap          # Better REPL experience
    pkgs.nixpkgs-fmt     # Nix formatting  
    pkgs.nil             # Nix LSP
    pkgs.gdb
  ] ++ dependencies ++ extraPackages;
  
  # Set up environment consistently with build functions
  LIBRARY_PATH = "${pkgs.openssl.out}/lib";
  GAMBIT_GSC_PATH = pkgs.lib.concatMapStringsSep ":" (dep: "${dep}") dependencies;
  GAMBIT_GSI_PATH = pkgs.lib.concatMapStringsSep ":" (dep: "${dep}") dependencies;
  
  shellHook = ''
    alias gsi='rlwrap gsi'
    echo "🎲 Gambit Scheme Development Environment"
    echo "Commands: gsi, gsc | Libraries: ${toString (builtins.length dependencies)}"
    ${shellHook}
  '';
}