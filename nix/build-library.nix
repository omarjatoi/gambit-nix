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

    # Validating R7RS structure or compiling could happen here.
    # For now, we treat libraries as source distributions to be compiled
    # or loaded by the final application, ensuring maximum compatibility.

    runHook postBuild
  '';

  installPhase = if installPhase != null then installPhase else ''
    runHook preInstall

    mkdir -p $out/share/gambit/modules

    # Copy the entire source tree to the modules directory
    # This supports structures like (scheme base) -> scheme/base.sld
    cp -r ./* $out/share/gambit/modules/

    runHook postInstall
  '';

  meta = {
    description = "Gambit Scheme library: ${name}";
    platforms = pkgs.lib.platforms.unix;
  } // meta;
}
