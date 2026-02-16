{ pkgs }:

{
  name,
  src,
  version ? "0.1.0",
  main ? "main.scm",
  dependencies ? [ ],
  gambit ? pkgs.gambit,
  cc ? null,
  buildInputs ? [ ],
  nativeBuildInputs ? [ ],
  buildPhase ? null,
  installPhase ? null,
  meta ? { },
}:

let
  # Resolve dependencies: accept either a derivation or a flake input.
  # Flake inputs are resolved to packages.${system}.default.
  resolveDep = dep: if dep ? packages then dep.packages.${pkgs.system}.default else dep;
  resolvedDeps = map resolveDep dependencies;
  useCustomCC = cc != null;
in

pkgs.stdenv.mkDerivation {
  pname = name;
  inherit version src;

  nativeBuildInputs = [ gambit ] ++ pkgs.lib.optional useCustomCC cc ++ nativeBuildInputs;
  buildInputs = resolvedDeps ++ buildInputs ++ [ pkgs.openssl ];

  LIBRARY_PATH = "${pkgs.lib.getLib pkgs.openssl}/lib";

  buildPhase =
    if buildPhase != null then
      buildPhase
    else
      ''
        runHook preBuild

        ${pkgs.lib.optionalString useCustomCC ''
          # Override C compiler for gsc -obj. BUILD_OBJ_CC_PARAM causes
          # gambuild-C to use this compiler and clear GCC-specific flags.
          export BUILD_OBJ_CC_PARAM="${pkgs.lib.getExe cc}"
        ''}

        SEARCH_FLAGS=""
        DEP_C_FILES=""
        DEP_O_FILES=""

        for dep in $buildInputs; do
          # Search paths for import resolution (reads .sld sources)
          if [ -d "$dep/share/gambit/modules" ]; then
            SEARCH_FLAGS="$SEARCH_FLAGS,search=$dep/share/gambit/modules"
          fi

          # Pre-compiled .c and .o files for linking
          if [ -d "$dep/lib/gambit/modules" ]; then
            DEP_C_FILES="$DEP_C_FILES $(find "$dep/lib/gambit/modules" -name '*.c' -type f | sort)"
            DEP_O_FILES="$DEP_O_FILES $(find "$dep/lib/gambit/modules" -name '*.o' -type f | sort)"
          fi
        done

        APP_BASENAME=$(basename "${main}" .scm)

        echo "Compiling ${main}..."
        # Compile app source to C (-:search= resolves imports to dep .sld files)
        gsc "-:search=$(pwd)$SEARCH_FLAGS" -c "${main}"

        echo "Generating link file..."
        # Generate link file from all .c files (deps + app).
        # -nopreload ensures R7RS modules are initialized in dependency order.
        # gsc -link only reads .c files for metadata — no writes to dep paths.
        gsc -link -nopreload $DEP_C_FILES "$APP_BASENAME.c"

        echo "Compiling objects..."
        # Compile app .c and link file .c to .o
        gsc -obj "$APP_BASENAME.c" "''${APP_BASENAME}_.c"

        echo "Linking ${name}..."
        # Final link: dep .o files (from store) + app .o + link .o
        GAMBIT_LIB="${gambit}/gambit/lib"
        ${
          if useCustomCC then "${pkgs.lib.getExe cc}" else "$CC"
        } $DEP_O_FILES "$APP_BASENAME.o" "''${APP_BASENAME}_.o" \
          -L"$GAMBIT_LIB" -lgambit -o "${name}"

        runHook postBuild
      '';

  installPhase =
    if installPhase != null then
      installPhase
    else
      ''
        runHook preInstall
        mkdir -p $out/bin
        install -m755 "${name}" $out/bin/
        runHook postInstall
      '';

  meta = {
    description = "Gambit Scheme application: ${name}";
    platforms = pkgs.lib.platforms.unix;
    mainProgram = name;
  }
  // meta;
}
