---
icon: lucide/snowflake
---

# Nix & NixOS

Kubus ships a flake, so Nix users get the same desktop app as everyone else —
installed declaratively, with no `chmod +x` and no AppImage lying around in
`~/Downloads`.

Under the hood the Nix package wraps the official release AppImage, so it is the
identical binary the [releases page](https://github.com/FloSch62/Kubus/releases)
serves; Nix only adds the desktop entry, the icons and the runtime libraries.

## Try it

```bash
nix run github:FloSch62/Kubus
```

## Install it

=== "Imperatively"

    ```bash
    nix profile install github:FloSch62/Kubus
    ```

=== "NixOS (flake)"

    ```nix
    {
      inputs.kubus.url = "github:FloSch62/Kubus";

      outputs = { nixpkgs, kubus, ... }: {
        nixosConfigurations.your-host = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            kubus.nixosModules.default
            { programs.kubus.enable = true; }
          ];
        };
      };
    }
    ```

    `programs.kubus.enable` installs the app system-wide, along with its
    `.desktop` entry so it shows up in your launcher. To pin a package built
    elsewhere, set `programs.kubus.package`.

=== "Home Manager / systemPackages"

    ```nix
    environment.systemPackages = [ kubus.packages.x86_64-linux.default ];
    ```

## Don't build it yourself

The Nix CI workflow (`nix/ci/nix-workflow.yml`, copy it to
`.github/workflows/nix.yml`) builds the package on every push to `main` and
pushes the closure to a [Cachix](https://cachix.org) binary cache, so an install
is a download rather than a build. Trust the cache once:

```nix
nix.settings = {
  substituters = [ "https://kubus.cachix.org" ];
  # Printed by `cachix use kubus`, and on the cache's Cachix page.
  trusted-public-keys = [ "kubus.cachix.org-1:<public-key>" ];
};
```

Without the cache, Nix still doesn't compile anything — it fetches the same
~140 MB AppImage the download page serves and wraps it locally.

## Development shell

```bash
nix develop
```

Gives you the Node.js and Go toolchains the workspace expects
([building from source](../community/development.md)), without installing them
globally.

## Supported platforms

`x86_64-linux` only, matching the Linux artifacts the release workflow
publishes. macOS and other architectures still use the
[desktop downloads](desktop.md).

## Updating

Flake inputs are pinned, so a new Kubus release reaches you when you refresh
the input:

```bash
nix flake update kubus   # in your own flake
```
