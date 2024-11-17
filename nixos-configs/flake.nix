{
  description = "NixOS configuration with Kea DHCP service";

  inputs = {
    # Use the stable NixOS channel for the base system
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    # Use the unstable channel for the latest Kea package
    unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, unstable }: {
    # Define the NixOS configuration
    nixosConfigurations = {
      hostname = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux"; 
        modules = [
          # Include the main system configuration
          ./configuration.nix

          # Include the DHCP-specific configuration with Kea
          (import ./dhcp-config.nix {
            inputs = { inherit unstable; };
          })
        ];
      };
    };
  };
}
