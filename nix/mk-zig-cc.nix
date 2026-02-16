{ pkgs }:

{
  zig ? pkgs.zig,
  target ? null,
}:

let
  targetFlag = if target != null then "-target ${target}" else "";
in
pkgs.writeShellScriptBin "zigcc" ''
  export ZIG_LOCAL_CACHE_DIR="''${ZIG_LOCAL_CACHE_DIR:-$TMPDIR/zig-cache}"
  export ZIG_GLOBAL_CACHE_DIR="''${ZIG_GLOBAL_CACHE_DIR:-$TMPDIR/zig-cache-global}"
  exec ${zig}/bin/zig cc ${targetFlag} "$@"
''
