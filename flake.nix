{
  description = "nicebucket - A fast, private, open-source S3 GUI built with Tauri";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        # Platform-specific dependencies  
        buildInputs = with pkgs; [
          openssl
          glib
        ] ++ lib.optionals stdenv.isLinux [
          # Linux-specific dependencies
          webkitgtk_4_1
          gtk3
          libsoup_3
          glib-networking
          libayatana-appindicator
        ] ++ lib.optionals stdenv.isDarwin [
          # macOS-specific dependencies
          libiconv
        ];

        nativeBuildInputs = with pkgs; [
          pkg-config
          nodejs_20
          cargo
          rustc
          rust.packages.stable.rustPlatform.cargoSetupHook
        ] ++ lib.optionals stdenv.isLinux [
          wrapGAppsHook3
        ];

      in
      {
        packages.default = pkgs.rustPlatform.buildRustPackage rec {
          pname = "nicebucket";
          version = "0.3.3";

          src = ./.;

          # Hash of the Cargo dependencies
          cargoHash = "sha256-VxvjMgn2fzuOAecTVdM7nLxUEzSxX5ONaDzX9k3+j54=";
          
          cargoRoot = "src-tauri";

          inherit buildInputs nativeBuildInputs;

          # Build the frontend before building the Rust backend
          preBuild = ''
            # Install frontend dependencies
            npm ci --cache .npm-cache

            # Build the frontend
            npm run build
          '';

          # Tauri needs these environment variables during build
          OPENSSL_NO_VENDOR = 1;

          installPhase = ''
            runHook preInstall

            mkdir -p $out/bin
            
            # Install the binary
            install -Dm755 target/release/nicebucket $out/bin/nicebucket

            runHook postInstall
          '';

          # Linux-specific post-install for desktop integration
          postInstall = pkgs.lib.optionalString pkgs.stdenv.isLinux ''
            # Install desktop file if it exists
            if [ -d "src-tauri/icons" ]; then
              mkdir -p $out/share/icons/hicolor/256x256/apps
              if [ -f "src-tauri/icons/icon.png" ]; then
                cp src-tauri/icons/icon.png $out/share/icons/hicolor/256x256/apps/nicebucket.png
              fi
            fi
          '';

          meta = with pkgs.lib; {
            description = "A fast, private, open-source S3 GUI built with Tauri";
            homepage = "https://github.com/nicebucket-org/nicebucket";
            license = licenses.gpl3Only;
            maintainers = [ ];
            platforms = platforms.linux ++ platforms.darwin;
            mainProgram = "nicebucket";
          };
        };

        # Development shell with all required dependencies
        devShells.default = pkgs.mkShell {
          inherit buildInputs;
          
          nativeBuildInputs = nativeBuildInputs ++ (with pkgs; [
            # Additional dev tools
            rustfmt
            clippy
            rust-analyzer
          ]);

          shellHook = ''
            echo "nicebucket development environment"
            echo "Run 'npm install' to install frontend dependencies"
            echo "Run 'npm run dev' to start the development server"
            echo ""
            echo "Available tools:"
            echo "  - cargo $(cargo --version | cut -d' ' -f2)"
            echo "  - rustc $(rustc --version | cut -d' ' -f2)"
            echo "  - node $(node --version)"
            echo "  - npm $(npm --version)"
          '';

          # Environment variables for development
          RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";
          OPENSSL_NO_VENDOR = 1;
        };

        # Allow building with 'nix build .#nicebucket'
        packages.nicebucket = self.packages.${system}.default;
      }
    );
}
