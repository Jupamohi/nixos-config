{
  description = "NixOS config de Juan Pablo";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";

      mkHost = hardwareFile: extraModules: nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          ./configuration.nix
          hardwareFile
          home-manager.nixosModules.home-manager
          ./modules/nixos/gnome.nix
          ./modules/nixos/linoffice.nix
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "backup";
            home-manager.overwriteBackup = true;
            home-manager.users.jupamohi = import ./home.nix;
          }
        ] ++ extraModules;
      };
    in {
      nixosConfigurations = {
        laptopVM = mkHost ./hosts/hardware-laptopVM/hardware-configuration.nix [ ];
        maicolVM = mkHost ./hosts/hardware-maicolVM/hardware-configuration.nix [ ];
        nitro = mkHost ./hosts/hardware-nitro/hardware-configuration.nix [ ./hosts/hardware-nitro/nitro.nix ];
        # NEW_HOST_MARKER
      };
    };
}
