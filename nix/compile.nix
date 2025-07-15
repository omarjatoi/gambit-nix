{ pkgs }:

# Utility function to compile individual Scheme files
{ src
, gambit ? pkgs.gambit
, output ? null
, flags ? []
, dependencies ? []
}:

let
  outputName = if output != null then output else 
    builtins.replaceStrings [".scm"] [".o1"] (baseNameOf src);
in

pkgs.runCommand outputName {
  nativeBuildInputs = [ gambit ];
  GAMBIT_GSC_PATH = pkgs.lib.concatMapStringsSep ":" (dep: "${dep}") dependencies;
  LIBRARY_PATH = "${pkgs.openssl.out}/lib";
} ''
  # Copy source file to build directory
  cp ${src} ./input.scm
  
  # Compile the file to .o1 (dynamically loadable module, default mode)
  gsc ${pkgs.lib.concatStringsSep " " flags} input.scm
  
  # Move output to result
  cp input.o1 $out
''