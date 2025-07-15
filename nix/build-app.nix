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
  buildInputs = dependencies ++ buildInputs;

  # Set up environment at derivation level
  LIBRARY_PATH = "${pkgs.openssl.out}/lib";
  GAMBIT_GSC_PATH = pkgs.lib.concatMapStringsSep ":" (dep: "${dep}") dependencies;

  buildPhase = if buildPhase != null then buildPhase else ''
    runHook preBuild
    
    # Copy dependency files to namespaced subdirectories
    ${pkgs.lib.concatMapStringsSep "\n" (dep: ''
      mkdir -p "${dep.name or (builtins.baseNameOf dep)}"
      cp -r ${dep}/* "${dep.name or (builtins.baseNameOf dep)}/"
    '') dependencies}
    
    gsc -exe -o "${name}" "${main}"
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
