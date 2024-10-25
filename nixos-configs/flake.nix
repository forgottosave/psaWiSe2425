{
  description = "NixOS configuration with Kea DHCP and PostgreSQL 17";

  inputs = {
    # Use the stable NixOS channel for the base system
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    # Use the unstable channel for the latest Kea package
    unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, unstable }: {
    nixosConfigurations = {
      vmpsateam03-01 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux"; 
        modules = [
          ./configuration.nix
        ];
      };
      vmpsateam03-02 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux"; 
        modules = [
          ./configuration.nix
        ];
      };
      vmpsateam03-03 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux"; 
        modules = [
          ./configuration.nix
          # Include the DHCP-specific configuration with Kea
          (import ./dhcp-config.nix {
            inputs = { inherit unstable; };
          })
        ];
      };
      vmpsateam03-04 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux"; 
        modules = [
          ./configuration.nix
        ];
      };
      vmpsateam03-05 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux"; 
        modules = [
          ./configuration.nix
        ];
      };
      vmpsateam03-06 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux"; 
        modules = [
          ./configuration.nix
        ];
      };
      vmpsateam03-07 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux"; 
        modules = [
          ./configuration.nix
        ];
      };
      vmpsateam03-08 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux"; 
        modules = [
          ./configuration.nix
        ];
      };
      vmpsateam03-09 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux"; 
        modules = [
          ./configuration.nix
        ];
      };
      vmpsateam03-10 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux"; 
        modules = [
          ./configuration.nix
        ];
      };
    };
  };
}
