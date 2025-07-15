# Simple library functions for external use
{ pkgs ? null }:

{
  # Re-export main build functions when pkgs is provided
  buildGambitLibrary = if pkgs != null then (import ./build-library.nix { inherit pkgs; }) else null;
  buildGambitApp = if pkgs != null then (import ./build-app.nix { inherit pkgs; }) else null;
  gambitDevShell = if pkgs != null then (import ./dev-shell.nix { inherit pkgs; }) else null;
}