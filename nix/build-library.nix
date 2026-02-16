{ pkgs }:

{ name
, src
, version ? "0.1.0"
, dependencies ? [ ]
, gambit ? pkgs.gambit
, buildInputs ? [ ]
, nativeBuildInputs ? [ ]
, buildPhase ? null
, installPhase ? null
, meta ? { }
}:

pkgs.stdenv.mkDerivation {
  pname = name;
  inherit version src;

  nativeBuildInputs = [ gambit ] ++ nativeBuildInputs;
  buildInputs = buildInputs;
  propagatedBuildInputs = dependencies;

  # This setup hook ensures that this library's path is added to GAMBIT_LOAD_PATH
  # when it is used as a dependency.
  setupHook = pkgs.writeText "gambit-setup-hook.sh" ''
    addGambitLoadPath() {
      if [ -d "$1/share/gambit/modules" ]; then
        export GAMBIT_LOAD_PATH="''${GAMBIT_LOAD_PATH-}''${GAMBIT_LOAD_PATH:+:}$1/share/gambit/modules"
      fi
    }
    addEnvHooks "$targetOffset" addGambitLoadPath
  '';

  buildPhase = if buildPhase != null then buildPhase else ''
    runHook preBuild

    # Build -:search= flags from dependencies (for inter-library imports)
    SEARCH_FLAGS=""
    ${pkgs.lib.concatMapStringsSep "\n" (dep: ''
      if [ -d "${dep}/share/gambit/modules" ]; then
        SEARCH_FLAGS="$SEARCH_FLAGS,search=${dep}/share/gambit/modules"
      fi
    '') dependencies}

    mkdir -p build_artifacts

    # Compile each .sld module for static linking.
    # gsc -c produces .c files with the correct linker IDs for gsc -link.
    find . -name "*.sld" -type f | while read -r sld; do
      rel="''${sld#./}"
      base=$(basename "$rel" .sld)
      dir=$(dirname "$rel")

      mkdir -p "build_artifacts/$dir"
      echo "Compiling $rel"

      # Scheme -> C for static linking.
      # -:search= flags (deps + current tree) must come first,
      # then -c -o controls output location.
      gsc "-:search=$(pwd)$SEARCH_FLAGS" -c -o "build_artifacts/$dir/$base.c" "$sld"

      # C -> Object
      gsc -obj "build_artifacts/$dir/$base.c"
    done

    runHook postBuild
  '';

  installPhase = if installPhase != null then installPhase else ''
    runHook preInstall

    # Install .sld sources for import resolution during downstream compilation
    mkdir -p $out/share/gambit/modules
    find . -name "*.sld" -type f | while read -r sld; do
      rel="''${sld#./}"
      dir=$(dirname "$rel")
      mkdir -p "$out/share/gambit/modules/$dir"
      cp "$sld" "$out/share/gambit/modules/$rel"
    done

    # Install .c and .o files for static linking
    mkdir -p $out/lib/gambit/modules
    cp -r build_artifacts/* $out/lib/gambit/modules/

    runHook postInstall
  '';

  meta = {
    description = "Gambit Scheme library: ${name}";
    platforms = pkgs.lib.platforms.unix;
  } // meta;
}
