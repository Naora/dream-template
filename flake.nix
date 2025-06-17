{
  description = "dream template";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@{ self, nixpkgs, flake-parts, ... }:
  flake-parts.lib.mkFlake { inherit inputs; } {
    systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];
    perSystem = { config, system, inputs', self', ... }:
    let
      pkgs = nixpkgs.legacyPackages.${system};
      ocamlPackages = pkgs.ocaml-ng.ocamlPackages_5_2;
      inherit (pkgs) mkShell;
      inherit (ocamlPackages) buildDunePackage;
      version = "0.0.1+dev";
    in
    {
      packages = {
        default = buildDunePackage {
          inherit version;
          pname = "dream-template";
          buildInputs = with ocamlPackages; [
                dream
                pure-html
                containers
                fmt
                yojson
                caqti-driver-postgresql
                ppx_deriving
                pkgs.dbmate
          ];
          src = ./.;
        };
      };

      devShells = {
        default = mkShell {
          inputsFrom = [
            self'.packages.default
          ];
          packages = with ocamlPackages; [
            pkgs.postgresql
            pkgs.tailwindcss_4
            ocaml-lsp
            ocamlformat
            odoc
            pkgs.just
          ];

          shellHook = ''
              ### Setup: Env vars ###
              echo "Setting up env vars"
              # APPLICATION
              export DREAM_DATABASE="postgresql://postgres@localhost:5432/dream-template"
              # DBMATE
              export DATABASE_URL="$DREAM_DATABASE?sslmode=disable"
              # POSTGRESQL
              export PG_DATA=".pg"
              export PG_HOST="/tmp"

              ### Setup: DB ###
              [ ! -d $PG_DATA ] && initdb -U postgres -D $PG_DATA

              pg_ctl -D $PG_DATA -o "-k $PG_HOST" -l "$PG_DATA/logs" start


              ### Run: Migrations ###
              echo "Running migrations"
              dbmate wait
              dbmate up
          '';
        };
      };

      formatter = pkgs.alejandra;
    };
  };
}
