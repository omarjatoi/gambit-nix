# gambit-nix

Nix build system for [Gambit Scheme](https://gambitscheme.org/) with an overlay that wraps the Gambit compiler toolchain.

## Features

*   **Nix Overlay**: Easy integration into existing Nix projects.
*   **R7RS Support**: First-class support for R7RS library definitions (`define-library`).
*   **Cached Compilation**: Libraries are compiled to C/Object files once and reused across applications.
*   **Static Linking**: Applications are statically linked with their dependencies for easy distribution.
*   **Development Shell**: Provides a pre-configured `gsi` REPL with access to your project's dependencies.

## Usage

Add `gambit-nix` to your `flake.nix` inputs and apply the overlay.

### Applications

Define your application derivation and list your libraries in `dependencies`.

```nix
my-app = pkgs.gambit-overlay.buildGambitApp {
  name = "my-app";
  src = ./src;
  main = "main.scm";  # Entry point
  dependencies = [ my-lib ];
};
```

### Libraries

Define your library derivation. Source files (`.sld`, `.scm`) are installed to the search path and compiled to object files.

```nix
{
  # ...
  outputs = { self, nixpkgs, gambit-nix, ... }: {
    # ...
    my-lib = pkgs.gambit-overlay.buildGambitLibrary {
      name = "my-lib";
      src = ./lib; # Directory containing .sld files
    };
  };
}
```
#### Git Dependencies

You can include libraries from Git repositories by adding them to your `flake.nix` inputs.

- **Library is a Nix Flake**

  ```nix
  inputs.gambit-library-flake.url = "github:user/repo";
  
  # ... inside buildGambitApp ...
  dependencies = [ inputs.gambit-library-flake.packages.${system}.default ];
  ```

- **Non-nix Gambit Library**

  ```nix
  inputs.gambit-library-src.url = "github:user/repo";
  
  # ... inside outputs ...
  remote-lib = pkgs.gambit-overlay.buildGambitLibrary {
    name = "remote-lib";
    src = inputs.gambit-library-src;
  };
  ```

### Development Shell

Get a shell with `gsi` and `gsc` configured to find your dependencies.

```nix
devShells.default = pkgs.gambit-overlay.gambitDevShell {
  dependencies = [ my-lib ];
};
```

Inside the shell:
```bash
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
