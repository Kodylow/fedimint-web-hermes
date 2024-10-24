{
  description = "A hermes lnaddress server for the fedimint web extension";

  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-24.05";
    };

    flakebox = {
      url = "github:rustshop/flakebox?rev=ee39d59b2c3779e5827f8fa2d269610c556c04c8";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flakebox,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
        lib = pkgs.lib;
        flakeboxLib = flakebox.lib.${system} { };
        rustSrc = flakeboxLib.filterSubPaths {
          root = builtins.path {
            name = "fedimint-web-hermes";
            path = ./.;
          };
          paths = [
            "Cargo.toml"
            "Cargo.lock"
            ".cargo"
            "src"
            "fedimint-web-hermes"
          ];
        };

        toolchainArgs =
          let
            llvmPackages = pkgs.llvmPackages_11;
          in
          {
            components = [
              "rustc"
              "cargo"
              "clippy"
              "rust-analyzer"
              "rust-src"
            ];

            args = {
              nativeBuildInputs = [ ] ++ lib.optionals (!pkgs.stdenv.isDarwin) [ ];
            };
          };

        # all standard toolchains provided by flakebox
        toolchainsStd = flakeboxLib.mkStdFenixToolchains toolchainArgs;

        toolchainsNative = (pkgs.lib.getAttrs [ "default" ] toolchainsStd);

        toolchainNative = flakeboxLib.mkFenixMultiToolchain { toolchains = toolchainsNative; };

        commonArgs = {
          buildInputs =
            [ ]
            ++ lib.optionals pkgs.stdenv.isDarwin [ pkgs.darwin.apple_sdk.frameworks.SystemConfiguration ];
          nativeBuildInputs = [ pkgs.pkg-config ];
        };
        outputs = (flakeboxLib.craneMultiBuild { toolchains = toolchainsStd; }) (
          craneLib':
          let
            craneLib =
              (craneLib'.overrideArgs {
                pname = "flexbox-multibuild";
                src = rustSrc;
              }).overrideArgs
                commonArgs;
          in
          rec {
            workspaceDeps = craneLib.buildWorkspaceDepsOnly { };
            workspaceBuild = craneLib.buildWorkspace { cargoArtifacts = workspaceDeps; };
            fedimint-web-hermes = craneLib.buildPackageGroup {
              pname = "fedimint-web-hermes";
              packages = [ "fedimint-web-hermes" ];
              mainProgram = "fedimint-web-hermes";
            };

            fedimint-web-hermes-oci = pkgs.dockerTools.buildLayeredImage {
              name = "fedimint-web-hermes";
              contents = [ fedimint-web-hermes ];
              config = {
                Cmd = [ "${fedimint-web-hermes}/bin/fedimint-web-hermes" ];
              };
            };
          }
        );
      in
      {
        legacyPackages = outputs;
        packages = {
          default = outputs.fedimint-web-hermes;
        };
        devShells = flakeboxLib.mkShells {
          packages = [ ];
          buildInputs = commonArgs.buildInputs;
          nativeBuildInputs = [ ];
          shellHook = ''
            export RUST_LOG="info"
          '';
        };
      }
    );
}
