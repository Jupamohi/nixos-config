{
  description = "NixOS config de Juan Pablo";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
	zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  }; 

    outputs = inputs@{ self, nixpkgs, home-manager, plasma-manager, ... }:
    let
      system = "x86_64-linux";
      mkHost = hardwareFile: nixpkgs.lib.nixosSystem {
        inherit system;
		specialArgs = { inherit inputs; };
        modules = [
          ./configuration.nix
          hardwareFile
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.sharedModules = [ plasma-manager.homeModules.plasma-manager ];
            home-manager.users.jupamohi = import ./home.nix;
          }
        ];
      };
    in {
      nixosConfigurations = {
        laptopVM = mkHost ./hosts/hardware-laptopVM/hardware-configuration.nix;
        maicolVM = mkHost ./hosts/hardware-maicolVM/hardware-configuration.nix;
        # NEW_HOST_MARKER
      };
    };
}
