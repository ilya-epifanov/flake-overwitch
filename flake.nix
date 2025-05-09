{
  description = "A flake for building Overwitch";

  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixos-unstable;
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }: 
    flake-utils.lib.eachDefaultSystem (system: let 
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      packages = rec {
        overwitch = pkgs.stdenv.mkDerivation {
          name = "overwitch";
          src = pkgs.fetchFromGitHub {
            owner = "ilya-epifanov";
            repo = "overwitch";
            rev = "56dd2dbe23e78518c2007d3565f0b2222ae8f15f";
#	    hash = nixpkgs.lib.fakeHash;
            hash = "sha256-QCS5ZqGC9NBiU+chkFp2v76FfPJbMFqNNJneA+95NgQ=";
          };

          nativeBuildInputs = with pkgs; [
            pkg-config
            autoreconfHook
            wrapGAppsHook
          ];

          buildInputs = with pkgs; [
            libtool
            libusb1
            libjack2
            libsamplerate
            libsndfile
            gettext
            json-glib
            gtk4
          ];

          postInstall = ''
            # install udev/hwdb rules
            mkdir -p $out/etc/udev/rules.d/
            mkdir -p $out/etc/udev/hwdb.d/
            cp ./udev/*.hwdb $out/etc/udev/hwdb.d/
            cp ./udev/*.rules $out/etc/udev/rules.d/
          '';
        };
        default = overwitch;
      };

      #### Dev shell (for `nix develop`)
      devShells.default = pkgs.mkShell {
        inputsFrom = [ self.packages ];
      };

  }) // 
  {
      #### NixOS module (`programs.overwitch`)
      nixosModules.default = { config, lib, pkgs, ...}:
      with lib;
      let cfg = config.services.overwitch;
      in {
          options.services.overwitch = {
              enable = mkEnableOption "Enables Overwitch";
          };

          config = mkIf cfg.enable {
            environment.systemPackages = [ self.packages.${pkgs.system}.overwitch ];
            services.udev.packages = [ self.packages.${pkgs.system}.overwitch ];
          };
        };
      };
}
