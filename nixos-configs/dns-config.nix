{ pkgs, ... }:
{
  services.bind = {
    enable = true;
    zones = {
      # OUR TEAM
      "psa-team03.cit.tum.de" = {
        master = true;
        file = pkgs.writeText "zone-psa-team03.cit.tum.de" ''
          $ORIGIN psa-team03.cit.tum.de.
          $TTL    1h
          @            IN      SOA     psa-team03.cit.tum.de. hostmaster (
                                           1    ; Serial
                                           3h   ; Refresh
                                           1h   ; Retry
                                           1w   ; Expire
                                           1h)  ; Negative Cache TTL
                       IN      NS      router
          
          router       IN      A       192.168.3.3
          
          vm1          IN      A       192.168.3.1
          
          vm2          IN      A       192.168.3.2
        '';
      };
      # OUR TEAM - reverse
      "3.168.192.in-addr.arpa" = {
        master = true;
        file = pkgs.writeText "zone-3.168.192.in-addr.arpa" ''
          $TTL    1h
          @            IN      SOA     psa-team03.cit.tum.de. hostmaster.psa-team03.cit.tum.de. (
                                           1    ; Serial
                                           3h   ; Refresh
                                           1h   ; Retry
                                           1w   ; Expire
                                           1h)  ; Negative Cache TTL
                       IN      NS      router.psa-team03.cit.tum.de.
      
          3          IN      PTR       router.psa-team03.cit.tum.de.
      
          1          IN      PTR       vm1.psa-team03.cit.tum.de.
      
          2          IN      PTR       vm2.psa-team03.cit.tum.de.
        '';
      };
      # OTHER TEAMS
      #"psa-team01.cit.tum.de" = {
      #  master = true;
      #  file = "";
      #  extraConfig = "forward only;\nforwarders { 192.168.1.1; };";
      #};
      #     ^
    };#    /|\
    #       |
    #       |
    # for Teams: extraConfig gives the same error as above solution, other DNS servers just not yet reachable...
    
    # DEFAULT
    directory = "/var/cache/bind";
    forward = "only";
    forwarders = [ "131.159.254.1" "131.159.254.2" ];
    extraOptions = ''
      listen-on port 53 { localhost; 192.168.3.3; };

      dnssec-validation auto;
      listen-on-v6 { any; };
    '';

    # non NixOS-able configs: (not supported yet -> use manual insertion)
    extraConfig = ''
      // __ Default _____________________
      // TODO
      
      // __ Teams _______________________
      zone "psa-team01.cit.tum.de" {
        type forward;
        forward only;
        forwarders { 192.168.1.1; };
      };
      zone "psa-team02.cit.tum.de" {
        type forward;
        forward only;
        forwarders { 192.168.2.2; };
      };
      zone "psa-team04.cit.tum.de" {
        type forward;
        forward only;
        forwarders { 192.168.4.4; };
      };
      zone "psa-team05.cit.tum.de" {
        type forward;
        forward only;
        forwarders { 192.168.5.5; };
      };
      zone "psa-team06.cit.tum.de" {
        type forward;
        forward only;
        forwarders { 192.168.6.6; };
      };
      zone "psa-team07.cit.tum.de" {
        type forward;
        forward only;
        forwarders { 192.168.7.7; };
      };
      zone "psa-team08.cit.tum.de" {
        type forward;
        forward only;
        forwarders { 192.168.8.8; };
      };
      zone "psa-team09.cit.tum.de" {
        type forward;
        forward only;
        forwarders { 192.168.9.9; };
      };
      zone "psa-team10.cit.tum.de" {
        type forward;
        forward only;
        forwarders { 192.168.10.10; };
      };

      // __ Teams reverse _______________
      zone "1.168.192.in-addr.arpa" {
        type forward;
        forward only;
        forwarders { 192.168.1.1; };
      };
      zone "2.168.192.in-addr.arpa" {
        type forward;
        forward only;
        forwarders { 192.168.2.2; };
      };
      zone "4.168.192.in-addr.arpa" {
        type forward;
        forward only;
        forwarders { 192.168.4.4; };
      };
      zone "5.168.192.in-addr.arpa" {
        type forward;
        forward only;
        forwarders { 192.168.5.5; };
      };
      zone "6.168.192.in-addr.arpa" {
        type forward;
        forward only;
        forwarders { 192.168.6.6; };
      };
      zone "7.168.192.in-addr.arpa" {
        type forward;
        forward only;
        forwarders { 192.168.7.7; };
      };
      zone "8.168.192.in-addr.arpa" {
        type forward;
        forward only;
        forwarders { 192.168.8.8; };
      };
      zone "9.168.192.in-addr.arpa" {
        type forward;
        forward only;
        forwarders { 192.168.9.9; };
      };
      zone "10.168.192.in-addr.arpa" {
        type forward;
        forward only;
        forwarders { 192.168.10.10; };
      };
      '';
  };
}
