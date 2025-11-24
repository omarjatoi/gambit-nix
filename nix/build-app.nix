{ pkgs }:

{ name
, src
, version ? "0.1.0"
, main ? "main.scm"
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
  buildInputs = dependencies ++ buildInputs ++ [ pkgs.openssl ];

  LIBRARY_PATH = "${pkgs.lib.getLib pkgs.openssl}/lib";

  buildPhase = if buildPhase != null then buildPhase else ''
    runHook preBuild

    echo "Scanning dependencies for Gambit modules..."

    SEARCH_FLAGS=""
    DEP_C_FILES=""
    DEP_O_FILES=""

    # Iterate over all inputs to find Gambit artifacts
    # This includes direct and propagated dependencies found in buildInputs
    for dep in $buildInputs; do
      # 1. Search Paths (for source visibility during compilation)
      if [ -d "$dep/share/gambit/modules" ]; then
        SEARCH_FLAGS="$SEARCH_FLAGS -:search=$dep/share/gambit/modules"
      fi

      # 2. Pre-compiled Objects and C files (for linking)
      if [ -d "$dep/lib/gambit/modules" ]; then
        echo "Found compiled modules in $dep"
        # Find all .c and .o files. Sort them to ensure deterministic order within the lib.
        # We accumulate them to pass to the linker.
        c_found=$(find "$dep/lib/gambit/modules" -name "*.c" | sort)
        o_found=$(find "$dep/lib/gambit/modules" -name "*.o" | sort)

        DEP_C_FILES="$DEP_C_FILES $c_found"
        DEP_O_FILES="$DEP_O_FILES $o_found"
      fi
    done

    echo "Compiling application..."
    APP_BASENAME=$(basename "${main}" .scm)

    # Compile main source to C
    # We rely on SEARCH_FLAGS to resolve (import ...) statements to .sld files in dependencies
    gsc $SEARCH_FLAGS -c -o "$APP_BASENAME.c" "${main}"

    # Compile main C to Object
    gsc -obj -o "$APP_BASENAME.o" "$APP_BASENAME.c"

    echo "Linking application..."

    # Generate Link File (contains initialization logic)
    # Must include ALL C files (dependencies + app)
    # Dependency order is approximated by buildInputs order + local sort
    gsc -link -o "${name}_.c" $DEP_C_FILES "$APP_BASENAME.c"

    # Compile Link File
    gsc -obj -o "${name}_.o" "${name}_.c"

    # Create Final Executable
    # Links all objects (dependencies + app + linker_obj)
    gsc -exe -o "${name}" $DEP_O_FILES "$APP_BASENAME.o" "${name}_.o"

    runHook postBuild
  '';

  installPhase = if installPhase != null then installPhase else ''
    runHook preInstall
    mkdir -p $out/bin
    install -m755 "${name}" $out/bin/
    runHook postInstall
  '';

  meta = {
    description = "Gambit Scheme application: ${name}";
    platforms = pkgs.lib.platforms.unix;
    mainProgram = name;
  } // meta;
}
