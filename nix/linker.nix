{ pkgs }:

# Utility function to link Gambit libraries and objects
{ name
, objects ? []
, libraries ? []
, gambit ? pkgs.gambit
, flags ? []
, output ? null
}:

let
  outputName = if output != null then output else name;
  
  # Collect all .o1 files from libraries
  libraryObjects = pkgs.lib.flatten (map (lib: 
    if builtins.pathExists "${lib}"
    then 
      let
        files = builtins.readDir lib;
        o1Files = builtins.filter (name: pkgs.lib.hasSuffix ".o1" name) (builtins.attrNames files);
      in map (f: "${lib}/${f}") o1Files
    else []
  ) libraries);
  
  # Combine provided objects with library objects
  allObjects = objects ++ libraryObjects;
in

pkgs.runCommand outputName {
  nativeBuildInputs = [ gambit ];
  GAMBIT_GSC_PATH = pkgs.lib.concatMapStringsSep ":" (lib: "${lib}") libraries;
  LIBRARY_PATH = "${pkgs.openssl.out}/lib";
} ''
  # Link all objects together
  gsc -link ${pkgs.lib.concatStringsSep " " flags} ${pkgs.lib.concatStringsSep " " (map toString allObjects)}
  
  # Copy result
  cp ${name}.c $out
''