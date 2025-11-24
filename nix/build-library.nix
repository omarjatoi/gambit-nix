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

  LIBRARY_PATH = "${pkgs.lib.getLib pkgs.openssl}/lib";

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

    # Prepare search path for compilation (including dependencies)
    SEARCH_FLAGS=""
    ${pkgs.lib.concatMapStringsSep "\n" (dep: ''
      if [ -d "${dep}/share/gambit/modules" ]; then
        SEARCH_FLAGS="$SEARCH_FLAGS -:search=${dep}/share/gambit/modules"
      fi
    '') dependencies}

    mkdir -p build_artifacts

    # Find all Scheme files
    find . -type f \( -name "*.sld" -o -name "*.scm" \) | while read -r file; do
      rel_path=''${file#./}
      base_name=$(basename "$rel_path" | sed 's/\.[^.]*$//')
      dir_name=$(dirname "$rel_path")

      mkdir -p "build_artifacts/$dir_name"

      echo "Compiling $file ..."

      # Compile to C
      # We output the C file to the artifacts directory
      gsc $SEARCH_FLAGS -c -o "build_artifacts/$dir_name/$base_name.c" "$file"

      # Compile C to Object
      gsc -obj -o "build_artifacts/$dir_name/$base_name.o" "build_artifacts/$dir_name/$base_name.c"
    done

    runHook postBuild
  '';

  installPhase = if installPhase != null then installPhase else ''
    runHook preInstall

    # Install sources to share/gambit/modules (for static analysis / macro expansion)
    mkdir -p $out/share/gambit/modules
    cp -r ./* $out/share/gambit/modules/
    # Remove the build artifacts from the source tree copy if they were created there
    rm -rf $out/share/gambit/modules/build_artifacts

    # Install compiled objects and C files to lib/gambit/modules
    mkdir -p $out/lib/gambit/modules
    cp -r build_artifacts/* $out/lib/gambit/modules/

    runHook postInstall
  '';

  meta = {
    description = "Gambit Scheme library: ${name}";
    platforms = pkgs.lib.platforms.unix;
  } // meta;
}
