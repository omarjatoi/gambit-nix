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

  LIBRARY_PATH = "${pkgs.openssl.out}/lib";

  buildPhase = if buildPhase != null then buildPhase else ''
    runHook preBuild
    find . -name "*.scm" -type f -exec gsc {} \;
    runHook postBuild
  '';

  installPhase = if installPhase != null then installPhase else ''
    runHook preInstall
    mkdir -p $out
    find . -name "*.o[0-9]*" -exec install -m644 {} $out/ \;
    find . -name "*.scm" -exec install -m644 {} $out/ \;
    runHook postInstall
  '';

  meta = {
    description = "Gambit Scheme library: ${name}";
    platforms = pkgs.lib.platforms.unix;
  } // meta;
}
