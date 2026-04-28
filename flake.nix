{
  description = "nicebucket - A fast, private, open-source S3 GUI built with Tauri";

  nixConfig = {
    extra-substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    bun2nix = {
      url = "github:nix-community/bun2nix/2.0.8";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, bun2nix }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = [ bun2nix.overlays.default ];
        };

        cargoToml = builtins.fromTOML (builtins.readFile ./src-tauri/Cargo.toml);
      in
      rec {
        packages.default = pkgs.rustPlatform.buildRustPackage rec {
          pname = cargoToml.package.name;
          version = cargoToml.package.version;

          src = self;

          cargoRoot = "src-tauri";

          cargoLock = {
            lockFile = ./src-tauri/Cargo.lock;
            allowBuiltinFetchGit = true;
          };

          postPatch = ''
            ${pkgs.jq}/bin/jq 'del(.scripts.postinstall)' package.json > $TMPDIR/package.json
            cp $TMPDIR/package.json package.json
          '';

          bunDeps = pkgs.bun2nix.fetchBunDeps {
            bunNix = ./.nix/bun.nix;
          };

          buildInputs = with pkgs; [
            openssl
            glib
            webkitgtk_4_1
            gtk3
            libsoup_3
            glib-networking
            libayatana-appindicator
            libx11
          ];

          nativeBuildInputs = with pkgs; [
            pkg-config
            cargo-tauri.hook
            wrapGAppsHook3
            pkgs.bun2nix.hook
            jq
            rustPlatform.bindgenHook
          ];

          doCheck = false;

          preBuild = ''
            export HOME=$TMPDIR
            bun run build
          '';

          installPhase = ''
            runHook preInstall
            mkdir -p $out
            cd src-tauri
            mv target/${pkgs.stdenv.hostPlatform.rust.rustcTarget}/release/bundle/deb/*/data/usr/* $out/ 2>/dev/null || true
            cd ..
            mkdir -p $out/bin
            find src-tauri/target -name nicebucket -type f -executable -not -path "*/deps/*" -not -path "*/bundle/*" -exec install -Dm755 {} $out/bin/nicebucket \;
            runHook postInstall
          '';

          postInstall = ''
            if [ -d "$out/src-tauri/icons" ]; then
              mkdir -p $out/share/icons/hicolor/256x256/apps
              if [ -f "$out/src-tauri/icons/icon.png" ]; then
                cp $out/src-tauri/icons/icon.png $out/share/icons/hicolor/256x256/apps/nicebucket.png
              fi
            fi
          '';

          meta = with pkgs.lib; {
            description = "A fast, private, open-source S3 GUI built with Tauri";
            homepage = "https://github.com/nicebucket-org/nicebucket";
            license = licenses.gpl3Only;
            maintainers = [ ];
            platforms = platforms.linux;
            mainProgram = "nicebucket";
          };
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            bun
            nodejs
          ];

          nativeBuildInputs = with pkgs; [
            pkg-config
            cargo
            rustc
            rustfmt
            clippy
            rust-analyzer
            cargo-tauri
            pkgs.bun2nix
          ];

          shellHook = ''
            echo "nicebucket development environment"
            echo "Run 'bun install' to install frontend dependencies"
            echo "Run 'bun run tauri dev' to start the app in development mode"
          '';

          RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";
          OPENSSL_NO_VENDOR = 1;
        };
      }
    );
}
