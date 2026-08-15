{
  description = "Loxedo's reproducible NixOS configuration for Acer Nitro ANV15-51";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Crystal Aura is consumed as an input rather than copied into this repo.
    # This keeps provenance clear and avoids duplicating upstream source.
    crystal.url = "github:namishh/crystal/aura";

    # SomeWM stable 1.4 branch is the Wayland/ Awesome-compatible target.
    # The package is maintained locally under pkgs/somewm.nix because it is not
    # assumed to exist in the selected nixpkgs channel.
    somewm.url = "github:trip-zip/somewm/release/1.4";
  };

  outputs = inputs@{ self, nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      lib = nixpkgs.lib;
    in {
      packages.${system}.somewm = import ./pkgs/somewm.nix {
        pkgs = import nixpkgs { inherit system; };
        src = inputs.somewm;
      };

      nixosConfigurations.nitro-v15 = lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/nitro-v15
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit inputs; };
            home-manager.users.loxedo = import ./home/loxedo;
          }
        ];
      };
    };
}
