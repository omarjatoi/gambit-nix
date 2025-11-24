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

  # Ensure linker can find OpenSSL if Gambit was built with it
  LIBRARY_PATH = "${pkgs.lib.getLib pkgs.openssl}/lib";

  buildPhase = if buildPhase != null then buildPhase else ''
    runHook preBuild

    # Create a writable directory for modules to avoid "Permission denied"
    # when gsc tries to write intermediate .c files next to sources.
    mkdir -p _gambit_modules

    # Copy dependency modules into the writable directory
    ${pkgs.lib.concatMapStringsSep "\n" (dep: ''
      if [ -d "${dep}/share/gambit/modules" ]; then
        # Use cp -L to follow symlinks and copy actual content
        cp -L -r "${dep}/share/gambit/modules/." _gambit_modules/
      fi
    '') dependencies}

    # Ensure the copied files are writable
    chmod -R u+w _gambit_modules

    # Find all dependency source files (scheme libraries)
    # We explicitly compile these into the executable to ensure static linking
    DEP_SOURCES=$(find _gambit_modules -type f \( -name "*.sld" -o -name "*.scm" \) | sort)

    # Compile the executable
    # Runtime options (starting with -:) must come first
    # -:search=DIR: add DIR to list of directories to search for included/imported files
    # -exe: create executable
    # -o: output file
    gsc -:search=$(pwd)/_gambit_modules -exe -o "${name}" $DEP_SOURCES "${main}"

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
