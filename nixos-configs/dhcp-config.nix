{
#  description = "NixOS configuration with nixpkgs-unstable overlay";
#
#  # Define the inputs section
#  inputs = {
#    # Standard nixpkgs input for stable packages (replace with desired branch or channel)
#    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
#
#    # Add nixpkgs-unstable as an input for access to unstable packages
#    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
#  };
#
#  # Define the outputs section, configuring NixOS modules with the unstable overlay
#  outputs = { self, nixpkgs, nixpkgs-unstable, ... }:
#    let
#      # Create an overlay for using packages from nixpkgs-unstable
#      unstableOverlay = final: prev: {
#        kea = nixpkgs-unstable.legacyPackages.x86_64-linux.kea;
#      };
#    in {
#      # NixOS system configuration
#      nixosConfigurations.my-machine = nixpkgs.lib.nixosSystem {
#        system = "x86_64-linux";
#        modules = [
#          ./configuration.nix
#
#          # Apply the overlay by including it in nixpkgs.overlays
#          {
#            nixpkgs.overlays = [ unstableOverlay ];
#
#            # Enable and configure the Kea DHCP service
#            services.kea.dhcp4 = {
#              enable = true;
#              configFile = ./dhcp4-config.json;
#            };
#          }
#        ];
#      };
#    };
}

#    # Interfaces, auf denen der DHCP-Server arbeitet
#    "interfaces-config" = {
#      "interfaces" = [ "enp0s8/192.168.3.3" ];
#      "dhcp-socket-type" = "raw";
#    };
#
#    # Lease Datenbank
#    "lease-database" = {
#        "type" = "memfile";
#        "persist" = true;
#        "name" = "/var/lib/kea/dhcp4.leases";
#        "lfc-interval" = 1800;
#    };
#
#    # DHCP soll nicht antworten, falls angefragte IP nicht verfügbar
#    "host-reservation-identifiers" = [ "hw-address" ];
#    "authoritative" = false;
#
#    
#    # definition einer option für wpad
#    "option-def" = [
#        {
#            "code" = 252;
#            "name" = "wpad";
#            "type" = "string";
#        }
#    ];
#
#    # Überwacht nur das spezifizierte Subnetz
#    "subnet4" = [
#      {
#        # Subnetz und Team spezifische IP-Bereiche
#        "subnet" = "192.168.3.0/24"; 
#        "pools" = [];
#        "reservations-out-of-pool" = true;
#        "reservations" = [
#          {
#            "hw-address" = "08:00:27:7a:a5:78"; 
#            "ip-address" = "192.168.3.1";     
#            "hostname" = "vm1";
#          }
#          {
#            "hw-address" = "08:00:27:4b:46:40";  
#            "ip-address" = "192.168.3.2";     
#            "hostname" = "vm2";
#          }
#        ];
#
#         # Domain-Informationen und Routen
#        "option-data" = [
#          { "name" = "domain-name"; "data" = "psa-team03.cit.tum.de";}
#          { "name" = "domain-name-servers"; "data" = "192.168.3.3";}
#          { "name" = "routers"; "data" = "192.168.3.3";}
#          { "name" = "wpad"; "data" = "http://pac.lrz.de";}
#          # https://gitlab.isc.org/isc-projects/kea/-/merge_requests/2135
#          #{
#          #  "code" = 121;
#          #  "name" = "classless-static-route";
#          #  "data" = "192.168.1.0/24 - 192.168.31.1, 192.168.2.0/24 - 192.168.32.1, 192.168.4.0/24 - 192.168.43.1, 192.168.5.0/24 - 192.168.53.1, 192.168.6.0/24 - 192.168.63.1, 192.168.7.0/24 - 192.168.73.1, 192.168.8.0/24 - 192.168.83.1, 192.168.9.0/24 - 192.168.93.1, 192.168.10.0/24 - 192.168.103.1";
#          #  "always-send" = true;
#          #}
#        ];
#      }
#    ];
#
#    # Settings für den Logger
#    #"loggers" = [
#    #  {
#    #    "name" = "kea-dhcp4";
#    #    "output-options" = [
#    #      {
#    #          "output" = "stdout";
#    #      }
#    #    ];
#    #    "severity" = "DEBUG";
#    #  }
#    #];
#
#  };
#}