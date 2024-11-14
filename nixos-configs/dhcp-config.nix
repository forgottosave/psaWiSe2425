{ inputs, ... }:
let 
  overlay-kea-unstable = final: prev: {
    kea = inputs.unstable.legacyPackages."x86_64-linux".kea;
  };
in
{
  imports = [
    { nixpkgs.overlays = [ overlay-kea-unstable ]; }
  ];

  services.kea.dhcp4.enable = {
    enable = true;
    configFile = ./dhcp4-config.json;
  };
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