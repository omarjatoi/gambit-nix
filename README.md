# gambit-nix

Nix build system for [Gambit Scheme](https://gambitscheme.org/) with an overlay that wraps the Gambit compiler toolchain.

## Features

*   **Nix Overlay**: Integration into existing Nix projects via a single overlay.
*   **R7RS Support**: First-class support for R7RS library definitions (`.sld` files using `define-library`).
*   **Cached Compilation**: Libraries are compiled to C and object files once and reused across application builds.
*   **Static Linking**: Applications are statically linked with their dependencies.
*   **Development Shell**: Pre-configured `gsi` REPL with access to your project's dependencies.

## Usage

Add `gambit-nix` to your `flake.nix` inputs and apply the overlay:

```nix
inputs.gambit-nix.url = "github:omarjatoi/gambit-nix";

# inside outputs:
pkgs = import nixpkgs {
  inherit system;
  overlays = [ gambit-nix.overlays.default ];
};
```

### Libraries

Libraries must use R7RS `define-library` in `.sld` files. The build compiles each `.sld` to C and object files for static linking, and installs the sources for downstream import resolution.

```nix
my-lib = pkgs.gambit-overlay.buildGambitLibrary {
  name = "my-lib";
  src = ./lib; # Directory containing .sld files
};
```

### Applications

```nix
my-app = pkgs.gambit-overlay.buildGambitApp {
  name = "my-app";
  src = ./src;
  main = "main.scm";  # Entry point (default: main.scm)
  dependencies = [ my-lib ];
};
```

The app build compiles only the application source. Pre-compiled dependency objects are linked directly from the Nix store without recompilation.

### Git Dependencies

Include libraries from Git repositories by adding them to your `flake.nix` inputs.

**Library is a Nix Flake:**

```nix
inputs.some-lib.url = "github:user/repo";

# inside buildGambitApp:
dependencies = [ inputs.some-lib.packages.${system}.default ];
```

**Non-Nix Gambit library:**

```nix
inputs.some-lib-src.url = "github:user/repo";

# inside outputs:
some-lib = pkgs.gambit-overlay.buildGambitLibrary {
  name = "some-lib";
  src = inputs.some-lib-src;
};
```

### Development Shell

```nix
devShells.default = pkgs.gambit-overlay.gambitDevShell {
  dependencies = [ my-lib ];
};
```

Inside the shell, `gsi` and `gsc` are wrapped with the correct search paths:

```
$ gsi
> (import (my-lib))
> (my-function ...)
```

## License

Licensed under either of

- Apache License, Version 2.0, ([LICENSE-APACHE](./LICENSE-APACHE) or https://www.apache.org/licenses/LICENSE-2.0)
- MIT license ([LICENSE-MIT](./LICENSE-MIT) or https://opensource.org/licenses/MIT)

at your option.

### Contribution

Unless you explicitly state otherwise, any contribution intentionally submitted for inclusion in the work by you, as defined in the Apache-2.0 license, shall be dual licensed as above, without any additional terms or conditions.
