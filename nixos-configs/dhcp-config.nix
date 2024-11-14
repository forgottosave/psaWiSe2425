{ pkgs, ... }:
{
  services.kea.dhcp4.enable = true;
  services.kea.dhcp4.settings = {
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
          { "pool" = "192.168.3.1 - 192.168.3.250"; }
        ];
        "client-class" = "vm1"; # TODO vm2

        # Domain-Informationen und Routen
        "option-data" = [
          { "name" = "domain-name"; "data" = "psa-team03.cit.tum.de"; }
          { "name" = "domain-name-servers"; "data" = "192.168.3.3"; }
          { "name" = "routers"; "data" = "192.168.3.3"; }
          # { "name" = "netmask"; "data" = "255.255.255.0"; } # auto calculated
          # { "name" = "wpad"; "data" = "http://pac.lrz.de"; } # not possible?
          # https://gitlab.isc.org/isc-projects/kea/-/merge_requests/2135
          #{
          #  "code" = 121;
          #  "data" = "192.168.1.0/24 - 192.168.31.1, 192.168.2.0/24 - 192.168.32.1, 192.168.4.0/24 - 192.168.43.1, 192.168.5.0/24 - 192.168.53.1, 192.168.6.0/24 - 192.168.63.1, 192.168.7.0/24 - 192.168.73.1, 192.168.8.0/24 - 192.168.83.1, 192.168.9.0/24 - 192.168.93.1, 192.168.10.0/24 - 192.168.103.1";
          #}

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
}