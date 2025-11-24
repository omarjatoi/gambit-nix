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

    # Construct search paths for Gambit modules from dependencies
    # We look for the 'share/gambit/modules' directory in each dependency

    SEARCH_FLAGS=""
    ${pkgs.lib.concatMapStringsSep "\n" (dep: ''
      if [ -d "${dep}/share/gambit/modules" ]; then
        SEARCH_FLAGS="$SEARCH_FLAGS -:search=${dep}/share/gambit/modules"
      fi
    '') dependencies}

    echo "Building ${name} with search flags: $SEARCH_FLAGS"

    # Compile the executable
    # -exe: create executable
    # -o: output file
    # -:search=DIR: add DIR to list of directories to search for included/imported files
    gsc $SEARCH_FLAGS -exe -o "${name}" "${main}"

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
