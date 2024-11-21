{
  description = "NixOS configuration with Kea DHCP and PostgreSQL 17";

  inputs = {
    # Use the stable NixOS channel for the base system
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    # Use the unstable channel for the latest Kea package
    unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, unstable }: {
    nixosConfigurations = {
      vmpsateam03-03 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux"; 
        modules = [
          ./configuration.nix
          # Include the DHCP-specific configuration with Kea
          (import ./dhcp-config.nix {
            inputs = { inherit unstable; };
          })
          # Database configuration using PostgreSQL 17
          (import ./database.nix {
            inputs = { inherit unstable; };
            pkgs = nixpkgs.legacyPackages."x86_64-linux";
          })
        ];
      };
    };
  };
}
