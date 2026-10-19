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
	dms = {
      url = "github:AvengeMedia/DankMaterialShell/stable";
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
          ./caelestia-kde/module.nix
		  ./modules/nixos/sddm-caelestia.nix
		  ./modules/nixos/linoffice.nix
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
			home-manager.backupFileExtension = "backup";
			home-manager.overwriteBackup = true;
            home-manager.sharedModules = [
              plasma-manager.homeModules.plasma-manager
              inputs.dms.homeModules.dank-material-shell
            ];
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
