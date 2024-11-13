{ pkgs, ... }:
{
  services.kea-dhcp4.enable = true;
  services.kea-dhcp4.settings = {
    "Dhcp4" = {
      # Allgemeine Einstellungen für den DHCP-Server
      "interfaces-config" = {
        "interfaces" = [ "enp0s8" ];
      };
      
      # Überwacht nur das spezifizierte Subnetz
      "subnet4" = [
        {
          # Subnetz und Team spezifische IP-Bereiche
          "subnet" = "192.168.3.0/24"; 
          "pools" = [
            { "pool" = "192.168.3.1 - 192.168.3.200"; }
          ];
          "client-class" = "vm1"; # TODO vm2

          # Domain-Informationen und Routen
          "option-data" = [
            { "name" = "domain-name"; "data" = "psa-team03.cit.tum.de"; }
            { "name" = "domain-name-servers"; "data" = "192.168.3.3"; }
            { "name" = "routers"; "data" = "192.168.3.3"; }
            { "name" = "netmask"; "data" = "255.255.255.0"; }
            { "name" = "wpad"; "data" = "http://pac.lrz.de"; }
            # { "name" = "classless-static-routes"; "data" = "192.168.1.0/24,192.168.3.1, 192.168.3.0/24,192.168.1.1"; } # https://webinar.defaultroutes.de/webinar/15-kea-options-workshop.html
          ];

          # static IP-Adressen für vm1 & vm2
          #https://kb.isc.org/docs/what-are-host-reservations-how-to-use-them
          "reservations" = [
            {
              "hw-address" = "08:00:27:7a:a5:78"; 
              "ip-address" = "192.168.3.1";     
              "hostname" = "vm1";
            }
            {
              "hw-address" = "08:00:27:4b:46:40";  
              "ip-address" = "192.168.3.2";     
              "hostname" = "vm2";
            }
          ];
        }
      ];

      # Steuerung von Anfragen, um nur auf bestimmte Clients zu antworten
      # https://kb.isc.org/docs/understanding-client-classification
      "client-classes" = [
        {
          "name" = "vm1";
          "test" = "pkt4.giaddr == 192.168.3.1";
        }
        {
          "name" = "vm2";
          "test" = "pkt4.giaddr == 192.168.3.2";
        }
      ];
    };
  };
}