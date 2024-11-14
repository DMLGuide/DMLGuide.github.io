{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      devShells.default = pkgs.mkShell {
        nativeBuildInputs = [ pkgs.bashInteractive ];
        buildInputs = [ 
          pkgs.ruby
          pkgs.bundler
          pkgs.jekyll
          pkgs.bundix
          pkgs.dart-sass
          pkgs.gcc
          pkgs.gnumake
          pkgs.stdenv.cc.cc.lib
        ];
        
        shellHook = ''
          export GEM_HOME="$PWD/.gems"
          export GEM_PATH="$GEM_HOME:$PWD/vendor/bundle"
          export PATH="$GEM_HOME/bin:$PATH"
          export BUNDLE_PATH="$PWD/vendor/bundle"
          export LD_LIBRARY_PATH="${pkgs.stdenv.cc.cc.lib}/lib"

          # Check if vendor/bundle exists, if not install gems
          if [ ! -d "vendor/bundle" ]; then
            echo "Installing gems..."
            bundle install
            bundix
          fi
        '';
      };
    });
}