{
  description = "Loxedo's reproducible NixOS configuration for Acer Nitro ANV15-51";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-flatpak.url = "github:gmodena/nix-flatpak";

    crystal = {
      url = "github:namishh/crystal/aura";
      flake = false;
    };

    somewm-stable.url = "github:trip-zip/somewm/release/1.4";
    somewm-dev.url = "github:trip-zip/somewm/main";
  };

  outputs = inputs@{ self, nixpkgs, home-manager, disko, nix-flatpak, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in {
      packages.${system} = {
        somewm-stable = import ./pkgs/somewm.nix {
          inherit pkgs;
          src = inputs.somewm-stable;
          version = "1.4.3";
          wlrootsVersion = "0.19";
        };

        somewm-dev = import ./pkgs/somewm.nix {
          inherit pkgs;
          src = inputs.somewm-dev;
          version = "2.0-dev";
          wlrootsVersion = "0.20";
        };
      };

      overlays.default = final: prev: {
        somewm-stable = self.packages.${system}.somewm-stable;
        somewm-dev = self.packages.${system}.somewm-dev;
      };

      nixosConfigurations.nitro-v15 = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          disko.nixosModules.disko
          nix-flatpak.nixosModules.nix-flatpak
          ./hosts/nitro-v15
          home-manager.nixosModules.home-manager
          {
            nixpkgs.overlays = [ self.overlays.default ];
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit inputs; };
            home-manager.users.loxedo = import ./home/loxedo;
          }
        ];
      };
    };
}