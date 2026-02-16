{ pkgs }:

{ name ? "gambit-dev"
, dependencies ? [ ]
, gambit ? pkgs.gambit
, extraPackages ? [ ]
, shellHook ? ""
}:

let
  resolveDep = dep:
    if dep ? packages
    then dep.packages.${pkgs.system}.default
    else dep;
  resolvedDeps = map resolveDep dependencies;
in

pkgs.mkShell {
  inherit name;

  buildInputs = [
    gambit
    pkgs.rlwrap # Better REPL experience
  ] ++ resolvedDeps ++ extraPackages;

  shellHook = ''
    # Calculate search paths from dependencies
    GAMBIT_SEARCH_FLAGS=""
    DEPENDENCIES="${toString resolvedDeps}"

    for dep in $DEPENDENCIES; do
      if [ -d "$dep/share/gambit/modules" ]; then
        GAMBIT_SEARCH_FLAGS="$GAMBIT_SEARCH_FLAGS -:search=$dep/share/gambit/modules"
      fi
    done

    # Define wrappers for gsi and gsc to include search paths
    # We use functions instead of aliases to ensure flags are passed even in scripts if sourced

    gsi() {
      command ${pkgs.rlwrap}/bin/rlwrap ${gambit}/bin/gsi $GAMBIT_SEARCH_FLAGS "$@"
    }

    gsc() {
      command ${gambit}/bin/gsc $GAMBIT_SEARCH_FLAGS "$@"
    }

    export -f gsi
    export -f gsc
    export GAMBIT_SEARCH_FLAGS

    echo "🎲 Gambit Scheme Development Environment"
    echo "Commands: gsi, gsc (wrapped with search paths)"
    if [ -n "$GAMBIT_SEARCH_FLAGS" ]; then
      echo "Search Flags: $GAMBIT_SEARCH_FLAGS"
    fi
    ${shellHook}
  '';
}
