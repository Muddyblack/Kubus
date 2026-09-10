{
  description = "Kubus - a free, open-source Kubernetes GUI";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      # The release workflow ships a Linux x86_64 AppImage only; add systems
      # here when electron-builder starts producing more Linux targets.
      systems = [ "x86_64-linux" ];
      forAll = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAll (pkgs: rec {
        kubus = pkgs.callPackage ./nix/kubus/package.nix { };
        default = kubus;
      });

      apps = forAll (pkgs: rec {
        kubus = {
          type = "app";
          program = nixpkgs.lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.kubus;
          meta.description = "Run the Kubus desktop app";
        };
        default = kubus;
      });

      # NixOS users can `programs.kubus.enable = true;` instead of hand-adding
      # the package; the module exists so desktop integration has one place to
      # grow (MIME handler registration, wrapper flags) without breaking users.
      nixosModules.default =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        let
          cfg = config.programs.kubus;
        in
        {
          options.programs.kubus = {
            enable = lib.mkEnableOption "the Kubus Kubernetes GUI";
            package = lib.mkOption {
              type = lib.types.package;
              default = self.packages.${pkgs.stdenv.hostPlatform.system}.kubus;
              defaultText = lib.literalExpression "kubus";
              description = "The Kubus package to install.";
            };
          };

          config = lib.mkIf cfg.enable {
            environment.systemPackages = [ cfg.package ];
          };
        };

      # Node and Go toolchains for the workspace build (pnpm build,
      # pnpm build:helm-engine). Packaging the desktop app itself is the
      # release workflow's job, not this shell's.
      devShells = forAll (pkgs: {
        default = pkgs.mkShell {
          packages = [
            pkgs.nodejs_24
            pkgs.pnpm
            pkgs.go
          ];
        };
      });

      checks = forAll (pkgs: {
        kubus = self.packages.${pkgs.stdenv.hostPlatform.system}.kubus;
      });

      formatter = forAll (pkgs: pkgs.nixfmt-rfc-style);
    };
}
